class_name SpaceDroneController
extends RefCounted

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
	for index in range(1, sim.ships.size()):
		var intent: SpaceIntent = _intents[index]
		intent.clear()
		var ship: SpaceShipState = sim.ships[index]
		if ship.hull <= 0.0 or sim.ships[0].hull <= 0.0 or ship.team == sim.ships[0].team:
			continue
		var offset: Vector2 = sim.ships[0].position - ship.position
		var angle: float = wrapf(offset.angle() - ship.angle, -PI, PI)
		var turn: float = deg_to_rad(ship.data.rotation_degrees) * Ticks.DELTA
		intent.turn = clampf(angle / turn, -1.0, 1.0) if turn > 0.0 else 0.0
		if ship.data.primary != null and offset.length() <= ship.data.primary.max_range and absf(angle) <= deg_to_rad(sim.config.drone_aim_degrees):
			intent.held = SpaceIntent.Command.PRIMARY
	return _intents
