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


func _init(configuration: InfiltrationConfig, map_data: InfiltrationMapData) -> void:
	config = configuration
	map = map_data
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
	for index in config.projectile_capacity:
		bolts.append(InfiltrationBolt.new())
	for index in config.event_capacity:
		events.append(InfiltrationEvent.new())


func step(intent: InfiltrationIntent) -> void:
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
	if (intent.pressed & Intent.Command.LIGHT) != 0 and player.swing_tick < 0 and player.vigor >= config.swing_vigor:
		player.swing_tick = 0
		player.swing_id += 1
		player.swing_aim = player.aim
		_spend_vigor(config.swing_vigor)
		_close_parry()
		_emit(InfiltrationEvent.Type.SWING_STARTED, 0, -1, player.position)
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
		speed = config.walk_speed * config.guard_speed_ratio
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
	for index in targets.size():
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
	var data: BoltData = map.targets[shooter].bolt
	for bolt in bolts:
		if bolt.active:
			continue
		bolt.active = true
		bolt.data = data
		bolt.shooter = shooter
		bolt.owner = shooter + 1
		bolt.position = source.position + source.aim * (config.body_radius + data.muzzle_forward)
		bolt.previous = bolt.position
		bolt.velocity = source.aim * data.speed
		bolt.travelled = 0.0
		_emit(InfiltrationEvent.Type.SHOT_FIRED, shooter + 1, 0, bolt.position)
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
					_damage_target(victim - 1, bolt.data.damage)
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


func _damage_target(index: int, damage: float) -> void:
	var target: InfiltrationActor = targets[index]
	target.health = maxf(target.health - damage, 0.0)
	if target.health == 0.0:
		target.respawn_ticks = Ticks.from_seconds(map.targets[index].respawn_seconds)
		target.burst_left = 0
		_emit(InfiltrationEvent.Type.TARGET_DISABLED, 0, index + 1, target.position)


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
	for actor in targets:
		actors.append(actor.capture())
	for bolt in bolts:
		projectiles.append(bolt.capture())
	return {"tick": tick, "player": player.capture(), "targets": actors, "bolts": projectiles, "dropped_events": dropped_events}


func restore(state: Dictionary) -> void:
	tick = state.tick
	player.restore(state.player)
	for index in targets.size():
		targets[index].restore(state.targets[index])
	for index in bolts.size():
		bolts[index].restore(state.bolts[index], map)
	dropped_events = state.dropped_events
	event_count = 0


func state_hash() -> int:
	return hash(capture())
