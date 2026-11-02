extends Control

const MARGIN: float = 100.0
const LIST_WIDTH: float = 540.0
const COLUMN_GAP: int = 80
const DETAIL_GAP: int = 12
const SHIP_SCALE: float = 5.0
const SHIP_PREVIEW_SIZE: Vector2 = Vector2(320.0, 280.0)
const STAT_LABEL_WIDTH: float = 220.0
const STAT_BAR_SIZE: Vector2 = Vector2(280.0, 8.0)
const STAT_ROW_GAP: int = 16
const PALETTE: UiPalette = preload("res://ui/palette.tres")
const STAT_MAXIMUM: Dictionary = {&"hull": 150.0, &"shield": 45.0, &"speed": 440.0, &"agility": 260.0, &"firepower": 60.0}
const STAT_KEYS: Dictionary = {&"hull": "SPACE_STAT_HULL", &"shield": "SPACE_STAT_SHIELD", &"speed": "SPACE_STAT_SPEED", &"agility": "SPACE_STAT_AGILITY", &"firepower": "SPACE_STAT_FIREPOWER"}

var _list: MenuList
var _preview: MissionPreview
var _ship_preview: TextureRect
var _stats: VBoxContainer
var _stat_bars: Dictionary = {}
var _title: Label
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
	var detail_column: VBoxContainer = VBoxContainer.new()
	detail_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_column.add_theme_constant_override(&"separation", DETAIL_GAP)
	columns.add_child(detail_column)
	_preview = MissionPreview.new()
	detail_column.add_child(_preview)
	_build_ship_area(detail_column)
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
	var footer: Label = _label(ControlHints.line(PackedStringArray([
		"↑ ↓  " + tr("HINT_CHANGE"), ControlHints.hint(&"ui_accept", "HINT_CONFIRM"), ControlHints.hint(&"ui_cancel", "HINT_BACK"),
	])), &"HuntHintLabel")
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_top = -65.0
	add_child(footer)


func _build_ship_area(parent: Control) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override(&"separation", COLUMN_GAP)
	row.visible = false
	parent.add_child(row)
	_ship_preview = TextureRect.new()
	_ship_preview.custom_minimum_size = SHIP_PREVIEW_SIZE
	_ship_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_ship_preview.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	_ship_preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	row.add_child(_ship_preview)
	_stats = VBoxContainer.new()
	_stats.alignment = BoxContainer.ALIGNMENT_CENTER
	_stats.add_theme_constant_override(&"separation", STAT_ROW_GAP)
	row.add_child(_stats)
	for stat in STAT_KEYS:
		var stat_row: HBoxContainer = HBoxContainer.new()
		stat_row.alignment = BoxContainer.ALIGNMENT_BEGIN
		var name_label: Label = _label(tr(STAT_KEYS[stat]), &"HuntBodyLabel")
		name_label.custom_minimum_size.x = STAT_LABEL_WIDTH
		stat_row.add_child(name_label)
		var holder: Control = Control.new()
		holder.custom_minimum_size = STAT_BAR_SIZE
		holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		stat_row.add_child(holder)
		var bar: HudBar = HudBar.new()
		bar.size = STAT_BAR_SIZE
		bar.fill_color = PALETTE.text
		holder.add_child(bar)
		_stat_bars[stat] = bar
		_stats.add_child(stat_row)


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
		&"ships":
			_show_ships()
		_:
			_heading.text = tr("MENU_SPACE").to_upper()
			for data in SpaceMode.MISSIONS:
				_list.add_item(data.id, tr(data.title_key))
			_list.add_item(&"ships", tr("SPACE_HANGAR_ROW").format({"name": tr(SaveService.space.selected_ship().name_key)}))
			_list.add_item(&"upgrades", tr("SPACE_WORKSHOP"))
			_list.add_item(&"back", tr("MENU_BACK"))
			_list.select_id(_mission)
			_highlight(_list._ids[_list.selected])


func _highlight(id: StringName) -> void:
	if _panel == &"ships":
		_highlight_ship(id)
		return
	if _panel != &"missions":
		return
	if id == &"upgrades" or id == &"back":
		_show_detail(null, "", tr("SPACE_WORKSHOP_RULES") if id == &"upgrades" else "")
		return
	if id == &"ships":
		_show_ship(SaveService.space.selected_ship(), tr("SPACE_HANGAR_INFO"))
		return
	for data in SpaceMode.MISSIONS:
		if data.id == id:
			_mode = SpaceMode.new(data, SaveService.space.loadout())
			_mission = id
	var record: Dictionary = SaveService.space.records.get(String(id), {})
	var progress: String = tr("SPACE_UNPLAYED") if record.is_empty() else tr("SPACE_RECORD").format({"time": ChallengeMode.format_time(record.ticks * Ticks.DELTA), "rating": record.rating})
	var ship_line: String = tr("SPACE_CURRENT_SHIP").format({"name": tr(SaveService.space.selected_ship().name_key)})
	_show_detail(_mode.data.preview, tr(_mode.data.title_key).to_upper(), tr(_mode.data.briefing_key) + "\n\n" + tr(_mode.data.objective_key) + "\n" + tr("SPACE_BRIEF_RULES").format({"par": int(_mode.data.par_seconds), "limit": int(_mode.data.limit_seconds)}) + "\n\n" + ship_line + " · " + progress)


func _show_detail(image: Texture2D, title: String, body: String) -> void:
	_preview.show_texture(image)
	_ship_preview.get_parent().visible = false
	_title.text = title
	_title.visible = title != ""
	_detail.text = body


func _show_ship(ship: SpaceShipData, note: String) -> void:
	_preview.show_texture(null)
	_ship_preview.get_parent().visible = true
	var size: Vector2 = ship.sprite.get_size() * SHIP_SCALE
	_ship_preview.texture = ship.sprite
	_ship_preview.stretch_mode = TextureRect.STRETCH_SCALE
	_ship_preview.custom_minimum_size = size
	_ship_preview.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_ship_preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_set_stat(&"hull", ship.hull)
	_set_stat(&"shield", ship.shield)
	_set_stat(&"speed", ship.speed)
	_set_stat(&"agility", ship.rotation_degrees)
	_set_stat(&"firepower", ship.primary.damage / ship.primary.interval)
	_title.text = tr(ship.name_key).to_upper()
	_title.visible = true
	_detail.text = tr(ship.description_key) + "\n\n" + note


func _set_stat(stat: StringName, value: float) -> void:
	var bar: HudBar = _stat_bars[stat]
	bar.ratio = clampf(value / STAT_MAXIMUM[stat], 0.0, 1.0)
	bar.ghost_ratio = bar.ratio
	bar.queue_redraw()


func _show_ships() -> void:
	_heading.text = tr("SPACE_HANGAR").to_upper()
	for ship in SpaceProgress.SHIPS:
		_list.add_item(ship.id, tr(ship.name_key))
	_list.add_item(&"back", tr("MENU_BACK"))
	_list.select_id(SaveService.space.selected_ship().id)
	_highlight_ship(_list._ids[_list.selected])


func _highlight_ship(id: StringName) -> void:
	if id == &"back":
		_show_detail(null, "", "")
		return
	for ship in SpaceProgress.SHIPS:
		if ship.id == id:
			_show_ship(ship, tr("SPACE_HANGAR_INFO"))


func _show_result() -> void:
	var result: SpaceMissionResult = _mode.result
	var keys: PackedStringArray = ["", "SPACE_SUCCESS", "SPACE_DEFEATED", "SPACE_ALLY_DOWN", "SPACE_TIMEOUT"]
	_heading.text = tr(keys[result.outcome]).to_upper()
	_list.add_item(&"retry", tr("RESULT_RETRY"))
	_list.add_item(&"upgrades", tr("SPACE_WORKSHOP"))
	if result.won():
		_list.add_item(&"next", tr("INF_NEXT"))
	_list.add_item(&"missions", tr("INF_MISSIONS"))
	var lines: PackedStringArray = [tr("SPACE_RESULT_TIME").format({"time": ChallengeMode.format_time(result.ticks * Ticks.DELTA)}), tr("SPACE_RATING").format({"rating": result.rating}), ""]
	for objective in result.objectives:
		lines.append(tr("INF_CHECK").format({"state": tr("INF_DONE" if objective.done else "INF_PENDING"), "objective": tr(objective.key)}))
	lines.append("")
	lines.append(tr("SPACE_POINT_EARNED" if result.point_earned else "SPACE_REPEAT" if result.won() else "SPACE_FAILURE_SAVE"))
	_show_detail(_mode.data.preview, tr(_mode.data.title_key).to_upper(), "\n".join(lines))


func _show_upgrades() -> void:
	_heading.text = tr("SPACE_WORKSHOP").to_upper()
	_list.clear_items()
	for index in 3:
		_list.add_item(StringName(str(index)), tr(["SPACE_UP_WEAPON", "SPACE_UP_SHIELD", "SPACE_UP_SPEED"][index]).format({"level": SaveService.space.levels[index], "max": SpaceProgress.CONFIG.max_level}))
	_list.add_item(&"reset", tr("SPACE_UP_RESET"))
	_list.add_item(&"back", tr("MENU_BACK"))
	_show_detail(null, "", tr("SPACE_POINTS").format({"points": SaveService.space.available()}) + "\n\n" + tr("SPACE_WORKSHOP_RULES") + "\n\n" + tr("SPACE_UP_VALUES").format({"damage": SpaceProgress.CONFIG.weapon_damage, "interval": SpaceProgress.CONFIG.weapon_interval, "shield": SpaceProgress.CONFIG.shield_capacity, "regen": SpaceProgress.CONFIG.shield_regeneration, "speed": SpaceProgress.CONFIG.speed, "accel": SpaceProgress.CONFIG.acceleration}))


func _choose(id: StringName) -> void:
	if id == &"back" or id == &"missions":
		_leave()
	elif _panel == &"ships":
		SaveService.select_space_ship(id)
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
	elif id == &"ships":
		SceneRouter.change(&"space_ships", {"panel": &"ships", "mission": _mission})
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
