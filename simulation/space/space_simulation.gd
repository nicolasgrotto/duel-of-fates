class_name SpaceSimulation
extends RefCounted

var config: SpaceConfig
var arena: SpaceArenaData
var ships: Array[SpaceShipState] = []
var projectiles: Array[SpaceProjectile] = []
var events: Array[SpaceEvent] = []
var tick: int = 0
var event_count: int = 0
var dropped_events: int = 0
var destroyed_targets: int = 0
var _empty: SpaceIntent = SpaceIntent.new()


func _init(configuration: SpaceConfig, arena_data: SpaceArenaData) -> void:
	config = configuration
	arena = arena_data
	for placement in arena.ships:
		var ship: SpaceShipState = SpaceShipState.new()
		ship.reset(placement)
		ships.append(ship)
	for index in config.projectile_capacity:
		projectiles.append(SpaceProjectile.new())
	for index in config.event_capacity:
		events.append(SpaceEvent.new())


func step(intents: Array[SpaceIntent]) -> void:
	event_count = 0
	if ships[0].hull <= 0.0:
		return
	tick += 1
	for index in ships.size():
		var ship: SpaceShipState = ships[index]
		ship.previous = ship.position
		ship.previous_angle = ship.angle
		if ship.hull <= 0.0:
			_step_respawn(index)
			continue
		_advance_timers(ship)
		_move(index, intents[index] if index < intents.size() else _empty)
	_resolve_bodies()
	for index in ships.size():
		if ships[index].hull > 0.0:
			var intent: SpaceIntent = intents[index] if index < intents.size() else _empty
			_step_weapon(index, 0, intent)
			_step_weapon(index, 1, intent)
	_step_projectiles()


func _advance_timers(ship: SpaceShipState) -> void:
	ship.boost_cooldown = maxi(ship.boost_cooldown - 1, 0)
	if ship.boost_tick >= 0:
		ship.boost_tick += 1
		if ship.boost_tick >= config.boost_ticks():
			ship.boost_tick = -1
			ship.velocity = ship.velocity.limit_length(ship.data.speed)
	for slot in 2:
		ship.cooldowns[slot] = maxi(ship.cooldowns[slot] - 1, 0)
	ship.shield_delay = maxi(ship.shield_delay - 1, 0)
	if ship.shield_delay == 0:
		ship.shield = minf(ship.shield + ship.data.shield_regeneration * Ticks.DELTA, ship.data.shield)


func _move(index: int, intent: SpaceIntent) -> void:
	var ship: SpaceShipState = ships[index]
	ship.thrust = clampf(intent.thrust, -1.0, 1.0)
	if ship.boost_tick < 0:
		ship.angle = wrapf(ship.angle + clampf(intent.turn, -1.0, 1.0) * deg_to_rad(ship.data.rotation_degrees) * Ticks.DELTA, -PI, PI)
		if ship.data.can_boost and ship.boost_cooldown == 0 and (intent.pressed & SpaceIntent.Command.BOOST) != 0:
			ship.boost_tick = 0
			ship.boost_cooldown = Ticks.from_seconds(config.boost_cooldown)
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
			var share: float = 1.0 if b.data.immobile else 0.0 if a.data.immobile else 0.5
			if not a.data.immobile:
				a.position -= normal * overlap * share
				a.velocity -= normal * maxf(a.velocity.dot(normal), 0.0)
			if not b.data.immobile:
				b.position += normal * overlap * (1.0 - share)
				b.velocity -= normal * minf(b.velocity.dot(normal), 0.0)
			_clamp_ship(a)
			_clamp_ship(b)


func weapon(source: int, slot: int) -> SpaceWeaponData:
	return ships[source].data.primary if slot == 0 else ships[source].data.secondary


func _step_weapon(source: int, slot: int, intent: SpaceIntent) -> void:
	var ship: SpaceShipState = ships[source]
	var command: int = SpaceIntent.Command.PRIMARY if slot == 0 else SpaceIntent.Command.SECONDARY
	var data: SpaceWeaponData = weapon(source, slot)
	if data == null:
		if slot == 1 and (intent.pressed & command) != 0:
			_emit(SpaceEvent.Type.ACTION_REFUSED, source, -1, ship.position, float(SpaceEvent.Refusal.NO_SECONDARY))
		return
	if ship.boost_tick >= 0 or (intent.held & command) == 0 or ship.cooldowns[slot] > 0:
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
	if _fire(source, slot, data):
		ship.cooldowns[slot] = Ticks.from_seconds(data.interval)
		ship.charges[slot] = -1


func _fire(source: int, slot: int, data: SpaceWeaponData) -> bool:
	for projectile in projectiles:
		if projectile.active:
			continue
		projectile.active = true
		projectile.source = source
		projectile.slot = slot
		projectile.position = ships[source].position + ships[source].forward() * data.muzzle + ships[source].forward().orthogonal() * data.muzzle_side
		projectile.previous = projectile.position
		projectile.velocity = ships[source].forward() * data.speed
		projectile.travelled = 0.0
		projectile.age = 0
		_emit(SpaceEvent.Type.SHOT_FIRED, source, slot, projectile.position)
		return true
	_emit(SpaceEvent.Type.ACTION_REFUSED, source, slot, ships[source].position, float(SpaceEvent.Refusal.POOL_FULL))
	return false


func _step_projectiles() -> void:
	for projectile in projectiles:
		if not projectile.active:
			continue
		var data: SpaceWeaponData = weapon(projectile.source, projectile.slot)
		projectile.previous = projectile.position
		var distance: float = minf(projectile.velocity.length() * Ticks.DELTA, data.max_range - projectile.travelled)
		var end: Vector2 = projectile.position + projectile.velocity.normalized() * distance
		var fraction: float = INF
		var victim: int = -1
		for index in ships.size():
			var ship: SpaceShipState = ships[index]
			if ship.hull <= 0.0 or ship.team == ships[projectile.source].team:
				continue
			var start: Vector2 = ship.position if projectile.age == 0 else ship.previous
			var impact: float = SpaceGeometry.segment_circle_fraction(projectile.position - start, end - ship.position, Vector2.ZERO, ship.data.radius + data.radius)
			if impact < fraction:
				fraction = impact
				victim = index
		if victim >= 0:
			projectile.position = projectile.position.lerp(end, fraction)
			projectile.active = false
			_damage(victim, projectile.source, data.damage, projectile.position)
		else:
			projectile.position = end
			projectile.travelled += distance
			projectile.age += 1
			if projectile.travelled >= data.max_range or not Rect2(Vector2.ZERO, arena.size).has_point(end):
				projectile.active = false


func _damage(target: int, source: int, amount: float, point: Vector2) -> void:
	var ship: SpaceShipState = ships[target]
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
		ship.hull = maxf(ship.hull - damage, 0.0)
		_emit(SpaceEvent.Type.HULL_HIT, source, target, point, damage)
	if ship.hull == 0.0:
		ship.velocity = Vector2.ZERO
		ship.boost_tick = -1
		ship.charges.fill(-1)
		ship.respawn_ticks = Ticks.from_seconds(arena.ships[target].respawn_seconds)
		if ship.team != ships[0].team:
			destroyed_targets += 1
		_emit(SpaceEvent.Type.SHIP_DESTROYED, source, target, ship.position)


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
	return {"tick": tick, "ships": actors, "projectiles": shots, "destroyed_targets": destroyed_targets, "dropped_events": dropped_events}


func restore(state: Dictionary) -> void:
	tick = state.tick
	destroyed_targets = state.destroyed_targets
	dropped_events = state.dropped_events
	for index in ships.size():
		ships[index].restore(state.ships[index])
	for index in projectiles.size():
		projectiles[index].restore(state.projectiles[index])
	event_count = 0


func state_hash() -> int:
	return hash(capture())
