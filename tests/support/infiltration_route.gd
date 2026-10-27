class_name InfiltrationRoute
extends RefCounted

var intent: InfiltrationIntent = InfiltrationIntent.new()
var _navigation: InfiltrationNavigation
var _points: PackedVector2Array = []
var _point: int = 0
var _aggressive: bool = false
var _combat_ticks: int = 0
var _combat_done: bool = false


func _init(sim: InfiltrationSimulation, aggressive: bool = false) -> void:
	_navigation = InfiltrationNavigation.new(sim.map)
	_aggressive = aggressive
	var data: InfiltrationMissionData = sim.mission.data
	if data.id == &"first_access":
		_points.append(data.map.panels[0].position)
	else:
		_points.append(Vector2(224, 1056))
		if data.disable_alarms:
			for panel in sim.map.panels:
				_points.append(panel.position)
		_points.append(Vector2(1632, 1056))
		_points.append(Vector2(224, 1056))
	_points.append(data.extraction)


func produce(sim: InfiltrationSimulation) -> InfiltrationIntent:
	intent.clear()
	intent.held = Intent.Command.SPECIAL
	if _aggressive and not _combat_done:
		_combat(sim)
		return intent
	if _point >= _points.size():
		return intent
	var destination: Vector2 = _points[_point]
	var offset: Vector2 = destination - sim.player.position
	intent.aim = offset.normalized()
	if offset.length() > 8.0:
		intent.movement = _navigation.direction(sim.player.position, destination, sim.config.body_radius)
	else:
		intent.pressed = Intent.Command.POWER
		_point += 1
	return intent


func _combat(sim: InfiltrationSimulation) -> void:
	_combat_ticks += 1
	intent.held = Intent.Command.BLOCK
	var victim: int = -1
	var nearest: float = INF
	for index in sim.targets.size():
		if sim.targets[index].health <= 0.0:
			continue
		var distance: float = sim.player.position.distance_to(sim.targets[index].position)
		if distance < nearest:
			nearest = distance
			victim = index
	if victim < 0:
		_combat_done = true
		return
	var target: InfiltrationActor = sim.targets[victim]
	intent.aim = (target.position - sim.player.position).normalized()
	if not sim.mission.alarm_raised and sim.map.enemies.size() > 2 and _combat_ticks < 2400:
		var runner: InfiltrationActor = sim.targets[1]
		intent.aim = (runner.position - sim.player.position).normalized()
		if sim.player.position.distance_to(runner.position) > 140.0:
			intent.movement = _navigation.direction(sim.player.position, runner.position, sim.config.body_radius)
		return
	if nearest > 65.0:
		intent.movement = _navigation.direction(sim.player.position, target.position, sim.config.body_radius)
	elif sim.player.swing_tick < 0:
		intent.pressed = Intent.Command.LIGHT
