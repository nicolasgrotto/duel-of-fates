class_name HudChip
extends PanelContainer

const GAP: int = 10

var _keycap: Keycap
var _text: Label


func _init() -> void:
	theme_type_variation = &"TacticalHudChip"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override(&"separation", GAP)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	_keycap = Keycap.new()
	_keycap.visible = false
	row.add_child(_keycap)
	_text = Label.new()
	_text.theme_type_variation = &"TacticalValueLabel"
	_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_text)


func show_text(text: String, key: String = "") -> void:
	visible = text != ""
	if _text.text != text:
		_text.text = text
	_keycap.visible = key != ""
	_keycap.set_text(key)


func set_tint(color: Color) -> void:
	_text.add_theme_color_override(&"font_color", color)
