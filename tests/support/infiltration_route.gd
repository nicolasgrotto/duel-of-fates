class_name InfiltrationRoute
extends RefCounted

const DANGER_MARGIN: float = 90.0
const DANGER_ANGLE_MARGIN: float = 16.0
const LOOKAHEAD: float = 110.0
const INTERACT_RANGE: float = 8.0
const SWING_RANGE: float = 65.0
const NOTICED_RANGE: float = 460.0
const ATTACK_RANGE: float = 420.0

var intent: InfiltrationIntent = InfiltrationIntent.new()
var _navigation: InfiltrationNavigation
var _points: PackedVector2Array = []
var _point: int = 0
var _aggressive: bool = false


func _init(sim: InfiltrationSimulation, aggressive: bool = false) -> void:
	_navigation = InfiltrationNavigation.new(sim.map)
	_aggressive = aggressive
	var data: InfiltrationMissionData = sim.mission.data
	if data.disable_alarms:
		for panel in sim.map.panels:
			_points.append(panel.position)
	_points.append_array(data.terminals)
	_points.append_array(data.prisoner_spawns)
	_points.append(data.extraction)


func produce(sim: InfiltrationSimulation) -> InfiltrationIntent:
	intent.clear()
	var threat: int = _threat(sim)
	if threat >= 0:
		_fight(sim, threat)
		return intent
	if _point >= _points.size():
		return intent
	var destination: Vector2 = _points[_point]
	var offset: Vector2 = destination - sim.player.position
	intent.aim = offset.normalized()
	if offset.length() <= INTERACT_RANGE:
		intent.pressed = Intent.Command.POWER
		_point += 1
		return intent
	var movement: Vector2 = _navigation.direction(sim.player.position, destination, sim.config.body_radius)
	if not _aggressive:
		intent.held = Intent.Command.SPECIAL
		if _is_watched(sim, sim.player.position + movement * LOOKAHEAD):
			movement = _evade(sim, movement)
	intent.movement = movement
	return intent


func _threat(sim: InfiltrationSimulation) -> int:
	var nearest: float = (ATTACK_RANGE if _aggressive else NOTICED_RANGE)
	var result: int = -1
	for index in range(sim.map.targets.size(), sim.targets.size()):
		var actor: InfiltrationActor = sim.targets[index]
		if actor.health <= 0.0 or (sim.enemy_placement(index).reinforcement and not sim.mission.alarm_raised):
			continue
		if not _aggressive and actor.awareness != InfiltrationActor.Awareness.ALERTED:
			continue
		var distance: float = sim.player.position.distance_to(actor.position)
		if distance < nearest and InfiltrationGeometry.wall_fraction(sim.map, sim.player.position, actor.position) == INF:
			nearest = distance
			result = index
	return result


func _fight(sim: InfiltrationSimulation, index: int) -> void:
	var target: InfiltrationActor = sim.targets[index]
	var offset: Vector2 = target.position - sim.player.position
	intent.aim = offset.normalized()
	if offset.length() > SWING_RANGE:
		intent.movement = _navigation.direction(sim.player.position, target.position, sim.config.body_radius)
		intent.held = Intent.Command.BLOCK
	elif sim.player.swing_tick < 0:
		intent.pressed = Intent.Command.LIGHT


func _is_watched(sim: InfiltrationSimulation, point: Vector2) -> bool:
	for index in range(sim.map.targets.size(), sim.targets.size()):
		var actor: InfiltrationActor = sim.targets[index]
		if actor.health <= 0.0 or sim.enemy_placement(index).reinforcement:
			continue
		var data: InfiltrationEnemyData = sim.target_data[index] as InfiltrationEnemyData
		var to_point: Vector2 = point - actor.position
		if to_point.length() > data.vision_range + DANGER_MARGIN:
			continue
		if rad_to_deg(absf(actor.aim.angle_to(to_point))) > data.vision_degrees * 0.5 + DANGER_ANGLE_MARGIN:
			continue
		if InfiltrationGeometry.wall_fraction(sim.map, actor.position, point) == INF:
			return true
	return false


func _evade(sim: InfiltrationSimulation, movement: Vector2) -> Vector2:
	if not _is_watched(sim, sim.player.position):
		return Vector2.ZERO
	for candidate in [movement.orthogonal(), -movement.orthogonal(), -movement]:
		var point: Vector2 = sim.player.position + candidate * LOOKAHEAD
		if InfiltrationGeometry.wall_fraction(sim.map, sim.player.position, point, sim.config.body_radius) == INF and not _is_watched(sim, point):
			return candidate
	return Vector2.ZERO
