class_name BlasterOpsSimulation
extends InfiltrationSimulation

const POWER_COMMANDS: Array[int] = [Intent.Command.POWER, InfiltrationIntent.POWER_2, InfiltrationIntent.POWER_3]
const POWER_BOLT_SHOOTER: int = -2
const SPREAD_PATTERN: PackedFloat32Array = [0.0, 1.0, -1.0, 0.5, -0.5]
const BOLT_SWEEP_MARGIN: float = 32.0

var operations: BlasterOpsConfig
var arena: BlasterOpsMap
var loadout: BlasterOpsLoadout
var state: BlasterOpsState = BlasterOpsState.new()
var cover_revision: int = 0


func _init(configuration: BlasterOpsConfig, data: InfiltrationMapData, equipment: BlasterOpsLoadout, mission_data: InfiltrationMissionData = null) -> void:
	operations = configuration
	arena = BlasterOpsMap.new(data)
	loadout = equipment
	super(configuration, arena, mission_data)
	for index in targets.size():
		var actor: BlasterOpsActor = BlasterOpsActor.new()
		actor.restore(targets[index].capture())
		if data is BlasterOpsArenaData and (data as BlasterOpsArenaData).enemies_alerted:
			actor.awareness = InfiltrationActor.Awareness.ALERTED
			actor.suspicion = 1.0
			actor.memory_ticks = Ticks.from_seconds(config.alert_memory)
			actor.last_known = player.position
		targets[index] = actor
	for index in bolts.size():
		bolts[index] = BlasterOpsBolt.new()
	if mission_data is BlasterOpsMissionData:
		mission = BlasterOpsMissionState.new(mission_data as BlasterOpsMissionData)
		arena.reserve_barriers(operations.barrier_capacity if (mission_data as BlasterOpsMissionData).kind == BlasterOpsMissionData.Kind.DEFENSE else 0, operations.deploy_health)
		(mission as BlasterOpsMissionState).setup(self)


func step(intent: InfiltrationIntent, enemy_intents: Array[InfiltrationIntent] = [], escort_intents: Array[InfiltrationIntent] = []) -> void:
	event_count = 0
	if (mission != null and mission.outcome != InfiltrationMissionState.Outcome.ACTIVE) or (mission == null and player.health <= 0.0):
		return
	tick += 1
	player.previous = player.position
	_refresh_live_bodies()
	for actor in live_bodies:
		actor.previous = actor.position
	_advance_player_timers()
	_advance_operations()
	_apply_intent(intent)
	_step_targets()
	_resolve_swing()
	_step_bolts()
	if player.health <= 0.0:
		if mission != null:
			mission.advance(self, escort_intents)
		return
	InfiltrationPerception.step(self)
	_step_enemies(enemy_intents)
	_step_panels()
	if mission != null:
		mission.advance(self, escort_intents)
		if mission is BlasterOpsMissionState and mission.outcome == InfiltrationMissionState.Outcome.ACTIVE:
			_step_allies(escort_intents)


func _refresh_live_bodies() -> void:
	live_bodies.clear()
	live_indices.clear()
	alerted_bodies = 0
	for index in targets.size():
		var actor: InfiltrationActor = targets[index]
		if actor.health > 0.0:
			live_bodies.append(actor)
			live_indices.append(index)
			alerted_bodies += int(actor.awareness == InfiltrationActor.Awareness.ALERTED)
		else:
			actor.previous = actor.position


func wall_for(side: BlasterOpsFaction.Side, start: Vector2, end: Vector2, radius: float = 0.0) -> float:
	arena.allied_query = side == BlasterOpsFaction.Side.ALLIED
	var fraction: float = InfiltrationGeometry.wall_fraction(map, start, end, radius)
	arena.allied_query = false
	return fraction


func apply_area_damage(side: BlasterOpsFaction.Side, center: Vector2, radius: float, damage: float, source: int, flinch_ticks: int = 0) -> void:
	_emit(InfiltrationEvent.Type.AREA_BLAST, source, int(side), center, radius)
	if side == BlasterOpsFaction.Side.ALLIED:
		for index in targets.size():
			if _area_reaches(side, center, radius, targets[index]):
				_damage_target(index, damage, false, center)
	else:
		if _area_reaches(side, center, radius, player) and not dodge_invulnerable() and not aftermath:
			var remaining: float = _absorb_barrier(damage, source, center)
			if remaining > 0.0:
				_hurt_player(remaining, flinch_ticks, source, center)
		for index in prisoners.size():
			if prisoner_exposed(index) and _area_reaches(side, center, radius, prisoners[index]):
				prisoners[index].health = maxf(prisoners[index].health - damage, 0.0)
				_emit(InfiltrationEvent.Type.BOLT_HIT, source, targets.size() + index + 1, prisoners[index].position, damage)
	for index in arena.covers.size():
		var cover: BlasterOpsCover = arena.covers[index]
		if cover.health <= 0.0 or (cover.deployed and side == BlasterOpsFaction.Side.ALLIED):
			continue
		var point: Vector2 = (Vector2(cover.data.cell) + Vector2.ONE * 0.5) * map.tile_size
		if point.distance_to(center) <= radius + map.tile_size * 0.5:
			_damage_cover(index, damage, point)


func _area_reaches(side: BlasterOpsFaction.Side, center: Vector2, radius: float, actor: InfiltrationActor) -> bool:
	return actor.health > 0.0 and actor.position.distance_to(center) <= radius + actor.radius and wall_for(side, center, actor.position) == INF


func _absorb_barrier(damage: float, source: int, point: Vector2) -> float:
	if state.barrier_health <= 0.0:
		return damage
	var absorbed: float = minf(damage, state.barrier_health)
	state.barrier_health -= absorbed
	_emit(InfiltrationEvent.Type.BOLT_BLOCKED, source, 0, point)
	return damage - absorbed


func deploy_barrier() -> bool:
	var progress: BlasterOpsMissionState = mission as BlasterOpsMissionState
	if progress == null or progress.definition.kind != BlasterOpsMissionData.Kind.DEFENSE or progress.intermission_ticks <= 0 or progress.barriers_placed >= operations.barrier_capacity:
		return false
	var cell: Vector2i = Vector2i((player.position + player.aim * operations.deploy_distance) / map.tile_size)
	var center: Vector2 = (Vector2(cell) + Vector2.ONE * 0.5) * map.tile_size
	for offset in [Vector2i.ZERO, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		if map.is_solid(cell.x + offset.x, cell.y + offset.y):
			return false
	if not _spawn_clear(center):
		return false
	for actor in prisoners:
		if actor.health > 0.0 and actor.position.distance_to(center) < map.tile_size:
			return false
	var index: int = arena.covers.size() - operations.barrier_capacity + progress.barriers_placed
	var cover: BlasterOpsCover = arena.covers[index]
	cover.data.cell = cell
	cover.health = operations.deploy_health
	progress.barriers_placed += 1
	arena.rebuild_cells()
	cover_revision += 1
	_emit(InfiltrationEvent.Type.BARRIER_PLACED, 0, index, center)
	return true


func _step_allies(intents: Array[InfiltrationIntent]) -> void:
	for index in prisoners.size():
		var actor: InfiltrationActor = prisoners[index]
		actor.fire_ticks = maxi(actor.fire_ticks - 1, 0)
		if actor.health <= 0.0 or mission.recruited[index] == 0 or actor.fire_ticks > 0 or index >= intents.size() or (intents[index].held & Intent.Command.LIGHT) == 0:
			continue
		var aim: Vector2 = intents[index].aim.normalized()
		var target: bool = false
		for enemy in live_bodies:
			if enemy.health > 0.0 and InfiltrationGeometry.in_sector(actor.position, aim, enemy.position, operations.ally_fire_range, config.swing_degrees) and wall_for(BlasterOpsFaction.Side.ALLIED, actor.position, enemy.position) == INF:
				target = true
				break
		if target and _spawn_bolt(-index - 2, operations.ally_bolt, aim, 1.0, actor) != null:
			actor.fire_ticks = Ticks.from_seconds(operations.ally_fire_interval)
			actor.aim = aim


func _advance_operations() -> void:
	state.fire_ticks = maxi(state.fire_ticks - 1, 0)
	state.dodge_cooldown = maxi(state.dodge_cooldown - 1, 0)
	for slot in POWER_COMMANDS.size():
		state.set_cooldown(slot, maxi(state.cooldown(slot) - 1, 0))
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
	if state.switch_ticks > 0:
		state.switch_ticks -= 1
		if state.switch_ticks == 0:
			state.blade_drawn = state.switch_to_blade
			_emit(InfiltrationEvent.Type.WEAPON_SWITCHED, 0, int(state.blade_drawn), player.position)
	state.absorb_ticks = maxi(state.absorb_ticks - 1, 0)
	state.boost_ticks = maxi(state.boost_ticks - 1, 0)
	if state.heal_ticks > 0:
		state.heal_ticks -= 1
		player.health = minf(player.health + state.heal_rate, operations.health)
	_advance_channel()
	_advance_area()


func _apply_intent(intent: InfiltrationIntent) -> void:
	if intent.aim.length_squared() > 0.0:
		player.aim = intent.aim.normalized()
	player.guard = false
	if (intent.pressed & Intent.Command.DODGE) != 0 and state.dodge_age < 0 and state.dodge_cooldown == 0 and player.stun_ticks == 0:
		_start_dodge(intent)
	if state.dodge_age >= 0:
		_cancel_burst()
		_close_parry()
		_move_player(state.dodge_direction * operations.dodge_speed, true)
		return
	if player.stun_ticks > 0:
		_cancel_burst()
		_interrupt_powers()
		_close_parry()
		player.velocity = Vector2.ZERO
		return
	if (intent.pressed & InfiltrationIntent.INTERACT) != 0:
		if nearby_panel() >= 0:
			_disable_panel()
		elif mission != null:
			mission.interact(self)
	if (intent.pressed & InfiltrationIntent.SWITCH_WEAPON) != 0 and player.swing_tick < 0 and state.power_ticks == 0 and state.channel_ticks == 0:
		_begin_switch(not state.blade_drawn)
	var blade_requested: bool = (intent.pressed & Intent.Command.HEAVY) != 0
	if blade_requested and player.swing_tick < 0 and state.power_ticks == 0:
		var victim: int = takedown_target()
		if victim >= 0:
			_emit(InfiltrationEvent.Type.TAKEDOWN_LANDED, 0, victim + 1, targets[victim].position)
			_damage_target(victim, targets[victim].health, true)
			blade_requested = false
	if blade_requested and _ranged_only():
		_begin_switch(true)
		state.strike_queued = true
		blade_requested = false
	elif state.strike_queued and state.switch_ticks == 0:
		state.strike_queued = false
		blade_requested = true
	if _primary_cuts() and ((intent.held | intent.pressed) & Intent.Command.LIGHT) != 0:
		blade_requested = true
	if state.switch_ticks > 0:
		blade_requested = false
	if blade_requested and player.swing_tick < 0 and state.power_ticks == 0 and state.power_recovery_ticks == 0 and player.vigor >= config.swing_vigor:
		player.swing_tick = 0
		player.swing_id += 1
		player.swing_aim = player.aim
		_spend_vigor(config.swing_vigor)
		_close_parry()
		_emit(InfiltrationEvent.Type.SWING_STARTED, 0, -1, player.position)
		InfiltrationPerception.noise(self, player.position, config.combat_noise, 0)
	if state.power_ticks > 0:
		state.power_ticks -= 1
		if state.power_ticks == 0:
			_release_power()
	elif player.swing_tick < 0 and state.channel_ticks == 0:
		_try_start_power(intent)
	if state.power_ticks == 0 and state.channel_ticks == 0 and player.swing_tick < 0 and (intent.held & Intent.Command.BLOCK) != 0 and loadout.can_deflect and _ranged_only():
		_begin_switch(true)
	elif state.switch_ticks == 0 and state.power_ticks == 0 and state.channel_ticks == 0 and player.swing_tick < 0 and (intent.held & Intent.Command.BLOCK) != 0 and loadout.can_deflect:
		player.guard = true
		if (intent.pressed & Intent.Command.BLOCK) != 0 and player.parry_cooldown == 0:
			player.parry_age = 0
	elif player.parry_age >= 0:
		_close_parry()
	var speed: float = config.walk_speed
	player.locomotion = InfiltrationActor.Locomotion.WALK
	if (intent.held & InfiltrationIntent.SNEAK) != 0:
		speed = config.sneak_speed
		player.locomotion = InfiltrationActor.Locomotion.SNEAK
	elif (intent.held & InfiltrationIntent.RUN) != 0:
		speed = config.run_speed
		player.locomotion = InfiltrationActor.Locomotion.RUN
	if player.guard or state.power_ticks > 0 or state.channel_ticks > 0:
		speed = minf(speed, config.walk_speed * config.guard_speed_ratio)
		if player.locomotion == InfiltrationActor.Locomotion.RUN:
			player.locomotion = InfiltrationActor.Locomotion.WALK
	_move_player(intent.movement.limit_length() * speed)
	if (intent.held & Intent.Command.LIGHT) != 0 and not _primary_cuts() and state.switch_ticks == 0 and player.swing_tick < 0 and not player.guard and state.power_ticks == 0 and state.power_recovery_ticks == 0:
		_fire_primary()
	else:
		_cancel_burst()


func _primary_cuts() -> bool:
	return loadout.blaster == null or (loadout.switchable and state.blade_drawn)


func _ranged_only() -> bool:
	return loadout.blaster != null and loadout.switchable and not state.blade_drawn and not (state.switch_ticks > 0 and state.switch_to_blade)


func _begin_switch(to_blade: bool) -> void:
	if loadout.blaster == null or not loadout.switchable or state.switch_ticks > 0 or to_blade == state.blade_drawn:
		return
	var seconds: float = (loadout.blaster.holster_time if to_blade else loadout.blaster.draw_time) * loadout.switch_scale
	state.switch_ticks = maxi(Ticks.from_seconds(seconds), 1)
	state.switch_to_blade = to_blade
	_cancel_burst()
	_close_parry()


func _cancel_burst() -> void:
	state.burst_left = 0
	state.burst_ticks = 0


func _resolve_swing() -> void:
	super._resolve_swing()
	if not swing_active():
		return
	var progress: float = float(player.swing_tick - config.startup_ticks()) / config.active_ticks()
	var first: float = lerpf(-config.swing_degrees * 0.5, config.swing_degrees * 0.5, progress)
	var last: float = first + config.swing_degrees / config.active_ticks()
	for index in arena.covers.size():
		var cover: BlasterOpsCover = arena.covers[index]
		if cover.health <= 0.0 or cover.deployed or cover.last_swing_id == player.swing_id:
			continue
		var point: Vector2 = (Vector2(cover.data.cell) + Vector2.ONE * 0.5) * map.tile_size
		if not InfiltrationGeometry.in_sector(player.position, player.swing_aim, point, config.swing_reach, config.swing_degrees, map.tile_size * 0.5):
			continue
		var angle: float = rad_to_deg(player.swing_aim.angle_to(point - player.position))
		if angle < first - InfiltrationGeometry.EPSILON or angle > last + InfiltrationGeometry.EPSILON:
			continue
		var near_edge: Vector2 = point - (point - player.position).normalized() * (map.tile_size * 0.5 + InfiltrationGeometry.EPSILON)
		if InfiltrationGeometry.wall_fraction(map, player.position, near_edge) != INF:
			continue
		cover.last_swing_id = player.swing_id
		_damage_cover(index, config.swing_damage, near_edge)


func _move_player(desired: Vector2, dash: bool = false) -> void:
	var acceleration: float = config.acceleration if desired.length_squared() > 0.0 else config.deceleration
	player.velocity = desired if dash else player.velocity.move_toward(desired, acceleration * Ticks.DELTA)
	player.position = InfiltrationGeometry.move_body(map, player.position, player.velocity * Ticks.DELTA, player.radius, live_bodies)
	player.velocity = (player.position - player.previous) / Ticks.DELTA
	player.walked += player.position.distance_to(player.previous)
	if player.walked >= config.step_distance:
		player.walked -= config.step_distance
		_emit(InfiltrationEvent.Type.FOOTSTEP, 0, -1, player.position, float(player.locomotion))
		if not dash:
			var radius: float = config.walk_noise
			if player.locomotion == InfiltrationActor.Locomotion.RUN:
				radius = config.run_noise
			elif player.locomotion == InfiltrationActor.Locomotion.SNEAK:
				radius = config.sneak_noise
			InfiltrationPerception.noise(self, player.position, radius, 0)


func _start_dodge(intent: InfiltrationIntent) -> void:
	state.dodge_age = 0
	state.dodge_cooldown = Ticks.from_seconds(operations.dodge_cooldown)
	state.dodge_direction = intent.movement.normalized() if intent.movement.length_squared() > 0.0 else player.aim
	state.precision_succeeded = false
	_interrupt_powers()
	player.swing_tick = -1
	_emit(InfiltrationEvent.Type.DODGED, 0, -1, player.position)
	InfiltrationPerception.noise(self, player.position, operations.dodge_noise, 0)


func dodge_invulnerable() -> bool:
	return state.dodge_age >= operations.invulnerable_from and state.dodge_age < operations.invulnerable_until


func _fire_primary() -> void:
	if state.overheated:
		_cancel_burst()
		return
	if state.burst_left == 0:
		if state.fire_ticks > 0:
			return
		state.burst_left = maxi(loadout.blaster.shot_count, 1)
	state.burst_ticks = maxi(state.burst_ticks - 1, 0)
	if state.burst_ticks > 0:
		return
	var aim: Vector2 = player.aim.rotated(deg_to_rad(loadout.spread_degrees * SPREAD_PATTERN[state.shot_index % SPREAD_PATTERN.size()]))
	var bolt: BlasterOpsBolt = _spawn_bolt(-1, loadout.blaster.bolt, aim, loadout.damage_scale * _dealt_scale())
	if bolt == null:
		return
	state.shot_index += 1
	state.burst_left -= 1
	state.burst_ticks = maxi(Ticks.from_seconds(loadout.blaster.shot_interval), 1)
	state.fire_ticks = maxi(Ticks.from_seconds(loadout.fire_interval), 1)
	state.cooling_ticks = Ticks.from_seconds(operations.cooling_delay)
	state.heat = minf(state.heat + loadout.heat_per_shot * loadout.blaster.vigor_multiplier, operations.heat_capacity)
	if state.heat >= operations.heat_capacity:
		state.overheated = true
		state.overheat_ticks = Ticks.from_seconds(operations.overheat_seconds)
		state.cooling_ticks = 0
		_emit(InfiltrationEvent.Type.OVERHEATED, 0, -1, player.position)


func _spawn_bolt(shooter: int, data: BoltData, aim: Vector2, scale: float = 1.0, body: InfiltrationActor = null) -> BlasterOpsBolt:
	var actor: InfiltrationActor = body if body != null else (player if shooter < 0 else targets[shooter])
	var muzzle: Vector2 = actor.position + aim * (actor.radius + data.muzzle_forward)
	if wall_for(BlasterOpsFaction.Side.ALLIED if shooter < 0 else BlasterOpsFaction.Side.HOSTILE, actor.position, muzzle, data.size) != INF:
		return null
	for candidate in bolts:
		if candidate.active:
			continue
		var bolt: BlasterOpsBolt = candidate as BlasterOpsBolt
		bolt.active = true
		bolt.data = data
		bolt.shooter = shooter
		bolt.owner = 0 if shooter < 0 else shooter + 1
		bolt.origin = actor.position
		bolt.position = muzzle
		bolt.previous = muzzle
		bolt.velocity = aim * data.speed
		bolt.travelled = 0.0
		bolt.damage = data.damage * scale
		bolt.evaded = false
		bolt.reflected = false
		_emit(InfiltrationEvent.Type.SHOT_FIRED, shooter + 1, -1, muzzle)
		if shooter == -1 and mission is BlasterOpsMissionState:
			(mission as BlasterOpsMissionState).attempts += 1
		InfiltrationPerception.noise(self, actor.position, config.combat_noise, bolt.owner)
		return bolt
	return null


func fire_bolt(shooter: int) -> InfiltrationBolt:
	return _spawn_bolt(shooter, target_data[shooter].bolt, targets[shooter].aim)


func _step_bolts() -> void:
	for candidate in bolts:
		if player.health <= 0.0 and not aftermath:
			return
		var bolt: BlasterOpsBolt = candidate as BlasterOpsBolt
		if not bolt.active:
			continue
		bolt.previous = bolt.position
		var distance: float = minf(bolt.velocity.length() * Ticks.DELTA, bolt.data.max_range - bolt.travelled)
		var end: Vector2 = bolt.position + bolt.velocity.normalized() * distance
		var fraction: float = wall_for(BlasterOpsFaction.of_bolt(bolt), bolt.position, end, bolt.data.size)
		var cover: int = _cover_impact(bolt, end, fraction)
		var victim: int = -1
		if bolt.owner != 0 and not bolt.evaded:
			var impact: float = _actor_impact(bolt, end, player)
			if impact < fraction:
				fraction = impact
				victim = 0
		elif bolt.owner == 0:
			var sweep: float = distance + bolt.data.size + BOLT_SWEEP_MARGIN
			for index in live_indices:
				var actor: InfiltrationActor = targets[index]
				var limit: float = sweep + actor.radius
				if actor.health <= 0.0 or actor.position.distance_squared_to(bolt.position) > limit * limit:
					continue
				var impact: float = _actor_impact(bolt, end, actor)
				if impact < fraction:
					fraction = impact
					victim = index + 1
		for index in prisoners.size():
			if not bolt_hurts_prisoner(bolt, index):
				continue
			var impact: float = _actor_impact(bolt, end, prisoners[index])
			if impact < fraction:
				fraction = impact
				victim = targets.size() + index + 1
		if fraction != INF:
			bolt.position = bolt.position.lerp(end, fraction)
			bolt.travelled += bolt.previous.distance_to(bolt.position)
			if victim == 0:
				_resolve_player_bolt(bolt)
			else:
				bolt.active = false
				if victim > targets.size():
					var prisoner: InfiltrationActor = prisoners[victim - targets.size() - 1]
					prisoner.health = maxf(prisoner.health - bolt.damage, 0.0)
					_emit(InfiltrationEvent.Type.BOLT_HIT, bolt.owner, victim, bolt.position, bolt.damage)
				elif victim > 0:
					if mission is BlasterOpsMissionState and bolt.shooter == -1 and not bolt.reflected:
						(mission as BlasterOpsMissionState).hits += 1
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
		if cover.health <= 0.0 or (cover.deployed and BlasterOpsFaction.of_bolt(bolt) == BlasterOpsFaction.Side.ALLIED):
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
	if aftermath:
		bolt.active = false
		return
	if dodge_invulnerable():
		bolt.evaded = true
		if state.dodge_age < operations.precision_until and not state.precision_succeeded:
			state.precision_succeeded = true
			state.dodge_cooldown = 0
			_emit(InfiltrationEvent.Type.PRECISION_DODGED, 0, bolt.owner, bolt.position)
		return
	if state.absorb_ticks > 0:
		bolt.active = false
		for slot in POWER_COMMANDS.size():
			state.set_cooldown(slot, maxi(state.cooldown(slot) - Ticks.from_seconds(operations.absorb_refund_seconds), 0))
		_emit(InfiltrationEvent.Type.BOLT_BLOCKED, bolt.owner, 0, bolt.position)
		return
	var front: bool = InfiltrationGeometry.in_sector(Vector2.ZERO, player.aim, -bolt.velocity, INF, config.guard_degrees)
	if player.guard and front:
		InfiltrationPerception.noise(self, bolt.position, config.combat_noise, 0)
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
	var damage: float = _absorb_barrier(bolt.damage, bolt.owner, bolt.position)
	if damage > 0.0:
		_hurt_player(damage, bolt.data.flinch_ticks(), bolt.owner, bolt.position)


func _hurt_player(damage: float, flinch_ticks: int, source: int, point: Vector2) -> void:
	if aftermath:
		return
	var taken: float = damage * (config.duel_config.flow.wrath_taken if state.boost_ticks > 0 else 1.0)
	if mission is BlasterOpsMissionState:
		(mission as BlasterOpsMissionState).damage_taken += minf(taken, player.health)
	super._hurt_player(taken, flinch_ticks, source, point)
	_interrupt_powers()
	state.heal_ticks = 0
	if player.health <= 0.0:
		state.dodge_age = -1


func _apply_enemy_intent(index: int, intent: InfiltrationIntent) -> void:
	var actor: BlasterOpsActor = targets[index] as BlasterOpsActor
	var data: BlasterOpsEnemyData = target_data[index] as BlasterOpsEnemyData
	if data == null:
		actor.stun_ticks = maxi(actor.stun_ticks - 1, 0)
		if actor.impulse_ticks > 0:
			actor.impulse_ticks -= 1
			actor.position = InfiltrationGeometry.move_body(map, actor.position, actor.impulse * Ticks.DELTA, actor.radius, live_bodies, actor, player)
		if actor.stun_ticks > 0:
			actor.burst_left = 0
			actor.velocity = (actor.position - actor.previous) / Ticks.DELTA
			return
		super._apply_enemy_intent(index, intent)
		return
	actor.fire_ticks = maxi(actor.fire_ticks - 1, 0)
	actor.stun_ticks = maxi(actor.stun_ticks - 1, 0)
	if actor.impulse_ticks > 0:
		actor.impulse_ticks -= 1
		actor.position = InfiltrationGeometry.move_body(map, actor.position, actor.impulse * Ticks.DELTA, actor.radius, live_bodies, actor, player)
	if actor.stun_ticks > 0:
		actor.telegraph_ticks = -1
		actor.burst_left = 0
		actor.velocity = (actor.position - actor.previous) / Ticks.DELTA
		return
	if intent.aim.length_squared() > 0.0 and actor.telegraph_ticks < 0:
		actor.aim = _turned_aim(actor, data, intent.aim.normalized())
	actor.decision = InfiltrationActor.Decision.FIGHT if actor.awareness == InfiltrationActor.Awareness.ALERTED else InfiltrationActor.Decision.INVESTIGATE
	if actor.awareness == InfiltrationActor.Awareness.UNAWARE:
		actor.decision = InfiltrationActor.Decision.PATROL
	if actor.telegraph_ticks < 0:
		var speed: float = data.speed * (data.alarm_speed_ratio if (intent.held & Intent.Command.DODGE) != 0 else 1.0)
		actor.position = InfiltrationGeometry.move_body(map, actor.position, intent.movement.limit_length() * speed * Ticks.DELTA, actor.radius, live_bodies, actor, player)
	actor.velocity = (actor.position - actor.previous) / Ticks.DELTA
	_advance_enemy_mission_intent(index, intent)
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
	var victim: InfiltrationActor = prisoners[actor.target_prisoner] if actor.target_prisoner >= 0 else player
	if victim.health <= 0.0 or InfiltrationGeometry.wall_fraction(map, actor.position, victim.position) != INF:
		actor.burst_left = 0
		return
	if data.melee_damage > 0.0:
		_resolve_enemy_melee(index, data, actor)
		actor.fire_ticks = Ticks.from_seconds(data.melee_interval)
		actor.burst_left = 0
		return
	var emitted: bool = false
	if data.shot_angles.is_empty():
		emitted = _spawn_bolt(index, data.bolt, actor.telegraph_aim) != null
	else:
		for angle in data.shot_angles:
			emitted = _spawn_bolt(index, data.bolt, actor.telegraph_aim.rotated(deg_to_rad(angle))) != null or emitted
	if not emitted:
		actor.telegraph_ticks = 1
		return
	actor.burst_left -= 1
	actor.fire_ticks = Ticks.from_seconds(data.fire_interval) if actor.burst_left == 0 else data.bolt.interval_ticks()


func _resolve_enemy_melee(index: int, data: BlasterOpsEnemyData, actor: BlasterOpsActor) -> void:
	if actor.target_prisoner >= 0:
		var prisoner: InfiltrationActor = prisoners[actor.target_prisoner]
		if not aftermath and InfiltrationGeometry.in_sector(actor.position, actor.telegraph_aim, prisoner.position, data.melee_range, data.attack_degrees, prisoner.radius):
			prisoner.health = maxf(prisoner.health - data.melee_damage, 0.0)
			_emit(InfiltrationEvent.Type.BOLT_HIT, index + 1, targets.size() + actor.target_prisoner + 1, prisoner.position, data.melee_damage)
		return
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


func _step_melee(index: int, data: InfiltrationEnemyData, intent: InfiltrationIntent) -> void:
	if targets[index].target_prisoner < 0 and dodge_invulnerable():
		return
	super._step_melee(index, data, intent)


func swing_damage() -> float:
	return config.swing_damage * _dealt_scale()


func _dealt_scale() -> float:
	return config.duel_config.flow.wrath_dealt if state.boost_ticks > 0 else 1.0


func _interrupt_powers() -> void:
	state.power_ticks = 0
	state.channel_ticks = 0
	state.channel_target = -1


func _try_start_power(intent: InfiltrationIntent) -> void:
	for slot in POWER_COMMANDS.size():
		if (intent.pressed & POWER_COMMANDS[slot]) != 0 and loadout.slot(slot) != null and state.cooldown(slot) == 0:
			_start_power(slot)
			return


func _start_power(slot: int) -> void:
	var entry: BlasterOpsPowerData = loadout.slot(slot)
	state.cast_slot = slot
	state.power_ticks = maxi(entry.power.startup_ticks(), 1)
	var multiplier: float = operations.stealth_power_cooldown_multiplier if stealth_objective() else 1.0
	state.set_cooldown(slot, Ticks.from_seconds(entry.cooldown * multiplier))
	state.power_aim = player.aim
	_close_parry()
	_emit(InfiltrationEvent.Type.POWER_PREPARED, 0, -1, player.position)


func _release_power() -> void:
	var entry: BlasterOpsPowerData = loadout.slot(state.cast_slot)
	var power: PowerData = entry.power
	state.power_recovery_ticks = power.recovery_ticks()
	_emit(InfiltrationEvent.Type.POWER_RELEASED, 0, -1, player.position, float(power.kind))
	InfiltrationPerception.noise(self, player.position, operations.power_noise, 0)
	if stealth_objective():
		for index in range(map.targets.size(), targets.size()):
			if InfiltrationPerception.sees(self, index):
				InfiltrationPerception.alert(self, index, player.position)
	match entry.effect:
		BlasterOpsPowerData.Effect.SHIELD:
			state.barrier_health = power.strength
			state.barrier_ticks = Ticks.from_seconds(power.max_channel)
		BlasterOpsPowerData.Effect.ABSORB:
			state.absorb_ticks = Ticks.from_seconds(power.max_channel)
		BlasterOpsPowerData.Effect.HEAL:
			state.heal_ticks = Ticks.from_seconds(power.duration)
			state.heal_rate = power.strength * entry.effect_scale / maxi(state.heal_ticks, 1)
		BlasterOpsPowerData.Effect.PROJECTILE:
			_spawn_bolt(POWER_BOLT_SHOOTER, entry.bolt, state.power_aim, _dealt_scale(), player)
		BlasterOpsPowerData.Effect.CHANNEL:
			state.channel_slot = state.cast_slot
			state.channel_ticks = Ticks.from_seconds(power.max_channel)
			state.pulse_ticks = 0
			state.power_recovery_ticks += state.channel_ticks
		BlasterOpsPowerData.Effect.STUN:
			var victim: int = _nearest_in_cone(state.power_aim, power.reach, entry.degrees)
			if victim >= 0:
				_hold_target(victim, Ticks.from_seconds(power.duration))
		BlasterOpsPowerData.Effect.BOOST:
			state.boost_ticks = Ticks.from_seconds(power.duration)
		BlasterOpsPowerData.Effect.AREA:
			state.area_slot = state.cast_slot
			state.area_ticks = Ticks.from_seconds(power.duration)
			state.pulse_ticks = 0
		_:
			_release_cone(entry)


func _release_cone(entry: BlasterOpsPowerData) -> void:
	var power: PowerData = entry.power
	var nearest: int = -1
	var distance: float = INF
	for index in targets.size():
		var actor: BlasterOpsActor = targets[index] as BlasterOpsActor
		if actor.health <= 0.0 or not InfiltrationGeometry.in_sector(player.position, state.power_aim, actor.position, power.reach, entry.degrees):
			continue
		if wall_for(BlasterOpsFaction.Side.ALLIED, player.position, actor.position) != INF:
			continue
		if power.kind == PowerData.Kind.REPULSE:
			_affect_enemy(index, entry)
		elif actor.position.distance_squared_to(player.position) < distance:
			nearest = index
			distance = actor.position.distance_squared_to(player.position)
	if nearest >= 0:
		_affect_enemy(nearest, entry)


func _nearest_in_cone(aim: Vector2, reach: float, degrees: float) -> int:
	var nearest: int = -1
	var distance: float = INF
	for index in targets.size():
		var actor: InfiltrationActor = targets[index]
		if actor.health <= 0.0 or not InfiltrationGeometry.in_sector(player.position, aim, actor.position, reach, degrees, actor.radius):
			continue
		var candidate: float = actor.position.distance_squared_to(player.position)
		if candidate < distance and wall_for(BlasterOpsFaction.Side.ALLIED, player.position, actor.position) == INF:
			nearest = index
			distance = candidate
	return nearest


func _hold_target(index: int, ticks: int) -> void:
	var actor: BlasterOpsActor = targets[index] as BlasterOpsActor
	actor.stun_ticks = maxi(actor.stun_ticks, ticks)
	actor.telegraph_ticks = -1
	actor.burst_left = 0


func _advance_channel() -> void:
	if state.channel_ticks <= 0:
		return
	state.channel_ticks -= 1
	state.pulse_ticks -= 1
	var entry: BlasterOpsPowerData = loadout.slot(state.channel_slot)
	state.channel_target = _nearest_in_cone(player.aim, entry.power.reach, entry.degrees)
	if state.channel_ticks == 0:
		state.channel_target = -1
	if state.pulse_ticks > 0 or state.channel_target < 0:
		return
	state.pulse_ticks = maxi(Ticks.from_seconds(entry.pulse_seconds), 1)
	var target: BlasterOpsActor = targets[state.channel_target] as BlasterOpsActor
	var hold: int = state.pulse_ticks + 1 if entry.holds_target else Ticks.from_seconds(entry.power.stagger)
	_hold_target(state.channel_target, hold)
	var damage: float = entry.power.damage * _dealt_scale()
	_emit(InfiltrationEvent.Type.BOLT_HIT, 0, state.channel_target + 1, target.position, damage)
	_damage_target(state.channel_target, damage, false, player.position)


func _advance_area() -> void:
	if state.area_ticks <= 0:
		return
	state.area_ticks -= 1
	state.pulse_ticks -= 1
	if state.pulse_ticks > 0:
		return
	var entry: BlasterOpsPowerData = loadout.slot(state.area_slot)
	state.pulse_ticks = maxi(Ticks.from_seconds(entry.pulse_seconds), 1)
	var nearest: int = -1
	var distance: float = operations.storm_reach * operations.storm_reach
	for index in targets.size():
		if targets[index].health > 0.0 and targets[index].position.distance_squared_to(player.position) < distance:
			nearest = index
			distance = targets[index].position.distance_squared_to(player.position)
	if nearest >= 0:
		apply_area_damage(BlasterOpsFaction.Side.ALLIED, targets[nearest].position, entry.effect_radius, entry.power.damage * _dealt_scale(), 0)


func stealth_objective() -> bool:
	return mission != null and mission.data.objective == InfiltrationMissionData.Objective.INFILTRATION


func _affect_enemy(index: int, entry: BlasterOpsPowerData) -> void:
	var power: PowerData = entry.power
	var actor: BlasterOpsActor = targets[index] as BlasterOpsActor
	_damage_target(index, power.damage * _dealt_scale())
	actor.stun_ticks = Ticks.from_seconds(power.stagger)
	actor.impulse_ticks = Ticks.from_seconds(entry.impulse_seconds)
	var direction: Vector2 = (actor.position - player.position).normalized()
	actor.impulse = direction * power.tier_value(0) * (-1.0 if power.kind == PowerData.Kind.PULL else 1.0)
	actor.telegraph_ticks = -1
	actor.burst_left = 0


func capture() -> Dictionary:
	var snapshot: Dictionary = super.capture()
	snapshot["operations"] = state.capture()
	var health: PackedFloat32Array = []
	var swings: PackedInt32Array = []
	var cells: PackedVector2Array = []
	for cover in arena.covers:
		health.append(cover.health)
		swings.append(cover.last_swing_id)
		cells.append(Vector2(cover.data.cell))
	snapshot["covers"] = health
	snapshot["cover_swings"] = swings
	snapshot["cover_cells"] = cells
	return snapshot


func restore(snapshot: Dictionary) -> void:
	super.restore(snapshot)
	state.restore(snapshot.operations)
	for index in arena.covers.size():
		arena.covers[index].health = snapshot.covers[index]
		arena.covers[index].last_swing_id = snapshot.cover_swings[index]
		arena.covers[index].data.cell = Vector2i(snapshot.cover_cells[index])
	arena.rebuild_cells()
	if mission is BlasterOpsMissionState:
		var progress: BlasterOpsMissionState = mission as BlasterOpsMissionState
		if progress.definition.phase_target >= 0:
			target_data[progress.definition.phase_target] = progress.definition.phases[progress.phase_index].enemy
	cover_revision += 1


func _emit(type: InfiltrationEvent.Type, source: int, target: int, point: Vector2, amount: float = 0.0) -> void:
	if mission is BlasterOpsMissionState:
		var progress: BlasterOpsMissionState = mission as BlasterOpsMissionState
		if type == InfiltrationEvent.Type.SWING_STARTED:
			progress.attempts += 1
		elif type == InfiltrationEvent.Type.SWING_HIT and amount > 0.0 and progress.last_hit_swing != player.swing_id:
			progress.hits += 1
			progress.last_hit_swing = player.swing_id
	super._emit(type, source, target, point, amount)
