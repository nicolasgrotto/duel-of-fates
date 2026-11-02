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
	return super.produce_all(sim)
