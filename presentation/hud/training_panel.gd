class_name TrainingPanel
extends CanvasLayer

const BOTTOM_MARGIN: float = 64.0
const FRAME_EVENTS: Array[CombatEvent.Type] = [
	CombatEvent.Type.HIT,
	CombatEvent.Type.BLOCK,
	CombatEvent.Type.PARRY,
	CombatEvent.Type.PERFECT_PARRY,
	CombatEvent.Type.GUARD_BREAK,
	CombatEvent.Type.SHOVE,
	CombatEvent.Type.EVADE_SUCCESS,
]
const BEHAVIOR_KEYS: Dictionary = {
	DummyController.Behavior.STAND: "DUMMY_STAND",
	DummyController.Behavior.GUARD: "DUMMY_GUARD",
	DummyController.Behavior.ATTACK: "DUMMY_ATTACK",
	DummyController.Behavior.PLAYBACK: "DUMMY_PLAYBACK",
}

var runner: TickRunner
var dummy: DummyController
var config: TrainingConfig
var player_index: int = 0

var _label: Label
var _recording: bool = false
var _frame_text: String = ""


func setup(tick_runner: TickRunner, dummy_controller: DummyController, training_config: TrainingConfig) -> void:
	layer = 11
	runner = tick_runner
	dummy = dummy_controller
	config = training_config
	_label = Label.new()
	_label.theme_type_variation = &"HintLabel"
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_label.offset_bottom = -BOTTOM_MARGIN
	add_child(_label)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"training_dummy_behavior"):
		_cycle_behavior()
	elif event.is_action_pressed(&"training_record"):
		_toggle_recording()
	elif event.is_action_pressed(&"training_playback"):
		var playing: bool = dummy.behavior == DummyController.Behavior.PLAYBACK
		dummy.set_behavior(DummyController.Behavior.STAND if playing or dummy.playback.length() == 0 else DummyController.Behavior.PLAYBACK)
	else:
		return
	get_viewport().set_input_as_handled()


func _cycle_behavior() -> void:
	var next: int = (dummy.behavior + 1) % DummyController.Behavior.size()
	if next == DummyController.Behavior.PLAYBACK and dummy.playback.length() == 0:
		next = DummyController.Behavior.STAND
	dummy.set_behavior(next as DummyController.Behavior)


func _toggle_recording() -> void:
	_recording = not _recording
	if _recording:
		dummy.set_behavior(DummyController.Behavior.STAND)
		dummy.playback.clear()


func on_ticked() -> void:
	if _recording:
		var player: FighterState = runner.sim.fighters[player_index]
		dummy.playback.append_relative(runner.intents[player_index], player.facing)
		if dummy.playback.length() >= Ticks.from_seconds(config.max_recording):
			_recording = false
	_refresh()


func on_event(event: CombatEvent) -> void:
	if event.source != player_index or not FRAME_EVENTS.has(event.type) or event.move == null:
		return
	var move_name: String = tr("MOVE_KIND_" + MoveData.Kind.find_key(event.move.kind))
	var result: String = tr("FRAME_" + CombatEvent.Type.find_key(event.type))
	_frame_text = tr("TRAINING_FRAME_DATA").format({
		"move": move_name, "result": result, "advantage": _signed_seconds(event.frame_advantage),
	})


func _refresh() -> void:
	var lines: PackedStringArray = [
		tr("TRAINING_PLAYER").format({"commands": _commands(runner.intents[player_index])}) + ControlHints.SEPARATOR
		+ tr("TRAINING_DUMMY_COMMANDS").format({"commands": _commands(runner.intents[1 - player_index])}),
		_frame_text,
		tr("TRAINING_DUMMY").format({"behavior": tr(BEHAVIOR_KEYS[dummy.behavior])}) + ControlHints.SEPARATOR + _recording_text(),
		ControlHints.line(PackedStringArray([
			ControlHints.hint(&"training_dummy_behavior", "HINT_DUMMY"),
			ControlHints.hint(&"training_record", "HINT_RECORD"),
			ControlHints.hint(&"training_playback", "HINT_PLAYBACK"),
			ControlHints.hint(&"debug_overlay", "HINT_BOXES"),
		])),
	]
	_label.text = "\n".join(lines)


func _recording_text() -> String:
	var seconds: String = "%.1f" % Ticks.to_seconds(dummy.playback.length())
	if _recording:
		return tr("TRAINING_RECORDING").format({"seconds": seconds})
	if dummy.playback.length() > 0:
		return tr("TRAINING_RECORDED").format({"seconds": seconds})
	return tr("TRAINING_NO_RECORDING")


func _commands(intent: Intent) -> String:
	var parts: PackedStringArray = []
	if intent.move_x < 0:
		parts.append("←")
	elif intent.move_x > 0:
		parts.append("→")
	for command in PlayerController.COMMAND_ACTIONS:
		if intent.is_held(command):
			parts.append(ControlHints.key_label(StringName(InputBindings.player_prefix(player_index) + PlayerController.COMMAND_ACTIONS[command])))
	return " ".join(parts) if not parts.is_empty() else "·"


func _signed_seconds(ticks: int) -> String:
	var text: String = "%.2f" % absf(Ticks.to_seconds(ticks))
	if TranslationServer.get_locale().begins_with("pt"):
		text = text.replace(".", ",")
	return ("−" if ticks < 0 else "+") + text
