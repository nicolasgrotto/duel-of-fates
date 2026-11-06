extends Control

const ROOT_MARGIN: Vector2 = Vector2(56.0, 44.0)
const ROOT_GAP: int = 16
const COLUMN_GAP: int = 16
const LIST_WIDTH: float = 728.0
const DETAIL_GAP: int = 12
const TITLE_GAP: int = 16
const CHIP_GAP: int = 8
const CHARACTER_ROW: StringName = &"character"
const WEAPON_ROW: StringName = &"weapon"
const OWN_WEAPON: StringName = &"own"
const BACK_ROW: StringName = &"back"
const PALETTE: UiPalette = preload("res://ui/palette.tres")

var _header: TacticalHeader
var _list: TacticalList
var _preview: MissionPreview
var _look_preview: InfiltrationLookPreview
var _title: Label
var _group: Label
var _pill: PanelContainer
var _pill_glyph: StatusGlyph
var _pill_text: Label
var _record: Label
var _detail: Label
var _chips: HBoxContainer
var _reward_box: VBoxContainer
var _reward_text: Label
var _footer: KeyFooter
var _mode: InfiltrationMode
var _result: bool = false
var _characters_panel: bool = false
var _weapons_panel: bool = false
var _focused_character: StringName = &""
var _mission: StringName
var _costume: int = 0
var _blade: int = 0


func _ready() -> void:
	InfiltrationBindings.install(Settings.blaster_ops_keys, Settings.blaster_ops_buttons)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var ground: ColorRect = ColorRect.new()
	ground.color = PALETTE.tactical_ground
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
	_header = TacticalHeader.new()
	root.add_child(_header)
	var columns: HBoxContainer = HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override(&"separation", COLUMN_GAP)
	root.add_child(columns)
	columns.add_child(_build_list_panel())
	columns.add_child(_build_detail_panel())
	_footer = KeyFooter.new()
	root.add_child(_footer)
	_set_footer(false)


func _build_list_panel() -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.theme_type_variation = &"TacticalPanel"
	panel.custom_minimum_size.x = LIST_WIDTH
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	_list = TacticalList.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	_list.highlighted.connect(_reveal_selection.bind(scroll))
	_list.chosen.connect(_choose)
	_list.highlighted.connect(_highlight)
	_list.adjusted.connect(_adjust)
	return panel


func _build_detail_panel() -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.theme_type_variation = &"TacticalDetailPanel"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var column: VBoxContainer = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override(&"separation", DETAIL_GAP)
	scroll.add_child(column)
	_preview = MissionPreview.new()
	column.add_child(_preview)
	_look_preview = InfiltrationLookPreview.new()
	column.add_child(_look_preview)
	column.add_child(_build_title_row())
	_record = _label("", &"TacticalNoteLabel")
	_record.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_record)
	_detail = _label("", &"TacticalBodyLabel")
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_detail)
	_chips = HBoxContainer.new()
	_chips.add_theme_constant_override(&"separation", CHIP_GAP)
	column.add_child(_chips)
	_reward_box = VBoxContainer.new()
	_reward_box.add_theme_constant_override(&"separation", 0)
	_reward_box.add_child(_label(tr("OPS_MENU_REWARDS").to_upper(), &"TacticalGroupLabel"))
	_reward_text = _label("", &"TacticalNoteLabel")
	_reward_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_reward_box.add_child(_reward_text)
	column.add_child(_reward_box)
	return panel


func _build_title_row() -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override(&"separation", TITLE_GAP)
	_title = _label("", &"TacticalNameLabel")
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(_title)
	_group = _label("", &"TacticalGroupLabel")
	_group.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_group)
	_pill = PanelContainer.new()
	_pill.theme_type_variation = &"TacticalPill"
	_pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var pill_row: HBoxContainer = HBoxContainer.new()
	pill_row.add_theme_constant_override(&"separation", CHIP_GAP)
	_pill.add_child(pill_row)
	_pill_glyph = StatusGlyph.new()
	pill_row.add_child(_pill_glyph)
	_pill_text = _label("", &"TacticalValueLabel")
	pill_row.add_child(_pill_text)
	row.add_child(_pill)
	return row


func required_resources(params: Dictionary) -> PackedStringArray:
	var paths: PackedStringArray = [CharacterRoster.path(InfiltrationMode.look_character().id)]
	if params.get("panel", &"") == &"characters":
		for id in CharacterRoster.IDS:
			paths.append(CharacterRoster.path(id))
	return paths


func _reveal_selection(id: StringName, scroll: ScrollContainer) -> void:
	await get_tree().process_frame
	if is_instance_valid(scroll) and is_instance_valid(_list) and _list.current_id() == id:
		scroll.ensure_control_visible(_list.row_control(id))


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
	if params.get("panel", &"") == &"weapons":
		_show_weapons()
		return
	_header.set_content(tr("MENU_OPERATIONS"), tr("OPS_MENU_COMPLETED").format({"done": _completed_count(), "total": BlasterOpsMode.all_missions().size()}))
	_list.add_heading(tr("OPS_MENU_TRAINING"))
	for mission in BlasterOpsMode.TUTORIALS:
		_list.add_row(mission.id, tr(mission.title_key), StatusGlyph.State.AVAILABLE, " ", " ")
	_list.add_heading(tr("OPS_MENU_INFILTRATION"))
	for mission in InfiltrationMode.MISSIONS:
		_add_mission_row(mission)
	_list.add_heading(tr("OPS_MENU_INCURSION"))
	for mission in BlasterOpsMode.INCURSIONS:
		_add_mission_row(mission)
	_list.add_rule()
	_list.add_row(CHARACTER_ROW, tr("INF_CHARACTER").format({"name": tr(InfiltrationMode.look_character().name_key)}))
	_list.add_row(WEAPON_ROW, _weapon_row_text(InfiltrationMode.look_character()))
	_list.add_row(BACK_ROW, tr("MENU_BACK"))
	_list.select_id(_mission)
	_highlight(_list.current_id())


func _add_mission_row(mission: InfiltrationMissionData) -> void:
	var summary: Dictionary = _record_summary(mission)
	_list.add_row(mission.id, tr(mission.title_key), summary.state, summary.mark, summary.time)


func _record_summary(mission: InfiltrationMissionData) -> Dictionary:
	var record: Dictionary = SaveService.incursion_best.get(String(mission.id), {}) if mission is BlasterOpsMissionData else SaveService.infiltration_best.get(String(mission.id), {})
	if record.is_empty():
		return {"state": StatusGlyph.State.AVAILABLE, "mark": " ", "time": " "}
	var mark: String = _rating_mark(record.get("rating", 0)) if mission is BlasterOpsMissionData else str(_bit_count(int(record.get("bonuses", 0))))
	var time: String = ChallengeMode.format_time(record.ticks * Ticks.DELTA) if record.has("ticks") else "–"
	return {"state": StatusGlyph.State.COMPLETED, "mark": mark, "time": time}


func _rating_mark(rating: int) -> String:
	return tr(BlasterOpsMode.rating_key(rating) + "_SHORT")


func _bit_count(mask: int) -> int:
	var count: int = 0
	for bit in 4:
		if mask & (1 << bit) != 0:
			count += 1
	return count


func _completed_count() -> int:
	var done: int = 0
	for mission in BlasterOpsMode.all_missions():
		if _record_summary(mission).state == StatusGlyph.State.COMPLETED:
			done += 1
	return done


func _highlight(id: StringName) -> void:
	if _result:
		return
	if _weapons_panel:
		_highlight_weapon(id)
	elif _characters_panel:
		_highlight_character(id)
	elif id == WEAPON_ROW:
		var character: CharacterData = InfiltrationMode.look_character()
		_show_panel(null, InfiltrationMode.current_look(), tr("OPS_WEAPON_TITLE"), _weapon_detail(character, InfiltrationMode.look_weapon()))
	elif id == BACK_ROW:
		_show_panel(null, null, "", "")
	elif id == CHARACTER_ROW:
		var character: CharacterData = InfiltrationMode.look_character()
		_show_panel(null, InfiltrationMode.current_look(), tr(character.name_key), tr("INF_CHARACTER_INFO"))
	else:
		_highlight_mission(id)


func _highlight_mission(id: StringName) -> void:
	for mission in BlasterOpsMode.menu_missions():
		if mission.id == id:
			_mode = BlasterOpsMode.new(mission as BlasterOpsMissionData) if mission is BlasterOpsMissionData else InfiltrationMode.new(mission)
			_mission = id
	var data: InfiltrationMissionData = _mode.data
	if data is BlasterOpsMissionData and (data as BlasterOpsMissionData).tutorial:
		_highlight_tutorial(data as BlasterOpsMissionData)
		return
	if data is BlasterOpsMissionData:
		_highlight_incursion(data as BlasterOpsMissionData)
		return
	var record: Dictionary = SaveService.infiltration_best.get(String(data.id), {})
	var progress: String = tr("INF_NOT_COMPLETED")
	if not record.is_empty():
		progress = tr("INF_RECORD").format({"time": ChallengeMode.format_time(record.ticks * Ticks.DELTA)}) + ControlHints.SEPARATOR + tr("OPS_MENU_BONUS_COUNT").format({"count": _bit_count(int(record.bonuses))})
	_show_panel(data.preview, null, tr(data.title_key), tr(data.briefing_key))
	_show_mission_state(tr("OPS_MENU_INFILTRATION"), not record.is_empty(), progress)
	_set_chips([
		[tr("OPS_MENU_PRISONERS"), str(data.prisoner_spawns.size())],
		[tr("OPS_MENU_TIME_BONUS"), "%d s" % int(data.bonus_seconds)],
		[tr("OPS_MENU_BONUSES"), tr("OPS_MENU_INFILTRATION_BONUSES")],
	])


func _highlight_incursion(data: BlasterOpsMissionData) -> void:
	var record: Dictionary = SaveService.incursion_best.get(String(data.id), {})
	var progress: String = tr("INF_NOT_COMPLETED")
	if record.has("ticks"):
		progress = tr("INF_RECORD").format({"time": ChallengeMode.format_time(record.ticks * Ticks.DELTA)}) + ControlHints.SEPARATOR + tr(BlasterOpsMode.rating_key(record.rating))
	elif not record.is_empty():
		progress = tr("OPS_RECORD_LEGACY").format({"rating": tr(BlasterOpsMode.rating_key(record.rating))})
	_show_panel(data.preview, null, tr(data.title_key), tr(data.briefing_key))
	_show_mission_state(tr("OPS_MENU_INCURSION"), not record.is_empty(), progress)
	var chips: Array[Array] = [
		[tr("OPS_MENU_STAGES"), str(data.objective_count())],
		[tr("OPS_MENU_REFERENCE"), ChallengeMode.format_time(data.bonus_seconds)],
	]
	if not data.supply_terminals.is_empty():
		chips.append([tr("OPS_MENU_SUPPLIES"), str(data.supply_terminals.size())])
	if data.barrier_charges + data.heavy_barrier_charges > 0:
		chips.append([tr("OPS_MENU_BARRIERS"), str(data.barrier_charges + data.heavy_barrier_charges)])
	chips.append([tr("OPS_MENU_CRITERIA"), tr("OPS_MENU_CRITERIA_TEXT")])
	_set_chips(chips)
	_reward_text.text = tr("OPS_REWARDS")
	_reward_box.visible = true


func _highlight_tutorial(data: BlasterOpsMissionData) -> void:
	_show_panel(data.preview, null, tr(data.title_key), tr(data.briefing_key))
	_show_mission_state(tr("OPS_MENU_TRAINING"), false, "")
	_set_chips([
		[tr("OPS_MENU_STEPS"), str(data.stages.size())],
		[tr("OPS_MENU_DURATION"), tr("OPS_MENU_DURATION_TEXT")],
		[tr("OPS_MENU_RULES"), tr("OPS_MENU_TRAINING_RULES")],
	])


func _show_mission_state(group: String, completed: bool, record: String) -> void:
	_group.text = group.to_upper()
	_group.visible = true
	_pill.visible = true
	_pill_glyph.state = StatusGlyph.State.COMPLETED if completed else StatusGlyph.State.AVAILABLE
	_pill_text.text = tr("OPS_MENU_DONE" if completed else "OPS_MENU_AVAILABLE")
	_record.text = record
	_record.visible = record != ""


func _set_chips(entries: Array) -> void:
	for child in _chips.get_children():
		_chips.remove_child(child)
		child.queue_free()
	for index in entries.size():
		var chip: InfoChip = InfoChip.new(entries[index][0], entries[index][1])
		chip.grows = index == entries.size() - 1
		_chips.add_child(chip)
	_chips.visible = not entries.is_empty()


func _show_panel(image: Texture2D, look: InfiltrationLook, title: String, body: String) -> void:
	_preview.show_texture(image)
	_look_preview.show_look(look)
	_title.text = title
	_title.visible = title != ""
	_detail.text = body
	_detail.visible = body != ""
	_group.visible = false
	_pill.visible = false
	_record.visible = false
	_reward_box.visible = false
	_set_chips([])


func _show_characters() -> void:
	_characters_panel = true
	_set_footer(true)
	_header.set_content(tr("INF_CHARACTER_TITLE"))
	var current: CharacterData = InfiltrationMode.look_character()
	for id in CharacterRoster.IDS:
		var character: CharacterData = CharacterRoster.character(id)
		if Unlocks.is_character_unlocked(character):
			_list.add_item(id, tr(character.name_key))
	_list.add_item(WEAPON_ROW, _weapon_row_text(current))
	_list.add_item(BACK_ROW, tr("MENU_BACK"))
	_focused_character = current.id
	_costume = InfiltrationMode.look_costume(current)
	_blade = InfiltrationMode.look_blade(current)
	_list.select_id(current.id)
	_refresh_character(current)


func _weapon_row_text(character: CharacterData) -> String:
	return tr("OPS_WEAPON_ROW").format({"name": tr(BlasterOpsTraining.weapon_name_key(character, InfiltrationMode.look_weapon()))})


func _weapon_detail(character: CharacterData, weapon_id: StringName) -> String:
	var entry: BlasterOpsWeaponData = BlasterOpsTraining.ARSENAL.weapon(weapon_id)
	if entry == null:
		return tr("OPS_WEAPON_OWN_INFO")
	var tier: BlasterOpsTrainingTier = BlasterOpsTraining.ARSENAL.tier_for(character.id, entry)
	var switching: bool = entry.two_handed or character.weapon.kind != WeaponData.Kind.SINGLE
	var lines: PackedStringArray = [
		tr("OPS_WEAPON_TRAINING").format({"character": tr(character.name_key), "tier": tr(tier.name_key)}),
		tr("OPS_WEAPON_SWITCH_INFO" if switching else "OPS_WEAPON_HYBRID_INFO"),
		tr("OPS_WEAPON_STATS").format({"damage": roundi(entry.blaster.bolt.damage * entry.damage_scale), "shots": maxi(entry.blaster.shot_count, 1), "interval": snappedf(entry.fire_interval * tier.interval_scale, 0.01), "heat": roundi(entry.heat_per_shot * tier.heat_scale * entry.blaster.vigor_multiplier)}),
		"",
		tr("OPS_WEAPON_ARSENAL_INFO"),
	]
	return "\n".join(lines)


func _show_weapons() -> void:
	_weapons_panel = true
	_header.set_content(tr("OPS_WEAPON_TITLE"))
	var character: CharacterData = InfiltrationMode.look_character()
	_list.add_item(OWN_WEAPON, tr(BlasterOpsTraining.weapon_name_key(character, &"")))
	for entry in BlasterOpsTraining.ARSENAL.weapons:
		_list.add_item(entry.blaster.id, tr(entry.blaster.name_key))
	_list.add_item(BACK_ROW, tr("MENU_BACK"))
	var current: StringName = InfiltrationMode.look_weapon()
	_list.select_id(current if BlasterOpsTraining.ARSENAL.weapon(current) != null else OWN_WEAPON)
	_highlight_weapon(_list.current_id())


func _highlight_weapon(id: StringName) -> void:
	if id == BACK_ROW:
		_show_panel(null, null, "", "")
		return
	var character: CharacterData = InfiltrationMode.look_character()
	var key: String = BlasterOpsTraining.weapon_name_key(character, id)
	_show_panel(null, InfiltrationMode.current_look(), tr(key), _weapon_detail(character, id))


func _highlight_character(id: StringName) -> void:
	if id == BACK_ROW:
		_show_panel(null, null, "", "")
		return
	if id == WEAPON_ROW:
		var focused: CharacterData = CharacterRoster.character(_focused_character)
		_show_panel(null, InfiltrationLook.create(focused, _costume, _blade), tr("OPS_WEAPON_TITLE"), _weapon_detail(focused, InfiltrationMode.look_weapon()))
		return
	_focused_character = id
	_costume = 0
	_blade = 0
	_refresh_character(CharacterRoster.character(id))


func _refresh_character(character: CharacterData) -> void:
	var powers: PackedStringArray = []
	var equipment: BlasterOpsLoadout = BlasterOpsTraining.mission_loadout(character)
	for index in equipment.slot_count():
		powers.append(tr(equipment.slot(index).power.name_key))
	var body: String = tr("INF_CHARACTER_COSTUME").format({"name": tr(character.costumes[_costume].name_key)}) + "\n" + tr("INF_CHARACTER_BLADE").format({"name": tr(character.blade_color_keys[_blade])}) + "\n" + tr("OPS_CHARACTER_POWERS").format({"powers": ControlHints.line(powers)}) + "\n\n" + tr("INF_CHARACTER_INFO")
	_show_panel(null, InfiltrationLook.create(character, _costume, _blade), tr(character.name_key), body)


func _adjust(id: StringName, direction: int) -> void:
	if not _characters_panel or id == BACK_ROW or id == WEAPON_ROW:
		return
	var character: CharacterData = CharacterRoster.character(id)
	var count: int = character.costumes.size()
	for step in count:
		_costume = posmod(_costume + direction, count)
		if Unlocks.is_costume_unlocked(character, character.costumes[_costume]):
			break
	_refresh_character(character)


func _cycle_blade(id: StringName) -> void:
	if id == BACK_ROW or id == WEAPON_ROW:
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
	_header.set_content(tr(title_key))
	if _mode is BlasterOpsMode and not won and result.outcome == InfiltrationMissionState.Outcome.PRISONER_DOWN:
		_header.set_content(tr("OPS_PROTECTED_DOWN"))
	_list.add_item(&"retry", tr("RESULT_RETRY"))
	var tutorial: bool = _mode.data is BlasterOpsMissionData and (_mode.data as BlasterOpsMissionData).tutorial
	if won and not tutorial:
		_list.add_item(&"next", tr("INF_NEXT"))
	_list.add_item(&"missions", tr("INF_MISSIONS"))
	if tutorial:
		_show_panel(_mode.data.preview, null, tr(_mode.data.title_key), tr("OPS_TRAINING_DONE" if won else "OPS_TRAINING_RETRY"))
		return
	var lines: PackedStringArray = [tr("INF_TIME").format({"time": ChallengeMode.format_time(result.ticks * Ticks.DELTA)}), tr("INF_APPROACH").format({"approach": tr("INF_DIRECT" if result.alarm_raised else "INF_STEALTH")}), ""]
	if _mode is BlasterOpsMode:
		lines = [tr(BlasterOpsMode.rating_key(result.rating)), tr("INF_TIME").format({"time": ChallengeMode.format_time(result.ticks * Ticks.DELTA)}), tr("OPS_STATISTICS").format({"damage": roundi(result.damage), "accuracy": roundi(100.0 * result.hits / maxi(result.attempts, 1))}), ""]
	for objective in result.objectives:
		lines.append(tr("INF_CHECK").format({"state": tr("INF_DONE" if objective.done else "INF_PENDING"), "objective": tr(objective.key).format({"index": objective.index})}))
	lines.append("")
	lines.append(tr("INF_BONUSES"))
	lines.append(BlasterOpsMode.incursion_bonus_text(result.bonuses) if _mode is BlasterOpsMode else InfiltrationMode.bonus_text(result.bonuses))
	if won and _mode is BlasterOpsMode:
		lines.append(tr("OPS_REWARDS"))
	if not won:
		lines.append(tr("INF_FAILURE_SAVE"))
	_show_panel(_mode.data.preview, null, tr(_mode.data.title_key), "\n".join(lines))


func _choose(id: StringName) -> void:
	if _result:
		match id:
			&"retry":
				_mode.start()
			&"next":
				_mode.next()
			&"missions":
				SceneRouter.change(&"operations", {"mission": _mode.data.id})
	elif _weapons_panel:
		if id != BACK_ROW:
			SaveService.set_infiltration_weapon(&"" if id == OWN_WEAPON else id)
		_leave()
	elif _characters_panel:
		if id == WEAPON_ROW:
			SaveService.set_infiltration_look(_focused_character, _costume, _blade)
			SceneRouter.change(&"operations_characters", {"panel": &"weapons", "mission": _mission})
			return
		if id != BACK_ROW:
			SaveService.set_infiltration_look(id, _costume, _blade)
		_leave()
	elif id == BACK_ROW:
		_leave()
	elif id == WEAPON_ROW:
		SceneRouter.change(&"operations_characters", {"panel": &"weapons", "mission": _mission})
	elif id == CHARACTER_ROW:
		SceneRouter.change(&"operations_characters", {"panel": &"characters", "mission": _mission})
	else:
		_mode.start()


func _exit_tree() -> void:
	InfiltrationBindings.uninstall()


func _leave() -> void:
	if _result:
		SceneRouter.change(&"operations", {"mission": _mode.data.id})
	elif _characters_panel or _weapons_panel:
		SceneRouter.change(&"operations", {"mission": _mission})
	else:
		SceneRouter.change(&"menu", {"group": &"special", "focus": &"operations"})


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_leave()
	elif _characters_panel and event.is_action_pressed(&"menu_variant"):
		get_viewport().set_input_as_handled()
		_cycle_blade(_list.current_id())


func _set_footer(characters: bool) -> void:
	var hints: Array[Dictionary] = [{"keys": PackedStringArray(["↑", "↓"]), "text": tr("HINT_CHANGE")}]
	if characters:
		hints.append({"keys": PackedStringArray(["←", "→"]), "text": tr("OPS_MENU_COSTUME")})
		hints.append({"keys": PackedStringArray([ControlHints.key_label(&"menu_variant")]), "text": tr("INF_CHARACTER_BLADE_HINT")})
	hints.append({"keys": PackedStringArray([ControlHints.key_label(&"ui_accept")]), "text": tr("HINT_CONFIRM")})
	hints.append({"keys": PackedStringArray([ControlHints.key_label(&"ui_cancel")]), "text": tr("HINT_BACK")})
	_footer.set_hints(hints)


func _label(text: String, variation: StringName) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.theme_type_variation = variation
	return label
