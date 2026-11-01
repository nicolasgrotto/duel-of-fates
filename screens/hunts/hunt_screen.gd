extends Control

const MARGIN: float = 110.0
const TOP: float = 180.0
const LIST_WIDTH: float = 520.0
const COLUMN_GAP: int = 100
const DETAIL_GAP: int = 12
const THUMBNAIL_GRID: Vector2i = Vector2i(480, 170)
const THUMBNAIL_SCALE: float = 2.0

var _list: MenuList
var _thumbnail: ArenaThumbnail
var _name: Label
var _condition: Label
var _phases: Label
var _reward: Label
var _record: Label
var _action: Label
var _selected: HuntData
var _epilogue: bool = false


func required_resources(_params: Dictionary) -> PackedStringArray:
	var paths: PackedStringArray = []
	for hunt in HuntMode.HUNTS:
		paths.append(DuelMode.CHARACTER_PATH % [hunt.opponent, hunt.opponent])
	return paths


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var title: Label = _label(tr("MENU_HUNTS").to_upper(), &"ScreenTitleLabel")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 80.0
	add_child(title)
	var columns: HBoxContainer = HBoxContainer.new()
	columns.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	columns.offset_left = MARGIN
	columns.offset_right = -MARGIN
	columns.offset_top = TOP
	columns.offset_bottom = -100.0
	columns.add_theme_constant_override(&"separation", COLUMN_GAP)
	add_child(columns)
	_list = MenuList.new()
	_list.custom_minimum_size.x = LIST_WIDTH
	columns.add_child(_list)
	for hunt in HuntMode.HUNTS:
		_list.add_item(hunt.id, tr(hunt.title_key))
	_list.add_item(&"back", tr("MENU_BACK"))
	_list.highlighted.connect(_highlight)
	_list.chosen.connect(_choose)
	_list.adjusted.connect(_adjust)
	var detail: VBoxContainer = VBoxContainer.new()
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_theme_constant_override(&"separation", DETAIL_GAP)
	columns.add_child(detail)
	var preview: Control = Control.new()
	preview.custom_minimum_size.y = THUMBNAIL_GRID.y * THUMBNAIL_SCALE
	detail.add_child(preview)
	_thumbnail = ArenaThumbnail.new()
	_thumbnail.configure(THUMBNAIL_GRID, THUMBNAIL_SCALE)
	_thumbnail.position = Vector2(THUMBNAIL_GRID) * THUMBNAIL_SCALE * 0.5
	preview.add_child(_thumbnail)
	_name = _detail_label(detail, &"HuntSubtitleLabel")
	_condition = _detail_label(detail, &"HuntBodyLabel")
	_phases = _detail_label(detail, &"HuntBodyLabel")
	var kit: Label = _detail_label(detail, &"HuntBodyLabel")
	kit.text = tr("HUNT_KIT")
	_reward = _detail_label(detail, &"HuntBodyLabel")
	_record = _detail_label(detail, &"HuntSubtitleLabel")
	_action = _detail_label(detail, &"HuntBodyLabel")
	var footer: Label = _label(ControlHints.line(PackedStringArray([
		"↑ ↓  " + tr("HINT_CHANGE"),
		ControlHints.hint(&"ui_accept", "HINT_CONFIRM"),
		ControlHints.hint(&"ui_cancel", "HINT_BACK"),
	])), &"HuntHintLabel")
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_top = -60.0
	add_child(footer)
	_highlight(HuntMode.HUNTS[0].id)


func open(params: Dictionary) -> void:
	if params.has("hunt"):
		_list.select_id(params["hunt"])


func _label(text: String, variation: StringName) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.theme_type_variation = variation
	return label


func _detail_label(parent: VBoxContainer, variation: StringName) -> Label:
	var label: Label = _label("", variation)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label


func _highlight(id: StringName) -> void:
	if id == &"back":
		return
	for hunt in HuntMode.HUNTS:
		if hunt.id == id:
			_selected = hunt
			break
	_epilogue = false
	_thumbnail.show_arena(_selected.arena)
	_name.text = tr("HUNT_OPPONENT").format({"boss": tr(DuelMode.character(_selected.opponent).name_key), "arena": tr(_selected.arena.name_key)})
	_condition.text = tr(_selected.condition.description_key)
	var phases: PackedStringArray = []
	for phase in _selected.phases:
		phases.append(tr("HUNT_PHASE_LIST").format({"phase": tr(phase.title_key), "health": roundi(phase.health_threshold * 100.0), "power": tr(phase.powers[0].name_key)}))
	_phases.text = "\n".join(phases)
	_reward.text = tr("HUNT_REWARD").format({"reward": tr(_selected.reward_key)})
	var key: String = String(_selected.id)
	_record.text = tr("HUNT_BEST").format({"time": ChallengeMode.format_time(SaveService.hunt_best[key])}) if SaveService.hunt_best.has(key) else tr("HUNT_PENDING")
	_refresh_action()


func _adjust(id: StringName, _step: int) -> void:
	if id != &"back" and _selected != null and SaveService.hunt_best.has(String(_selected.id)):
		_epilogue = not _epilogue
		_refresh_action()


func _refresh_action() -> void:
	_action.text = tr("HUNT_ACTION").format({"action": tr("HUNT_EPILOGUE" if _epilogue else "HUNT_START")}) if SaveService.hunt_best.has(String(_selected.id)) else tr("HUNT_START")


func _choose(id: StringName) -> void:
	if id == &"back":
		_leave()
		return
	var mode: HuntMode = HuntMode.new(_selected)
	if _epilogue:
		mode.choose(&"continue")
	else:
		mode.start_briefing()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_leave()


func _leave() -> void:
	SceneRouter.change(&"menu", {"group": &"battles", "focus": &"hunts"})
