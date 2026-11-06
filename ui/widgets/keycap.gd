class_name Keycap
extends PanelContainer

const MINIMUM_SIZE: Vector2 = Vector2(42.0, 38.0)

var _label: Label


func _init(text: String = "") -> void:
	theme_type_variation = &"KeycapPanel"
	custom_minimum_size = MINIMUM_SIZE
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_label = Label.new()
	_label.theme_type_variation = &"KeycapLabel"
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.text = text
	add_child(_label)


func set_text(text: String) -> void:
	_label.text = text
