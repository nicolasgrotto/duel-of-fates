extends Control

const MARGIN: float = 100.0
const LIST_WIDTH: float = 540.0
const COLUMN_GAP: int = 80

var _list: MenuList
var _detail: Label
var _heading: Label
var _mode: InfiltrationMode
var _result: bool = false


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
	_result = params.has("result")
	if _result:
		_mode = params.mode
		_show_result()
		return
	_heading.text = tr("MENU_INFILTRATION").to_upper()
	for mission in InfiltrationMode.MISSIONS:
		_list.add_item(mission.id, tr(mission.title_key))
	_list.add_item(&"back", tr("MENU_BACK"))
	_list.select_id(params.get("mission", InfiltrationMode.MISSIONS[0].id))
	_highlight(_list._ids[_list.selected])


func _highlight(id: StringName) -> void:
	if _result or id == &"back":
		return
	for mission in InfiltrationMode.MISSIONS:
		if mission.id == id:
			_mode = InfiltrationMode.new(mission)
	var data: InfiltrationMissionData = _mode.data
	var record: Dictionary = SaveService.infiltration_best.get(String(data.id), {})
	var progress: String = tr("INF_NOT_COMPLETED")
	if not record.is_empty():
		progress = tr("INF_RECORD").format({"time": ChallengeMode.format_time(record.ticks * Ticks.DELTA)}) + "\n" + InfiltrationMode.bonus_text(record.bonuses)
	var controls: String = ControlHints.line(PackedStringArray([ControlHints.hint(&"p1_power", "INF_INTERACT"), ControlHints.hint(&"p1_heavy_attack", "INFILTRATION_TAKEDOWN")]))
	_detail.text = tr(data.title_key).to_upper() + "\n\n" + tr(data.briefing_key) + "\n\n" + tr("INF_BRIEF_RULES").format({"time": int(data.bonus_seconds)}) + "\n" + controls + "\n\n" + progress + "\n\n" + tr("INF_START")


func _show_result() -> void:
	var result: Dictionary = _mode.result
	var won: bool = result.outcome == InfiltrationMissionState.Outcome.COMPLETED
	var title_key: String = "INF_SUCCESS" if won else "INF_PRISONER_DOWN" if result.outcome == InfiltrationMissionState.Outcome.PRISONER_DOWN else "INF_PLAYER_DOWN"
	_heading.text = tr(title_key).to_upper()
	_list.add_item(&"retry", tr("RESULT_RETRY"))
	if won:
		_list.add_item(&"next", tr("INF_NEXT"))
	_list.add_item(&"missions", tr("INF_MISSIONS"))
	var lines: PackedStringArray = [tr(_mode.data.title_key).to_upper(), "", tr("INF_TIME").format({"time": ChallengeMode.format_time(result.ticks * Ticks.DELTA)}), tr("INF_APPROACH").format({"approach": tr("INF_DIRECT" if result.alarm_raised else "INF_STEALTH")}), ""]
	for objective in result.objectives:
		lines.append(tr("INF_CHECK").format({"state": tr("INF_DONE" if objective.done else "INF_PENDING"), "objective": tr(objective.key).format({"index": objective.index})}))
	lines.append("")
	lines.append(tr("INF_BONUSES"))
	lines.append(InfiltrationMode.bonus_text(result.bonuses))
	if not won:
		lines.append(tr("INF_FAILURE_SAVE"))
	_detail.text = "\n".join(lines)


func _choose(id: StringName) -> void:
	if _result:
		match id:
			&"retry":
				_mode.start()
			&"next":
				_mode.next()
			&"missions":
				SceneRouter.change(&"infiltration", {"mission": _mode.data.id})
	elif id == &"back":
		_leave()
	else:
		_mode.start()


func _leave() -> void:
	if _result:
		SceneRouter.change(&"infiltration", {"mission": _mode.data.id})
	else:
		SceneRouter.change(&"menu", {"group": &"special", "focus": &"infiltration"})


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_leave()


func _label(text: String, variation: StringName) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.theme_type_variation = variation
	return label
