extends Control

const PALETTE: UiPalette = preload("res://ui/palette.tres")
const CATALOG: PowerCatalog = preload("res://data/powers/catalog.tres")
const POWER_LINE_KEYS: Array[String] = ["SELECT_POWER_NEUTRAL", "SELECT_POWER_FORWARD", "SELECT_POWER_BACK", "SELECT_POWER_FOURTH"]
const TECHNIQUE_LINE_KEYS: Array[String] = ["SELECT_TECHNIQUE_FORWARD", "SELECT_TECHNIQUE_BACK", "SELECT_TECHNIQUE_AIR"]
const EDIT_RESET: StringName = &"reset"
const EDIT_DONE: StringName = &"done"
const CHARACTER_PATH: String = "res://data/characters/%s/%s.tres"
const ROSTER: Array[StringName] = [
	&"guardian", &"shadow", &"bastion", &"wasp", &"mirror", &"lance", &"ember", &"forge", &"heron", &"reaper", &"echo",
	&"sovereign", &"elder", &"foretold",
]
const RANDOM: StringName = &"random"
const STEP_TITLES: Dictionary = {
	&"player": "SELECT_PLAYER", &"opponent": "SELECT_OPPONENT", &"dummy": "SELECT_DUMMY", &"arena": "SELECT_ARENA",
}
const LEFT: float = 120.0
const CENTER: float = 620.0
const RIGHT: float = 1400.0
const TOP: float = 190.0
const PREVIEW_SCALE: float = 1.0
const TITLE_TOP: float = 70.0
const FOOTER_HEIGHT: float = 30.0
const PREVIEW_FLOOR: float = 760.0
const INFO_WIDTH: float = 640.0
const FOOTER_MARGIN: float = 36.0

var mode: DuelMode
var _characters: Dictionary = {}
var _step_index: int = 0
var _costume_index: int = 0
var _blade_index: int = 0
var _use_variant: bool = false
var _custom: Array[PowerData] = []
var _editing: bool = false

var _title: Label
var _list: MenuList
var _name: Label
var _info: VBoxContainer
var _style: Label
var _path: Label
var _trait: Label
var _ability: Label
var _powers_title: Label
var _power_lines: Array[Label] = []
var _technique_lines: Array[Label] = []
var _set_label: Label
var _editor: MenuList
var _bars: AttributeBars
var _preview: FighterPreview
var _look: Label
var _blade: Label
var _variant: Label
var _requirement: Label
var _footer: Label


func open(params: Dictionary) -> void:
	mode = params["mode"]
	for id in ROSTER:
		_characters[id] = load(CHARACTER_PATH % [id, id])
	_build()
	_show_step()


func _build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_title = _label(&"ScreenTitleLabel", Vector2.ZERO)
	_title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.offset_top = TITLE_TOP
	_list = MenuList.new()
	_list.position = Vector2(LEFT, TOP)
	add_child(_list)
	_list.chosen.connect(_on_chosen)
	_list.adjusted.connect(_on_adjusted)
	_list.highlighted.connect(_on_highlighted)
	_name = _label(&"FighterNameLabel", Vector2(CENTER, TOP - 20.0))
	_info = VBoxContainer.new()
	_info.position = Vector2(CENTER, TOP + 70.0)
	_info.custom_minimum_size = Vector2(INFO_WIDTH, 0.0)
	_info.add_theme_constant_override(&"separation", 10)
	add_child(_info)
	_style = _info_line()
	_path = _info_line()
	_trait = _info_line()
	_ability = _info_line()
	_powers_title = _info_line()
	_powers_title.theme_type_variation = &"CaptionLabel"
	for i in POWER_LINE_KEYS.size():
		_power_lines.append(_info_line())
	for i in TECHNIQUE_LINE_KEYS.size():
		_technique_lines.append(_info_line())
	_set_label = _info_line()
	_set_label.theme_type_variation = &"CaptionLabel"
	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 12.0)
	_info.add_child(spacer)
	_bars = AttributeBars.new()
	_info.add_child(_bars)
	_editor = MenuList.new()
	_editor.position = Vector2(CENTER, TOP + 70.0)
	_editor.visible = false
	add_child(_editor)
	_editor.adjusted.connect(_on_power_adjusted)
	_editor.chosen.connect(_on_power_chosen)
	_preview = FighterPreview.new()
	_preview.position = Vector2(RIGHT, PREVIEW_FLOOR)
	_preview.scale = Vector2.ONE * PREVIEW_SCALE
	add_child(_preview)
	_look = _label(&"InfoLabel", Vector2(RIGHT - 200.0, PREVIEW_FLOOR + 40.0))
	_blade = _label(&"InfoLabel", Vector2(RIGHT - 200.0, PREVIEW_FLOOR + 76.0))
	_variant = _label(&"InfoLabel", Vector2(RIGHT - 200.0, PREVIEW_FLOOR + 112.0))
	_requirement = _label(&"CaptionLabel", Vector2(RIGHT - 200.0, PREVIEW_FLOOR + 152.0))
	_footer = _label(&"HintLabel", Vector2.ZERO)
	_footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_footer.offset_top = -FOOTER_MARGIN - FOOTER_HEIGHT
	_footer.offset_bottom = -FOOTER_MARGIN


func _label(variation: StringName, at: Vector2) -> Label:
	var label: Label = Label.new()
	label.theme_type_variation = variation
	label.position = at
	add_child(label)
	return label


func _info_line() -> Label:
	var label: Label = Label.new()
	label.theme_type_variation = &"InfoLabel"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(INFO_WIDTH, 0.0)
	_info.add_child(label)
	return label


func _step() -> StringName:
	return mode.steps()[_step_index]


func _slot() -> int:
	return 0 if _step() == &"player" else 1


func _show_step() -> void:
	_title.text = tr(STEP_TITLES[_step()])
	_list.clear_items()
	if _step() == &"arena":
		_show_arena_step()
		return
	_list.add_item(RANDOM, tr("SELECT_RANDOM"))
	for id in ROSTER:
		_list.add_item(id, tr(_characters[id].name_key))
	var previous: CharacterData = mode.selection.characters[_slot()]
	_list.select_id(previous.id if previous != null else ROSTER[0])
	_show_character_hints()


func _show_character_hints() -> void:
	_footer.text = ControlHints.line(PackedStringArray([
		"↑ ↓  " + tr("HINT_CHANGE"), "← →  " + tr("HINT_BLADE"),
		ControlHints.hint(&"menu_costume", "HINT_LOOK"), ControlHints.hint(&"menu_variant", "HINT_VARIANT"),
		ControlHints.hint(&"menu_powers", "HINT_POWERS"),
		ControlHints.hint(&"ui_accept", "HINT_CONFIRM"), ControlHints.hint(&"ui_cancel", "HINT_BACK"),
	]))


func _show_arena_step() -> void:
	_list.add_item(RANDOM, tr("SELECT_RANDOM_ARENA"))
	for arena in DuelMode.ARENAS:
		_list.add_item(arena.id, tr(arena.name_key))
	_list.select_id(DuelMode.ARENAS[0].id)
	_preview.show_fighter(null, null, Color.WHITE)
	for label in [_look, _blade, _variant, _requirement]:
		label.text = ""
	_bars.visible = false
	_footer.text = ControlHints.line(PackedStringArray([
		"↑ ↓  " + tr("HINT_CHANGE"), ControlHints.hint(&"ui_accept", "HINT_CONFIRM"), ControlHints.hint(&"ui_cancel", "HINT_BACK"),
	]))


func _on_highlighted(id: StringName) -> void:
	if _step() == &"arena":
		var arena: ArenaData = _arena(id)
		_name.text = tr(arena.name_key) if arena != null else tr("SELECT_RANDOM_ARENA")
		_style.text = tr(arena.phrase_key) if arena != null else tr("ARENA_PHRASE_RANDOM")
		for label in [_path, _trait, _ability]:
			label.text = ""
		_clear_power_lines()
		return
	_costume_index = 0
	_blade_index = 0
	_use_variant = false
	_custom.clear()
	_refresh_character()


func _current_character() -> CharacterData:
	var id: StringName = _list.current_id()
	if id == RANDOM or not _characters.has(id):
		return null
	var data: CharacterData = _characters[id]
	if _use_variant and data.variant != null:
		return data.variant
	return data


func _refresh_character() -> void:
	var data: CharacterData = _current_character()
	_bars.visible = data != null
	if data == null:
		_name.text = tr("SELECT_RANDOM")
		for label in [_style, _path, _trait, _ability, _look, _blade, _variant, _requirement]:
			label.text = ""
		_clear_power_lines()
		_preview.show_fighter(null, null, Color.WHITE)
		return
	var base: CharacterData = _characters[_list.current_id()]
	var costumes: Array[CostumeData] = base.costumes if not base.costumes.is_empty() else data.costumes
	var costume: CostumeData = costumes[_costume_index % costumes.size()]
	var blade_color: Color = data.blade_colors[_blade_index % data.blade_colors.size()]
	_name.text = tr(data.name_key)
	_style.text = "%s · %s" % [tr("SELECT_STYLE"), tr(data.style_key)]
	var path_key: String = "PATH_ECLIPSE" if data.path == CharacterData.Path.ECLIPSE else "PATH_AURORA"
	_path.text = "%s · %s" % [tr("SELECT_PATH"), tr(path_key)]
	_path.add_theme_color_override(&"font_color", PALETTE.eclipse if data.path == CharacterData.Path.ECLIPSE else PALETTE.aurora)
	_trait.text = "%s · %s" % [tr("SELECT_TRAIT"), tr(data.trait_key)]
	_ability.text = "%s · %s" % [tr("SELECT_ABILITY"), tr(data.ability_key)]
	_show_powers(data)
	_bars.show_character(data)
	_preview.show_fighter(data, costume, blade_color)
	_look.text = tr("SELECT_LOOK").format({"name": tr(costume.name_key), "index": _costume_index % costumes.size() + 1, "count": costumes.size()})
	var blade_key: String = data.blade_color_keys[_blade_index % data.blade_colors.size()]
	_blade.text = tr("SELECT_BLADE").format({"name": tr(blade_key), "index": _blade_index % data.blade_colors.size() + 1, "count": data.blade_colors.size()})
	_variant.text = tr("SELECT_VARIANT").format({"name": tr("VARIANT_ECLIPSE" if _use_variant else "VARIANT_AURORA")}) if base.variant != null else ""
	_requirement.text = tr("SELECT_REQUIREMENT").format({"requirement": tr(costume.requirement_key)}) if costume.requirement_key != "" else ""


func _clear_power_lines() -> void:
	_powers_title.text = ""
	_set_label.text = ""
	for label in _power_lines + _technique_lines:
		label.text = ""


func _show_powers(data: CharacterData) -> void:
	_powers_title.text = tr("SELECT_POWERS")
	var equipped: Array[PowerData] = _custom.duplicate() if not _custom.is_empty() else CATALOG.base_set(data)
	equipped.append(data.fourth_power)
	for slot in _power_lines.size():
		var power: PowerData = equipped[slot]
		_power_lines[slot].text = tr(POWER_LINE_KEYS[slot]).format({"name": tr(power.name_key)}) if power != null else ""
	var techniques: Array[MoveData] = [data.technique_forward, data.technique_back, data.technique_air]
	for i in techniques.size():
		var technique: MoveData = techniques[i]
		_technique_lines[i].text = tr(TECHNIQUE_LINE_KEYS[i]).format({"name": tr(PowerCatalog.technique_key(technique))}) if technique != null else ""
	_set_label.text = tr("SELECT_SET_CUSTOM" if not _custom.is_empty() else "SELECT_SET_BASE")
	for label in _power_lines + _technique_lines:
		label.visible = label.text != ""


func _open_editor() -> void:
	if _custom.is_empty():
		_custom = CATALOG.base_set(_current_character())
	_editing = true
	_info.visible = false
	_editor.visible = true
	_list.set_process_unhandled_input(false)
	_editor.clear_items()
	for slot in PowerCatalog.SET_SIZE:
		_editor.add_item(StringName(str(slot)), "")
	_editor.add_item(EDIT_RESET, tr("SELECT_EDIT_RESET"))
	_editor.add_item(EDIT_DONE, tr("SELECT_EDIT_DONE"))
	_refresh_editor()
	_footer.text = ControlHints.line(PackedStringArray([
		"↑ ↓  " + tr("HINT_CHANGE"), "← →  " + tr("HINT_EDIT_POWER"), ControlHints.hint(&"ui_cancel", "HINT_BACK"),
	]))


func _close_editor() -> void:
	_editing = false
	_info.visible = true
	_editor.visible = false
	_list.set_process_unhandled_input(true)
	if _custom == CATALOG.base_set(_current_character()):
		_custom.clear()
	_show_character_hints()
	_refresh_character()


func _refresh_editor() -> void:
	for slot in PowerCatalog.SET_SIZE:
		var power: PowerData = _custom[slot]
		var power_name: String = "‹ %s ›" % (tr(power.name_key) if power != null else "—")
		_editor.set_item_text(StringName(str(slot)), tr(POWER_LINE_KEYS[slot]).format({"name": power_name}))


func _on_power_adjusted(id: StringName, step: int) -> void:
	if id == EDIT_RESET or id == EDIT_DONE:
		return
	CATALOG.cycle(_custom, int(String(id)), step, _current_character())
	_refresh_editor()


func _on_power_chosen(id: StringName) -> void:
	if id == EDIT_RESET:
		_custom = CATALOG.base_set(_current_character())
		_refresh_editor()
		return
	_close_editor()


func _on_adjusted(_id: StringName, step: int) -> void:
	if _step() == &"arena" or _current_character() == null:
		return
	_blade_index = posmod(_blade_index + step, _current_character().blade_colors.size())
	_refresh_character()


func _unhandled_input(event: InputEvent) -> void:
	if _editing:
		if event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"menu_powers"):
			get_viewport().set_input_as_handled()
			AudioDirector.play_ui(&"ui_back")
			_close_editor()
		return
	if _step() != &"arena" and event.is_action_pressed(&"menu_powers") and _current_character() != null:
		get_viewport().set_input_as_handled()
		AudioDirector.play_ui(&"ui_confirm")
		_open_editor()
	elif event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		AudioDirector.play_ui(&"ui_back")
		_go_back()
	elif _step() != &"arena" and event.is_action_pressed(&"menu_costume") and _current_character() != null:
		_costume_index += 1
		AudioDirector.play_ui(&"ui_move")
		_refresh_character()
	elif _step() != &"arena" and event.is_action_pressed(&"menu_variant") and _current_character() != null:
		if _characters[_list.current_id()].variant != null:
			_use_variant = not _use_variant
			_blade_index = 0
			_custom.clear()
			AudioDirector.play_ui(&"ui_move")
			_refresh_character()


func _go_back() -> void:
	if _step_index == 0:
		SceneRouter.change(&"menu")
		return
	_step_index -= 1
	_show_step()


func _on_chosen(id: StringName) -> void:
	if _step() == &"arena":
		mode.selection.arena = _arena(id) if id != RANDOM else DuelMode.ARENAS[randi() % DuelMode.ARENAS.size()]
	else:
		_store_character(id)
	if _step_index + 1 >= mode.steps().size():
		mode.start()
		return
	_step_index += 1
	_show_step()


func _store_character(id: StringName) -> void:
	var slot: int = _slot()
	var data: CharacterData = _current_character()
	var costume_source: CharacterData = _characters[id] if id != RANDOM else null
	if data == null:
		var picked: StringName = ROSTER[randi() % ROSTER.size()]
		data = _characters[picked]
		costume_source = data
		_costume_index = 0
		_blade_index = 0
	var costumes: Array[CostumeData] = costume_source.costumes if not costume_source.costumes.is_empty() else data.costumes
	mode.selection.characters[slot] = data
	mode.selection.costumes[slot] = costumes[_costume_index % costumes.size()]
	mode.selection.blade_colors[slot] = data.blade_colors[_blade_index % data.blade_colors.size()]
	mode.selection.power_sets[slot] = _custom.duplicate() if id != RANDOM else []


func _arena(id: StringName) -> ArenaData:
	for arena in DuelMode.ARENAS:
		if arena.id == id:
			return arena
	return null
