class_name ObjectiveCard
extends PanelContainer

enum Tone { NORMAL, AMBER, DANGER }

const PALETTE: UiPalette = preload("res://ui/palette.tres")
const CARD_WIDTH: float = 760.0
const PROGRESS_HEIGHT: float = 8.0
const ROW_GAP: int = 3
const FLASH_SECONDS: float = 1.4
const TONE_STYLES: Dictionary = {Tone.NORMAL: &"ObjectiveCardPanel", Tone.AMBER: &"ObjectiveCardAmber", Tone.DANGER: &"ObjectiveCardDanger"}

var _eyebrow: Label
var _timer: Label
var _objective: Label
var _progress: ProgressBar
var _detail: Label
var _flash_left: float = 0.0
var _tone: Tone = Tone.NORMAL


func _init() -> void:
	theme_type_variation = TONE_STYLES[Tone.NORMAL]
	custom_minimum_size.x = CARD_WIDTH
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override(&"separation", ROW_GAP)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)
	var top: HBoxContainer = HBoxContainer.new()
	column.add_child(top)
	_eyebrow = _make_label(&"TacticalGroupLabel")
	_eyebrow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_eyebrow)
	_timer = _make_label(&"TacticalNoteLabel")
	top.add_child(_timer)
	_objective = _make_label(&"ObjectiveTextLabel")
	_objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_objective)
	_progress = ProgressBar.new()
	_progress.theme_type_variation = &"TacticalProgress"
	_progress.custom_minimum_size.y = PROGRESS_HEIGHT
	_progress.show_percentage = false
	_progress.max_value = 1.0
	_progress.step = 0.0
	_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_progress)
	_detail = _make_label(&"TacticalNoteLabel")
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_detail)


func _make_label(variation: StringName) -> Label:
	var label: Label = Label.new()
	label.theme_type_variation = variation
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func show_objective(eyebrow: String, objective: String, ratio: float = -1.0, detail: String = "", timer: String = "", tone: Tone = Tone.NORMAL) -> void:
	if _flash_left > 0.0:
		return
	_set_text(_eyebrow, eyebrow.to_upper())
	_set_text(_timer, timer)
	_set_text(_objective, objective)
	_set_text(_detail, detail)
	_detail.visible = detail != ""
	_progress.visible = ratio >= 0.0
	if ratio >= 0.0:
		_progress.value = clampf(ratio, 0.0, 1.0)
	_apply_tone(tone)


func flash(text: String, reduced: bool = false) -> void:
	_flash_left = FLASH_SECONDS
	_set_text(_eyebrow, "")
	_set_text(_timer, "")
	_set_text(_objective, text)
	_detail.visible = false
	_progress.visible = false
	_apply_tone(Tone.AMBER)
	if reduced:
		return
	modulate = Color(PALETTE.text, 1.0).lightened(0.3)
	var tween: Tween = create_tween()
	tween.tween_property(self, ^"modulate", Color.WHITE, FLASH_SECONDS * 0.5)


func tick(delta: float) -> void:
	_flash_left = maxf(_flash_left - delta, 0.0)


func _apply_tone(tone: Tone) -> void:
	if tone == _tone:
		return
	_tone = tone
	theme_type_variation = TONE_STYLES[tone]
	var accent: Color = PALETTE.menu_blade_a
	if tone == Tone.AMBER:
		accent = PALETTE.menu_blade_b
	elif tone == Tone.DANGER:
		accent = PALETTE.danger
	_eyebrow.add_theme_color_override(&"font_color", accent)


func _set_text(label: Label, text: String) -> void:
	if label.text != text:
		label.text = text
