class_name ReplayController
extends FighterController

var _recording: IntentRecording
var _slot: int
var cursor: int = 0


func _init(recording: IntentRecording, slot: int, start_tick: int = 0) -> void:
	_recording = recording
	_slot = slot
	cursor = start_tick


func produce(_sim: MatchSimulation, _fighter_index: int, intent: Intent) -> void:
	if cursor < _recording.length():
		intent.unpack(_recording.packed_at(cursor, _slot))
	else:
		intent.clear()
	cursor += 1


func finished() -> bool:
	return cursor >= _recording.length()
