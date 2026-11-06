class_name BlasterOpsEnemyController
extends InfiltrationEnemyController

var _revision: int = -1


func _init(map: InfiltrationMapData, capacity: int) -> void:
	super(map, capacity)


func produce_all(sim: InfiltrationSimulation) -> Array[InfiltrationIntent]:
	var operations: BlasterOpsSimulation = sim as BlasterOpsSimulation
	if _revision != operations.cover_revision:
		_navigation.invalidate()
		_revision = operations.cover_revision
	var commands: Array[InfiltrationIntent] = super.produce_all(sim)
	for index in operations.aura_indices:
		var data: BlasterOpsEnemyData = sim.target_data[index] as BlasterOpsEnemyData
		var actor: InfiltrationActor = sim.targets[index]
		if data.flee_range > 0.0 and actor.health > 0.0 and actor.position.distance_to(sim.player.position) < data.flee_range:
			commands[index].movement = _navigation.direction(actor.position, actor.position + (actor.position - sim.player.position).normalized() * data.flee_range, actor.radius)
	return commands
