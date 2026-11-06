extends Node2D

const CONFIG: BlasterOpsConfig = BlasterOpsTraining.CONFIG
const TRAINING_MAP: InfiltrationMapData = preload("res://data/infiltration/patrol_map.tres")
const MUSIC: MusicData = preload("res://data/audio/duel_music.tres")
const SUSPICION_SOUND: AudioStream = preload("res://assets/audio/infiltration/suspicion.wav")
const ALARM_SOUND: AudioStream = preload("res://assets/audio/infiltration/alarm.wav")
const PALETTE: UiPalette = preload("res://ui/palette.tres")
const MAX_STEPS: int = 5
const HUD_MARGIN: float = 44.0
const HUD_WIDTH: float = 320.0
const HUD_ROW_GAP: int = 6
const HUD_LABEL_WIDTH: float = 86.0
const HUD_BAR_HEIGHT: float = 10.0
const CARD_TOP: float = 24.0
const CHIP_GAP: int = 8
const PROMPT_BOTTOM: float = 150.0
const HINTS_BOTTOM: float = 44.0
const HINTS_SECONDS: float = 12.0
const HINTS_PER_LINE: int = 3
const COUNTED_ACTIONS: int = 20
const HINTS_FADE_SECONDS: float = 2.0
const GUIDE_REFRESH_FRAMES: int = 15
const ABILITY_BOTTOM: float = 40.0
const ABILITY_RESERVE: float = 356.0
const WEAPON_CHIP_BOTTOM: float = 136.0
const TICK_COST_WINDOW: int = 300
const SOUNDS: Dictionary = {
	InfiltrationEvent.Type.SWING_STARTED: &"swing_light",
	InfiltrationEvent.Type.SWING_HIT: &"hit_light",
	InfiltrationEvent.Type.SHOT_FIRED: &"bolt_shot",
	InfiltrationEvent.Type.BOLT_BLOCKED: &"bolt_deflect",
	InfiltrationEvent.Type.BOLT_REFLECTED: &"bolt_reflect",
	InfiltrationEvent.Type.BOLT_HIT: &"bolt_hit",
	InfiltrationEvent.Type.FOOTSTEP: &"step",
}

var sim: BlasterOpsSimulation
var mode: InfiltrationMode
var escort_controller: InfiltrationEscortController
var _card: ObjectiveCard
var _finished: bool = false
var controller: InfiltrationPlayerController
var enemy_controller: InfiltrationEnemyController
var intent: InfiltrationIntent = InfiltrationIntent.new()
var paused: bool = false
var _stage: PixelStage
var _view: BlasterOpsView
var _map_view: BlasterOpsMapView
var _dodge_status: Label
var _camera: Camera2D
var _health: HudBar
var _vigor: HudBar
var _heat: HeatBar
var _heat_row: HBoxContainer
var _heat_label: Label
var _abilities: AbilityBar
var _weapon_chip: HudChip
var _allies_chip: HudChip
var _barrier_chip: HudChip
var _supply_chip: HudChip
var _stance_chip: HudChip
var _prompt: HudChip
var _command_menu: CommandMenu
var _hints_panel: PanelContainer
var _hints_left: float = HINTS_SECONDS + HINTS_FADE_SECONDS
var _shop: SupplyShop
var _last_order: int = 0
var _debug: Label
var _pause_layer: CanvasLayer
var _pause_title: Label
var _pause_list: MenuList
var _hum: AudioStreamPlayer
var _alarm: AudioStreamPlayer
var _notice: AudioStreamPlayer
var _music: Array[AudioStreamPlayer] = []
var _accumulator: float = 0.0
var _guide_navigation: InfiltrationNavigation
var _guide_revision: int = -1
var _tick_total: int = 0
var _tick_peak: int = 0
var _tick_samples: int = 0
var _tick_average: int = 0
var _tick_worst: int = 0
var _guide_age: int = 0
var _guide_text: String = ""
var _guide_text_direction: String = ""
var _guide_target: Vector2 = Vector2.INF
var _guide_tiles: int = -1
var _guide_key: String = ""
var _guide_number: int = 1


func required_resources(_params: Dictionary) -> PackedStringArray:
	return PackedStringArray([CharacterRoster.path(InfiltrationMode.look_character().id)])


func open(params: Dictionary) -> void:
	InfiltrationBindings.install(Settings.blaster_ops_keys, Settings.blaster_ops_buttons)
	controller = InfiltrationPlayerController.new()
	mode = params.get("mode")
	var mission_data: InfiltrationMissionData = mode.data if mode != null else null
	sim = mode.create_simulation() if mode != null else BlasterOpsSimulation.new(CONFIG, params.get("map", TRAINING_MAP), BlasterOpsTraining.equipment(InfiltrationMode.look_character(), 0), mission_data)
	enemy_controller = BlasterOpsMissionController.new(sim.map, sim.targets.size())
	escort_controller = InfiltrationEscortController.new(sim)
	_guide_navigation = InfiltrationNavigation.new(sim.map)
	_stage = PixelStage.new(CONFIG.units_per_pixel)
	_stage.viewport.world_2d = World2D.new()
	add_child(_stage)
	_map_view = BlasterOpsMapView.new()
	_stage.viewport.add_child(_map_view)
	_map_view.attach(sim)
	_view = BlasterOpsView.new()
	_stage.viewport.add_child(_view)
	_view.setup(sim, mode.mission_look() if mode != null else InfiltrationMode.current_look())
	_view.emitter = sim.loadout.integrated
	_view.reduced = Settings.reduced_effects
	_camera = Camera2D.new()
	_camera.zoom = Vector2.ONE * CONFIG.camera_zoom
	add_child(_camera)
	_camera.make_current()
	_stage.rig = _camera
	_build_hud()
	_build_pause()
	_build_shop()
	_hum = AudioStreamPlayer.new()
	_hum.stream = AudioDirector.stream(&"blade_hum")
	_hum.bus = &"Blades"
	_hum.volume_db = CONFIG.hum_db
	add_child(_hum)
	_hum.play()
	_build_audio()
	_update_presentation(1.0)


func _build_hud() -> void:
	var hud: CanvasLayer = CanvasLayer.new()
	hud.layer = 10
	add_child(hud)
	var vitals: PanelContainer = PanelContainer.new()
	vitals.theme_type_variation = &"TacticalHudChip"
	vitals.position = Vector2(HUD_MARGIN, CARD_TOP)
	vitals.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vitals.add_child(_build_vitals())
	hud.add_child(vitals)
	var top: CenterContainer = CenterContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_top = CARD_TOP
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(top)
	_card = ObjectiveCard.new()
	top.add_child(_card)
	hud.add_child(_build_mission_chips())
	var prompt_box: CenterContainer = CenterContainer.new()
	prompt_box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	prompt_box.offset_top = -PROMPT_BOTTOM
	prompt_box.offset_bottom = -PROMPT_BOTTOM
	prompt_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	prompt_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(prompt_box)
	var prompt_column: VBoxContainer = VBoxContainer.new()
	prompt_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_column.add_theme_constant_override(&"separation", CHIP_GAP)
	prompt_box.add_child(prompt_column)
	_command_menu = CommandMenu.new()
	prompt_column.add_child(_command_menu)
	_prompt = HudChip.new()
	_prompt.visible = false
	_prompt.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	prompt_column.add_child(_prompt)
	hud.add_child(_build_hints())
	_abilities = AbilityBar.new()
	_abilities.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_abilities.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_abilities.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_abilities.offset_left = -HUD_MARGIN
	_abilities.offset_right = -HUD_MARGIN
	_abilities.offset_top = -ABILITY_BOTTOM
	_abilities.offset_bottom = -ABILITY_BOTTOM
	hud.add_child(_abilities)
	_setup_abilities()
	_weapon_chip = HudChip.new()
	_weapon_chip.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_weapon_chip.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_weapon_chip.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_weapon_chip.offset_left = -HUD_MARGIN
	_weapon_chip.offset_right = -HUD_MARGIN
	_weapon_chip.offset_top = -WEAPON_CHIP_BOTTOM
	_weapon_chip.offset_bottom = -WEAPON_CHIP_BOTTOM
	hud.add_child(_weapon_chip)
	_debug = _label("", &"DebugLabel")
	_debug.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_debug.offset_left = HUD_MARGIN
	_debug.offset_top = 190.0
	_debug.visible = false
	hud.add_child(_debug)


func _build_hints() -> CenterContainer:
	var box: CenterContainer = CenterContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	box.offset_top = -HINTS_BOTTOM
	box.offset_bottom = -HINTS_BOTTOM
	box.offset_left = ABILITY_RESERVE
	box.offset_right = -ABILITY_RESERVE
	box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hints_panel = PanelContainer.new()
	_hints_panel.theme_type_variation = &"TacticalHudChip"
	_hints_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_hints_panel)
	var label: Label = _label(_hints(), &"TacticalNoteLabel")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hints_panel.add_child(label)
	if mode != null and mode.data is BlasterOpsMissionData and (mode.data as BlasterOpsMissionData).tutorial:
		_hints_left = 0.0
		_hints_panel.visible = false
	return box


func _build_vitals() -> VBoxContainer:
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override(&"separation", HUD_ROW_GAP)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title: Label = _label(tr(mode.data.title_key if mode != null else "INFILTRATION_TRAINING").to_upper(), &"TacticalCaptionLabel")
	column.add_child(title)
	_health = HudBar.new()
	_health.fill_color = PALETTE.text
	column.add_child(_bar_row(tr("OPS_HUD_HEALTH"), _health))
	_vigor = HudBar.new()
	_vigor.fill_color = PALETTE.accent
	column.add_child(_bar_row(tr("OPS_HUD_VIGOR"), _vigor))
	_heat = HeatBar.new()
	_heat.reduced = Settings.reduced_effects
	_heat_row = _bar_row(tr("OPS_HUD_HEAT"), _heat)
	_heat_label = _label("", &"TacticalCaptionLabel")
	_heat_row.add_child(_heat_label)
	column.add_child(_heat_row)
	_dodge_status = _label("", &"TacticalCaptionLabel")
	column.add_child(_dodge_status)
	return column


func _bar_row(caption: String, bar: Control) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label: Label = _label(caption, &"TacticalCaptionLabel")
	label.custom_minimum_size.x = HUD_LABEL_WIDTH
	row.add_child(label)
	bar.custom_minimum_size = Vector2(HUD_WIDTH, HUD_BAR_HEIGHT)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(bar)
	return row


func _build_mission_chips() -> VBoxContainer:
	var column: VBoxContainer = VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	column.grow_vertical = Control.GROW_DIRECTION_BEGIN
	column.offset_left = HUD_MARGIN
	column.offset_right = HUD_MARGIN
	column.offset_top = -ABILITY_BOTTOM
	column.offset_bottom = -ABILITY_BOTTOM
	column.add_theme_constant_override(&"separation", CHIP_GAP)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stance_chip = HudChip.new()
	_allies_chip = HudChip.new()
	_barrier_chip = HudChip.new()
	_supply_chip = HudChip.new()
	for chip in [_stance_chip, _supply_chip, _barrier_chip, _allies_chip]:
		chip.visible = false
		chip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		column.add_child(chip)
	return column


func _label(text: String, variation: StringName) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.theme_type_variation = variation
	return label


func _power_legend() -> String:
	var entries: PackedStringArray = []
	for index in sim.loadout.slot_count():
		entries.append("%s  %s" % [ControlHints.blaster_ops_hud_key(AbilityBar.SUFFIXES[index]), tr(sim.loadout.slot(index).power.name_key)])
	return ControlHints.line(entries)


func _setup_abilities() -> void:
	_abilities.setup(sim.loadout, CONFIG.stealth_power_cooldown_multiplier if sim.stealth_objective() else 1.0)


func _hints() -> String:
	var movement: String = TranslationServer.translate("INFILTRATION_MOVE").format({
		"left": ControlHints.key_label(&"infiltration_left"), "right": ControlHints.key_label(&"infiltration_right"),
		"up": ControlHints.key_label(&"infiltration_up"), "down": ControlHints.key_label(&"infiltration_down"),
	})
	return ControlHints.line(PackedStringArray([
		movement,
		ControlHints.blaster_ops_hud_hint("run"), ControlHints.blaster_ops_hud_hint("sneak"),
		ControlHints.blaster_ops_hud_hint("dodge"),
	])) + "\n" + _wrapped_hints(_combat_hints())


func _wrapped_hints(hints: PackedStringArray) -> String:
	var lines: PackedStringArray = []
	var index: int = 0
	while index < hints.size():
		lines.append(ControlHints.line(hints.slice(index, index + HINTS_PER_LINE)))
		index += HINTS_PER_LINE
	return "
".join(lines)


func _combat_hints() -> PackedStringArray:
	var hints: PackedStringArray = [
		ControlHints.blaster_ops_hud_hint("fire"), ControlHints.blaster_ops_hud_hint("guard"),
		ControlHints.blaster_ops_hud_hint("strike"), ControlHints.blaster_ops_hud_hint("interact"),
	]
	if sim.loadout.switchable and sim.loadout.blaster != null:
		hints.append(ControlHints.blaster_ops_hud_hint("switch_weapon"))
	if sim.mission is BlasterOpsMissionState:
		hints.append(ControlHints.blaster_ops_hud_hint("order_allies"))
	return hints


func _build_pause() -> void:
	_pause_layer = CanvasLayer.new()
	_pause_layer.layer = 30
	add_child(_pause_layer)
	var overlay: ColorRect = ColorRect.new()
	overlay.color = Color(PALETTE.background, 0.9)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_layer.add_child(overlay)
	var column: VBoxContainer = VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	column.grow_horizontal = Control.GROW_DIRECTION_BOTH
	column.grow_vertical = Control.GROW_DIRECTION_BOTH
	column.add_theme_constant_override(&"separation", 38)
	_pause_layer.add_child(column)
	_pause_title = _label(tr("PAUSE_TITLE"), &"ScreenTitleLabel")
	_pause_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_pause_title)
	var legend: Label = _label(_hints() + "\n" + _power_legend(), &"InfiltrationLabel")
	legend.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(legend)
	var center: CenterContainer = CenterContainer.new()
	column.add_child(center)
	_pause_list = MenuList.new()
	center.add_child(_pause_list)
	_pause_list.chosen.connect(_on_pause_chosen)
	_set_paused(false)


func _build_shop() -> void:
	_shop = SupplyShop.new()
	add_child(_shop)
	_shop.purchase_requested.connect(_on_shop_purchase)
	_shop.closed.connect(_close_shop)


func _open_shop() -> void:
	paused = true
	_accumulator = 0.0
	_view.animate = false
	controller.discard_pending()
	_shop.open(sim)


func _close_shop() -> void:
	paused = false
	_accumulator = 0.0
	_view.animate = true
	controller.discard_pending()
	_shop.close()


func _on_shop_purchase(offer: int) -> void:
	controller.queue_purchase(offer)
	controller.produce(sim, intent)
	step_once(intent)
	AudioDirector.play_ui(&"ui_confirm")
	_shop.purchased(offer)


func _process(delta: float) -> void:
	if sim == null:
		return
	if not paused and not _finished and sim.player.health > 0.0:
		_accumulator += delta
		var steps: int = 0
		while _accumulator >= Ticks.DELTA and steps < MAX_STEPS:
			_accumulator -= Ticks.DELTA
			controller.track_pointer(get_global_mouse_position())
			controller.produce(sim, intent)
			step_once(intent)
			steps += 1
			if _finished:
				break
			if sim.player.health <= 0.0:
				_set_paused(true)
				break
		if steps == MAX_STEPS:
			_accumulator = 0.0
	elif _finished:
		_step_aftermath(delta)
	_update_presentation(_accumulator / Ticks.DELTA)


func step_once(command: InfiltrationIntent) -> void:
	if _finished:
		return
	var started: int = Time.get_ticks_usec()
	sim.step(command, enemy_controller.produce_all(sim), escort_controller.produce_all(sim))
	_record_tick_cost(Time.get_ticks_usec() - started)
	_present_events()
	if mode != null and sim.mission.outcome != InfiltrationMissionState.Outcome.ACTIVE:
		_finished = true
		mode.finish(sim)
		if not (mode is BlasterOpsMode and (mode as BlasterOpsMode).external):
			_begin_closure()


func _step_aftermath(delta: float) -> void:
	_accumulator += delta
	var steps: int = 0
	while _accumulator >= Ticks.DELTA and steps < MAX_STEPS:
		_accumulator -= Ticks.DELTA
		sim.step_aftermath(enemy_controller.produce_all(sim))
		_present_events()
		steps += 1
	if steps == MAX_STEPS:
		_accumulator = 0.0


func _present_events() -> void:
	for index in sim.event_count:
		var event: InfiltrationEvent = sim.events[index]
		_view.on_event(event)
		if event.type == InfiltrationEvent.Type.STAGE_COMPLETED:
			_card.flash(tr("OPS_HUD_STAGE_DONE"), Settings.reduced_effects)
		if event.type in [InfiltrationEvent.Type.WAVE_STARTED, InfiltrationEvent.Type.PHASE_CHANGED, InfiltrationEvent.Type.BARRIER_PLACED, InfiltrationEvent.Type.EXTRACTION_OPENED, InfiltrationEvent.Type.STAGE_COMPLETED]:
			AudioDirector.play_ui(&"ui_confirm")
		if BlasterOpsAudio.SOUNDS.has(event.type) and not SOUNDS.has(event.type):
			AudioDirector.play(BlasterOpsAudio.SOUNDS[event.type], event.position, CONFIG.effects_db)
		elif event.type == InfiltrationEvent.Type.POWER_RELEASED:
			AudioDirector.play(BlasterOpsAudio.POWER_SOUNDS.get(int(event.amount), &"power_cast"), event.position, CONFIG.effects_db)
		if event.type == InfiltrationEvent.Type.WEAPON_SWITCHED:
			AudioDirector.play(&"extinguish" if event.target == 0 else &"ignition", event.position, CONFIG.effects_db)
		if event.type == InfiltrationEvent.Type.AWARENESS_CHANGED and event.amount > 0.0:
			_notice.play()
		elif event.type == InfiltrationEvent.Type.TAKEDOWN_LANDED:
			AudioDirector.play(&"hit_light", event.position, CONFIG.effects_db)
		elif event.type == InfiltrationEvent.Type.INFORMATION_COPIED or event.type == InfiltrationEvent.Type.PRISONER_RECRUITED:
			AudioDirector.play_ui(&"ui_confirm")
		if SOUNDS.has(event.type):
			var volume: float = CONFIG.effects_db
			if event.type == InfiltrationEvent.Type.FOOTSTEP:
				volume = CONFIG.footstep_db - (8.0 if int(event.amount) == InfiltrationActor.Locomotion.SNEAK else 0.0)
			AudioDirector.play(SOUNDS[event.type], event.position, volume)


func _begin_closure() -> void:
	controller.discard_pending()
	if is_instance_valid(_alarm):
		_alarm.stop()
	AudioDirector.play_ui(&"ui_confirm")
	var banner: MissionEndBanner = MissionEndBanner.new()
	add_child(banner)
	banner.closed.connect(_show_result)
	var won: bool = sim.mission.outcome == InfiltrationMissionState.Outcome.COMPLETED
	banner.present(won, _closure_detail(won))


func _closure_detail(won: bool) -> String:
	if mode is BlasterOpsMode:
		return tr(BlasterOpsMode.rating_key(mode.result.rating)) if won else tr("OPS_PROTECTED_DOWN" if sim.mission.outcome == InfiltrationMissionState.Outcome.PRISONER_DOWN else "INF_END_PLAYER")
	if not won:
		return tr("INF_END_PRISONER" if sim.mission.outcome == InfiltrationMissionState.Outcome.PRISONER_DOWN else "INF_END_PLAYER")
	var time: String = tr("INF_TIME").format({"time": ChallengeMode.format_time(sim.mission.finished_tick * Ticks.DELTA)})
	if sim.prisoners.is_empty():
		return time
	return tr("INF_END_RESCUED").format({"count": sim.mission.rescued(), "total": sim.prisoners.size()}) + ControlHints.SEPARATOR + time


func _show_result() -> void:
	SceneRouter.change(&"operations_result", {"mode": mode, "result": true})


func _update_presentation(alpha: float) -> void:
	if paused:
		alpha = 1.0
	_view.alpha = alpha
	var half: Vector2 = get_viewport_rect().size / CONFIG.camera_zoom * 0.5
	var desired: Vector2 = sim.player.previous.lerp(sim.player.position, alpha)
	_camera.position = desired.clamp(half, sim.map.world_size() - half)
	_view.view_rect = Rect2(_camera.position - half, half * 2.0)
	_health.ratio = sim.player.health / CONFIG.health
	_health.ghost_ratio = _health.ratio
	_health.fill_color = PALETTE.danger if _health.ratio < 0.25 else PALETTE.text
	_health.queue_redraw()
	_vigor.ratio = sim.player.vigor / CONFIG.vigor
	_vigor.ghost_ratio = _vigor.ratio
	_vigor.queue_redraw()
	_dodge_status.text = tr("OPS_HUD_DODGE").format({"time": _cooldown(sim.state.dodge_cooldown)}) if sim.state.dodge_cooldown > 0 else ""
	_abilities.show_state(sim.state)
	_update_heat()
	_update_weapon()
	_update_chips()
	_update_hints(get_process_delta_time())
	_card.tick(get_process_delta_time())
	if sim.mission is BlasterOpsMissionState:
		_update_incursion_hud()
	else:
		_update_security_hud()
	_update_audio()
	if _view.debug:
		var player: InfiltrationActor = sim.player
		_debug.text = "FPS %d  tick %d\npos %s  velocity %s\naim %s  guard %s  parry %d / lockout %d\nswing %d  health %.0f  vigor %.0f  dropped %d" % [
			Engine.get_frames_per_second(), sim.tick, str(player.position), str(player.velocity), str(player.aim), player.guard,
			player.parry_age, player.parry_cooldown, player.swing_tick, player.health, player.vigor, sim.dropped_events,
		]
		_debug.text += "\nalarm %s  reinforcements %d  tick %d us avg / %d us max  active %d" % [sim.alarm_active(), sim.reinforcement_ticks, _tick_average, _tick_worst, _active_enemies()]
		_debug.text += "\nheat %.1f  burst %d / %d  dodge %d / %d  power %d slot %d cooldowns %d %d %d  channel %d  absorb %d  heal %d  boost %d  area %d" % [sim.state.heat, sim.state.burst_left, sim.state.burst_ticks, sim.state.dodge_age, sim.state.dodge_cooldown, sim.state.power_ticks, sim.state.cast_slot, sim.state.power_cooldown, sim.state.power_cooldown_2, sim.state.power_cooldown_3, sim.state.channel_ticks, sim.state.absorb_ticks, sim.state.heal_ticks, sim.state.boost_ticks, sim.state.area_ticks]
		if sim.mission is BlasterOpsMissionState:
			var progress: BlasterOpsMissionState = sim.mission as BlasterOpsMissionState
			_debug.text += "\nwave %d prep %d phase %d damage %.1f hits %d/%d barriers %d" % [progress.wave_index, progress.intermission_ticks, progress.phase_index, progress.damage_taken, progress.hits, progress.attempts, progress.barriers_placed]
			if progress.definition.tutorial:
				_debug.text += "\ntraining step %d progress %d performed %d skipped [%s]" % [progress.stage_index + 1, progress.action_progress, progress.performed_actions, progress.skip_report()]
		if sim.mission != null:
			_debug.text += "\nmission %s  alarm history %s  takedowns %d  copied %s  recruited %s  extracted %s" % [InfiltrationMissionState.Outcome.keys()[sim.mission.outcome], sim.mission.alarm_raised, sim.mission.takedowns, sim.mission.copied, sim.mission.recruited, sim.mission.extracted]
		for index in range(sim.map.targets.size(), sim.targets.size()):
			var actor: InfiltrationActor = sim.targets[index]
			_debug.text += "\n%d %s %.3f  %s  waypoint %d" % [index + 1, InfiltrationActor.Awareness.keys()[actor.awareness], actor.suspicion, InfiltrationActor.Decision.keys()[actor.decision], actor.waypoint]


func _record_tick_cost(microseconds: int) -> void:
	_tick_total += microseconds
	_tick_peak = maxi(_tick_peak, microseconds)
	_tick_samples += 1
	if _tick_samples < TICK_COST_WINDOW:
		return
	_tick_average = _tick_total / _tick_samples
	_tick_worst = _tick_peak
	if _view.debug:
		print("ops_tick_us avg=%d max=%d active=%d" % [_tick_average, _tick_worst, _active_enemies()])
	_tick_total = 0
	_tick_peak = 0
	_tick_samples = 0


func _active_enemies() -> int:
	var count: int = 0
	for actor in sim.targets:
		count += int(actor.health > 0.0)
	return count


func _update_weapon() -> void:
	var name_key: String = sim.loadout.blaster.name_key if sim.loadout.blaster != null else "OPS_WEAPON_BLADE"
	var text: String = tr(name_key)
	if sim.loadout.integrated:
		text = tr("OPS_WEAPON_OWN_EMITTER")
	var switchable: bool = sim.loadout.switchable and sim.loadout.blaster != null
	if switchable:
		var mode_key: String = "OPS_MODE_SWITCHING" if sim.state.switch_ticks > 0 else "OPS_MODE_BLADE" if sim.state.blade_drawn else "OPS_MODE_RANGED"
		text += ControlHints.SEPARATOR + tr(mode_key)
	_weapon_chip.show_text(text, ControlHints.blaster_ops_hud_key("switch_weapon") if switchable else "")


func _update_heat() -> void:
	var armed: bool = sim.loadout.blaster != null
	_heat_row.visible = armed
	if not armed:
		return
	_heat.show_heat(sim, CONFIG)
	_heat_label.text = tr(HeatBar.label_key(sim.state)) if _heat.level != HeatBar.Level.COOL else ""
	_heat_label.modulate = _heat.fill_color


func _cooldown(ticks: int) -> String:
	return tr("BOPS_READY") if ticks == 0 else tr("BOPS_SECONDS").format({"seconds": snappedf(ticks * Ticks.DELTA, 0.1)})


func _update_chips() -> void:
	var stance: int = controller.stance()
	_stance_chip.show_text("" if stance == 0 else tr("BOPS_STANCE_RUN" if stance == InfiltrationIntent.RUN else "BOPS_STANCE_SNEAK"))
	var progress: BlasterOpsMissionState = sim.mission as BlasterOpsMissionState
	if progress == null:
		return
	var allies: int = progress.living_allies(sim)
	var order_text: String = tr(["OPS_ORDER_FOLLOW", "OPS_ORDER_HOLD", "OPS_ORDER_GUARD"][progress.ally_order])
	_allies_chip.show_text(tr("OPS_HUD_ALLIES").format({"count": allies, "order": order_text}) if allies > 0 else "", ControlHints.blaster_ops_hud_key("order_allies"))
	_allies_chip.set_tint(PALETTE.menu_blade_b if progress.ally_order != BlasterOpsMissionState.AllyOrder.FOLLOW else PALETTE.text)
	if progress.ally_order != _last_order:
		_last_order = progress.ally_order
		AudioDirector.play_ui(&"ui_confirm")
	_view.order_point = progress.order_point(sim) if allies > 0 else Vector2.INF
	_command_menu.visible = false
	if allies > 0 and controller.command_menu_open():
		_command_menu.show_orders(progress.ally_order, progress.guard_point(sim) != Vector2.INF)
	var barriers: int = progress.barrier_charges + progress.heavy_barrier_charges
	_barrier_chip.show_text(tr("OPS_HUD_BARRIERS").format({"count": barriers}) if barriers > 0 else "", ControlHints.blaster_ops_hud_key("interact") if progress.can_deploy() else "")
	_supply_chip.show_text(tr("OPS_HUD_SUPPLIES").format({"count": progress.supplies}) if progress.has_supplies() else "")


func _update_hints(delta: float) -> void:
	if _hints_left <= 0.0:
		return
	_hints_left = maxf(_hints_left - delta, 0.0)
	_hints_panel.modulate.a = clampf(_hints_left / HINTS_FADE_SECONDS, 0.0, 1.0)
	_hints_panel.visible = _hints_left > 0.0


func _restart_hints() -> void:
	if mode != null and mode.data is BlasterOpsMissionData and (mode.data as BlasterOpsMissionData).tutorial:
		return
	_hints_left = HINTS_SECONDS + HINTS_FADE_SECONDS
	_hints_panel.visible = true
	_hints_panel.modulate.a = 1.0


func _update_incursion_hud() -> void:
	var progress: BlasterOpsMissionState = sim.mission as BlasterOpsMissionState
	if _guide_revision != sim.cover_revision:
		_guide_navigation.invalidate()
		_guide_revision = sim.cover_revision
	var data: BlasterOpsMissionData = progress.definition
	var time: String = ChallengeMode.format_time(sim.tick * Ticks.DELTA)
	var stage: BlasterOpsStageData = progress.current_stage()
	var point: Vector2 = data.extraction if progress.waves_finished else progress.objective_point(sim)
	var guide: String = _incursion_guide(point)
	_view.objective_point = point
	if progress.waves_finished:
		_card.show_objective(tr("OPS_HUD_EXTRACT"), tr("OPS_HUD_EXTRACT_TEXT"), -1.0, guide, time)
	elif stage != null:
		var eyebrow: String = tr("OPS_HUD_TRAINING_STEP" if data.tutorial else "OPS_HUD_STAGE").format({"index": progress.stage_index + 1, "total": data.stages.size()})
		var measure: Dictionary = _stage_measure(progress, stage)
		var detail: String = ControlHints.line(_detail_parts(measure.text, guide))
		_card.show_objective(eyebrow, _stage_title(stage), measure.ratio, detail, time)
	else:
		_card.show_objective(tr("OPS_MENU_INCURSION"), tr("OPS_KIND_" + str(data.kind)), -1.0, guide, time)
	_show_prompt(_incursion_prompt(progress))


func _stage_title(stage: BlasterOpsStageData) -> String:
	if stage.hint_actions.is_empty():
		return tr(stage.title_key)
	var keys: Array[String] = []
	for suffix in stage.hint_actions:
		keys.append(ControlHints.blaster_ops_hud_key(suffix))
	return tr(stage.title_key).format(keys)


func _show_prompt(entry: Array) -> void:
	_prompt.show_text(entry[0], entry[1])


func _detail_parts(first: String, second: String) -> PackedStringArray:
	var parts: PackedStringArray = []
	for part in [first, second]:
		if part != "":
			parts.append(part)
	return parts


func _stage_measure(progress: BlasterOpsMissionState, stage: BlasterOpsStageData) -> Dictionary:
	if progress.intermission_ticks > 0 and progress.definition.tutorial:
		return {"ratio": 0.0, "text": ""}
	if progress.intermission_ticks > 0:
		return {"ratio": -1.0, "text": tr("OPS_HUD_PREPARE").format({"time": ceili(progress.intermission_ticks * Ticks.DELTA)})}
	var data: BlasterOpsMissionData = progress.definition
	match stage.objective:
		BlasterOpsStageData.Objective.ACTION:
			var text: String = "%d / %d" % [mini(progress.action_progress, stage.action_count), stage.action_count] if stage.action_count <= COUNTED_ACTIONS else ""
			if stage.action == BlasterOpsStageData.Action.FIRE and sim.state.blade_drawn and sim.loadout.switchable:
				text = tr("OPS_HUD_BACK_TO_GUN").format({"key": ControlHints.blaster_ops_hud_key("switch_weapon")})
			return {"ratio": float(progress.action_progress) / stage.action_count, "text": text}
		BlasterOpsStageData.Objective.HOLD:
			var left: int = maxi(ceili(stage.hold_seconds - progress.hold_ticks * Ticks.DELTA), 0)
			var inside: bool = stage.zone_radius <= 0.0 or sim.player.position.distance_to(stage.zone) <= stage.zone_radius
			return {"ratio": progress.hold_ticks * Ticks.DELTA / stage.hold_seconds, "text": tr("OPS_HUD_HOLD" if inside else "OPS_HUD_HOLD_OUTSIDE").format({"time": left})}
		BlasterOpsStageData.Objective.DESTROY:
			var alive: int = 0
			for target in stage.targets:
				alive += int(not sim.targets[target].spawned or sim.targets[target].health > 0.0)
			return {"ratio": 1.0 - float(alive) / maxi(stage.targets.size(), 1), "text": tr("OPS_HUD_TARGETS").format({"left": alive, "total": stage.targets.size()})}
		BlasterOpsStageData.Objective.INTERACT:
			var pending: int = 0
			for terminal in stage.terminals:
				pending += int(progress.copied[terminal] == 0)
			return {"ratio": 1.0 - float(pending) / maxi(stage.terminals.size(), 1), "text": tr("OPS_HUD_TERMINALS").format({"left": pending, "total": stage.terminals.size()})}
		BlasterOpsStageData.Objective.ESCORT:
			var protected: InfiltrationActor = sim.prisoners[data.protected_index]
			return {"ratio": protected.health / data.protected_health, "text": tr("OPS_HUD_PROTECTED").format({"health": roundi(protected.health), "total": roundi(data.protected_health)})}
		BlasterOpsStageData.Objective.BOSS:
			var boss: InfiltrationActor = sim.targets[data.phase_target]
			if boss.spawned:
				return {"ratio": boss.health / progress.phase_health, "text": tr(data.phases[progress.phase_index].title_key)}
		BlasterOpsStageData.Objective.REACH:
			return {"ratio": -1.0, "text": ""}
	return {"ratio": -1.0, "text": tr("OPS_HUD_ENEMIES").format({"left": progress.enemies_left(sim)}) if progress.enemies_left(sim) > 0 else ""}


func _incursion_prompt(progress: BlasterOpsMissionState) -> Array:
	var interact: String = ControlHints.key_label(&"infiltration_interact")
	if sim.takedown_target() >= 0:
		return [tr("INFILTRATION_TAKEDOWN"), ControlHints.key_label(&"infiltration_takedown")]
	if sim.nearby_panel() >= 0:
		return [tr("INFILTRATION_DISABLE"), interact]
	var object: int = progress.nearby_object(sim)
	if object >= 0:
		return [tr("INF_COPY" if object < progress.definition.terminals.size() else "INF_RECRUIT"), interact]
	if progress.nearby_terminal(sim) >= 0:
		return [tr("OPS_SUPPLY_OPEN"), interact]
	return ["", ""]


func _incursion_guide(point: Vector2) -> String:
	if point == Vector2.INF:
		_guide_text = ""
		return ""
	_guide_age = (_guide_age + 1) % GUIDE_REFRESH_FRAMES
	if _guide_age != 1 and _guide_text != "":
		return _guide_text
	var offset: Vector2 = _guide_navigation.direction(sim.player.position, point, CONFIG.body_radius)
	var direction: String = "←" if offset.x < 0.0 else "→"
	if absf(offset.y) > absf(offset.x):
		direction = "↑" if offset.y < 0.0 else "↓"
	var tiles: int = _guide_navigation.path_tiles(sim.player.position, point)
	_guide_text = tr("OPS_STAGE_GUIDE").format({"direction": direction, "distance": roundi(maxi(tiles, 0) * sim.map.tile_size)})
	return _guide_text


func _unhandled_input(event: InputEvent) -> void:
	if sim == null or _finished:
		return
	if _shop.visible:
		if event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"p1_pause"):
			_close_shop()
			get_viewport().set_input_as_handled()
		return
	if not paused and event.is_action_pressed(&"infiltration_interact") and sim.mission is BlasterOpsMissionState and (sim.mission as BlasterOpsMissionState).nearby_terminal(sim) >= 0:
		_open_shop()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(&"debug_overlay"):
		_view.debug = not _view.debug
		_debug.visible = _view.debug
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"p1_pause") or (paused and event.is_action_pressed(&"ui_cancel")):
		if sim.player.health > 0.0:
			_set_paused(not paused)
		get_viewport().set_input_as_handled()
	elif not paused:
		if event is InputEventMouseMotion:
			controller.point_at(get_global_mouse_position())
		controller.handle_input(event)


func _set_paused(value: bool) -> void:
	paused = value
	_accumulator = 0.0
	_view.animate = not value
	_pause_layer.visible = value
	_pause_list.set_process_unhandled_input(value)
	controller.discard_pending()
	if is_instance_valid(_hum):
		_hum.stream_paused = value
	if is_instance_valid(_alarm):
		if value:
			_alarm.stop()
		_notice.stream_paused = value
	for music in _music:
		music.stream_paused = value
	if not value:
		return
	_pause_title.text = tr("PAUSE_TITLE" if sim.player.health > 0.0 else "INFILTRATION_DEFEATED")
	_pause_list.clear_items()
	if sim.player.health > 0.0:
		_pause_list.add_item(&"continue", tr("PAUSE_CONTINUE"))
	_pause_list.add_item(&"restart", tr("RESULT_RETRY" if mode != null else "INFILTRATION_RESTART"))
	_pause_list.add_item(&"back", tr("INF_MISSIONS" if mode != null else "INFILTRATION_BACK"))


func _on_pause_chosen(option: StringName) -> void:
	match option:
		&"continue":
			_set_paused(false)
		&"restart":
			sim = mode.create_simulation() if mode != null else BlasterOpsSimulation.new(CONFIG, sim.arena.source, sim.loadout)
			enemy_controller = BlasterOpsMissionController.new(sim.map, sim.targets.size())
			escort_controller = InfiltrationEscortController.new(sim)
			_guide_navigation = InfiltrationNavigation.new(sim.map)
			_guide_text = ""
			_last_order = 0
			_restart_hints()
			controller.reset_stance()
			_setup_abilities()
			_map_view.attach(sim)
			_view.setup(sim, mode.mission_look() if mode != null else InfiltrationMode.current_look())
			_set_paused(false)
		&"back":
			if mode is BlasterOpsMode and (mode as BlasterOpsMode).external:
				(mode as BlasterOpsMode).exit_requested.emit()
				return
			if mode != null:
				SceneRouter.change(&"operations", {"mission": mode.data.id})
			else:
				SceneRouter.change(&"menu", {"group": &"special", "focus": &"operations"})


func _exit_tree() -> void:
	InfiltrationBindings.uninstall()
	if is_instance_valid(_hum):
		_hum.stop()
	for music in _music:
		music.stop()
	if is_instance_valid(_alarm):
		_alarm.stop()
		_notice.stop()


func _build_audio() -> void:
	_alarm = AudioStreamPlayer.new()
	_alarm.stream = ALARM_SOUND
	_alarm.bus = &"Effects"
	_alarm.volume_db = CONFIG.alarm_db
	add_child(_alarm)
	_notice = AudioStreamPlayer.new()
	_notice.stream = SUSPICION_SOUND
	_notice.bus = &"Effects"
	_notice.volume_db = CONFIG.effects_db
	add_child(_notice)
	for stream in [MUSIC.base, MUSIC.percussion, MUSIC.tension]:
		var music: AudioStreamPlayer = AudioStreamPlayer.new()
		music.stream = stream
		music.bus = &"Music"
		music.volume_db = CONFIG.silent_db
		add_child(music)
		_music.append(music)
	for music in _music:
		music.play()


func _update_audio() -> void:
	if paused:
		return
	var alarm: bool = sim.alarm_active()
	if alarm and not _alarm.playing:
		_alarm.play()
	elif not alarm:
		_alarm.stop()
	var alerted: bool = false
	for actor in sim.targets:
		if actor.health > 0.0 and actor.awareness == InfiltrationActor.Awareness.ALERTED:
			alerted = true
	for index in _music.size():
		_music[index].volume_db = CONFIG.music_db if index == 0 else (CONFIG.music_db if alarm or (alerted and index == 1) else CONFIG.silent_db)


func _update_security_hud() -> void:
	var disabled: bool = not sim.panels.is_empty()
	for panel in sim.panels:
		disabled = disabled and panel.disabled
	var alarm: bool = sim.alarm_active()
	var eyebrow: String
	if mode != null:
		eyebrow = tr("INF_SECURITY_ACTIVE" if alarm else "INF_SECURITY_DISABLED" if disabled else "INF_SECURITY_READY")
	else:
		eyebrow = tr("INFILTRATION_ALARM_ACTIVE" if alarm else "INFILTRATION_ALARM_DISABLED" if disabled else "INFILTRATION_STATUS")
	var tone: ObjectiveCard.Tone = ObjectiveCard.Tone.DANGER if alarm else ObjectiveCard.Tone.NORMAL
	if sim.mission == null:
		_card.show_objective(eyebrow, tr("INFILTRATION_OBJECTIVE"), -1.0, "", "", tone)
		_show_prompt(_security_prompt())
		return
	var guide: String = _mission_guide()
	var parts: PackedStringArray = [_guide_text_direction, tr("OPS_HUD_OBJECTIVES").format({"done": sim.mission.completed_objectives(sim), "total": mode.data.objective_count()})]
	if not sim.prisoners.is_empty():
		parts.append(_escort_guide())
	var ratio: float = float(sim.mission.completed_objectives(sim)) / maxi(mode.data.objective_count(), 1)
	_card.show_objective(eyebrow, guide, ratio, ControlHints.line(parts), ChallengeMode.format_time(sim.tick * Ticks.DELTA), tone)
	_view.objective_point = _guide_target
	_show_prompt(_security_prompt())


func _security_prompt() -> Array:
	var interact: String = ControlHints.key_label(&"infiltration_interact")
	if sim.takedown_target() >= 0:
		return [tr("INFILTRATION_TAKEDOWN"), ControlHints.key_label(&"infiltration_takedown")]
	if sim.nearby_panel() >= 0:
		return [tr("INFILTRATION_DISABLE"), interact]
	if sim.mission != null:
		if sim.mission.locked_prisoner_nearby(sim):
			return [tr("INF_LOCKED"), ""]
		var object: int = sim.mission.nearby_object(sim)
		if object >= 0:
			return [tr("INF_COPY" if object < mode.data.terminals.size() else "INF_RECRUIT"), interact]
	return ["", ""]


func _escort_guide() -> String:
	var following: int = 0
	for index in sim.prisoners.size():
		following += int(sim.prisoners[index].health > 0.0 and sim.mission.recruited[index] != 0 and sim.mission.extracted[index] == 0)
	return tr("OPS_HUD_RESCUED").format({"safe": sim.mission.rescued(), "minimum": mode.data.required_prisoners(), "following": following})


func _mission_guide() -> String:
	_guide_age = (_guide_age + 1) % GUIDE_REFRESH_FRAMES
	if _guide_age != 1 and _guide_text != "":
		return _guide_text
	_guide_target = Vector2.INF
	_guide_tiles = InfiltrationNavigation.NONE
	_guide_key = "INF_OBJECTIVE_EXIT"
	_guide_number = 1
	if mode.data.disable_alarms:
		for index in sim.panels.size():
			if not sim.panels[index].disabled:
				_consider_objective(sim.map.panels[index].position, "INF_OBJECTIVE_PANEL", index + 1)
	for index in sim.mission.copied.size():
		if sim.mission.copied[index] == 0:
			_consider_objective(mode.data.terminals[index], "INF_OBJECTIVE_TERMINAL", index + 1)
	if not sim.mission.prisoners_locked(sim):
		for index in sim.prisoners.size():
			if sim.mission.recruited[index] == 0 and sim.prisoners[index].health > 0.0:
				_consider_objective(sim.prisoners[index].position, "INF_OBJECTIVE_PRISONER", index + 1)
	if _guide_target == Vector2.INF:
		_consider_objective(mode.data.extraction, "INF_OBJECTIVE_EXIT", 1)
	var offset: Vector2 = _guide_navigation.direction(sim.player.position, _guide_target, CONFIG.body_radius)
	var direction: String = "←" if offset.x < 0.0 else "→"
	if absf(offset.y) > absf(offset.x):
		direction = "↑" if offset.y < 0.0 else "↓"
	_guide_text_direction = tr("OPS_STAGE_GUIDE").format({"direction": direction, "distance": roundi(maxi(_guide_tiles, 0) * sim.map.tile_size)})
	_guide_text = tr(_guide_key).format({"index": _guide_number})
	return _guide_text


func _consider_objective(point: Vector2, key: String, number: int) -> void:
	var tiles: int = _guide_navigation.path_tiles(sim.player.position, point)
	if tiles == InfiltrationNavigation.NONE:
		return
	if _guide_tiles == InfiltrationNavigation.NONE or tiles < _guide_tiles:
		_guide_tiles = tiles
		_guide_target = point
		_guide_key = key
		_guide_number = number
