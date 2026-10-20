class_name DeadState
extends StateLogic


func step(sim: MatchSimulation, fighter: FighterState, _intent: Intent) -> void:
	decelerate(sim, fighter)
