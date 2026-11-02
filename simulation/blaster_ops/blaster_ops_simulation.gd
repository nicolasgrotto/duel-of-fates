class_name BlasterOpsSimulation
extends InfiltrationSimulation

var operations: BlasterOpsConfig
var arena: BlasterOpsMap
var loadout: BlasterOpsLoadout
var state: BlasterOpsState = BlasterOpsState.new()
var cover_revision: int = 0


func _init(configuration: BlasterOpsConfig, data: BlasterOpsArenaData, equipment: BlasterOpsLoadout) -> void:
	operations = configuration
	arena = BlasterOpsMap.new(data)
	loadout = equipment
	super(configuration, arena)
	for index in targets.size():
		var actor: BlasterOpsActor = BlasterOpsActor.new()
		actor.restore(targets[index].capture())
		if data.enemies_alerted:
			actor.awareness = InfiltrationActor.Awareness.ALERTED
			actor.suspicion = 1.0
			actor.memory_ticks = Ticks.from_seconds(config.alert_memory)
			actor.last_known = player.position
		targets[index] = actor
	for index in bolts.size():
		bolts[index] = BlasterOpsBolt.new()


func step(intent: InfiltrationIntent, enemy_intents: Array[InfiltrationIntent] = [], _escort_intents: Array[InfiltrationIntent] = []) -> void:
	event_count = 0
	if player.health <= 0.0:
		return
	tick += 1
	player.previous = player.position
	for actor in targets:
		actor.previous = actor.position
	_advance_player_timers()
	_advance_operations()
	_apply_intent(intent)
	_step_bolts()
	if player.health <= 0.0:
		return
	InfiltrationPerception.step(self)
	_step_enemies(enemy_intents)


func _advance_operations() -> void:
	state.fire_ticks = maxi(state.fire_ticks - 1, 0)
	state.dodge_cooldown = maxi(state.dodge_cooldown - 1, 0)
	state.power_cooldown = maxi(state.power_cooldown - 1, 0)
	state.power_recovery_ticks = maxi(state.power_recovery_ticks - 1, 0)
	state.barrier_ticks = maxi(state.barrier_ticks - 1, 0)
	if state.barrier_ticks == 0:
		state.barrier_health = 0.0
	state.overheat_ticks = maxi(state.overheat_ticks - 1, 0)
	state.cooling_ticks = maxi(state.cooling_ticks - 1, 0)
	if state.cooling_ticks == 0 or state.overheated:
		state.heat = maxf(state.heat - operations.cooling_rate * Ticks.DELTA, 0.0)
	if state.overheated and state.overheat_ticks == 0 and state.heat <= operations.resume_heat:
		state.overheated = false
	if state.dodge_age >= 0:
		state.dodge_age += 1
		if state.dodge_age >= Ticks.from_seconds(operations.dodge_seconds):
			state.dodge_age = -1


func _apply_intent(intent: InfiltrationIntent) -> void:
	if intent.aim.length_squared() > 0.0:
		player.aim = intent.aim.normalized()
	player.guard = false
	if (intent.pressed & Intent.Command.DODGE) != 0 and state.dodge_age < 0 and state.dodge_cooldown == 0 and player.stun_ticks == 0:
		_start_dodge(intent)
	if state.dodge_age >= 0:
		_close_parry()
		_move_player(state.dodge_direction * operations.dodge_speed, true)
		return
	if player.stun_ticks > 0:
		state.power_ticks = 0
		_close_parry()
		player.velocity = Vector2.ZERO
		return
	if state.power_ticks > 0:
		state.power_ticks -= 1
		if state.power_ticks == 0:
			_release_power()
	elif (intent.pressed & Intent.Command.POWER) != 0 and state.power_cooldown == 0:
		_start_power()
	if state.power_ticks == 0 and (intent.held & Intent.Command.BLOCK) != 0 and loadout.can_deflect:
		player.guard = true
		if (intent.pressed & Intent.Command.BLOCK) != 0 and player.parry_cooldown == 0:
			player.parry_age = 0
	elif player.parry_age >= 0:
		_close_parry()
	var speed: float = config.walk_speed
	if player.guard or state.power_ticks > 0:
		speed *= config.guard_speed_ratio
	_move_player(intent.movement.limit_length() * speed)
	if (intent.held & Intent.Command.LIGHT) != 0 and not player.guard and state.power_ticks == 0 and state.power_recovery_ticks == 0:
		_fire_primary()


func _move_player(desired: Vector2, dash: bool = false) -> void:
	var acceleration: float = config.acceleration if desired.length_squared() > 0.0 else config.deceleration
	player.velocity = desired if dash else player.velocity.move_toward(desired, acceleration * Ticks.DELTA)
	player.position = InfiltrationGeometry.move_body(map, player.position, player.velocity * Ticks.DELTA, player.radius, targets)
	player.velocity = (player.position - player.previous) / Ticks.DELTA
	player.walked += player.position.distance_to(player.previous)
	if player.walked >= config.step_distance:
		player.walked -= config.step_distance
		_emit(InfiltrationEvent.Type.FOOTSTEP, 0, -1, player.position)


func _start_dodge(intent: InfiltrationIntent) -> void:
	state.dodge_age = 0
	state.dodge_cooldown = Ticks.from_seconds(operations.dodge_cooldown)
	state.dodge_direction = intent.movement.normalized() if intent.movement.length_squared() > 0.0 else player.aim
	state.precision_succeeded = false
	state.power_ticks = 0
	_emit(InfiltrationEvent.Type.DODGED, 0, -1, player.position)


func dodge_invulnerable() -> bool:
	return state.dodge_age >= operations.invulnerable_from and state.dodge_age < operations.invulnerable_until


func _fire_primary() -> void:
	if state.overheated or state.fire_ticks > 0:
		return
	var bolt: BlasterOpsBolt = _spawn_bolt(-1, loadout.blaster.bolt, player.aim, loadout.damage_scale)
	if bolt == null:
		return
	state.fire_ticks = maxi(Ticks.from_seconds(loadout.fire_interval), 1)
	state.cooling_ticks = Ticks.from_seconds(operations.cooling_delay)
	state.heat = minf(state.heat + loadout.heat_per_shot, operations.heat_capacity)
	if state.heat >= operations.heat_capacity:
		state.overheated = true
		state.overheat_ticks = Ticks.from_seconds(operations.overheat_seconds)
		state.cooling_ticks = 0
		_emit(InfiltrationEvent.Type.OVERHEATED, 0, -1, player.position)


func _spawn_bolt(shooter: int, data: BoltData, aim: Vector2, scale: float = 1.0) -> BlasterOpsBolt:
	var actor: InfiltrationActor = player if shooter < 0 else targets[shooter]
	var muzzle: Vector2 = actor.position + aim * (actor.radius + data.muzzle_forward)
	if InfiltrationGeometry.wall_fraction(map, actor.position, muzzle, data.size) != INF:
		return null
	for candidate in bolts:
		if candidate.active:
			continue
		var bolt: BlasterOpsBolt = candidate as BlasterOpsBolt
		bolt.active = true
		bolt.data = data
		bolt.shooter = shooter
		bolt.owner = shooter + 1
		bolt.origin = actor.position
		bolt.position = muzzle
		bolt.previous = muzzle
		bolt.velocity = aim * data.speed
		bolt.travelled = 0.0
		bolt.damage = data.damage * scale
		bolt.evaded = false
		bolt.reflected = false
		_emit(InfiltrationEvent.Type.SHOT_FIRED, bolt.owner, -1, muzzle)
		InfiltrationPerception.noise(self, actor.position, config.combat_noise, bolt.owner)
		return bolt
	return null


func _step_bolts() -> void:
	for candidate in bolts:
		if player.health <= 0.0:
			return
		var bolt: BlasterOpsBolt = candidate as BlasterOpsBolt
		if not bolt.active:
			continue
		bolt.previous = bolt.position
		var distance: float = minf(bolt.velocity.length() * Ticks.DELTA, bolt.data.max_range - bolt.travelled)
		var end: Vector2 = bolt.position + bolt.velocity.normalized() * distance
		var fraction: float = InfiltrationGeometry.wall_fraction(map, bolt.position, end, bolt.data.size)
		var cover: int = _cover_impact(bolt, end, fraction)
		var victim: int = -1
		if bolt.owner != 0 and not bolt.evaded:
			var impact: float = _actor_impact(bolt, end, player)
			if impact < fraction:
				fraction = impact
				victim = 0
		elif bolt.owner == 0:
			for index in targets.size():
				if targets[index].health <= 0.0:
					continue
				var impact: float = _actor_impact(bolt, end, targets[index])
				if impact < fraction:
					fraction = impact
					victim = index + 1
		if fraction != INF:
			bolt.position = bolt.position.lerp(end, fraction)
			bolt.travelled += bolt.previous.distance_to(bolt.position)
			if victim == 0:
				_resolve_player_bolt(bolt)
			else:
				bolt.active = false
				if victim > 0:
					var damage: float = _armored_damage(victim - 1, bolt.damage, bolt.origin)
					_emit(InfiltrationEvent.Type.BOLT_HIT, bolt.owner, victim, bolt.position, damage)
					_damage_target(victim - 1, damage, false, bolt.origin)
				elif cover >= 0:
					_damage_cover(cover, bolt.damage, bolt.position)
			continue
		bolt.position = end
		bolt.travelled += distance
		if bolt.travelled >= bolt.data.max_range:
			bolt.active = false


func _cover_impact(bolt: BlasterOpsBolt, end: Vector2, wall: float) -> int:
	if wall == INF:
		return -1
	for index in arena.covers.size():
		var cover: BlasterOpsCover = arena.covers[index]
		if cover.health <= 0.0:
			continue
		var box: Rect2 = Rect2(Vector2(cover.data.cell) * map.tile_size, Vector2.ONE * map.tile_size).grow(bolt.data.size)
		var impact: float = InfiltrationGeometry.segment_box_fraction(bolt.position, end, box)
		if impact != INF and absf(impact - wall) <= InfiltrationGeometry.EPSILON:
			return index
	return -1


func _actor_impact(bolt: BlasterOpsBolt, end: Vector2, actor: InfiltrationActor) -> float:
	var radius: float = actor.radius + bolt.data.size
	return InfiltrationGeometry.segment_box_fraction(bolt.position - actor.previous, end - actor.position, Rect2(-Vector2.ONE * radius, Vector2.ONE * radius * 2.0))


func _damage_cover(index: int, damage: float, point: Vector2) -> void:
	var cover: BlasterOpsCover = arena.covers[index]
	cover.health = maxf(cover.health - damage, 0.0)
	_emit(InfiltrationEvent.Type.COVER_HIT, 0, index, point, damage)
	if cover.health <= 0.0:
		cover_revision += 1
		_emit(InfiltrationEvent.Type.COVER_DESTROYED, 0, index, point)


func _resolve_player_bolt(candidate: InfiltrationBolt) -> void:
	var bolt: BlasterOpsBolt = candidate as BlasterOpsBolt
	if dodge_invulnerable():
		bolt.evaded = true
		if state.dodge_age < operations.precision_until and not state.precision_succeeded:
			state.precision_succeeded = true
			state.dodge_cooldown = 0
			_emit(InfiltrationEvent.Type.PRECISION_DODGED, 0, bolt.owner, bolt.position)
		return
	var front: bool = InfiltrationGeometry.in_sector(Vector2.ZERO, player.aim, -bolt.velocity, INF, config.guard_degrees)
	if player.guard and front:
		if player.parry_age >= 0:
			var perfect: bool = player.parry_age < Ticks.from_seconds(config.duel_config.perfect_parry_window)
			bolt.owner = 0
			bolt.origin = player.position
			bolt.travelled = 0.0
			bolt.evaded = false
			bolt.reflected = true
			bolt.velocity = player.aim * bolt.data.speed * (bolt.data.perfect_reflect_speed if perfect else 1.0)
			_emit(InfiltrationEvent.Type.BOLT_REFLECTED, 0, bolt.shooter + 1, bolt.position, 1.0 if perfect else 0.0)
		else:
			_spend_vigor(bolt.data.guard_vigor)
			bolt.active = false
			_emit(InfiltrationEvent.Type.BOLT_BLOCKED, bolt.owner, 0, bolt.position)
		return
	bolt.active = false
	var damage: float = bolt.damage
	if state.barrier_health > 0.0:
		var absorbed: float = minf(damage, state.barrier_health)
		state.barrier_health -= absorbed
		damage -= absorbed
		_emit(InfiltrationEvent.Type.BOLT_BLOCKED, bolt.owner, 0, bolt.position)
	if damage > 0.0:
		_hurt_player(damage, bolt.data.flinch_ticks(), bolt.owner, bolt.position)


func _hurt_player(damage: float, flinch_ticks: int, source: int, point: Vector2) -> void:
	super._hurt_player(damage, flinch_ticks, source, point)
	state.power_ticks = 0
	if player.health <= 0.0:
		state.dodge_age = -1


func _apply_enemy_intent(index: int, intent: InfiltrationIntent) -> void:
	var actor: BlasterOpsActor = targets[index] as BlasterOpsActor
	var data: BlasterOpsEnemyData = target_data[index] as BlasterOpsEnemyData
	actor.fire_ticks = maxi(actor.fire_ticks - 1, 0)
	actor.stun_ticks = maxi(actor.stun_ticks - 1, 0)
	if actor.impulse_ticks > 0:
		actor.impulse_ticks -= 1
		actor.position = InfiltrationGeometry.move_body(map, actor.position, actor.impulse * Ticks.DELTA, actor.radius, targets, actor, player)
	if actor.stun_ticks > 0:
		actor.telegraph_ticks = -1
		actor.burst_left = 0
		actor.velocity = (actor.position - actor.previous) / Ticks.DELTA
		return
	if intent.aim.length_squared() > 0.0 and actor.telegraph_ticks < 0:
		actor.aim = _turned_aim(actor, data, intent.aim.normalized())
	actor.decision = InfiltrationActor.Decision.FIGHT if actor.awareness == InfiltrationActor.Awareness.ALERTED else InfiltrationActor.Decision.INVESTIGATE
	if actor.telegraph_ticks < 0:
		actor.position = InfiltrationGeometry.move_body(map, actor.position, intent.movement.limit_length() * data.speed * Ticks.DELTA, actor.radius, targets, actor, player)
	actor.velocity = (actor.position - actor.previous) / Ticks.DELTA
	if actor.awareness != InfiltrationActor.Awareness.ALERTED or (intent.held & Intent.Command.LIGHT) == 0:
		actor.telegraph_ticks = -1
		actor.burst_left = 0
		return
	if actor.telegraph_ticks >= 0:
		actor.telegraph_ticks -= 1
		if actor.telegraph_ticks == 0:
			_release_enemy_attack(index, data, actor)
		return
	if actor.fire_ticks > 0 or not InfiltrationPerception.has_shot(self, index):
		return
	if data.melee_damage > 0.0 and actor.position.distance_to(player.position) > data.melee_range + player.radius:
		return
	if actor.burst_left == 0:
		actor.burst_left = data.bolt.count if data.bolt != null else 1
	actor.telegraph_ticks = maxi(Ticks.from_seconds(data.telegraph_seconds), 1)
	actor.telegraph_aim = actor.aim
	_emit(InfiltrationEvent.Type.ATTACK_PREPARED, index + 1, 0, actor.position)


func _release_enemy_attack(index: int, data: BlasterOpsEnemyData, actor: BlasterOpsActor) -> void:
	actor.telegraph_ticks = -1
	if player.health <= 0.0 or InfiltrationGeometry.wall_fraction(map, actor.position, player.position) != INF:
		actor.burst_left = 0
		return
	if data.melee_damage > 0.0:
		_resolve_enemy_melee(index, data, actor)
		actor.fire_ticks = Ticks.from_seconds(data.melee_interval)
		actor.burst_left = 0
		return
	if _spawn_bolt(index, data.bolt, actor.telegraph_aim) == null:
		actor.telegraph_ticks = 1
		return
	actor.burst_left -= 1
	actor.fire_ticks = Ticks.from_seconds(data.fire_interval) if actor.burst_left == 0 else data.bolt.interval_ticks()


func _resolve_enemy_melee(index: int, data: BlasterOpsEnemyData, actor: BlasterOpsActor) -> void:
	if dodge_invulnerable() or not InfiltrationGeometry.in_sector(actor.position, actor.telegraph_aim, player.position, data.melee_range, data.attack_degrees, player.radius):
		return
	if player.guard and InfiltrationGeometry.in_sector(player.position, player.aim, actor.position, INF, config.guard_degrees):
		if player.parry_age >= 0:
			actor.stun_ticks = Ticks.from_seconds(operations.melee_parry_stun)
			_emit(InfiltrationEvent.Type.BOLT_REFLECTED, 0, index + 1, actor.position)
		else:
			_spend_vigor(data.melee_guard_vigor)
			_emit(InfiltrationEvent.Type.BOLT_BLOCKED, index + 1, 0, player.position)
		return
	_hurt_player(data.melee_damage, Ticks.from_seconds(data.melee_flinch), index + 1, player.position)


func _start_power() -> void:
	state.power_ticks = maxi(loadout.power.power.startup_ticks(), 1)
	state.power_cooldown = Ticks.from_seconds(loadout.power.cooldown)
	state.power_aim = player.aim
	_close_parry()
	_emit(InfiltrationEvent.Type.POWER_PREPARED, 0, -1, player.position)


func _release_power() -> void:
	var power: PowerData = loadout.power.power
	state.power_recovery_ticks = power.recovery_ticks()
	_emit(InfiltrationEvent.Type.POWER_RELEASED, 0, -1, player.position, float(power.kind))
	if power.kind == PowerData.Kind.BARRIER:
		state.barrier_health = power.strength
		state.barrier_ticks = Ticks.from_seconds(power.max_channel)
		return
	var nearest: int = -1
	var distance: float = INF
	for index in targets.size():
		var actor: BlasterOpsActor = targets[index] as BlasterOpsActor
		if actor.health <= 0.0 or not InfiltrationGeometry.in_sector(player.position, state.power_aim, actor.position, power.reach, loadout.power.degrees):
			continue
		if InfiltrationGeometry.wall_fraction(map, player.position, actor.position) != INF:
			continue
		if power.kind == PowerData.Kind.REPULSE:
			_affect_enemy(index, power)
		elif actor.position.distance_squared_to(player.position) < distance:
			nearest = index
			distance = actor.position.distance_squared_to(player.position)
	if nearest >= 0:
		_affect_enemy(nearest, power)


func _affect_enemy(index: int, power: PowerData) -> void:
	var actor: BlasterOpsActor = targets[index] as BlasterOpsActor
	_damage_target(index, power.damage)
	actor.stun_ticks = Ticks.from_seconds(power.stagger)
	actor.impulse_ticks = Ticks.from_seconds(loadout.power.impulse_seconds)
	var direction: Vector2 = (actor.position - player.position).normalized()
	actor.impulse = direction * power.tier_value(0) * (-1.0 if power.kind == PowerData.Kind.PULL else 1.0)
	actor.telegraph_ticks = -1
	actor.burst_left = 0


func capture() -> Dictionary:
	var snapshot: Dictionary = super.capture()
	snapshot["operations"] = state.capture()
	var health: PackedFloat32Array = []
	for cover in arena.covers:
		health.append(cover.health)
	snapshot["covers"] = health
	return snapshot


func restore(snapshot: Dictionary) -> void:
	super.restore(snapshot)
	state.restore(snapshot.operations)
	for index in arena.covers.size():
		arena.covers[index].health = snapshot.covers[index]
	cover_revision += 1
