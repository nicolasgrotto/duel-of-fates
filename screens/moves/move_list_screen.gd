extends Control

const PALETTE: UiPalette = preload("res://ui/palette.tres")
const TITLE_TOP: float = 56.0
const TABLE_TOP: float = 130.0
const COLUMN_GAP: int = 56
const ROW_GAP: int = 4
const FOOTER_MARGIN: float = 28.0

var _character: CharacterData
var _powers: Array[PowerData] = []
var _prefix: String = "p1_"
var _show_powers: bool = true


func open(params: Dictionary) -> void:
	_character = params["character"]
	_powers.assign(params.get("powers", []))
	_prefix = InputBindings.player_prefix(params.get("slot", 0))
	_show_powers = params.get("show_powers", true)
	_build()


func _build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var backdrop: ColorRect = ColorRect.new()
	backdrop.color = PALETTE.background
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var title: Label = Label.new()
	title.theme_type_variation = &"ScreenTitleLabel"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = TITLE_TOP
	title.text = tr("MOVES_TITLE").format({"name": tr(_character.name_key)})
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
	for row in rows():
		table.add_child(_cell(row[0], &"InfoLabel", HORIZONTAL_ALIGNMENT_RIGHT))
		table.add_child(_cell(row[1], &"CaptionLabel", HORIZONTAL_ALIGNMENT_LEFT))
	var footer: Label = Label.new()
	footer.theme_type_variation = &"HintLabel"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_top = -FOOTER_MARGIN - 30.0
	footer.offset_bottom = -FOOTER_MARGIN
	footer.text = ControlHints.hint(&"ui_cancel", "HINT_BACK")
	add_child(footer)


func rows() -> Array:
	var light: String = _key("light_attack")
	var heavy: String = _key("heavy_attack")
	var block: String = _key("block")
	var special: String = _key("special")
	var power: String = _key("power")
	var chain: PackedStringArray = []
	for move in _character.light_chain:
		chain.append(light)
	var list: Array = [
		[tr("MOVES_LIGHT_CHAIN").format({"count": _character.light_chain.size()}), " ".join(chain)],
		[tr("ACTION_HEAVY_ATTACK"), heavy],
		[tr("MOVES_FORWARD_HEAVY"), _forward(heavy)],
		[tr("MOVES_AERIAL"), tr("MOVES_IN_AIR").format({"key": "%s / %s" % [light, heavy]})],
		[tr("CONTROL_GUARD"), block],
		[tr("CONTROL_PARRY"), tr("CONTROL_PARRY_KEYS").format({"block": block})],
		[tr("MOVES_COUNTER"), tr("MOVES_COUNTER_KEYS").format({"key": light})],
		[tr("CONTROL_SHOVE"), "%s + %s" % [block, light]],
		[tr("CONTROL_DODGE"), _key("dodge")],
		[tr("ACTION_EVADE"), _key("evade")],
		[tr("MOVES_LOCK"), tr("MOVES_LOCK_KEYS").format({"key": light})],
		[tr(_character.ability_key), special],
		[tr(_character.trait_key), tr("MOVES_PASSIVE")],
	]
	if not _show_powers:
		return list
	var techniques: Array = [[_character.technique_forward, _forward(special)], [_character.technique_back, _back(special)], [_character.technique_air, tr("MOVES_IN_AIR").format({"key": special})]]
	for entry in techniques:
		if entry[0] != null:
			list.append([tr(PowerCatalog.technique_key(entry[0])), entry[1]])
	var commands: Array[String] = [power, _forward(power), _back(power), "%s + %s" % [power, special]]
	for slot in mini(_powers.size(), commands.size()):
		var item: PowerData = _powers[slot]
		if item == null:
			continue
		var name: String = tr(item.name_key)
		if item.is_channeled():
			name = tr("MOVES_HELD").format({"name": name})
		list.append([name, commands[slot]])
	return list


func _key(action: String) -> String:
	return ControlHints.key_label(StringName(_prefix + action))


func _forward(key: String) -> String:
	return tr("MOVES_FORWARD_PLUS").format({"key": key})


func _back(key: String) -> String:
	return tr("MOVES_BACK_PLUS").format({"key": key})


func _cell(text: String, variation: StringName, alignment: HorizontalAlignment) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.theme_type_variation = variation
	label.horizontal_alignment = alignment
	return label


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"ui_accept") or event.is_action_pressed(&"p1_pause") or event.is_action_pressed(&"p2_pause"):
		get_viewport().set_input_as_handled()
		SceneRouter.pop()
