class_name AbilityBar
extends HBoxContainer

const PALETTE: UiPalette = preload("res://ui/palette.tres")
const SLOT_SIZE: Vector2 = Vector2(84.0, 84.0)
const SLOT_GAP: int = 12
const ICON_INSET: float = 8.0
const BORDER_WIDTH: float = 2.0
const SUFFIXES: PackedStringArray = ["power", "power_2", "power_3"]

var _slots: Array[AbilitySlot] = []


class AbilitySlot:
	extends Control

	var icon: Texture2D
	var ratio: float = 0.0
	var active: bool = false
	var key_label: Label
	var time_label: Label

	func _draw() -> void:
		var area: Rect2 = Rect2(Vector2.ZERO, size)
		draw_rect(area, Color(PALETTE.background, 0.85))
		if icon != null:
			draw_texture_rect(icon, area.grow(-ICON_INSET), false, Color(1.0, 1.0, 1.0, 0.4 if ratio > 0.0 else 1.0))
		if ratio > 0.0:
			draw_rect(Rect2(0.0, size.y * (1.0 - ratio), size.x, size.y * ratio), Color(PALETTE.background, 0.6))
		var border: Color = PALETTE.text if active else PALETTE.accent if ratio <= 0.0 else PALETTE.secondary
		draw_rect(area, border, false, BORDER_WIDTH)


func setup(loadout: BlasterOpsLoadout, multiplier: float) -> void:
	add_theme_constant_override(&"separation", SLOT_GAP)
	for child in get_children():
		child.queue_free()
	_slots.clear()
	for index in loadout.slot_count():
		var slot: AbilitySlot = AbilitySlot.new()
		slot.custom_minimum_size = SLOT_SIZE
		slot.icon = loadout.slot(index).power.icon
		slot.set_meta(&"total", Ticks.from_seconds(loadout.slot(index).cooldown * multiplier))
		slot.key_label = _label(slot, ControlHints.blaster_ops_hud_key(SUFFIXES[index]), HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP)
		slot.time_label = _label(slot, "", HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER)
		add_child(slot)
		_slots.append(slot)


func show_state(state: BlasterOpsState) -> void:
	for index in _slots.size():
		var slot: AbilitySlot = _slots[index]
		var left: int = state.cooldown(index)
		var total: int = slot.get_meta(&"total")
		slot.ratio = clampf(float(left) / maxi(total, 1), 0.0, 1.0)
		slot.active = state.casting(index)
		slot.time_label.text = "" if left == 0 else str(ceili(left * Ticks.DELTA))
		slot.queue_redraw()


func _label(parent: Control, text: String, horizontal: HorizontalAlignment, vertical: VerticalAlignment) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.theme_type_variation = &"InfiltrationLabel"
	label.horizontal_alignment = horizontal
	label.vertical_alignment = vertical
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.offset_left = ICON_INSET * 0.5
	label.add_theme_color_override(&"font_outline_color", PALETTE.background)
	label.add_theme_constant_override(&"outline_size", 6)
	parent.add_child(label)
	return label
