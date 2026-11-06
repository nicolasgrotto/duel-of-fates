class_name CommandMenu
extends VBoxContainer

const PALETTE: UiPalette = preload("res://ui/palette.tres")
const GAP: int = 8
const ORDER_KEYS: PackedStringArray = ["OPS_ORDER_FOLLOW", "OPS_ORDER_HOLD", "OPS_ORDER_GUARD"]
const ARROWS: PackedStringArray = ["↑", "←", "→"]

var _chips: Array[HudChip] = []


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override(&"separation", GAP)
	var top: CenterContainer = CenterContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top)
	var row: HBoxContainer = HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override(&"separation", GAP)
	add_child(row)
	for index in ORDER_KEYS.size():
		var chip: HudChip = HudChip.new()
		_chips.append(chip)
		if index == 0:
			top.add_child(chip)
		else:
			row.add_child(chip)
	visible = false


func show_orders(current: int, guard_available: bool) -> void:
	visible = true
	for index in _chips.size():
		_chips[index].show_text(TranslationServer.translate(ORDER_KEYS[index]), ARROWS[index])
		var tint: Color = PALETTE.text
		if index == current:
			tint = PALETTE.menu_blade_b
		elif index == BlasterOpsMissionState.AllyOrder.GUARD and not guard_available:
			tint = PALETTE.tactical_dim
		_chips[index].set_tint(tint)
