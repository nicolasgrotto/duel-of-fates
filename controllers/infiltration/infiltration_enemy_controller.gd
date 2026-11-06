class_name InfiltrationEnemyController
extends RefCounted

var intents: Array[InfiltrationIntent] = []
var _navigation: InfiltrationNavigation


func _init(map: InfiltrationMapData, capacity: int) -> void:
	_navigation = InfiltrationNavigation.new(map)
	for index in capacity:
		intents.append(InfiltrationIntent.new())


func produce_all(sim: InfiltrationSimulation) -> Array[InfiltrationIntent]:
	for index in range(sim.map.targets.size(), sim.targets.size()):
		produce(sim, index, intents[index])
	return intents


func produce(sim: InfiltrationSimulation, index: int, intent: InfiltrationIntent) -> void:
	intent.clear()
	var actor: InfiltrationActor = sim.targets[index]
	var data: InfiltrationEnemyData = sim.target_data[index] as InfiltrationEnemyData
	if actor.health <= 0.0:
		return
	if actor.awareness == InfiltrationActor.Awareness.ALERTED:
		var panel: int = sim.available_panel(actor.position)
		if panel >= 0 and data.speed > 0.0 and data.can_raise_alarm:
			intent.panel = panel
			intent.held = Intent.Command.DODGE
			_move(sim, actor, sim.map.panels[panel].position, intent, sim.config.panel_activation_range)
			intent.aim = intent.movement
			return
		intent.aim = actor.last_known - actor.position
		var has_target: bool = actor.visible_player or actor.target_prisoner >= 0
		if has_target:
			intent.held = Intent.Command.LIGHT
		if data.speed > 0.0 and (not has_target or actor.position.distance_to(actor.last_known) > data.preferred_range):
			_move(sim, actor, actor.last_known, intent, sim.config.waypoint_radius)
		return
	if actor.awareness == InfiltrationActor.Awareness.SUSPICIOUS:
		intent.aim = actor.last_known - actor.position
		if data.speed > 0.0:
			_move(sim, actor, actor.last_known, intent, sim.config.waypoint_radius)
		return
	var placement: InfiltrationEnemyPlacement = sim.enemy_placement(index)
	if data.archetype == InfiltrationEnemyData.Archetype.SENTRY or data.archetype == InfiltrationEnemyData.Archetype.MARKSMAN:
		intent.aim = placement.direction.rotated(deg_to_rad(data.rotation_degrees) * (sim.tick + 1) * Ticks.DELTA)
	elif not placement.route.is_empty():
		_move(sim, actor, placement.route[actor.waypoint], intent, sim.config.waypoint_radius)
		intent.aim = intent.movement


func _move(sim: InfiltrationSimulation, actor: InfiltrationActor, destination: Vector2, intent: InfiltrationIntent, stop: float) -> void:
	if actor.position.distance_to(destination) > stop:
		intent.movement = _navigation.direction(actor.position, destination, actor.radius, sim.alerted_bodies > sim.config.sight_stagger_above)
