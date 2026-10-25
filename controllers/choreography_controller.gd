class_name ChoreographyController
extends FighterController

var bout: ExhibitionBout
var fighter_index: int = 0
var _start_tick: int = -1


func _init(exhibition_bout: ExhibitionBout, index: int) -> void:
	bout = exhibition_bout
	fighter_index = index


func produce(sim: MatchSimulation, index: int, intent: Intent) -> void:
	intent.clear()
	if sim.phase != MatchSimulation.Phase.FIGHT:
		return
	if _start_tick < 0:
		_start_tick = sim.tick
	var elapsed: int = sim.tick - _start_tick
	var facing: int = sim.fighters[index].facing
	for cue in bout.cues:
		if cue.fighter != fighter_index or elapsed < cue.at or elapsed >= cue.at + maxi(cue.hold, 1):
			continue
		if elapsed == cue.at:
			intent.pressed |= cue.command
		intent.held |= cue.command
		if cue.move != 0:
			intent.move_x = cue.move * facing


func elapsed_ticks(sim: MatchSimulation) -> int:
	return sim.tick - _start_tick if _start_tick >= 0 else -1


func debug_lines() -> PackedStringArray:
	return PackedStringArray(["choreography %s" % bout.id])
