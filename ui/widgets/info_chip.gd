class_name InfoChip
extends PanelContainer

const COLUMN_GAP: int = 0

var grows: bool = false:
	set(value):
		grows = value
		size_flags_horizontal = Control.SIZE_EXPAND_FILL if value else Control.SIZE_SHRINK_BEGIN
		_value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if value else TextServer.AUTOWRAP_OFF
var _caption: Label
var _value: Label


func _init(caption: String = "", value: String = "") -> void:
	theme_type_variation = &"TacticalChip"
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override(&"separation", COLUMN_GAP)
	add_child(column)
	_caption = Label.new()
	_caption.theme_type_variation = &"TacticalCaptionLabel"
	column.add_child(_caption)
	_value = Label.new()
	_value.theme_type_variation = &"TacticalValueLabel"
	column.add_child(_value)
	set_content(caption, value)


func set_content(caption: String, value: String) -> void:
	_caption.text = caption
	_value.text = value
