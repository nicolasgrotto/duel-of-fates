class_name InfiltrationEscortController
extends RefCounted

var _navigation: InfiltrationNavigation
var _intents: Array[InfiltrationIntent] = []


func _init(sim: InfiltrationSimulation) -> void:
	_navigation = InfiltrationNavigation.new(sim.map)
	for actor in sim.prisoners:
		_intents.append(InfiltrationIntent.new())


func produce_all(sim: InfiltrationSimulation) -> Array[InfiltrationIntent]:
	var leader: Vector2 = sim.player.position
	for index in _intents.size():
		var intent: InfiltrationIntent = _intents[index]
		intent.clear()
		var actor: InfiltrationActor = sim.prisoners[index]
		if actor.health <= 0.0 or sim.mission.recruited[index] == 0 or sim.mission.extracted[index] != 0:
			continue
		if actor.position.distance_to(leader) > sim.config.escort_follow_distance:
			intent.movement = _navigation.direction(actor.position, leader, sim.config.body_radius)
		leader = actor.position
	return _intents
