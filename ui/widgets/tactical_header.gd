class_name TacticalHeader
extends HBoxContainer

const PALETTE: UiPalette = preload("res://ui/palette.tres")
const ACCENT_SIZE: Vector2 = Vector2(10.0, 36.0)
const ACCENT_GAP: int = 16
const HEIGHT: float = 60.0

var _accent: ColorRect
var _title: Label
var _side: Label


func _init(accent_color: Color = PALETTE.menu_blade_a) -> void:
	custom_minimum_size.y = HEIGHT
	add_theme_constant_override(&"separation", ACCENT_GAP)
	var box: CenterContainer = CenterContainer.new()
	_accent = ColorRect.new()
	_accent.custom_minimum_size = ACCENT_SIZE
	_accent.color = accent_color
	box.add_child(_accent)
	add_child(box)
	_title = Label.new()
	_title.theme_type_variation = &"TacticalTitleLabel"
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_title)
	_side = Label.new()
	_side.theme_type_variation = &"TacticalMutedLabel"
	_side.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_side)


func set_content(title: String, side: String = "") -> void:
	_title.text = title.to_upper()
	_side.text = side
