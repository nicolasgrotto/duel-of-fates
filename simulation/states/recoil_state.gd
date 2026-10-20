class_name RecoilState
extends StateLogic


func step(sim: MatchSimulation, fighter: FighterState, _intent: Intent) -> void:
	decelerate(sim, fighter)
	fighter.stun_ticks -= 1
	if fighter.stun_ticks <= 0:
		finish_to_neutral(sim, fighter)


func exit(_sim: MatchSimulation, fighter: FighterState) -> void:
	fighter.stun_ticks = 0
	fighter.stagger_counterable = false
	fighter.combo_taken = 0


func debug_lines(_sim: MatchSimulation, fighter: FighterState) -> PackedStringArray:
	return PackedStringArray(["stun %d  counterable %s" % [fighter.stun_ticks, fighter.stagger_counterable]])
