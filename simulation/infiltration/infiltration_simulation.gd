class_name InfiltrationSimulation
extends RefCounted

var config: InfiltrationConfig
var map: InfiltrationMapData
var player: InfiltrationActor = InfiltrationActor.new()
var targets: Array[InfiltrationActor] = []
var bolts: Array[InfiltrationBolt] = []
var events: Array[InfiltrationEvent] = []
var event_count: int = 0
var dropped_events: int = 0
var tick: int = 0
var target_data: Array[InfiltrationTargetData] = []
var panels: Array[InfiltrationPanel] = []
var reinforcement_ticks: int = -1
var reinforcement_called: bool = false
var _empty_enemy_intent: InfiltrationIntent = InfiltrationIntent.new()
var _panel_requests: PackedByteArray = []


func _init(configuration: InfiltrationConfig, map_data: InfiltrationMapData) -> void:
	config = configuration
	map = map_data
	target_data.assign(map.targets)
	player.position = map.player_spawn
	player.previous = player.position
	player.aim = map.player_direction.normalized()
	player.health = config.health
	player.vigor = config.vigor
	for data in map.targets:
		var target: InfiltrationActor = InfiltrationActor.new()
		target.position = data.position
		target.previous = data.position
		target.aim = data.direction.normalized()
		target.health = data.health
		target.fire_ticks = Ticks.from_seconds(data.initial_delay)
		targets.append(target)
	for placement in map.enemies:
		target_data.append(placement.enemy)
		var actor: InfiltrationActor = InfiltrationActor.new()
		actor.position = placement.position
		actor.previous = actor.position
		actor.last_known = actor.position
		actor.aim = placement.direction.normalized()
		actor.health = 0.0 if placement.reinforcement else placement.enemy.health
		actor.spawned = not placement.reinforcement
		actor.fire_ticks = Ticks.from_seconds(placement.enemy.initial_delay)
		targets.append(actor)
	for panel in map.panels:
		panels.append(InfiltrationPanel.new())
	_panel_requests.resize(panels.size())
	for index in config.projectile_capacity:
		bolts.append(InfiltrationBolt.new())
	for index in config.event_capacity:
		events.append(InfiltrationEvent.new())


func step(intent: InfiltrationIntent, enemy_intents: Array[InfiltrationIntent] = []) -> void:
	event_count = 0
	if player.health <= 0.0:
		return
	tick += 1
	player.previous = player.position
	_advance_player_timers()
	_apply_intent(intent)
	_step_targets()
	_resolve_swing()
	_step_bolts()
	if player.health <= 0.0:
		return
	InfiltrationPerception.step(self)
	_step_enemies(enemy_intents)
	_step_panels()


func _advance_player_timers() -> void:
	player.stun_ticks = maxi(player.stun_ticks - 1, 0)
	player.parry_cooldown = maxi(player.parry_cooldown - 1, 0)
	if player.parry_age >= 0:
		player.parry_age += 1
		if player.parry_age >= Ticks.from_seconds(config.duel_config.parry_window):
			_close_parry()
	if player.swing_tick >= 0:
		player.swing_tick += 1
		if player.swing_tick >= config.swing_ticks():
			player.swing_tick = -1
	player.regeneration_ticks = maxi(player.regeneration_ticks - 1, 0)
	if player.regeneration_ticks == 0:
		player.vigor = minf(player.vigor + config.vigor_regeneration * Ticks.DELTA, config.vigor)


func _apply_intent(intent: InfiltrationIntent) -> void:
	if intent.aim.length_squared() > 0.0:
		player.aim = intent.aim.normalized()
	player.guard = false
	if player.stun_ticks > 0:
		player.velocity = Vector2.ZERO
		_close_parry()
		return
	if (intent.pressed & Intent.Command.POWER) != 0:
		_disable_panel()
	if (intent.pressed & Intent.Command.HEAVY) != 0 and player.swing_tick < 0:
		var victim: int = takedown_target()
		if victim >= 0:
			_emit(InfiltrationEvent.Type.TAKEDOWN_LANDED, 0, victim + 1, targets[victim].position)
			_damage_target(victim, targets[victim].health, true)
	if (intent.pressed & Intent.Command.LIGHT) != 0 and player.swing_tick < 0 and player.vigor >= config.swing_vigor:
		player.swing_tick = 0
		player.swing_id += 1
		player.swing_aim = player.aim
		_spend_vigor(config.swing_vigor)
		_close_parry()
		_emit(InfiltrationEvent.Type.SWING_STARTED, 0, -1, player.position)
		InfiltrationPerception.noise(self, player.position, config.combat_noise, 0)
	if player.swing_tick < 0 and (intent.held & Intent.Command.BLOCK) != 0:
		player.guard = true
		if (intent.pressed & Intent.Command.BLOCK) != 0 and player.parry_cooldown == 0:
			player.parry_age = 0
	elif player.parry_age >= 0:
		_close_parry()
	player.locomotion = InfiltrationActor.Locomotion.WALK
	var speed: float = config.walk_speed
	if (intent.held & Intent.Command.SPECIAL) != 0:
		speed = config.sneak_speed
		player.locomotion = InfiltrationActor.Locomotion.SNEAK
	elif (intent.held & Intent.Command.DODGE) != 0:
		speed = config.run_speed
		player.locomotion = InfiltrationActor.Locomotion.RUN
	if player.guard:
		speed = minf(speed, config.walk_speed * config.guard_speed_ratio)
		if player.locomotion == InfiltrationActor.Locomotion.RUN:
			player.locomotion = InfiltrationActor.Locomotion.WALK
	var movement: Vector2 = intent.movement.limit_length()
	var acceleration: float = config.acceleration if movement.length_squared() > 0.0 else config.deceleration
	player.velocity = player.velocity.move_toward(movement * speed, acceleration * Ticks.DELTA)
	var next: Vector2 = InfiltrationGeometry.move_body(map, player.position, player.velocity * Ticks.DELTA, config.body_radius, targets)
	player.velocity = (next - player.position) / Ticks.DELTA
	player.position = next
	player.walked += player.previous.distance_to(player.position)
	if player.walked >= config.step_distance:
		player.walked -= config.step_distance
		_emit(InfiltrationEvent.Type.FOOTSTEP, 0, -1, player.position, float(player.locomotion))
		var radius: float = config.walk_noise
		if player.locomotion == InfiltrationActor.Locomotion.RUN:
			radius = config.run_noise
		elif player.locomotion == InfiltrationActor.Locomotion.SNEAK:
			radius = config.sneak_noise
		InfiltrationPerception.noise(self, player.position, radius, 0)


func _close_parry() -> void:
	if player.parry_age >= 0:
		player.parry_age = -1
		player.parry_cooldown = Ticks.from_seconds(config.duel_config.parry_lockout)


func _spend_vigor(amount: float) -> void:
	player.vigor = maxf(player.vigor - amount, 0.0)
	player.regeneration_ticks = Ticks.from_seconds(config.regeneration_delay)


func swing_active() -> bool:
	return player.swing_tick >= config.startup_ticks() and player.swing_tick < config.startup_ticks() + config.active_ticks()


func _resolve_swing() -> void:
	if not swing_active():
		return
	for index in targets.size():
		var target: InfiltrationActor = targets[index]
		if target.health <= 0.0 or target.last_swing_id == player.swing_id:
			continue
		if not InfiltrationGeometry.in_sector(player.position, player.swing_aim, target.position, config.swing_reach, config.swing_degrees, config.body_radius):
			continue
		var progress: float = float(player.swing_tick - config.startup_ticks()) / config.active_ticks()
		var angle: float = rad_to_deg(player.swing_aim.angle_to(target.position - player.position))
		var first: float = lerpf(-config.swing_degrees * 0.5, config.swing_degrees * 0.5, progress)
		var last: float = first + config.swing_degrees / config.active_ticks()
		if angle < first - InfiltrationGeometry.EPSILON or angle > last + InfiltrationGeometry.EPSILON:
			continue
		if InfiltrationGeometry.wall_fraction(map, player.position, target.position) != INF:
			continue
		target.last_swing_id = player.swing_id
		_emit(InfiltrationEvent.Type.SWING_HIT, 0, index + 1, target.position, config.swing_damage)
		_damage_target(index, config.swing_damage)


func _step_targets() -> void:
	for index in map.targets.size():
		var target: InfiltrationActor = targets[index]
		var data: InfiltrationTargetData = map.targets[index]
		if target.health <= 0.0:
			if target.respawn_ticks > 0:
				target.respawn_ticks -= 1
				if target.respawn_ticks == 0:
					target.health = data.health
					target.fire_ticks = Ticks.from_seconds(data.initial_delay)
					_emit(InfiltrationEvent.Type.TARGET_RESTORED, index + 1, -1, target.position)
			continue
		if data.kind != InfiltrationTargetData.Kind.EMITTER or data.bolt == null:
			continue
		if target.burst_left == 0:
			target.fire_ticks = maxi(target.fire_ticks - 1, 0)
			if target.fire_ticks == 0:
				target.burst_left = data.bolt.count
				target.burst_ticks = 0
		if target.burst_left > 0:
			target.burst_ticks = maxi(target.burst_ticks - 1, 0)
			if target.burst_ticks == 0:
				fire_bolt(index)
				target.burst_left -= 1
				target.burst_ticks = data.bolt.interval_ticks()
				if target.burst_left == 0:
					target.fire_ticks = Ticks.from_seconds(data.fire_interval)


func fire_bolt(shooter: int) -> InfiltrationBolt:
	var source: InfiltrationActor = targets[shooter]
	var data: BoltData = target_data[shooter].bolt
	var muzzle: Vector2 = source.position + source.aim * (config.body_radius + data.muzzle_forward)
	if InfiltrationGeometry.wall_fraction(map, source.position, muzzle, data.size) != INF:
		return null
	for bolt in bolts:
		if bolt.active:
			continue
		bolt.active = true
		bolt.data = data
		bolt.shooter = shooter
		bolt.origin = source.position
		bolt.owner = shooter + 1
		bolt.position = muzzle
		bolt.previous = bolt.position
		bolt.velocity = source.aim * data.speed
		bolt.travelled = 0.0
		_emit(InfiltrationEvent.Type.SHOT_FIRED, shooter + 1, 0, bolt.position)
		InfiltrationPerception.noise(self, source.position, config.combat_noise, shooter + 1)
		return bolt
	return null


func _step_bolts() -> void:
	for bolt in bolts:
		if player.health <= 0.0:
			return
		if not bolt.active:
			continue
		bolt.previous = bolt.position
		var distance: float = bolt.velocity.length() * Ticks.DELTA
		var remaining: float = bolt.data.max_range - bolt.travelled
		var end: Vector2 = bolt.position + bolt.velocity.normalized() * minf(distance, remaining)
		var fraction: float = InfiltrationGeometry.wall_fraction(map, bolt.position, end, bolt.data.size)
		var victim: int = -1
		if bolt.owner != 0:
			var impact: float = InfiltrationGeometry.segment_box_fraction(bolt.position, end, _body_box(player, bolt.data.size))
			if impact < fraction:
				fraction = impact
				victim = 0
		else:
			for index in targets.size():
				if targets[index].health <= 0.0:
					continue
				var impact: float = InfiltrationGeometry.segment_box_fraction(bolt.position, end, _body_box(targets[index], bolt.data.size))
				if impact < fraction:
					fraction = impact
					victim = index + 1
		if fraction != INF:
			bolt.position = bolt.position.lerp(end, fraction)
			if victim == 0:
				_resolve_player_bolt(bolt)
			else:
				bolt.active = false
				if victim > 0:
					_emit(InfiltrationEvent.Type.BOLT_HIT, bolt.owner, victim, bolt.position, bolt.data.damage)
					_damage_target(victim - 1, bolt.data.damage, false, bolt.origin)
				elif bolt.owner == 0:
					InfiltrationPerception.noise(self, bolt.position, config.reflected_wall_noise, 0)
			continue
		bolt.position = end
		bolt.travelled += minf(distance, remaining)
		if bolt.travelled >= bolt.data.max_range:
			bolt.active = false


func _body_box(actor: InfiltrationActor, padding: float) -> Rect2:
	var radius: float = config.body_radius + padding
	return Rect2(actor.position - Vector2.ONE * radius, Vector2.ONE * radius * 2.0)


func _resolve_player_bolt(bolt: InfiltrationBolt) -> void:
	var front: bool = InfiltrationGeometry.in_sector(Vector2.ZERO, player.aim, -bolt.velocity, INF, config.guard_degrees)
	if player.guard and front:
		if player.parry_age >= 0:
			var perfect: bool = player.parry_age < Ticks.from_seconds(config.duel_config.perfect_parry_window)
			bolt.owner = 0
			bolt.origin = player.position
			bolt.travelled = 0.0
			if perfect:
				bolt.velocity = (targets[bolt.shooter].position - bolt.position).normalized() * bolt.data.speed * bolt.data.perfect_reflect_speed
			else:
				bolt.velocity = -bolt.velocity
			_emit(InfiltrationEvent.Type.BOLT_REFLECTED, 0, bolt.shooter + 1, bolt.position, 1.0 if perfect else 0.0)
		else:
			_spend_vigor(bolt.data.guard_vigor)
			bolt.active = false
			_emit(InfiltrationEvent.Type.BOLT_BLOCKED, bolt.owner, 0, bolt.position)
		InfiltrationPerception.noise(self, bolt.position, config.combat_noise, 0)
		return
	bolt.active = false
	player.health = maxf(player.health - bolt.data.damage, 0.0)
	_emit(InfiltrationEvent.Type.BOLT_HIT, bolt.owner, 0, bolt.position, bolt.data.damage)
	var interruptible: bool = player.swing_tick < 0 or player.swing_tick >= config.startup_ticks() + config.active_ticks()
	if interruptible:
		player.stun_ticks = bolt.data.flinch_ticks()
		player.swing_tick = -1
		player.velocity = Vector2.ZERO
	if player.health == 0.0:
		player.guard = false
		player.swing_tick = -1
		_emit(InfiltrationEvent.Type.DEFEATED, bolt.owner, 0, player.position)


func _damage_target(index: int, damage: float, silent: bool = false, source_position: Vector2 = Vector2(INF, INF)) -> void:
	var target: InfiltrationActor = targets[index]
	target.health = maxf(target.health - damage, 0.0)
	if target.health == 0.0:
		target.respawn_ticks = Ticks.from_seconds(target_data[index].respawn_seconds) if index < map.targets.size() else 0
		target.burst_left = 0
		target.velocity = Vector2.ZERO
		_emit(InfiltrationEvent.Type.TARGET_DISABLED, 0, index + 1, target.position)
	elif index >= map.targets.size() and not silent:
		InfiltrationPerception.alert(self, index, player.position if source_position.x == INF else source_position)


func _emit(type: InfiltrationEvent.Type, source: int, target: int, position: Vector2, amount: float = 0.0) -> void:
	if event_count >= events.size():
		dropped_events += 1
		return
	var event: InfiltrationEvent = events[event_count]
	event_count += 1
	event.type = type
	event.source = source
	event.target = target
	event.position = position
	event.amount = amount


func capture() -> Dictionary:
	var actors: Array[Dictionary] = []
	var projectiles: Array[Dictionary] = []
	var terminals: Array[Dictionary] = []
	for actor in targets:
		actors.append(actor.capture())
	for bolt in bolts:
		projectiles.append(bolt.capture())
	for panel in panels:
		terminals.append(panel.capture())
	return {"tick": tick, "player": player.capture(), "targets": actors, "bolts": projectiles, "dropped_events": dropped_events, "panels": terminals, "reinforcement_ticks": reinforcement_ticks, "reinforcement_called": reinforcement_called}


func restore(state: Dictionary) -> void:
	tick = state.tick
	player.restore(state.player)
	for index in targets.size():
		targets[index].restore(state.targets[index])
	for index in bolts.size():
		bolts[index].restore(state.bolts[index], target_data)
	for index in panels.size():
		panels[index].restore(state.panels[index])
	reinforcement_ticks = state.reinforcement_ticks
	reinforcement_called = state.reinforcement_called
	dropped_events = state.dropped_events
	event_count = 0


func state_hash() -> int:
	return hash(capture())


func enemy_placement(index: int) -> InfiltrationEnemyPlacement:
	return map.enemies[index - map.targets.size()]


func takedown_target() -> int:
	if player.stun_ticks > 0 or player.swing_tick >= 0:
		return -1
	for index in range(map.targets.size(), targets.size()):
		var actor: InfiltrationActor = targets[index]
		if actor.health <= 0.0 or actor.awareness != InfiltrationActor.Awareness.UNAWARE:
			continue
		if not InfiltrationGeometry.in_sector(actor.position, -actor.aim, player.position, config.takedown_range, config.takedown_rear_degrees):
			continue
		if InfiltrationGeometry.in_sector(player.position, player.aim, actor.position, config.takedown_range, config.swing_degrees) and InfiltrationGeometry.wall_fraction(map, player.position, actor.position) == INF:
			return index
	return -1


func nearby_panel() -> int:
	for index in panels.size():
		if not panels[index].disabled and player.position.distance_to(map.panels[index].position) <= config.interaction_range and InfiltrationGeometry.wall_fraction(map, player.position, map.panels[index].position) == INF:
			return index
	return -1


func available_panel(position: Vector2) -> int:
	var nearest: int = -1
	var distance: float = INF
	for index in panels.size():
		if panels[index].disabled or panels[index].active:
			continue
		var candidate: float = position.distance_squared_to(map.panels[index].position)
		if candidate < distance:
			distance = candidate
			nearest = index
	return nearest


func alarm_active() -> bool:
	for panel in panels:
		if panel.active:
			return true
	return false


func _disable_panel() -> void:
	var index: int = nearby_panel()
	if index < 0:
		return
	panels[index].disabled = true
	panels[index].active = false
	panels[index].activation_ticks = 0
	_emit(InfiltrationEvent.Type.PANEL_DISABLED, 0, index, map.panels[index].position)
	if not alarm_active():
		reinforcement_ticks = -1


func _step_enemies(intents: Array[InfiltrationIntent]) -> void:
	_panel_requests.fill(0)
	for index in range(map.targets.size(), targets.size()):
		var actor: InfiltrationActor = targets[index]
		actor.previous = actor.position
		if actor.health <= 0.0:
			continue
		_apply_enemy_intent(index, intents[index] if index < intents.size() else _empty_enemy_intent)


func _apply_enemy_intent(index: int, intent: InfiltrationIntent) -> void:
	var actor: InfiltrationActor = targets[index]
	var data: InfiltrationEnemyData = target_data[index] as InfiltrationEnemyData
	if intent.aim.length_squared() > 0.0:
		actor.aim = intent.aim.normalized()
	actor.decision = InfiltrationActor.Decision.PATROL
	if actor.awareness == InfiltrationActor.Awareness.SUSPICIOUS:
		actor.decision = InfiltrationActor.Decision.INVESTIGATE
	elif actor.awareness == InfiltrationActor.Awareness.ALERTED:
		actor.decision = InfiltrationActor.Decision.FIGHT
	var speed: float = data.speed * (data.alarm_speed_ratio if (intent.held & Intent.Command.DODGE) != 0 else 1.0)
	var movement: Vector2 = intent.movement.limit_length() * speed * Ticks.DELTA
	actor.position = InfiltrationGeometry.move_body(map, actor.position, movement, config.body_radius, targets, actor, player)
	actor.velocity = (actor.position - actor.previous) / Ticks.DELTA
	actor.walked += actor.previous.distance_to(actor.position)
	if actor.walked >= config.step_distance:
		actor.walked -= config.step_distance
		_emit(InfiltrationEvent.Type.FOOTSTEP, index + 1, -1, actor.position)
	var placement: InfiltrationEnemyPlacement = enemy_placement(index)
	if actor.awareness == InfiltrationActor.Awareness.UNAWARE and not placement.route.is_empty() and actor.position.distance_to(placement.route[actor.waypoint]) <= config.waypoint_radius:
		actor.waypoint = (actor.waypoint + 1) % placement.route.size()
	if actor.awareness == InfiltrationActor.Awareness.ALERTED and intent.panel >= 0 and intent.panel < panels.size() and not panels[intent.panel].disabled and not panels[intent.panel].active:
		actor.decision = InfiltrationActor.Decision.ALARM
		var point: Vector2 = map.panels[intent.panel].position
		if actor.position.distance_to(point) <= config.panel_activation_range and InfiltrationGeometry.wall_fraction(map, actor.position, point) == INF:
			_panel_requests[intent.panel] = 1
	actor.fire_ticks = maxi(actor.fire_ticks - 1, 0)
	if actor.awareness != InfiltrationActor.Awareness.ALERTED or (intent.held & Intent.Command.LIGHT) == 0 or not InfiltrationPerception.sees(self, index):
		actor.burst_left = 0
		return
	if actor.fire_ticks == 0 and actor.burst_left == 0:
		actor.burst_left = data.bolt.count
		actor.burst_ticks = 0
	if actor.burst_left > 0:
		actor.burst_ticks = maxi(actor.burst_ticks - 1, 0)
		if actor.burst_ticks == 0:
			fire_bolt(index)
			actor.burst_left -= 1
			actor.burst_ticks = data.bolt.interval_ticks()
			if actor.burst_left == 0:
				actor.fire_ticks = Ticks.from_seconds(data.fire_interval)


func _step_panels() -> void:
	for index in panels.size():
		var panel: InfiltrationPanel = panels[index]
		if panel.disabled or panel.active:
			continue
		panel.activation_ticks = panel.activation_ticks + 1 if _panel_requests[index] != 0 else 0
		if panel.activation_ticks >= Ticks.from_seconds(config.panel_activation_seconds):
			panel.active = true
			_emit(InfiltrationEvent.Type.ALARM_RAISED, -1, index, map.panels[index].position)
			if not reinforcement_called:
				reinforcement_called = true
				reinforcement_ticks = Ticks.from_seconds(config.reinforcement_delay) + 1
	if reinforcement_ticks < 0 or not alarm_active():
		return
	reinforcement_ticks = maxi(reinforcement_ticks - 1, 0)
	if reinforcement_ticks == 0:
		var pending: bool = false
		for index in range(map.targets.size(), targets.size()):
			var actor: InfiltrationActor = targets[index]
			if actor.spawned:
				continue
			if not _spawn_clear(actor.position):
				pending = true
				continue
			actor.spawned = true
			actor.health = target_data[index].health
			_emit(InfiltrationEvent.Type.REINFORCEMENT_ARRIVED, index + 1, -1, actor.position)
			reinforcement_ticks = 0
		if not pending:
			reinforcement_ticks = -1


func _spawn_clear(point: Vector2) -> bool:
	var diameter: float = config.body_radius * 2.0
	var offset: Vector2 = (player.position - point).abs()
	if InfiltrationGeometry.wall_fraction(map, point, point, config.body_radius) != INF or (offset.x < diameter and offset.y < diameter):
		return false
	for actor in targets:
		offset = (actor.position - point).abs()
		if actor.health > 0.0 and offset.x < diameter and offset.y < diameter:
			return false
	return true
