class_name BlasterOpsMissionController
extends BlasterOpsEnemyController


func produce_all(sim: InfiltrationSimulation) -> Array[InfiltrationIntent]:
	var commands: Array[InfiltrationIntent] = super.produce_all(sim)
	var progress: BlasterOpsMissionState = sim.mission as BlasterOpsMissionState
	if progress == null or progress.definition.phase_target < 0:
		return commands
	var index: int = progress.definition.phase_target
	var actor: InfiltrationActor = sim.targets[index]
	var phase: BlasterOpsPhaseData = progress.definition.phases[progress.phase_index]
	if actor.health > 0.0 and actor.visible_player and actor.position.distance_to(sim.player.position) <= phase.enemy.preferred_range:
		commands[index].movement = commands[index].aim.normalized().orthogonal() * phase.strafe
	return commands
