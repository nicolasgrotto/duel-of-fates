class_name InfiltrationEscortController
extends RefCounted

var _navigation: InfiltrationNavigation
var _intents: Array[InfiltrationIntent] = []
var _revision: int = -1


func _init(sim: InfiltrationSimulation) -> void:
	_navigation = InfiltrationNavigation.new(sim.map)
	for actor in sim.prisoners:
		_intents.append(InfiltrationIntent.new())


func produce_all(sim: InfiltrationSimulation) -> Array[InfiltrationIntent]:
	var operations: BlasterOpsSimulation = sim as BlasterOpsSimulation
	if operations != null and _revision != operations.cover_revision:
		_navigation.invalidate()
		_revision = operations.cover_revision
	var leader: Vector2 = sim.player.position
	for index in _intents.size():
		var intent: InfiltrationIntent = _intents[index]
		intent.clear()
		var actor: InfiltrationActor = sim.prisoners[index]
		if actor.health <= 0.0 or sim.mission.recruited[index] == 0 or sim.mission.extracted[index] != 0:
			continue
		if actor.position.distance_to(leader) > sim.config.escort_follow_distance:
			intent.movement = _navigation.direction(actor.position, leader, sim.config.body_radius)
		if sim.mission is BlasterOpsMissionState:
			var progress: BlasterOpsMissionState = sim.mission as BlasterOpsMissionState
			if index == progress.definition.protected_index:
				intent.movement = Vector2.ZERO
				if progress.definition.kind == BlasterOpsMissionData.Kind.ESCORT and actor.position.distance_to(sim.player.position) <= operations.operations.protected_follow_range and actor.position.distance_to(progress.data.extraction) > progress.data.extraction_radius * 0.5:
					intent.movement = _navigation.direction(actor.position, progress.data.extraction, actor.radius) * operations.operations.protected_speed / sim.config.escort_speed
				if progress.definition.kind == BlasterOpsMissionData.Kind.DEFENSE:
					continue
			var nearest: float = operations.operations.ally_fire_range
			for target in sim.targets:
				var distance: float = actor.position.distance_to(target.position)
				if target.health > 0.0 and distance < nearest and operations.wall_for(BlasterOpsFaction.Side.ALLIED, actor.position, target.position) == INF:
					nearest = distance
					intent.aim = target.position - actor.position
					intent.held = Intent.Command.LIGHT
		leader = actor.position
	return _intents
