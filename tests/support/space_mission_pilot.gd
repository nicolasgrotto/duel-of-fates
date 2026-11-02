class_name SpaceMissionPilot
extends RefCounted

const DODGE_RANGE: float = 120.0
const THREAT_RANGE: float = 520.0
const STANDOFF: Vector2 = Vector2(-440, 0)
const ARRIVAL_RADIUS: float = 120.0
const ARRIVAL_SPEED: float = 25.0
const DRIFT_LIMIT: float = 640.0

var intent: SpaceIntent = SpaceIntent.new()
var _arrived: int = -1


func produce(sim: SpaceSimulation) -> SpaceIntent:
	intent.clear()
	var pilot: SpaceShipState = sim.ships[0]
	var target: int = _nearby_threat(sim)
	if target < 0:
		target = sim.mission.next_target(sim)
	if target < 0:
		return intent
	intent.target = target
	var enemy: SpaceShipState = sim.ships[target]
	var offset: Vector2 = enemy.position - pilot.position
	if enemy.data.immobile and _arrived == target and offset.length() > DRIFT_LIMIT:
		_arrived = -1
	if enemy.data.immobile and _arrived != target:
		var goal: Vector2 = enemy.position + STANDOFF - pilot.position
		var speed: float = pilot.velocity.length()
		if goal.length() < ARRIVAL_RADIUS and speed < ARRIVAL_SPEED:
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
	if pilot.boost_cooldown == 0 and _projectile_incoming(sim):
		intent.thrust = -1.0
		intent.pressed |= SpaceIntent.Command.BOOST
	return intent


func _projectile_incoming(sim: SpaceSimulation) -> bool:
	var pilot: SpaceShipState = sim.ships[0]
	for projectile in sim.projectiles:
		if projectile.active and sim.ships[projectile.source].team != pilot.team and projectile.position.distance_to(pilot.position) < DODGE_RANGE:
			return true
	return false


func _nearby_threat(sim: SpaceSimulation) -> int:
	var pilot: SpaceShipState = sim.ships[0]
	var nearest: int = -1
	var distance: float = THREAT_RANGE
	for index in range(1, sim.ships.size()):
		var ship: SpaceShipState = sim.ships[index]
		if ship.hull <= 0.0 or ship.team == pilot.team or ship.data.immobile:
			continue
		var candidate: float = ship.position.distance_to(pilot.position)
		if candidate < distance:
			distance = candidate
			nearest = index
	return nearest
