class_name ExhibitionCard
extends CanvasLayer

const LAYER: int = 6
const NAMES_GAP: float = 72.0
const FOOTER_MARGIN: float = 66.0

var _card: Control
var _title: Label
var _names: Label
var _footer: Label
var _tween: Tween


func _ready() -> void:
	layer = LAYER
	_card = Control.new()
	_card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.modulate.a = 0.0
	add_child(_card)
	_title = _centered_label(&"ScreenTitleLabel", _card)
	_names = _centered_label(&"InfoLabel", _card)
	_names.offset_top = NAMES_GAP
	_names.offset_bottom = NAMES_GAP
	_footer = Label.new()
	_footer.theme_type_variation = &"HintLabel"
	_footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_footer.offset_top = -FOOTER_MARGIN
	add_child(_footer)


func _centered_label(variation: StringName, parent: Control) -> Label:
	var label: Label = Label.new()
	label.theme_type_variation = variation
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	label.grow_vertical = Control.GROW_DIRECTION_BOTH
	parent.add_child(label)
	return label


func play(title: String, names: String, footer: String, fade: float, hold: float) -> void:
	_title.text = title
	_names.text = names
	_footer.text = footer
	if _tween != null:
		_tween.kill()
	_card.modulate.a = 0.0
	_tween = create_tween()
	_tween.tween_property(_card, "modulate:a", 1.0, fade)
	_tween.tween_interval(hold)
	_tween.tween_property(_card, "modulate:a", 0.0, fade)


func _exit_tree() -> void:
	if _tween != null:
		_tween.kill()
