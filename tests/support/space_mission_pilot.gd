class_name SpaceMissionPilot
extends RefCounted

var intent: SpaceIntent = SpaceIntent.new()
var _arrived: int = -1


func produce(sim: SpaceSimulation) -> SpaceIntent:
	intent.clear()
	var target: int = sim.mission.next_target(sim)
	if target < 0:
		return intent
	intent.target = target
	var pilot: SpaceShipState = sim.ships[0]
	var enemy: SpaceShipState = sim.ships[target]
	var offset: Vector2 = enemy.position - pilot.position
	if enemy.data.immobile and _arrived != target:
		var goal: Vector2 = enemy.position + Vector2(-440, 0) - pilot.position
		var speed: float = pilot.velocity.length()
		if goal.length() < 120.0 and speed < 25.0:
			_arrived = target
		else:
			var heading: float = wrapf(goal.angle() - pilot.angle, -PI, PI)
			intent.turn = clampf(heading / (deg_to_rad(pilot.data.rotation_degrees) * Ticks.DELTA), -1.0, 1.0)
			if absf(heading) < 0.3 and goal.length() > speed * speed / (2.0 * pilot.data.drag) + 40.0:
				intent.thrust = 0.6
			return intent
	var lead: Vector2 = offset + enemy.velocity * offset.length() / pilot.data.primary.speed
	var angle: float = wrapf(lead.angle() - pilot.angle, -PI, PI)
	intent.turn = clampf(angle / (deg_to_rad(pilot.data.rotation_degrees) * Ticks.DELTA), -1.0, 1.0)
	if not enemy.data.immobile and absf(angle) < 0.4 and offset.length() > 440.0:
		intent.thrust = clampf((offset.length() - 440.0) / 250.0, 0.0, 1.0)
	if absf(angle) < 0.09:
		intent.held |= SpaceIntent.Command.PRIMARY
		if pilot.cooldowns[1] == 0:
			intent.pressed |= SpaceIntent.Command.SECONDARY
	return intent
