class_name KeyFooter
extends HBoxContainer

const GROUP_GAP: int = 36
const KEY_GAP: int = 8
const LABEL_GAP: int = 10
const SHORT_KEYS: Dictionary = {"Escape": "Esc"}


func _ready() -> void:
	add_theme_constant_override(&"separation", GROUP_GAP)


func set_hints(hints: Array[Dictionary]) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	for hint: Dictionary in hints:
		add_child(_group(hint.keys, hint.text))


func _group(keys: PackedStringArray, text: String) -> HBoxContainer:
	var group: HBoxContainer = HBoxContainer.new()
	group.add_theme_constant_override(&"separation", KEY_GAP)
	for key in keys:
		group.add_child(Keycap.new(SHORT_KEYS.get(key, key)))
	var spacer: Control = Control.new()
	spacer.custom_minimum_size.x = LABEL_GAP - KEY_GAP
	group.add_child(spacer)
	var label: Label = Label.new()
	label.theme_type_variation = &"TacticalMutedLabel"
	label.text = text
	group.add_child(label)
	return group
