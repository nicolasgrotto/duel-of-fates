class_name FighterController
extends RefCounted


func produce(_sim: MatchSimulation, _fighter_index: int, intent: Intent) -> void:
	intent.clear()


func handle_input(_event: InputEvent) -> void:
	pass


func debug_lines() -> PackedStringArray:
	return PackedStringArray()
