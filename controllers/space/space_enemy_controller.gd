class_name SpaceEnemyController
extends RefCounted

const ATTACK_STAGGER: int = 47

var _intents: Array[SpaceIntent] = []


func _init(count: int) -> void:
	for index in count:
		_intents.append(SpaceIntent.new())


func produce_all(sim: SpaceSimulation, player: SpaceIntent) -> Array[SpaceIntent]:
	var first: SpaceIntent = _intents[0]
	first.thrust = player.thrust
	first.turn = player.turn
	first.held = player.held
	first.pressed = player.pressed
	first.target = player.target
	for index in range(1, sim.ships.size()):
		var intent: SpaceIntent = _intents[index]
		intent.clear()
		var ship: SpaceShipState = sim.ships[index]
		if ship.hull <= 0.0:
			continue
		var target: int = _target(sim, index)
		if target < 0:
			continue
		intent.target = target
		var offset: Vector2 = sim.ships[target].position - ship.position
		var desired: Vector2 = offset
		if not ship.data.immobile:
			desired = _movement_goal(sim, index, target)
			intent.thrust = sim.config.formation_thrust if offset.length() < ship.data.preferred_range else 1.0
		var angle: float = wrapf(desired.angle() - ship.angle, -PI, PI)
		var turn: float = deg_to_rad(ship.data.rotation_degrees) * Ticks.DELTA
		intent.turn = clampf(angle / turn, -1.0, 1.0) if turn > 0.0 else 0.0
		var aim: float = absf(wrapf(offset.angle() - ship.angle, -PI, PI))
		for slot in 2:
			var weapon: SpaceWeaponData = sim.weapon(index, slot)
			if weapon != null and offset.length() <= weapon.max_range and aim <= deg_to_rad(sim.config.drone_aim_degrees):
				intent.held |= SpaceIntent.Command.PRIMARY if slot == 0 else SpaceIntent.Command.SECONDARY
	return _intents


func _target(sim: SpaceSimulation, index: int) -> int:
	var placement: SpaceShipPlacement = sim.arena.ships[index]
	if placement.target >= 0 and placement.target < sim.ships.size():
		if sim.ships[placement.target].hull > 0.0 and sim.ships[placement.target].team != sim.ships[index].team:
			return placement.target
	var nearest: int = -1
	var distance: float = INF
	for candidate in sim.ships.size():
		if sim.ships[candidate].hull <= 0.0 or sim.ships[candidate].team == sim.ships[index].team:
			continue
		var squared: float = sim.ships[candidate].position.distance_squared_to(sim.ships[index].position)
		if squared < distance:
			distance = squared
			nearest = candidate
	return nearest


func _is_attacking(sim: SpaceSimulation, index: int) -> bool:
	var orbit: int = Ticks.from_seconds(sim.config.orbit_seconds)
	var cycle: int = orbit + Ticks.from_seconds(sim.config.attack_seconds)
	return (sim.tick + index * ATTACK_STAGGER) % cycle >= orbit


func _movement_goal(sim: SpaceSimulation, index: int, target: int) -> Vector2:
	var ship: SpaceShipState = sim.ships[index]
	var placement: SpaceShipPlacement = sim.arena.ships[index]
	if placement.formation >= 0 and placement.formation != index and sim.ships[placement.formation].hull > 0.0:
		var leader: SpaceShipState = sim.ships[placement.formation]
		var goal: Vector2 = leader.position + placement.formation_offset.rotated(leader.angle)
		if goal.distance_to(ship.position) > sim.config.formation_distance:
			return goal - ship.position
	var offset: Vector2 = sim.ships[target].position - ship.position
	if ship.data.archetype == SpaceShipData.Archetype.FIGHTER and offset.length() < ship.data.preferred_range and not _is_attacking(sim, index):
		return offset.rotated(sim.config.orbit_angle * (-1.0 if index % 2 == 0 else 1.0))
	if ship.data.archetype == SpaceShipData.Archetype.GUNSHIP and offset.length() < ship.data.preferred_range * sim.config.gunship_retreat_ratio:
		return -offset
	return offset
