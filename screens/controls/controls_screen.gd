extends Control

const TITLE_TOP: float = 90.0
const TABLE_TOP: float = 210.0
const COLUMN_GAP: int = 64
const ROW_GAP: int = 10
const FOOTER_MARGIN: float = 36.0
const PREFIX: String = "p1_"


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var title: Label = Label.new()
	title.theme_type_variation = &"ScreenTitleLabel"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = TITLE_TOP
	title.text = tr("CONTROLS_TITLE")
	add_child(title)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	center.offset_top = TABLE_TOP
	add_child(center)
	var table: GridContainer = GridContainer.new()
	table.columns = 2
	table.add_theme_constant_override(&"h_separation", COLUMN_GAP)
	table.add_theme_constant_override(&"v_separation", ROW_GAP)
	center.add_child(table)
	for row in _rows():
		table.add_child(_cell(row[0], &"MenuItemLabel", HORIZONTAL_ALIGNMENT_RIGHT))
		table.add_child(_cell(row[1], &"MenuItemSelectedLabel", HORIZONTAL_ALIGNMENT_LEFT))
	var footer: Label = Label.new()
	footer.theme_type_variation = &"HintLabel"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_top = -FOOTER_MARGIN - 30.0
	footer.offset_bottom = -FOOTER_MARGIN
	footer.text = ControlHints.hint(&"ui_cancel", "HINT_BACK")
	add_child(footer)


func _rows() -> Array:
	var block: String = _keys("block")
	var light: String = _keys("light_attack")
	var special: String = _keys("special")
	var power: String = _keys("power")
	return [
		[tr("CONTROL_MOVE"), "%s  %s" % [_keys("move_left"), _keys("move_right")]],
		[tr("CONTROL_JUMP"), _keys("jump")],
		[tr("ACTION_LIGHT_ATTACK"), light],
		[tr("ACTION_HEAVY_ATTACK"), _keys("heavy_attack")],
		[tr("CONTROL_GUARD"), block],
		[tr("CONTROL_PARRY"), tr("CONTROL_PARRY_KEYS").format({"block": block})],
		[tr("CONTROL_SHOVE"), "%s + %s" % [block, light]],
		[tr("CONTROL_DODGE"), _keys("dodge")],
		[tr("ACTION_EVADE"), _keys("evade")],
		[tr("ACTION_SPECIAL"), special],
		[tr("CONTROL_TECHNIQUES"), tr("CONTROL_DIRECTION_PLUS").format({"key": special})],
		[tr("CONTROL_POWER"), power],
		[tr("CONTROL_OTHER_POWERS"), tr("CONTROL_DIRECTION_PLUS").format({"key": power})],
		[tr("CONTROL_FOURTH_POWER"), "%s + %s" % [power, special]],
		[tr("ACTION_PAUSE"), _keys("pause")],
	]


func _keys(action: String) -> String:
	return " / ".join(ControlHints.key_names(StringName(PREFIX + action)))


func _cell(text: String, variation: StringName, alignment: HorizontalAlignment) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.theme_type_variation = variation
	label.horizontal_alignment = alignment
	return label


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"ui_accept"):
		get_viewport().set_input_as_handled()
		SceneRouter.change(&"menu", {"group": &"learn", "focus": &"controls"})
