class_name BlasterOpsEnemyController
extends InfiltrationEnemyController

var _revision: int = -1


func _init(map: InfiltrationMapData, capacity: int) -> void:
	super(map, capacity)


func _target_barriers(sim: BlasterOpsSimulation, commands: Array[InfiltrationIntent]) -> void:
	var covers: Array[BlasterOpsCover] = sim.arena.covers
	var first: int = covers.size() - sim.operations.barrier_slots
	if first < 0 or sim.mission == null:
		return
	var any: bool = false
	for index in range(first, covers.size()):
		any = any or covers[index].health > 0.0
	if not any:
		return
	for index in range(sim.map.targets.size(), sim.targets.size()):
		var actor: InfiltrationActor = sim.targets[index]
		if actor.health <= 0.0 or actor.awareness != InfiltrationActor.Awareness.ALERTED or actor.visible_player or actor.target_prisoner >= 0:
			continue
		var nearest: int = -1
		var distance: float = sim.operations.barrier_aggro_range
		for cover in range(first, covers.size()):
			if covers[cover].health <= 0.0:
				continue
			var candidate: float = actor.position.distance_to(sim.cover_center(cover))
			if candidate < distance:
				distance = candidate
				nearest = cover
		if nearest < 0:
			continue
		var data: InfiltrationEnemyData = sim.target_data[index] as InfiltrationEnemyData
		var offset: Vector2 = sim.cover_center(nearest) - actor.position
		commands[index].cover_target = nearest
		commands[index].aim = offset
		commands[index].held |= Intent.Command.LIGHT
		if data.bolt == null:
			commands[index].movement = offset.normalized() if distance > data.melee_range else Vector2.ZERO


func produce_all(sim: InfiltrationSimulation) -> Array[InfiltrationIntent]:
	var operations: BlasterOpsSimulation = sim as BlasterOpsSimulation
	if _revision != operations.cover_revision:
		_navigation.invalidate()
		_revision = operations.cover_revision
	var commands: Array[InfiltrationIntent] = super.produce_all(sim)
	_target_barriers(operations, commands)
	for index in operations.aura_indices:
		var data: BlasterOpsEnemyData = sim.target_data[index] as BlasterOpsEnemyData
		var actor: InfiltrationActor = sim.targets[index]
		if data.flee_range > 0.0 and actor.health > 0.0 and actor.position.distance_to(sim.player.position) < data.flee_range:
			commands[index].movement = _navigation.direction(actor.position, actor.position + (actor.position - sim.player.position).normalized() * data.flee_range, actor.radius)
	return commands
