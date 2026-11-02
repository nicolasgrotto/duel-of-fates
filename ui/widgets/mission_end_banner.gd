class_name MissionEndBanner
extends CanvasLayer

signal closed

const PALETTE: UiPalette = preload("res://ui/palette.tres")
const LAYER: int = 20
const HOLD_SECONDS: float = 2.5
const FADE_SECONDS: float = 0.35
const SKIP_AFTER_SECONDS: float = 0.4
const DIM_ALPHA: float = 0.72
const TITLE_OFFSET: float = -70.0
const RULE_OFFSET: float = -8.0
const RULE_WIDTH: float = 560.0
const RULE_HEIGHT: float = 2.0
const DETAIL_OFFSET: float = 8.0

var _dim: ColorRect
var _title: Label
var _rule: ColorRect
var _detail: Label
var _elapsed: float = 0.0
var _presented: bool = false
var _closed: bool = false


func _init() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_dim = ColorRect.new()
	_dim.color = Color(PALETTE.background, 0.0)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dim)
	_title = _label(&"ScreenTitleLabel", TITLE_OFFSET)
	_detail = _label(&"HuntBodyLabel", DETAIL_OFFSET)
	_rule = ColorRect.new()
	_rule.set_anchors_preset(Control.PRESET_CENTER)
	_rule.offset_top = RULE_OFFSET
	_rule.offset_bottom = RULE_OFFSET + RULE_HEIGHT
	_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rule)


func present(won: bool, detail: String) -> void:
	_presented = true
	_title.text = TranslationServer.translate("MISSION_END_SUCCESS" if won else "MISSION_END_FAILURE").to_upper()
	_title.modulate = PALETTE.text
	_detail.text = detail
	_rule.color = PALETTE.accent if won else PALETTE.danger
	_apply_progress(0.0)


func title_text() -> String:
	return _title.text


func close() -> void:
	if _closed:
		return
	_closed = true
	closed.emit()


func _process(delta: float) -> void:
	if not _presented or _closed:
		return
	_elapsed += delta
	_apply_progress(minf(_elapsed / FADE_SECONDS, 1.0))
	if _elapsed >= HOLD_SECONDS:
		close()


func _unhandled_input(event: InputEvent) -> void:
	if not _presented or _elapsed < SKIP_AFTER_SECONDS:
		return
	var clicked: bool = event is InputEventMouseButton and event.pressed
	if clicked or event.is_action_pressed(&"ui_accept"):
		get_viewport().set_input_as_handled()
		close()


func _apply_progress(progress: float) -> void:
	_dim.color.a = DIM_ALPHA * progress
	_title.modulate.a = progress
	_detail.modulate.a = progress
	var half: float = RULE_WIDTH * 0.5 * progress
	_rule.offset_left = -half
	_rule.offset_right = half


func _label(variation: StringName, offset: float) -> Label:
	var label: Label = Label.new()
	label.theme_type_variation = variation
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	label.anchor_right = 1.0
	label.anchor_top = 0.5
	label.anchor_bottom = 0.5
	label.offset_top = offset
	label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	add_child(label)
	return label
