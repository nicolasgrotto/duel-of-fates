extends Control

const MARGIN: float = 100.0
const LIST_WIDTH: float = 540.0
const COLUMN_GAP: int = 80
const DETAIL_GAP: int = 12
const CHARACTER_ROW: StringName = &"character"
const BACK_ROW: StringName = &"back"

var _list: MenuList
var _preview: MissionPreview
var _look_preview: InfiltrationLookPreview
var _title: Label
var _detail: Label
var _heading: Label
var _footer: Label
var _mode: InfiltrationMode
var _result: bool = false
var _characters_panel: bool = false
var _mission: StringName
var _costume: int = 0
var _blade: int = 0


func _ready() -> void:
	InfiltrationBindings.install()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_heading = _label("", &"ScreenTitleLabel")
	_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_heading.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_heading.offset_top = 70.0
	add_child(_heading)
	var columns: HBoxContainer = HBoxContainer.new()
	columns.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	columns.offset_left = MARGIN
	columns.offset_right = -MARGIN
	columns.offset_top = 200.0
	columns.offset_bottom = -110.0
	columns.add_theme_constant_override(&"separation", COLUMN_GAP)
	add_child(columns)
	_list = MenuList.new()
	_list.custom_minimum_size.x = LIST_WIDTH
	columns.add_child(_list)
	_list.chosen.connect(_choose)
	_list.highlighted.connect(_highlight)
	_list.adjusted.connect(_adjust)
	var detail_column: VBoxContainer = VBoxContainer.new()
	detail_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_column.add_theme_constant_override(&"separation", DETAIL_GAP)
	columns.add_child(detail_column)
	_preview = MissionPreview.new()
	detail_column.add_child(_preview)
	_look_preview = InfiltrationLookPreview.new()
	detail_column.add_child(_look_preview)
	_title = _label("", &"HuntSubtitleLabel")
	_title.visible = false
	detail_column.add_child(_title)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_column.add_child(scroll)
	_detail = _label("", &"HuntBodyLabel")
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	scroll.add_child(_detail)
	_footer = _label("", &"HuntHintLabel")
	_footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_footer.offset_top = -65.0
	add_child(_footer)
	_set_footer(false)


func required_resources(params: Dictionary) -> PackedStringArray:
	var paths: PackedStringArray = [CharacterRoster.path(InfiltrationMode.look_character().id)]
	if params.get("panel", &"") == &"characters":
		for id in CharacterRoster.IDS:
			paths.append(CharacterRoster.path(id))
	return paths


func open(params: Dictionary) -> void:
	_result = params.has("result")
	if _result:
		_mode = params.mode
		_show_result()
		return
	_mission = params.get("mission", InfiltrationMode.MISSIONS[0].id)
	if params.get("panel", &"") == &"characters":
		_show_characters()
		return
	_heading.text = tr("MENU_INFILTRATION").to_upper()
	for mission in InfiltrationMode.MISSIONS:
		_list.add_item(mission.id, tr(mission.title_key))
	_list.add_item(CHARACTER_ROW, tr("INF_CHARACTER").format({"name": tr(InfiltrationMode.look_character().name_key)}))
	_list.add_item(BACK_ROW, tr("MENU_BACK"))
	_list.select_id(_mission)
	_highlight(_list._ids[_list.selected])


func _highlight(id: StringName) -> void:
	if _result:
		return
	if _characters_panel:
		_highlight_character(id)
	elif id == BACK_ROW:
		_show_panel(null, null, "", "")
	elif id == CHARACTER_ROW:
		var character: CharacterData = InfiltrationMode.look_character()
		_show_panel(null, InfiltrationMode.current_look(), tr(character.name_key).to_upper(), tr("INF_CHARACTER_INFO"))
	else:
		_highlight_mission(id)


func _highlight_mission(id: StringName) -> void:
	for mission in InfiltrationMode.MISSIONS:
		if mission.id == id:
			_mode = InfiltrationMode.new(mission)
			_mission = id
	var data: InfiltrationMissionData = _mode.data
	var record: Dictionary = SaveService.infiltration_best.get(String(data.id), {})
	var progress: String = tr("INF_NOT_COMPLETED")
	if not record.is_empty():
		progress = tr("INF_RECORD").format({"time": ChallengeMode.format_time(record.ticks * Ticks.DELTA)}) + "\n" + InfiltrationMode.bonus_text(record.bonuses)
	var controls: String = ControlHints.line(PackedStringArray([ControlHints.hint(&"infiltration_interact", "INF_INTERACT"), ControlHints.hint(&"infiltration_takedown", "INFILTRATION_TAKEDOWN")]))
	_show_panel(data.preview, null, tr(data.title_key).to_upper(), tr(data.briefing_key) + "\n\n" + tr("INF_BRIEF_RULES").format({"time": int(data.bonus_seconds)}) + "\n" + controls + "\n\n" + progress)


func _show_panel(image: Texture2D, look: InfiltrationLook, title: String, body: String) -> void:
	_preview.show_texture(image)
	_look_preview.show_look(look)
	_title.text = title
	_title.visible = title != ""
	_detail.text = body


func _show_characters() -> void:
	_characters_panel = true
	_set_footer(true)
	_heading.text = tr("INF_CHARACTER_TITLE").to_upper()
	var current: CharacterData = InfiltrationMode.look_character()
	for id in CharacterRoster.IDS:
		var character: CharacterData = CharacterRoster.character(id)
		if Unlocks.is_character_unlocked(character):
			_list.add_item(id, tr(character.name_key))
	_list.add_item(BACK_ROW, tr("MENU_BACK"))
	_costume = InfiltrationMode.look_costume(current)
	_blade = InfiltrationMode.look_blade(current)
	_list.select_id(current.id)
	_refresh_character(current)


func _highlight_character(id: StringName) -> void:
	if id == BACK_ROW:
		_show_panel(null, null, "", "")
		return
	_costume = 0
	_blade = 0
	_refresh_character(CharacterRoster.character(id))


func _refresh_character(character: CharacterData) -> void:
	var body: String = tr("INF_CHARACTER_COSTUME").format({"name": tr(character.costumes[_costume].name_key)}) + "\n" + tr("INF_CHARACTER_BLADE").format({"name": tr(character.blade_color_keys[_blade])}) + "\n\n" + tr("INF_CHARACTER_INFO")
	_show_panel(null, InfiltrationLook.create(character, _costume, _blade), tr(character.name_key).to_upper(), body)


func _adjust(id: StringName, direction: int) -> void:
	if not _characters_panel or id == BACK_ROW:
		return
	var character: CharacterData = CharacterRoster.character(id)
	var count: int = character.costumes.size()
	for step in count:
		_costume = posmod(_costume + direction, count)
		if Unlocks.is_costume_unlocked(character, character.costumes[_costume]):
			break
	_refresh_character(character)


func _cycle_blade(id: StringName) -> void:
	if id == BACK_ROW:
		return
	var character: CharacterData = CharacterRoster.character(id)
	var count: int = character.blade_colors.size()
	for step in count:
		_blade = posmod(_blade + 1, count)
		if Unlocks.is_color_unlocked(character, _blade):
			break
	_refresh_character(character)


func _show_result() -> void:
	var result: Dictionary = _mode.result
	var won: bool = result.outcome == InfiltrationMissionState.Outcome.COMPLETED
	var title_key: String = "INF_SUCCESS" if won else "INF_PRISONER_DOWN" if result.outcome == InfiltrationMissionState.Outcome.PRISONER_DOWN else "INF_PLAYER_DOWN"
	_heading.text = tr(title_key).to_upper()
	_list.add_item(&"retry", tr("RESULT_RETRY"))
	if won:
		_list.add_item(&"next", tr("INF_NEXT"))
	_list.add_item(&"missions", tr("INF_MISSIONS"))
	var lines: PackedStringArray = [tr("INF_TIME").format({"time": ChallengeMode.format_time(result.ticks * Ticks.DELTA)}), tr("INF_APPROACH").format({"approach": tr("INF_DIRECT" if result.alarm_raised else "INF_STEALTH")}), ""]
	for objective in result.objectives:
		lines.append(tr("INF_CHECK").format({"state": tr("INF_DONE" if objective.done else "INF_PENDING"), "objective": tr(objective.key).format({"index": objective.index})}))
	lines.append("")
	lines.append(tr("INF_BONUSES"))
	lines.append(InfiltrationMode.bonus_text(result.bonuses))
	if not won:
		lines.append(tr("INF_FAILURE_SAVE"))
	_show_panel(_mode.data.preview, null, tr(_mode.data.title_key).to_upper(), "\n".join(lines))


func _choose(id: StringName) -> void:
	if _result:
		match id:
			&"retry":
				_mode.start()
			&"next":
				_mode.next()
			&"missions":
				SceneRouter.change(&"infiltration", {"mission": _mode.data.id})
	elif _characters_panel:
		if id != BACK_ROW:
			SaveService.set_infiltration_look(id, _costume, _blade)
		_leave()
	elif id == BACK_ROW:
		_leave()
	elif id == CHARACTER_ROW:
		SceneRouter.change(&"infiltration_characters", {"panel": &"characters", "mission": _mission})
	else:
		_mode.start()


func _exit_tree() -> void:
	InfiltrationBindings.uninstall()


func _leave() -> void:
	if _result:
		SceneRouter.change(&"infiltration", {"mission": _mode.data.id})
	elif _characters_panel:
		SceneRouter.change(&"infiltration", {"mission": _mission})
	else:
		SceneRouter.change(&"menu", {"group": &"special", "focus": &"infiltration"})


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_leave()
	elif _characters_panel and event.is_action_pressed(&"menu_variant"):
		get_viewport().set_input_as_handled()
		_cycle_blade(_list._ids[_list.selected])


func _set_footer(characters: bool) -> void:
	var hints: PackedStringArray = ["↑ ↓  " + tr("HINT_CHANGE")]
	if characters:
		hints.append(tr("INF_CHARACTER_HINT"))
		hints.append(ControlHints.hint(&"menu_variant", "INF_CHARACTER_BLADE_HINT"))
	hints.append(ControlHints.hint(&"ui_accept", "HINT_CONFIRM"))
	hints.append(ControlHints.hint(&"ui_cancel", "HINT_BACK"))
	_footer.text = ControlHints.line(hints)


func _label(text: String, variation: StringName) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.theme_type_variation = variation
	return label
