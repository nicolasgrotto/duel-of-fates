class_name HeldState
extends StateLogic


func step(_sim: MatchSimulation, fighter: FighterState, _intent: Intent) -> void:
	fighter.vx = 0.0
	if fighter.held_by_choke:
		return
	fighter.held_ticks -= 1
	if fighter.held_ticks <= 0:
		finish_to_neutral(_sim, fighter)


func exit(_sim: MatchSimulation, fighter: FighterState) -> void:
	fighter.held_ticks = 0
	fighter.held_by_choke = false


func debug_lines(_sim: MatchSimulation, fighter: FighterState) -> PackedStringArray:
	return PackedStringArray(["held %d  choke %s" % [fighter.held_ticks, fighter.held_by_choke]])
