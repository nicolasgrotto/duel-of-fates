class_name SpaceSimulation
extends RefCounted

const PLAYER_INDEX: int = 0

var config: SpaceConfig
var arena: SpaceArenaData
var ships: Array[SpaceShipState] = []
var projectiles: Array[SpaceProjectile] = []
var events: Array[SpaceEvent] = []
var tick: int = 0
var event_count: int = 0
var dropped_events: int = 0
var destroyed_targets: int = 0
var mission: SpaceMissionState
var weapon_catalog: Array[SpaceWeaponData] = []
var _ends: PackedVector2Array = []
var _distances: PackedFloat32Array = []
var _empty: SpaceIntent = SpaceIntent.new()


func _init(configuration: SpaceConfig, arena_data: SpaceArenaData, mission_data: SpaceMissionData = null) -> void:
	config = configuration
	arena = arena_data
	for placement in arena.ships:
		var ship: SpaceShipState = SpaceShipState.new()
		ship.reset(placement)
		if mission_data != null and placement.wave > 0:
			ship.hull = 0.0
		_register_weapon(placement.ship.primary)
		_register_weapon(placement.ship.secondary)
		ships.append(ship)
	if mission_data != null:
		mission = SpaceMissionState.new(mission_data)
		for phase in mission_data.phases:
			_register_weapon(phase.primary)
			_register_weapon(phase.secondary)
	for index in config.projectile_capacity:
		projectiles.append(SpaceProjectile.new())
	for index in config.event_capacity:
		events.append(SpaceEvent.new())
	_ends.resize(projectiles.size())
	_distances.resize(projectiles.size())


func step(intents: Array[SpaceIntent]) -> void:
	event_count = 0
	if (mission != null and mission.outcome != SpaceMissionState.Outcome.ACTIVE) or (mission == null and ships[0].hull <= 0.0):
		return
	tick += 1
	if mission != null:
		mission.before_tick(self)
	for index in ships.size():
		var ship: SpaceShipState = ships[index]
		ship.previous = ship.position
		ship.previous_angle = ship.angle
		if ship.hull <= 0.0:
			_step_respawn(index)
			continue
		_advance_timers(ship, index)
		_move(index, intents[index] if index < intents.size() else _empty)
	_resolve_bodies()
	for index in ships.size():
		if ships[index].hull > 0.0:
			var intent: SpaceIntent = intents[index] if index < intents.size() else _empty
			_step_weapon(index, 0, intent)
			_step_weapon(index, 1, intent)
	_step_projectiles()
	if mission != null:
		mission.advance(self)


func _advance_timers(ship: SpaceShipState, index: int) -> void:
	ship.boost_cooldown = maxi(ship.boost_cooldown - 1, 0)
	ship.contact_cooldown = maxi(ship.contact_cooldown - 1, 0)
	if ship.boost_tick >= 0:
		ship.boost_tick += 1
		if ship.boost_tick >= config.boost_ticks():
			ship.boost_tick = -1
			ship.velocity = ship.velocity.limit_length(ship.data.speed)
	for slot in 2:
		ship.cooldowns[slot] = maxi(ship.cooldowns[slot] - 1, 0)
	ship.shield_delay = maxi(ship.shield_delay - 1, 0)
	if ship.shield_delay == 0 and (mission == null or mission.shield_online(self, index)):
		ship.shield = minf(ship.shield + ship.data.shield_regeneration * Ticks.DELTA, ship.data.shield)


func _move(index: int, intent: SpaceIntent) -> void:
	var ship: SpaceShipState = ships[index]
	ship.thrust = clampf(intent.thrust, -1.0, 1.0)
	if ship.boost_tick < 0:
		var ratio: float = mission.rotation_ratio(self, index) if mission != null else 1.0
		ship.angle = wrapf(ship.angle + clampf(intent.turn, -1.0, 1.0) * deg_to_rad(ship.data.rotation_degrees) * ratio * Ticks.DELTA, -PI, PI)
		if ship.data.can_boost and ship.boost_cooldown == 0 and (intent.pressed & SpaceIntent.Command.BOOST) != 0:
			ship.boost_tick = 0
			ship.boost_cooldown = Ticks.from_seconds(config.boost_cooldown * ship.data.boost_cooldown_ratio)
			ship.boost_direction = ship.forward() * (-1.0 if ship.thrust < 0.0 else 1.0)
			ship.charges.fill(-1)
			_emit(SpaceEvent.Type.BOOST_STARTED, index, -1, ship.position)
	if ship.data.immobile:
		ship.velocity = Vector2.ZERO
	elif ship.boost_tick >= 0:
		ship.velocity = ship.boost_direction * config.boost_speed
	else:
		var acceleration: float = ship.data.acceleration * ship.thrust * (ship.data.reverse_ratio if ship.thrust < 0.0 else 1.0)
		ship.velocity += ship.forward() * acceleration * Ticks.DELTA
		ship.velocity = ship.velocity.move_toward(Vector2.ZERO, ship.data.drag * Ticks.DELTA).limit_length(ship.data.speed)
	ship.position += ship.velocity * Ticks.DELTA
	_clamp_ship(ship)


func _clamp_ship(ship: SpaceShipState) -> void:
	var bounded: Vector2 = ship.position.clamp(Vector2.ONE * ship.data.radius, arena.size - Vector2.ONE * ship.data.radius)
	if bounded.x != ship.position.x:
		ship.velocity.x = 0.0
	if bounded.y != ship.position.y:
		ship.velocity.y = 0.0
	ship.position = bounded


func _resolve_bodies() -> void:
	for first in ships.size():
		var a: SpaceShipState = ships[first]
		if a.hull <= 0.0:
			continue
		for second in range(first + 1, ships.size()):
			var b: SpaceShipState = ships[second]
			if b.hull <= 0.0:
				continue
			var offset: Vector2 = b.position - a.position
			var distance: float = offset.length()
			var overlap: float = a.data.radius + b.data.radius - distance
			if overlap <= 0.0:
				continue
			var normal: Vector2 = offset / distance if distance > SpaceGeometry.EPSILON else Vector2.RIGHT
			if first == PLAYER_INDEX:
				_apply_contact(second, a.position + normal * a.data.radius)
			var share: float = 1.0 if b.data.immobile else 0.0 if a.data.immobile else 0.5
			if not a.data.immobile:
				a.position -= normal * overlap * share
				a.velocity -= normal * maxf(a.velocity.dot(normal), 0.0)
			if not b.data.immobile:
				b.position += normal * overlap * (1.0 - share)
				b.velocity -= normal * minf(b.velocity.dot(normal), 0.0)
			_clamp_ship(a)
			_clamp_ship(b)
		for obstacle in arena.obstacles:
			var offset: Vector2 = a.position - obstacle.position
			var distance: float = offset.length()
			var overlap: float = a.data.radius + obstacle.radius - distance
			if overlap > 0.0 and not a.data.immobile:
				var normal: Vector2 = offset / distance if distance > SpaceGeometry.EPSILON else Vector2.LEFT
				a.position += normal * overlap
				a.velocity -= normal * minf(a.velocity.dot(normal), 0.0)
				_clamp_ship(a)


func _apply_contact(other: int, point: Vector2) -> void:
	var ship: SpaceShipState = ships[PLAYER_INDEX]
	if ship.contact_cooldown > 0 or ship.invulnerable(config):
		return
	ship.contact_cooldown = Ticks.from_seconds(config.contact_cooldown)
	ship.shield_delay = Ticks.from_seconds(ship.data.shield_delay)
	var absorbed: float = minf(ship.shield, config.contact_shield_damage * ship.data.contact_ratio)
	if absorbed <= 0.0:
		return
	ship.shield -= absorbed
	_emit(SpaceEvent.Type.SHIELD_HIT, other, PLAYER_INDEX, point, absorbed)


func weapon(source: int, slot: int) -> SpaceWeaponData:
	if mission != null and source == mission.data.boss and not mission.data.phases.is_empty():
		var phase: SpaceBossPhase = mission.data.phases[mission.phase]
		return phase.primary if slot == 0 else phase.secondary
	return ships[source].data.primary if slot == 0 else ships[source].data.secondary


func projectile_data(projectile: SpaceProjectile) -> SpaceWeaponData:
	return weapon_catalog[projectile.weapon_index] if projectile.weapon_index >= 0 else weapon(projectile.source, projectile.slot)


func _register_weapon(data: SpaceWeaponData) -> void:
	if data != null and not weapon_catalog.has(data):
		weapon_catalog.append(data)


func _step_weapon(source: int, slot: int, intent: SpaceIntent) -> void:
	var ship: SpaceShipState = ships[source]
	var command: int = SpaceIntent.Command.PRIMARY if slot == 0 else SpaceIntent.Command.SECONDARY
	var data: SpaceWeaponData = weapon(source, slot)
	if data == null:
		if slot == 1 and (intent.pressed & command) != 0:
			_emit(SpaceEvent.Type.ACTION_REFUSED, source, -1, ship.position, float(SpaceEvent.Refusal.NO_SECONDARY))
		return
	var requested: bool = ((intent.pressed if data.press_only else intent.held) & command) != 0
	if ship.boost_tick >= 0 or not requested or ship.cooldowns[slot] > 0:
		ship.charges[slot] = -1
		return
	var windup: int = Ticks.from_seconds(data.windup)
	if ship.charges[slot] < 0:
		ship.charges[slot] = 0
		if windup > 0:
			_emit(SpaceEvent.Type.WEAPON_PRIMED, source, slot, ship.position)
	if ship.charges[slot] < windup:
		ship.charges[slot] += 1
		return
	if _fire(source, slot, data, intent.target):
		ship.cooldowns[slot] = Ticks.from_seconds(data.interval)
		ship.charges[slot] = -1


func _fire(source: int, slot: int, data: SpaceWeaponData, target: int = -1) -> bool:
	var free: int = 0
	for projectile in projectiles:
		free += int(not projectile.active)
	if free < data.count:
		_emit(SpaceEvent.Type.ACTION_REFUSED, source, slot, ships[source].position, float(SpaceEvent.Refusal.POOL_FULL))
		return false
	if target < 0 or target >= ships.size() or ships[target].hull <= 0.0 or ships[target].team == ships[source].team:
		target = mission.next_target(self) if source == 0 and mission != null else _nearest_hostile(source)
	var fired: int = 0
	for projectile in projectiles:
		if projectile.active:
			continue
		projectile.active = true
		projectile.source = source
		projectile.slot = slot
		projectile.weapon_index = weapon_catalog.find(data)
		projectile.target = target
		projectile.hull = data.projectile_hull
		projectile.position = ships[source].position + ships[source].forward() * data.muzzle + ships[source].forward().orthogonal() * data.muzzle_side
		projectile.previous = projectile.position
		var spread: float = lerpf(-data.spread_degrees * 0.5, data.spread_degrees * 0.5, float(fired) / (data.count - 1)) if data.count > 1 else 0.0
		projectile.velocity = Vector2.from_angle(ships[source].angle + deg_to_rad(spread)) * data.speed
		projectile.travelled = 0.0
		projectile.age = 0
		_emit(SpaceEvent.Type.SHOT_FIRED, source, slot, projectile.position, float(data.kind))
		fired += 1
		if fired == data.count:
			return true
	return true


func _nearest_hostile(source: int) -> int:
	var nearest: int = -1
	var distance: float = INF
	for index in ships.size():
		if ships[index].hull <= 0.0 or ships[index].team == ships[source].team:
			continue
		var candidate: float = ships[index].position.distance_squared_to(ships[source].position)
		if candidate < distance:
			distance = candidate
			nearest = index
	return nearest


func _step_projectiles() -> void:
	for index in projectiles.size():
		var projectile: SpaceProjectile = projectiles[index]
		if not projectile.active:
			continue
		var data: SpaceWeaponData = projectile_data(projectile)
		projectile.previous = projectile.position
		if data.kind == SpaceWeaponData.Kind.MISSILE:
			_steer_missile(projectile, data)
		_distances[index] = minf(projectile.velocity.length() * Ticks.DELTA, data.max_range - projectile.travelled)
		_ends[index] = projectile.position + projectile.velocity.normalized() * _distances[index]
	for kind in 2:
		for index in projectiles.size():
			if projectiles[index].active and int(projectile_data(projectiles[index]).kind) == kind:
				_resolve_projectile(index)


func _steer_missile(projectile: SpaceProjectile, data: SpaceWeaponData) -> void:
	if projectile.target < 0 or ships[projectile.target].hull <= 0.0:
		return
	var angle: float = projectile.velocity.angle()
	var desired: float = (ships[projectile.target].position - projectile.position).angle()
	var difference: float = wrapf(desired - angle, -PI, PI)
	var turn: float = deg_to_rad(data.turn_degrees) * Ticks.DELTA
	projectile.velocity = Vector2.from_angle(angle + clampf(difference, -turn, turn)) * data.speed


func _resolve_projectile(index: int) -> void:
	var projectile: SpaceProjectile = projectiles[index]
	var data: SpaceWeaponData = projectile_data(projectile)
	var end: Vector2 = _ends[index]
	var fraction: float = INF
	var victim: int = -1
	for obstacle in arena.obstacles:
		fraction = minf(fraction, SpaceGeometry.segment_circle_fraction(projectile.previous, end, obstacle.position, obstacle.radius + data.radius))
	for target in ships.size():
		var ship: SpaceShipState = ships[target]
		if ship.hull <= 0.0 or ship.team == ships[projectile.source].team:
			continue
		var start: Vector2 = ship.position if projectile.age == 0 else ship.previous
		var impact: float = SpaceGeometry.segment_circle_fraction(projectile.previous - start, end - ship.position, Vector2.ZERO, ship.data.radius + data.radius)
		if impact < fraction:
			fraction = impact
			victim = target
	if data.kind == SpaceWeaponData.Kind.BOLT:
		for target in projectiles.size():
			var missile: SpaceProjectile = projectiles[target]
			if not missile.active or missile.hull <= 0.0 or ships[missile.source].team == ships[projectile.source].team:
				continue
			var impact: float = SpaceGeometry.segment_circle_fraction(projectile.previous - missile.previous, end - _ends[target], Vector2.ZERO, data.radius + projectile_data(missile).radius)
			if impact < fraction:
				fraction = impact
				victim = ships.size() + target
	if fraction != INF:
		projectile.position = projectile.previous.lerp(end, fraction)
		projectile.active = false
		if victim >= ships.size():
			var missile: SpaceProjectile = projectiles[victim - ships.size()]
			missile.hull = maxf(missile.hull - data.damage, 0.0)
			if missile.hull == 0.0:
				missile.active = false
				_emit(SpaceEvent.Type.MISSILE_DESTROYED, projectile.source, victim - ships.size(), projectile.position)
		elif victim >= 0:
			_damage(victim, projectile.source, data.damage, projectile.position)
	else:
		projectile.position = end
		projectile.travelled += _distances[index]
		projectile.age += 1
		if projectile.travelled >= data.max_range or not Rect2(Vector2.ZERO, arena.size).has_point(end):
			projectile.active = false


func _damage(target: int, source: int, amount: float, point: Vector2) -> void:
	var ship: SpaceShipState = ships[target]
	if mission != null and not mission.can_damage(self, target):
		_emit(SpaceEvent.Type.SHIELD_HIT, source, target, point)
		return
	if ship.invulnerable(config):
		_emit(SpaceEvent.Type.SHOT_EVADED, source, target, point)
		return
	ship.shield_delay = Ticks.from_seconds(ship.data.shield_delay)
	var absorbed: float = minf(ship.shield, amount)
	ship.shield -= absorbed
	if absorbed > 0.0:
		_emit(SpaceEvent.Type.SHIELD_HIT, source, target, point, absorbed)
	var damage: float = amount - absorbed
	if damage > 0.0:
		var actual: float = minf(ship.hull, damage)
		ship.hull = maxf(ship.hull - damage, 0.0)
		_emit(SpaceEvent.Type.HULL_HIT, source, target, point, damage)
		var placement: SpaceShipPlacement = arena.ships[target]
		if mission != null and placement.role == SpaceShipPlacement.Role.WEAKPOINT and placement.parent >= 0:
			var parent: SpaceShipState = ships[placement.parent]
			parent.hull = maxf(parent.hull - actual, 0.0)
			if parent.hull == 0.0:
				_destroy_ship(placement.parent, source)
	if ship.hull == 0.0:
		_destroy_ship(target, source)


func _destroy_ship(target: int, source: int) -> void:
	var ship: SpaceShipState = ships[target]
	ship.velocity = Vector2.ZERO
	ship.boost_tick = -1
	ship.charges.fill(-1)
	ship.respawn_ticks = Ticks.from_seconds(arena.ships[target].respawn_seconds)
	if ship.team != ships[0].team:
		destroyed_targets += 1
	if mission != null:
		mission.on_destroyed(self, target)
	_emit(SpaceEvent.Type.SHIP_DESTROYED, source, target, ship.position)


func spawn_clear(index: int) -> bool:
	var ship: SpaceShipState = ships[index]
	var point: Vector2 = arena.ships[index].position
	if point.x < ship.data.radius or point.y < ship.data.radius or point.x > arena.size.x - ship.data.radius or point.y > arena.size.y - ship.data.radius:
		return false
	for other in ships:
		if other.hull > 0.0 and other.position.distance_to(point) < other.data.radius + ship.data.radius:
			return false
	for obstacle in arena.obstacles:
		if point.distance_to(obstacle.position) < ship.data.radius + obstacle.radius:
			return false
	return true


func emit_event(type: SpaceEvent.Type, source: int, target: int, position: Vector2, amount: float = 0.0) -> void:
	_emit(type, source, target, position, amount)


func _step_respawn(index: int) -> void:
	var ship: SpaceShipState = ships[index]
	if ship.respawn_ticks <= 0:
		return
	if ship.respawn_ticks > 1:
		ship.respawn_ticks -= 1
		return
	var placement: SpaceShipPlacement = arena.ships[index]
	for other in ships:
		if other.hull > 0.0 and other.position.distance_to(placement.position) < other.data.radius + ship.data.radius:
			return
	ship.reset(placement)
	_emit(SpaceEvent.Type.SHIP_RESTORED, index, index, ship.position)


func _emit(type: SpaceEvent.Type, source: int, target: int, position: Vector2, amount: float = 0.0) -> void:
	if event_count >= events.size():
		dropped_events += 1
		return
	var event: SpaceEvent = events[event_count]
	event_count += 1
	event.type = type
	event.source = source
	event.target = target
	event.position = position
	event.amount = amount


func capture() -> Dictionary:
	var actors: Array[Dictionary] = []
	var shots: Array[Dictionary] = []
	for ship in ships:
		actors.append(ship.capture())
	for projectile in projectiles:
		shots.append(projectile.capture())
	return {"tick": tick, "ships": actors, "projectiles": shots, "destroyed_targets": destroyed_targets, "dropped_events": dropped_events, "mission": mission.capture() if mission != null else {}}


func restore(state: Dictionary) -> void:
	tick = state.tick
	destroyed_targets = state.destroyed_targets
	dropped_events = state.dropped_events
	for index in ships.size():
		ships[index].restore(state.ships[index])
	for index in projectiles.size():
		projectiles[index].restore(state.projectiles[index])
	event_count = 0
	if mission != null:
		mission.restore(state.mission)


func state_hash() -> int:
	return hash(capture())
