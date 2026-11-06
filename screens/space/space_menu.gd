extends Control

const ROOT_MARGIN: Vector2 = Vector2(56.0, 44.0)
const ROOT_GAP: int = 16
const COLUMN_GAP: int = 16
const DETAIL_GAP: int = 10
const CHIP_GAP: int = 6
const MAP_WIDTH: float = 1120.0
const PREVIEW_SIZE: Vector2 = Vector2(620.0, 220.0)
const SPRITE_SIZE: Vector2 = Vector2(40.0, 40.0)
const SHIP_LIST_WIDTH: float = 470.0
const UPGRADE_WIDTH: float = 620.0
const SHIP_DISPLAY: Vector2 = Vector2(420.0, 300.0)
const STAT_ROW_GAP: int = 10
const STAT_NAME_WIDTH: float = 190.0
const STAT_VALUE_WIDTH: float = 130.0
const THREAT_LEVELS: int = 5
const RATING_LEVELS: int = 3
const REVIEW_LIST_WIDTH: float = 728.0
const TOOL_HANGAR: int = 0
const TOOL_BACK: int = 1
const PALETTE: UiPalette = preload("res://ui/palette.tres")
const STAT_MAXIMUM: Dictionary = {&"hull": 150.0, &"shield": 75.0, &"speed": 480.0, &"agility": 260.0, &"firepower": 130.0}
const STAT_KEYS: Dictionary = {&"hull": "SPACE_STAT_HULL", &"shield": "SPACE_STAT_SHIELD", &"speed": "SPACE_STAT_SPEED", &"agility": "SPACE_STAT_AGILITY", &"firepower": "SPACE_STAT_FIREPOWER"}
const TRACK_KEYS: PackedStringArray = ["SPACE_TRACK_WEAPON", "SPACE_TRACK_SHIELD", "SPACE_TRACK_SPEED"]
const RESET_ROW: StringName = &"reset"
const BACK_ROW: StringName = &"back"

var _header: TacticalHeader
var _body: HBoxContainer
var _footer: KeyFooter
var _mode: SpaceMode
var _panel: StringName = &"missions"
var _mission: StringName = &"open_corridor"
var _map: SectorMap
var _focus: int = 0
var _tools: Array[PanelContainer] = []
var _detail_preview: MissionPreview
var _detail_title: Label
var _detail_objective: Label
var _detail_brief: Label
var _enemy_flow: HFlowContainer
var _threat: LevelPips
var _rating: LevelPips
var _best: Label
var _status_glyph: StatusGlyph
var _status_text: Label
var _ship_list: TacticalList
var _track_list: TacticalList
var _ship_sprite: TextureRect
var _ship_name: Label
var _ship_note: Label
var _stat_bars: Dictionary = {}
var _stat_values: Dictionary = {}
var _points_label: Label
var _effect_label: Label
var _notice: Label
var _focused_ship: StringName = &""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var ground: ColorRect = ColorRect.new()
	ground.color = PALETTE.tactical_deep
	ground.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(ground)
	var root: VBoxContainer = VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = ROOT_MARGIN.x
	root.offset_right = -ROOT_MARGIN.x
	root.offset_top = ROOT_MARGIN.y
	root.offset_bottom = -ROOT_MARGIN.y
	root.add_theme_constant_override(&"separation", ROOT_GAP)
	add_child(root)
	_header = TacticalHeader.new(PALETTE.menu_blade_b)
	root.add_child(_header)
	_body = HBoxContainer.new()
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override(&"separation", COLUMN_GAP)
	root.add_child(_body)
	_footer = KeyFooter.new()
	root.add_child(_footer)


func open(params: Dictionary) -> void:
	_panel = params.get("panel", &"missions")
	_mission = params.get("mission", &"open_corridor")
	_mode = params.get("mode")
	if _mode != null:
		_mission = _mode.data.id
	match _panel:
		&"result":
			_show_result()
		&"upgrades", &"ships":
			_panel = &"hangar"
			_show_hangar()
		_:
			_show_sector()


func _show_sector() -> void:
	_header.set_content(tr("MENU_SPACE"), tr("SPACE_MAP_PROGRESS").format({"done": SaveService.space.records.size(), "total": SpaceMode.MISSIONS.size(), "points": SaveService.space.earned()}))
	_body.add_child(_build_map_column())
	_body.add_child(_build_mission_panel())
	_focus = maxi(_mission_index(_mission), 0)
	_map.selected = _focus
	_footer.set_hints([
		{"keys": PackedStringArray(["←", "→"]), "text": tr("SPACE_MAP_MOVE")},
		{"keys": PackedStringArray([ControlHints.key_label(&"ui_accept")]), "text": tr("SPACE_MAP_START")},
		{"keys": PackedStringArray([ControlHints.key_label(&"ui_cancel")]), "text": tr("HINT_BACK")},
	])
	_refresh_focus()


func _mission_index(id: StringName) -> int:
	for index in SpaceMode.MISSIONS.size():
		if SpaceMode.MISSIONS[index].id == id:
			return index
	return -1


func _build_map_column() -> VBoxContainer:
	var column: VBoxContainer = VBoxContainer.new()
	column.custom_minimum_size.x = MAP_WIDTH
	column.add_theme_constant_override(&"separation", COLUMN_GAP)
	_map = SectorMap.new()
	_map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_map)
	var done: Array[bool] = []
	var rates: PackedInt32Array = []
	for mission in SpaceMode.MISSIONS:
		var record: Dictionary = SaveService.space.records.get(String(mission.id), {})
		done.append(not record.is_empty())
		rates.append(int(record.get("rating", 0)))
	_map.configure(SpaceMode.MISSIONS, done, rates)
	_map.node_clicked.connect(_on_node_clicked)
	var tools: HBoxContainer = HBoxContainer.new()
	tools.add_theme_constant_override(&"separation", CHIP_GAP)
	_tools.clear()
	_tools.append(_tool_button(tr("SPACE_HANGAR_ROW").format({"name": tr(SaveService.space.selected_ship().name_key)}), TOOL_HANGAR))
	_tools.append(_tool_button(tr("MENU_BACK"), TOOL_BACK))
	for tool in _tools:
		tools.add_child(tool)
	column.add_child(tools)
	return column


func _tool_button(text: String, tool: int) -> PanelContainer:
	var button: PanelContainer = PanelContainer.new()
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.gui_input.connect(_on_tool_input.bind(tool))
	var label: Label = _label(text, &"TacticalValueLabel")
	button.add_child(label)
	return button


func _build_mission_panel() -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.theme_type_variation = &"TacticalChamferPanel"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var column: VBoxContainer = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override(&"separation", DETAIL_GAP)
	scroll.add_child(column)
	_detail_preview = MissionPreview.new()
	_detail_preview.display_size = PREVIEW_SIZE
	column.add_child(_detail_preview)
	_detail_title = _label("", &"TacticalNameLabel")
	_detail_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_detail_title)
	_detail_objective = _label("", &"TacticalAmberLabel")
	_detail_objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_detail_objective)
	_detail_brief = _label("", &"TacticalNoteLabel")
	_detail_brief.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_brief.add_theme_color_override(&"font_color", PALETTE.text)
	column.add_child(_detail_brief)
	column.add_child(_caption(tr("SPACE_MAP_ENEMIES")))
	_enemy_flow = HFlowContainer.new()
	_enemy_flow.add_theme_constant_override(&"h_separation", CHIP_GAP)
	_enemy_flow.add_theme_constant_override(&"v_separation", CHIP_GAP)
	column.add_child(_enemy_flow)
	column.add_child(_build_status_row())
	var reward: Label = _label(tr("SPACE_MAP_REWARD"), &"TacticalNoteLabel")
	reward.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(reward)
	return panel


func _build_status_row() -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override(&"separation", COLUMN_GAP * 2)
	_threat = LevelPips.new(0, THREAT_LEVELS)
	_threat.filled_color = PALETTE.danger
	row.add_child(_status_cell(tr("SPACE_MAP_THREAT"), _threat))
	var rating_row: HBoxContainer = HBoxContainer.new()
	rating_row.add_theme_constant_override(&"separation", CHIP_GAP)
	_rating = LevelPips.new(0, RATING_LEVELS)
	_rating.diamonds = true
	rating_row.add_child(_rating)
	_best = _label("", &"TacticalNoteLabel")
	rating_row.add_child(_best)
	row.add_child(_status_cell(tr("SPACE_MAP_BEST"), rating_row))
	var status_row: HBoxContainer = HBoxContainer.new()
	status_row.add_theme_constant_override(&"separation", CHIP_GAP)
	_status_glyph = StatusGlyph.new()
	status_row.add_child(_status_glyph)
	_status_text = _label("", &"TacticalNoteLabel")
	status_row.add_child(_status_text)
	row.add_child(_status_cell(tr("SPACE_MAP_STATUS"), status_row))
	return row


func _status_cell(caption: String, content: Control) -> VBoxContainer:
	var cell: VBoxContainer = VBoxContainer.new()
	cell.add_child(_caption(caption))
	cell.add_child(content)
	return cell


func _caption(text: String) -> Label:
	var label: Label = _label(text.to_upper(), &"TacticalCaptionLabel")
	label.add_theme_color_override(&"font_color", PALETTE.menu_blade_b)
	return label


func _focus_count() -> int:
	return SpaceMode.MISSIONS.size() + _tools.size()


func _refresh_focus() -> void:
	var missions: int = SpaceMode.MISSIONS.size()
	_map.selected = _focus if _focus < missions else -1
	for index in _tools.size():
		_tools[index].theme_type_variation = &"TacticalRowSelected" if _focus == missions + index else &"TacticalChip"
	if _focus < missions:
		_show_mission(SpaceMode.MISSIONS[_focus])


func _show_mission(data: SpaceMissionData) -> void:
	_mission = data.id
	_mode = SpaceMode.new(data, SaveService.space.loadout())
	_detail_preview.show_texture(data.preview)
	_detail_title.text = tr(data.title_key)
	_detail_objective.text = tr(data.objective_key)
	_detail_brief.text = tr(data.briefing_key)
	for child in _enemy_flow.get_children():
		_enemy_flow.remove_child(child)
		child.queue_free()
	for ship in data.enemy_types():
		_enemy_flow.add_child(_enemy_chip(ship))
	_threat.level = data.threat
	var record: Dictionary = SaveService.space.records.get(String(data.id), {})
	_rating.level = int(record.get("rating", 0))
	_best.text = ChallengeMode.format_time(record.ticks * Ticks.DELTA) if not record.is_empty() else "–"
	_status_glyph.state = StatusGlyph.State.COMPLETED if not record.is_empty() else StatusGlyph.State.AVAILABLE
	_status_text.text = tr("OPS_MENU_DONE" if not record.is_empty() else "OPS_MENU_AVAILABLE")


func _enemy_chip(ship: SpaceShipData) -> PanelContainer:
	var chip: PanelContainer = PanelContainer.new()
	chip.theme_type_variation = &"TacticalDangerChip"
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override(&"separation", CHIP_GAP)
	chip.add_child(row)
	if ship.sprite != null:
		var sprite: TextureRect = TextureRect.new()
		sprite.texture = ship.sprite
		sprite.custom_minimum_size = SPRITE_SIZE
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		row.add_child(sprite)
	var name_label: Label = _label(tr(ship.name_key), &"TacticalNoteLabel")
	name_label.add_theme_color_override(&"font_color", PALETTE.text)
	name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(name_label)
	return chip


func _on_node_clicked(index: int) -> void:
	if index == _focus:
		_start_mission()
		return
	AudioDirector.play_ui(&"ui_move")
	_focus = index
	_refresh_focus()


func _on_tool_input(event: InputEvent, tool: int) -> void:
	if event is InputEventMouseMotion and _focus != SpaceMode.MISSIONS.size() + tool:
		_focus = SpaceMode.MISSIONS.size() + tool
		_refresh_focus()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_run_tool(tool)


func _run_tool(tool: int) -> void:
	if tool == TOOL_HANGAR:
		SceneRouter.change(&"space_ships", {"panel": &"ships", "mission": _mission})
	else:
		_leave()


func _start_mission() -> void:
	AudioDirector.play_ui(&"ui_confirm")
	_mode.loadout = SaveService.space.loadout()
	_mode.start()


func _show_hangar() -> void:
	_header.set_content(tr("SPACE_HANGAR_TITLE"), tr("SPACE_POINTS_EARNED").format({"points": SaveService.space.earned(), "total": SpaceMode.MISSIONS.size()}))
	var ships_panel: PanelContainer = PanelContainer.new()
	ships_panel.theme_type_variation = &"TacticalPanel"
	ships_panel.custom_minimum_size.x = SHIP_LIST_WIDTH
	_ship_list = TacticalList.new()
	ships_panel.add_child(_ship_list)
	_body.add_child(ships_panel)
	_body.add_child(_build_ship_panel())
	_body.add_child(_build_upgrade_panel())
	_ship_list.highlighted.connect(_on_ship_highlighted)
	_ship_list.chosen.connect(_on_ship_chosen)
	_ship_list.adjusted.connect(_on_column_switch)
	_track_list.highlighted.connect(_on_track_highlighted)
	_track_list.chosen.connect(_on_track_chosen)
	_track_list.adjusted.connect(_on_column_switch)
	_track_list.active = false
	_fill_ship_list()
	_focused_ship = SaveService.space.selected_ship().id
	_ship_list.select_id(_focused_ship)
	_set_hangar_footer()
	_refresh_ship()


func _build_ship_panel() -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.theme_type_variation = &"TacticalPanel"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override(&"separation", DETAIL_GAP)
	panel.add_child(column)
	_ship_name = _label("", &"TacticalNameLabel")
	column.add_child(_ship_name)
	_ship_sprite = TextureRect.new()
	_ship_sprite.custom_minimum_size = SHIP_DISPLAY
	_ship_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_ship_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_ship_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	column.add_child(_ship_sprite)
	var stats: VBoxContainer = VBoxContainer.new()
	stats.add_theme_constant_override(&"separation", STAT_ROW_GAP)
	for stat: StringName in STAT_KEYS:
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override(&"separation", CHIP_GAP)
		var name_label: Label = _label(tr(STAT_KEYS[stat]), &"TacticalNoteLabel")
		name_label.custom_minimum_size.x = STAT_NAME_WIDTH
		row.add_child(name_label)
		var bar: StatBar = StatBar.new()
		row.add_child(bar)
		_stat_bars[stat] = bar
		var value_label: Label = _label("", &"TacticalNoteLabel")
		value_label.custom_minimum_size.x = STAT_VALUE_WIDTH
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(value_label)
		_stat_values[stat] = value_label
		stats.add_child(row)
	column.add_child(stats)
	_ship_note = _label("", &"TacticalNoteLabel")
	_ship_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_ship_note)
	return panel


func _build_upgrade_panel() -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.theme_type_variation = &"TacticalPanel"
	panel.custom_minimum_size.x = UPGRADE_WIDTH
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override(&"separation", DETAIL_GAP)
	panel.add_child(column)
	column.add_child(_caption(tr("SPACE_WORKSHOP")))
	_points_label = _label("", &"TacticalValueLabel")
	_points_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_points_label)
	_track_list = TacticalList.new()
	column.add_child(_track_list)
	_effect_label = _label("", &"TacticalBodyLabel")
	_effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_effect_label)
	_notice = _label("", &"TacticalAmberLabel")
	_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_notice)
	var rules: Label = _label(tr("SPACE_WORKSHOP_RULES"), &"TacticalNoteLabel")
	rules.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rules.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rules.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	column.add_child(rules)
	return panel


func _fill_ship_list() -> void:
	var keep: int = _ship_list.selected
	_ship_list.clear_items()
	for ship in SpaceProgress.SHIPS:
		var owned: PackedInt32Array = SaveService.space.levels_for(ship.id)
		var total: int = owned[0] + owned[1] + owned[2]
		var pips: LevelPips = LevelPips.new(total, SpaceProgress.CONFIG.max_level * owned.size())
		var state: StatusGlyph.State = StatusGlyph.State.ACTIVE if ship.id == SaveService.space.ship_id else StatusGlyph.State.AVAILABLE
		_ship_list.add_row(ship.id, tr(ship.name_key), state, "", "", false, pips)
	_ship_list.add_rule()
	_ship_list.add_row(BACK_ROW, tr("MENU_BACK"))
	_ship_list.selected = keep
	_ship_list._refresh()


func _fill_track_list() -> void:
	var keep: int = _track_list.selected
	_track_list.clear_items()
	var owned: PackedInt32Array = SaveService.space.levels_for(_focused_ship)
	for track in TRACK_KEYS.size():
		var maxed: bool = owned[track] >= SpaceProgress.CONFIG.max_level
		var pips: LevelPips = LevelPips.new(owned[track], SpaceProgress.CONFIG.max_level)
		var cost: String = tr("SPACE_TRACK_MAX") if maxed else tr("SPACE_TRACK_COST").format({"cost": SpaceProgress.CONFIG.cost})
		_track_list.add_row(StringName(str(track)), tr(TRACK_KEYS[track]), StatusGlyph.State.NONE, "", cost, false, pips)
	_track_list.add_row(RESET_ROW, tr("SPACE_UP_RESET"))
	_track_list.selected = keep
	_track_list._refresh()


func _set_hangar_footer() -> void:
	_footer.set_hints([
		{"keys": PackedStringArray(["↑", "↓"]), "text": tr("HINT_CHANGE")},
		{"keys": PackedStringArray(["←", "→"]), "text": tr("SPACE_HANGAR_SWITCH")},
		{"keys": PackedStringArray([ControlHints.key_label(&"ui_accept")]), "text": tr("SPACE_HANGAR_CONFIRM_SHIP" if _ship_list.active else "SPACE_HANGAR_CONFIRM_BUY")},
		{"keys": PackedStringArray([ControlHints.key_label(&"ui_cancel")]), "text": tr("HINT_BACK")},
	])


func _ship_by_id(id: StringName) -> SpaceShipData:
	for ship in SpaceProgress.SHIPS:
		if ship.id == id:
			return ship
	return SpaceProgress.SHIPS[0]


func _refresh_ship() -> void:
	var ship: SpaceShipData = _ship_by_id(_focused_ship)
	var built: SpaceShipData = SaveService.space.loadout_for(ship).build_ship(SpaceProgress.CONFIG, ship)
	_ship_sprite.texture = ship.sprite
	_ship_name.text = tr(ship.name_key)
	if ship.id == SaveService.space.ship_id:
		_ship_name.text += ControlHints.SEPARATOR + tr("SPACE_IN_USE")
	_ship_note.text = tr(ship.description_key)
	_set_stat(&"hull", ship.hull, built.hull)
	_set_stat(&"shield", ship.shield, built.shield)
	_set_stat(&"speed", ship.speed, built.speed)
	_set_stat(&"agility", ship.rotation_degrees, built.rotation_degrees)
	_set_stat(&"firepower", ship.primary.damage / ship.primary.interval, built.primary.damage / built.primary.interval)
	_points_label.text = tr("SPACE_POINTS_SHIP").format({"ship": tr(ship.name_key), "free": SaveService.space.available(ship.id), "total": SaveService.space.earned()})
	_fill_track_list()
	_refresh_effect()


func _set_stat(stat: StringName, base: float, upgraded: float) -> void:
	_stat_bars[stat].show_values(base, upgraded, STAT_MAXIMUM[stat])
	_stat_values[stat].text = str(roundi(upgraded)) if roundi(upgraded) == roundi(base) else "%d + %d" % [roundi(base), roundi(upgraded) - roundi(base)]


func _refresh_effect() -> void:
	var id: StringName = _track_list.current_id()
	if id == RESET_ROW:
		_effect_label.text = tr("SPACE_HANGAR_INFO")
		return
	var track: int = int(String(id))
	var owned: PackedInt32Array = SaveService.space.levels_for(_focused_ship)
	var maxed: bool = owned[track] >= SpaceProgress.CONFIG.max_level
	_effect_label.text = _effect_text(track, owned[track], owned[track] if maxed else owned[track] + 1)
	if maxed:
		_effect_label.text += "\n" + tr("SPACE_TRACK_FULL")
	elif owned[track] + 1 == SpaceProgress.CONFIG.max_level:
		_effect_label.text += "\n" + tr("SPACE_TRACK_ONE_LEFT")


func _effect_text(track: int, level: int, next: int) -> String:
	var config: SpaceUpgradeConfig = SpaceProgress.CONFIG
	var ship: SpaceShipData = _ship_by_id(_focused_ship)
	match track:
		0:
			return tr("SPACE_EFFECT_WEAPON").format({"a": snappedf(ship.primary.damage + config.weapon_damage * level, 0.1), "b": snappedf(ship.primary.damage + config.weapon_damage * next, 0.1), "c": snappedf(ship.primary.interval - config.weapon_interval * level, 0.01), "d": snappedf(ship.primary.interval - config.weapon_interval * next, 0.01)})
		1:
			return tr("SPACE_EFFECT_SHIELD").format({"a": roundi(ship.shield + config.shield_capacity * level), "b": roundi(ship.shield + config.shield_capacity * next), "c": roundi(ship.shield_regeneration + config.shield_regeneration * level), "d": roundi(ship.shield_regeneration + config.shield_regeneration * next)})
	return tr("SPACE_EFFECT_SPEED").format({"a": roundi(ship.speed + config.speed * level), "b": roundi(ship.speed + config.speed * next), "c": roundi(ship.acceleration + config.acceleration * level), "d": roundi(ship.acceleration + config.acceleration * next)})


func _on_ship_highlighted(id: StringName) -> void:
	if id == BACK_ROW:
		return
	_focused_ship = id
	_notice.text = ""
	_refresh_ship()


func _on_ship_chosen(id: StringName) -> void:
	if id == BACK_ROW:
		_leave()
		return
	SaveService.select_space_ship(id)
	_fill_ship_list()
	_refresh_ship()
	_notice.text = tr("SPACE_SHIP_EQUIPPED").format({"name": tr(_ship_by_id(id).name_key)})


func _on_column_switch(_id: StringName, _step: int) -> void:
	var to_tracks: bool = _ship_list.active
	if to_tracks and _ship_list.current_id() == BACK_ROW:
		return
	_ship_list.active = not to_tracks
	_track_list.active = to_tracks
	_notice.text = ""
	_set_hangar_footer()
	_refresh_effect()


func _on_track_highlighted(_id: StringName) -> void:
	_notice.text = ""
	_refresh_effect()


func _on_track_chosen(id: StringName) -> void:
	if id == RESET_ROW:
		SaveService.reset_space_upgrades(_focused_ship)
		_notice.text = tr("SPACE_UP_RESET_DONE")
	elif SaveService.buy_space_upgrade(int(String(id)), _focused_ship):
		_notice.text = tr("SPACE_UP_PURCHASED")
	elif SaveService.space.levels_for(_focused_ship)[int(String(id))] >= SpaceProgress.CONFIG.max_level:
		_notice.text = tr("SPACE_TRACK_FULL")
	else:
		_notice.text = tr("SPACE_TRACK_NEED_POINT")
	_fill_ship_list()
	_refresh_ship()


func _show_result() -> void:
	var result: SpaceMissionResult = _mode.result
	var keys: PackedStringArray = ["", "SPACE_SUCCESS", "SPACE_END_PLAYER", "SPACE_ALLY_DOWN", "SPACE_TIMEOUT"]
	_header.set_content(tr(keys[result.outcome]))
	var list_panel: PanelContainer = PanelContainer.new()
	list_panel.theme_type_variation = &"TacticalPanel"
	list_panel.custom_minimum_size.x = REVIEW_LIST_WIDTH
	var list: TacticalList = TacticalList.new()
	list_panel.add_child(list)
	list.add_row(&"retry", tr("RESULT_RETRY"))
	list.add_row(&"upgrades", tr("SPACE_HANGAR_TITLE"))
	if result.won():
		list.add_row(&"next", tr("INF_NEXT"))
	list.add_row(&"missions", tr("INF_MISSIONS"))
	list.chosen.connect(_on_result_chosen)
	_body.add_child(list_panel)
	var detail: PanelContainer = PanelContainer.new()
	detail.theme_type_variation = &"TacticalDetailPanel"
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override(&"separation", DETAIL_GAP)
	detail.add_child(column)
	var preview: MissionPreview = MissionPreview.new()
	column.add_child(preview)
	preview.show_texture(_mode.data.preview)
	column.add_child(_label(tr(_mode.data.title_key), &"TacticalNameLabel"))
	var lines: PackedStringArray = [tr("SPACE_RESULT_TIME").format({"time": ChallengeMode.format_time(result.ticks * Ticks.DELTA)}), tr("SPACE_RATING").format({"rating": result.rating}), ""]
	for objective in result.objectives:
		lines.append(tr("INF_CHECK").format({"state": tr("INF_DONE" if objective.done else "INF_PENDING"), "objective": tr(objective.key)}))
	lines.append("")
	lines.append(tr("SPACE_POINT_EARNED" if result.point_earned else "SPACE_REPEAT" if result.won() else "SPACE_FAILURE_SAVE"))
	var body: Label = _label("\n".join(lines), &"TacticalBodyLabel")
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(body)
	_body.add_child(detail)
	_footer.set_hints([
		{"keys": PackedStringArray(["↑", "↓"]), "text": tr("HINT_CHANGE")},
		{"keys": PackedStringArray([ControlHints.key_label(&"ui_accept")]), "text": tr("HINT_CONFIRM")},
		{"keys": PackedStringArray([ControlHints.key_label(&"ui_cancel")]), "text": tr("HINT_BACK")},
	])


func _on_result_chosen(id: StringName) -> void:
	match id:
		&"retry":
			_mode.loadout = SaveService.space.loadout()
			_mode.start()
		&"upgrades":
			SceneRouter.change(&"space_ships", {"panel": &"ships", "mission": _mission})
		&"next":
			_mode.next()
		_:
			_leave()


func _leave() -> void:
	if _panel != &"missions":
		SceneRouter.change(&"space", {"mission": _mission})
	else:
		SceneRouter.change(&"menu", {"group": &"special", "focus": &"space"})


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_leave()
	elif _panel == &"missions":
		_sector_input(event)


func _sector_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_right") or event.is_action_pressed(&"ui_down"):
		_step_focus(1)
	elif event.is_action_pressed(&"ui_left") or event.is_action_pressed(&"ui_up"):
		_step_focus(-1)
	elif event.is_action_pressed(&"ui_accept"):
		_accept_focus()
	else:
		return
	get_viewport().set_input_as_handled()


func _step_focus(step: int) -> void:
	AudioDirector.play_ui(&"ui_move")
	_focus = posmod(_focus + step, _focus_count())
	_refresh_focus()


func _accept_focus() -> void:
	var missions: int = SpaceMode.MISSIONS.size()
	if _focus < missions:
		_start_mission()
	else:
		AudioDirector.play_ui(&"ui_confirm")
		_run_tool(_focus - missions)


func _label(text: String, variation: StringName) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.theme_type_variation = variation
	return label
