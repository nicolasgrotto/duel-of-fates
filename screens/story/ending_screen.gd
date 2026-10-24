extends Control

const PALETTE: UiPalette = preload("res://ui/palette.tres")
const LINE_DELAY: float = 1.6
const FADE_TIME: float = 0.8
const LINE_GAP: float = 28.0
const BAR_HEIGHT: float = 110.0

var ending: EndingData
var campaign: StoryCampaign
var gallery: bool = false

var _labels: Array[Label] = []
var _time: float = 0.0
var _hint: Label


func open(params: Dictionary) -> void:
	ending = params["ending"]
	campaign = params.get("campaign")
	gallery = params.get("gallery", false)
	_build()


func _build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var black: ColorRect = ColorRect.new()
	black.color = PALETTE.background
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(black)
	for top in [true, false]:
		var bar: ColorRect = ColorRect.new()
		bar.color = PALETTE.letterbox
		bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE if top else Control.PRESET_BOTTOM_WIDE)
		if top:
			bar.offset_bottom = BAR_HEIGHT
		else:
			bar.offset_top = -BAR_HEIGHT
		add_child(bar)
	var column: VBoxContainer = VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_CENTER)
	column.grow_horizontal = Control.GROW_DIRECTION_BOTH
	column.grow_vertical = Control.GROW_DIRECTION_BOTH
	column.add_theme_constant_override(&"separation", int(LINE_GAP))
	add_child(column)
	var title: Label = _line(tr(ending.title_key).to_upper(), &"TitleLabel")
	column.add_child(title)
	var player_name: String = campaign.name if campaign != null else tr("STORY_PROTAGONIST")
	for key in ending.lines:
		var label: Label = _line(tr(key).format({"name": player_name}), &"InfoLabel")
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size = Vector2(1100.0, 0.0)
		column.add_child(label)
	_hint = Label.new()
	_hint.theme_type_variation = &"HintLabel"
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_hint.offset_top = -BAR_HEIGHT * 0.5 - 15.0
	_hint.text = ControlHints.hint(&"ui_accept", "HINT_CONFIRM")
	add_child(_hint)


func _line(text: String, variation: StringName) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.theme_type_variation = variation
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.modulate.a = 0.0
	_labels.append(label)
	return label


func _process(delta: float) -> void:
	_time += delta
	for i in _labels.size():
		_labels[i].modulate.a = clampf((_time - i * LINE_DELAY) / FADE_TIME, 0.0, 1.0)
	if _hint != null:
		_hint.modulate.a = 1.0 if _time > _labels.size() * LINE_DELAY else 0.0


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_accept") or event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		if _time < _labels.size() * LINE_DELAY:
			_time = _labels.size() * LINE_DELAY
			return
		SceneRouter.change(&"story_gallery" if gallery else &"story_hub")
