class_name StateLogic
extends RefCounted


func enter(_sim: MatchSimulation, _fighter: FighterState) -> void:
	pass


func step(_sim: MatchSimulation, _fighter: FighterState, _intent: Intent) -> void:
	pass


func exit(_sim: MatchSimulation, _fighter: FighterState) -> void:
	pass


func debug_lines(_sim: MatchSimulation, fighter: FighterState) -> PackedStringArray:
	return PackedStringArray(["ticks %d" % fighter.state_ticks])


static func decelerate(sim: MatchSimulation, fighter: FighterState) -> void:
	if fighter.on_ground:
		fighter.vx = move_toward(fighter.vx, 0.0, sim.config.ground_deceleration * Ticks.DELTA)


static func finish_to_neutral(sim: MatchSimulation, fighter: FighterState) -> void:
	var next_state: FighterState.State = FighterState.State.IDLE if fighter.on_ground else FighterState.State.JUMPING
	sim.change_state(fighter, next_state)
