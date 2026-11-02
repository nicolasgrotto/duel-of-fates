extends Control

const MARGIN: float = 100.0
const LIST_WIDTH: float = 540.0
const COLUMN_GAP: int = 80

var _list: MenuList
var _detail: Label
var _heading: Label
var _mode: SpaceMode
var _panel: StringName = &"missions"
var _mission: StringName = &"open_corridor"


func _ready() -> void:
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
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	columns.add_child(scroll)
	_detail = _label("", &"InfiltrationLabel")
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	scroll.add_child(_detail)
	var footer: Label = _label(ControlHints.line(PackedStringArray([
		"↑ ↓  " + tr("HINT_CHANGE"), ControlHints.hint(&"ui_accept", "HINT_CONFIRM"), ControlHints.hint(&"ui_cancel", "HINT_BACK"),
	])), &"HuntHintLabel")
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_top = -65.0
	add_child(footer)


func open(params: Dictionary) -> void:
	_panel = params.get("panel", &"missions")
	_mission = params.get("mission", &"open_corridor")
	_mode = params.get("mode")
	if _mode != null:
		_mission = _mode.data.id
	match _panel:
		&"result":
			_show_result()
		&"upgrades":
			_show_upgrades()
		_:
			_heading.text = tr("MENU_SPACE").to_upper()
			for data in SpaceMode.MISSIONS:
				_list.add_item(data.id, tr(data.title_key))
			_list.add_item(&"upgrades", tr("SPACE_WORKSHOP"))
			_list.add_item(&"back", tr("MENU_BACK"))
			_list.select_id(_mission)
			_highlight(_list._ids[_list.selected])


func _highlight(id: StringName) -> void:
	if _panel != &"missions":
		return
	if id == &"upgrades" or id == &"back":
		_detail.text = tr("SPACE_WORKSHOP_RULES") if id == &"upgrades" else ""
		return
	for data in SpaceMode.MISSIONS:
		if data.id == id:
			_mode = SpaceMode.new(data, SaveService.space.loadout())
			_mission = id
	var record: Dictionary = SaveService.space.records.get(String(id), {})
	var progress: String = tr("SPACE_UNPLAYED") if record.is_empty() else tr("SPACE_RECORD").format({"time": ChallengeMode.format_time(record.ticks * Ticks.DELTA), "rating": record.rating})
	_detail.text = tr(_mode.data.title_key).to_upper() + "\n\n" + tr(_mode.data.briefing_key) + "\n\n" + tr(_mode.data.objective_key) + "\n\n" + tr("SPACE_BRIEF_RULES").format({"par": int(_mode.data.par_seconds), "limit": int(_mode.data.limit_seconds)}) + "\n\n" + progress + "\n\n" + tr("SPACE_START")


func _show_result() -> void:
	var result: SpaceMissionResult = _mode.result
	var keys: PackedStringArray = ["", "SPACE_SUCCESS", "SPACE_DEFEATED", "SPACE_ALLY_DOWN", "SPACE_TIMEOUT"]
	_heading.text = tr(keys[result.outcome]).to_upper()
	_list.add_item(&"retry", tr("RESULT_RETRY"))
	_list.add_item(&"upgrades", tr("SPACE_WORKSHOP"))
	if result.won():
		_list.add_item(&"next", tr("INF_NEXT"))
	_list.add_item(&"missions", tr("INF_MISSIONS"))
	var lines: PackedStringArray = [tr(_mode.data.title_key).to_upper(), "", tr("SPACE_RESULT_TIME").format({"time": ChallengeMode.format_time(result.ticks * Ticks.DELTA)}), tr("SPACE_RATING").format({"rating": result.rating}), ""]
	for objective in result.objectives:
		lines.append(tr("INF_CHECK").format({"state": tr("INF_DONE" if objective.done else "INF_PENDING"), "objective": tr(objective.key)}))
	lines.append("")
	lines.append(tr("SPACE_POINT_EARNED" if result.point_earned else "SPACE_REPEAT" if result.won() else "SPACE_FAILURE_SAVE"))
	_detail.text = "\n".join(lines)


func _show_upgrades() -> void:
	_heading.text = tr("SPACE_WORKSHOP").to_upper()
	_list.clear_items()
	for index in 3:
		_list.add_item(StringName(str(index)), tr(["SPACE_UP_WEAPON", "SPACE_UP_SHIELD", "SPACE_UP_SPEED"][index]).format({"level": SaveService.space.levels[index], "max": SpaceProgress.CONFIG.max_level}))
	_list.add_item(&"reset", tr("SPACE_UP_RESET"))
	_list.add_item(&"back", tr("MENU_BACK"))
	_detail.text = tr("SPACE_POINTS").format({"points": SaveService.space.available()}) + "\n\n" + tr("SPACE_WORKSHOP_RULES") + "\n\n" + tr("SPACE_UP_VALUES").format({"damage": SpaceProgress.CONFIG.weapon_damage, "interval": SpaceProgress.CONFIG.weapon_interval, "shield": SpaceProgress.CONFIG.shield_capacity, "regen": SpaceProgress.CONFIG.shield_regeneration, "speed": SpaceProgress.CONFIG.speed, "accel": SpaceProgress.CONFIG.acceleration})


func _choose(id: StringName) -> void:
	if id == &"back" or id == &"missions":
		_leave()
	elif _panel == &"upgrades":
		var notice: String = "SPACE_UP_RESET_DONE"
		if id == &"reset":
			SaveService.reset_space_upgrades()
		else:
			notice = "SPACE_UP_PURCHASED" if SaveService.buy_space_upgrade(int(String(id))) else "SPACE_UP_UNAVAILABLE"
		_show_upgrades()
		_detail.text += "\n\n" + tr(notice)
		_list.select_id(id)
	elif id == &"upgrades":
		SceneRouter.change(&"space_upgrades", {"panel": &"upgrades", "mission": _mission})
	elif id == &"next":
		_mode.next()
	else:
		_mode.loadout = SaveService.space.loadout()
		_mode.start()


func _leave() -> void:
	if _panel != &"missions":
		SceneRouter.change(&"space", {"mission": _mission})
	else:
		SceneRouter.change(&"menu", {"group": &"special", "focus": &"space"})


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_leave()


func _label(text: String, variation: StringName) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.theme_type_variation = variation
	return label
