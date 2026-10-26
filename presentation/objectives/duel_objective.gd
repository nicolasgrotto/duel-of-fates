class_name DuelObjective
extends RefCounted

signal finished
signal announced(text_key: String)

var done: bool = false


func on_tick(_sim: MatchSimulation) -> void:
	pass


func on_event(_event: CombatEvent, _sim: MatchSimulation) -> void:
	pass


func instruction() -> String:
	return ""


func progress_line() -> String:
	return ""


func result_title() -> String:
	return ""


func result_note() -> String:
	return ""


func debug_lines() -> PackedStringArray:
	return PackedStringArray()


func _finish() -> void:
	if done:
		return
	done = true
	finished.emit()


static func format_keys(text: String) -> String:
	var keys: Dictionary = {}
	for action in InputBindings.COMBAT_KEYS:
		keys[action] = ControlHints.key_label(StringName(InputBindings.player_prefix(0) + action))
	return text.format(keys)
