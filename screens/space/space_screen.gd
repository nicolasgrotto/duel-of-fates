extends Node2D

const END_REASONS: Dictionary = {SpaceMissionState.Outcome.PLAYER_DOWN: "SPACE_END_PLAYER", SpaceMissionState.Outcome.ALLY_DOWN: "SPACE_ALLY_DOWN", SpaceMissionState.Outcome.TIMEOUT: "SPACE_TIMEOUT"}
const CONFIG: SpaceConfig = preload("res://data/balance/space_config.tres")
const PALETTE: UiPalette = preload("res://ui/palette.tres")
const MAX_STEPS: int = 5
const HUD_MARGIN: float = 44.0
const HUD_WIDTH: float = 320.0
const HUD_LABEL_WIDTH: float = 86.0
const HUD_BAR_HEIGHT: float = 10.0
const HUD_ROW_GAP: int = 6
const CARD_TOP: float = 24.0
const CHIP_GAP: int = 8
const CHIP_BOTTOM: float = 40.0
const HINTS_BOTTOM: float = 44.0
const HINTS_RESERVE: float = 356.0
const HINTS_SECONDS: float = 12.0
const HINTS_FADE_SECONDS: float = 2.0
const FACING_AHEAD: float = 45.0
const FACING_ASIDE: float = 135.0

var sim: SpaceSimulation
var controller: SpacePlayerController
var mode: SpaceMode
var enemy_controller: SpaceEnemyController
var finished: bool = false
var _idle_intent: SpaceIntent = SpaceIntent.new()
var intent: SpaceIntent = SpaceIntent.new()
var paused: bool = false
var _stage: PixelStage
var _camera: Camera2D
var _backdrop: SpaceBackdrop
var _view: SpaceView
var _audio: SpaceAudio
var _hull: HudBar
var _shield: HudBar
var _card: ObjectiveCard
var _boost_chip: HudChip
var _missile_chip: HudChip
var _hints_panel: PanelContainer
var _hints_left: float = HINTS_SECONDS + HINTS_FADE_SECONDS
var _debug: Label
var _pause_layer: CanvasLayer
var _pause_title: Label
var _pause_list: MenuList
var _accumulator: float = 0.0
var _refusal_left: float = 0.0
var _refusal_key: String = ""


func _ready() -> void:
	_open_default.call_deferred()


func _open_default() -> void:
	if sim == null:
		open({"mode": SpaceMode.new(SpaceMode.MISSIONS[0], SaveService.space.loadout())})


func open(params: Dictionary) -> void:
	if sim != null:
		return
	SpaceBindings.install()
	controller = SpacePlayerController.new()
	mode = params.mode
	sim = mode.create_simulation()
	enemy_controller = SpaceEnemyController.new(sim.ships.size())
	_stage = PixelStage.new(CONFIG.units_per_pixel)
	_stage.viewport.world_2d = World2D.new()
	add_child(_stage)
	_backdrop = SpaceBackdrop.new()
	_backdrop.setup(CONFIG, sim.arena)
	_stage.viewport.add_child(_backdrop)
	_view = SpaceView.new()
	_stage.viewport.add_child(_view)
	_view.setup(sim)
	_view.reduced = Settings.reduced_effects
	_camera = Camera2D.new()
	_camera.zoom = Vector2.ONE * CONFIG.camera_zoom
	add_child(_camera)
	_camera.make_current()
	_stage.rig = _camera
	_audio = SpaceAudio.new()
	add_child(_audio)
	_audio.setup(CONFIG)
	_build_hud()
	_build_pause()
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
	hud.add_child(_build_weapon_chips())
	hud.add_child(_build_hints())
	_debug = _label("", &"DebugLabel")
	_debug.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_debug.offset_left = HUD_MARGIN
	_debug.offset_top = 200.0
	_debug.visible = false
	hud.add_child(_debug)


func _build_vitals() -> VBoxContainer:
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override(&"separation", HUD_ROW_GAP)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_label(tr(mode.data.title_key).to_upper(), &"TacticalCaptionLabel"))
	_hull = HudBar.new()
	_hull.fill_color = PALETTE.text
	column.add_child(_bar_row(tr("SPACE_HULL"), _hull))
	_shield = HudBar.new()
	_shield.fill_color = PALETTE.menu_blade_a
	column.add_child(_bar_row(tr("SPACE_SHIELD"), _shield))
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


func _build_weapon_chips() -> VBoxContainer:
	var column: VBoxContainer = VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	column.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	column.grow_vertical = Control.GROW_DIRECTION_BEGIN
	column.offset_left = -HUD_MARGIN
	column.offset_right = -HUD_MARGIN
	column.offset_top = -CHIP_BOTTOM
	column.offset_bottom = -CHIP_BOTTOM
	column.add_theme_constant_override(&"separation", CHIP_GAP)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boost_chip = HudChip.new()
	_boost_chip.size_flags_horizontal = Control.SIZE_SHRINK_END
	column.add_child(_boost_chip)
	_missile_chip = HudChip.new()
	_missile_chip.size_flags_horizontal = Control.SIZE_SHRINK_END
	column.add_child(_missile_chip)
	return column


func _build_hints() -> CenterContainer:
	var box: CenterContainer = CenterContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	box.offset_top = -HINTS_BOTTOM
	box.offset_bottom = -HINTS_BOTTOM
	box.offset_left = HINTS_RESERVE
	box.offset_right = -HINTS_RESERVE
	box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hints_panel = PanelContainer.new()
	_hints_panel.theme_type_variation = &"TacticalHudChip"
	_hints_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_hints_panel)
	var label: Label = _label(_hints(), &"TacticalNoteLabel")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hints_panel.add_child(label)
	return box


func _hints() -> String:
	return ControlHints.line(PackedStringArray([
		ControlHints.key_label(&"space_left") + "/" + ControlHints.key_label(&"space_right") + " " + tr("SPACE_TURN"),
		ControlHints.hint(&"space_thrust", "SPACE_THRUST"), ControlHints.hint(&"space_reverse", "SPACE_REVERSE"),
	])) + "\n" + ControlHints.line(PackedStringArray([
		ControlHints.hint(&"space_fire", "SPACE_FIRE"), ControlHints.hint(&"space_boost", "SPACE_BOOST"),
		ControlHints.hint(&"space_secondary", "SPACE_SECONDARY"), ControlHints.hint(&"p1_pause", "HINT_PAUSE"),
	]))


func _build_pause() -> void:
	_pause_layer = CanvasLayer.new()
	_pause_layer.layer = 30
	add_child(_pause_layer)
	var overlay: ColorRect = ColorRect.new()
	overlay.color = Color(PALETTE.background, 0.93)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_layer.add_child(overlay)
	var column: VBoxContainer = VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	column.grow_horizontal = Control.GROW_DIRECTION_BOTH
	column.grow_vertical = Control.GROW_DIRECTION_BOTH
	column.add_theme_constant_override(&"separation", 32)
	_pause_layer.add_child(column)
	_pause_title = _label(tr("PAUSE_TITLE"), &"ScreenTitleLabel")
	_pause_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_pause_title)
	var legend: Label = _label(tr("SPACE_LEGEND"), &"InfiltrationLabel")
	legend.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(legend)
	var center: CenterContainer = CenterContainer.new()
	column.add_child(center)
	_pause_list = MenuList.new()
	center.add_child(_pause_list)
	_pause_list.chosen.connect(_on_pause_chosen)
	_set_paused(false)


func _process(delta: float) -> void:
	if sim == null or SceneRouter._busy:
		return
	if not paused and not finished:
		_refusal_left = maxf(_refusal_left - delta, 0.0)
		_accumulator += delta
		var steps: int = 0
		while _accumulator >= Ticks.DELTA and steps < MAX_STEPS:
			_accumulator -= Ticks.DELTA
			controller.produce(intent)
			step_once(intent)
			steps += 1
			if paused or finished:
				break
		if steps == MAX_STEPS:
			_accumulator = 0.0
	elif finished and not mode.external:
		_step_aftermath(delta)
	_update_presentation(_accumulator / Ticks.DELTA)


func _step_aftermath(delta: float) -> void:
	_accumulator += delta
	var steps: int = 0
	while _accumulator >= Ticks.DELTA and steps < MAX_STEPS:
		_accumulator -= Ticks.DELTA
		sim.step_aftermath(enemy_controller.produce_all(sim, _idle_intent))
		_present_events()
		steps += 1
	if steps == MAX_STEPS:
		_accumulator = 0.0


func step_once(command: SpaceIntent) -> void:
	if paused or finished:
		return
	sim.step(enemy_controller.produce_all(sim, command))
	_present_events()
	if sim.mission.outcome != SpaceMissionState.Outcome.ACTIVE:
		finished = true
		if mode.external:
			_view.animate = false
			_audio.set_paused(true)
		mode.finish(sim)
		if not mode.external:
			_begin_closure()


func _present_events() -> void:
	for index in sim.event_count:
		var event: SpaceEvent = sim.events[index]
		_view.on_event(event)
		_audio.on_event(event)
		if event.source == 0 and event.type == SpaceEvent.Type.ACTION_REFUSED:
			_refusal_key = "SPACE_NO_SECONDARY" if int(event.amount) == SpaceEvent.Refusal.NO_SECONDARY else "SPACE_POOL_FULL"
			_refusal_left = CONFIG.refusal_seconds


func _begin_closure() -> void:
	AudioDirector.play_ui(&"ui_confirm")
	var banner: MissionEndBanner = MissionEndBanner.new()
	add_child(banner)
	banner.closed.connect(_show_result)
	var won: bool = sim.mission.outcome == SpaceMissionState.Outcome.COMPLETED
	banner.present(won, tr("SPACE_RESULT_TIME").format({"time": ChallengeMode.format_time(sim.mission.finished_tick * Ticks.DELTA)}) if won else tr(END_REASONS[sim.mission.outcome]))


func _show_result() -> void:
	SceneRouter.change(&"space_result", {"mode": mode, "panel": &"result"})


func _update_objective(target: int, player: SpaceShipState) -> void:
	_card.tick(get_process_delta_time())
	var time: String = ChallengeMode.format_time(sim.tick * Ticks.DELTA)
	var parts: PackedStringArray = []
	var ratio: float = -1.0
	var eyebrow: String = tr(mode.data.title_key)
	if not mode.data.waves.is_empty():
		eyebrow = tr("SPACE_HUD_WAVE").format({"wave": sim.mission.wave, "total": mode.data.waves.size()})
	if not mode.data.phases.is_empty():
		var boss: SpaceShipState = sim.ships[mode.data.boss]
		ratio = boss.hull / boss.data.hull
		parts.append(tr(mode.data.phases[sim.mission.phase].title_key) + ControlHints.SEPARATOR + tr("SPACE_OPEN" if sim.mission.weakpoint_open() else "SPACE_CLOSED"))
	if mode.data.protected_ship >= 0:
		var ally: SpaceShipState = sim.ships[mode.data.protected_ship]
		ratio = ally.hull / ally.data.hull
		parts.append(tr("SPACE_ALLY_HULL").format({"hull": roundi(ratio * 100.0)}))
	if target >= 0:
		parts.append(_bearing(sim.ships[target].position - player.position, player.angle))
	_card.show_objective(eyebrow, tr(mode.data.objective_key), ratio, ControlHints.line(parts), time)


func _bearing(offset: Vector2, facing: float) -> String:
	var angle: float = absf(rad_to_deg(wrapf(offset.angle() - facing, -PI, PI)))
	var side: String = "SPACE_HUD_AHEAD" if angle <= FACING_AHEAD else "SPACE_HUD_BEHIND" if angle >= FACING_ASIDE else "SPACE_HUD_SIDE"
	return tr("SPACE_HUD_TARGET").format({"side": tr(side), "distance": roundi(offset.length())})


func _update_chips(player: SpaceShipState) -> void:
	var boost: String = tr("SPACE_BOOST_READY") if player.boost_cooldown == 0 else tr("SPACE_BOOST_COOLDOWN").format({"seconds": snappedf(player.boost_cooldown * Ticks.DELTA, 0.1)})
	if _refusal_left > 0.0:
		boost = tr(_refusal_key)
	_boost_chip.show_text(boost, ControlHints.key_label(&"space_boost"))
	_boost_chip.set_tint(PALETTE.text if player.boost_cooldown == 0 and _refusal_left <= 0.0 else PALETTE.tactical_muted)
	var missile: String = tr("SPACE_MISSILE_READY") if player.cooldowns[1] == 0 else tr("SPACE_MISSILE_COOLDOWN").format({"seconds": snappedf(player.cooldowns[1] * Ticks.DELTA, 0.1)})
	_missile_chip.show_text(missile, ControlHints.key_label(&"space_secondary"))
	_missile_chip.set_tint(PALETTE.text if player.cooldowns[1] == 0 else PALETTE.tactical_muted)


func _update_hints(delta: float) -> void:
	if _hints_left <= 0.0:
		return
	_hints_left = maxf(_hints_left - delta, 0.0)
	_hints_panel.modulate.a = clampf(_hints_left / HINTS_FADE_SECONDS, 0.0, 1.0)
	_hints_panel.visible = _hints_left > 0.0


func _update_presentation(alpha: float) -> void:
	if paused:
		alpha = 1.0
	_view.alpha = alpha
	var player: SpaceShipState = sim.ships[0]
	var half: Vector2 = (get_viewport_rect().size / CONFIG.camera_zoom * 0.5).min(sim.arena.size * 0.5)
	var focus: Vector2 = player.previous.lerp(player.position, alpha)
	var target: int = sim.mission.next_target(sim)
	if target >= 0:
		var ahead: Vector2 = ((sim.ships[target].position - focus) * CONFIG.camera_focus_ratio).limit_length(CONFIG.camera_lookahead)
		ahead.y = clampf(ahead.y, -CONFIG.camera_vertical_lookahead, CONFIG.camera_vertical_lookahead)
		focus += ahead
	_camera.position = focus.clamp(half, sim.arena.size - half)
	_backdrop.center = _camera.position
	_backdrop.queue_redraw()
	_hull.ratio = player.hull / player.data.hull
	_hull.ghost_ratio = _hull.ratio
	_hull.fill_color = PALETTE.danger if _hull.ratio < 0.25 else PALETTE.text
	_hull.queue_redraw()
	_shield.ratio = player.shield / player.data.shield if player.data.shield > 0.0 else 0.0
	_shield.ghost_ratio = _shield.ratio
	_shield.queue_redraw()
	_update_objective(target, player)
	_update_chips(player)
	_update_hints(get_process_delta_time())
	if not paused and not finished:
		_audio.update(player)
	if _view.debug:
		var active: int = 0
		for projectile in sim.projectiles:
			active += int(projectile.active)
		_debug.text = "FPS %d  tick %d\npos %s  velocity %s  speed %.2f\nangle %.3f  thrust %.2f\nhull %.1f  shield %.1f  recharge %d\nboost %d / %d  invulnerable %s\nweapons %s  windup %s\nprojectiles %d/%d  events %d/%d  dropped %d" % [Engine.get_frames_per_second(), sim.tick, player.position, player.velocity, player.velocity.length(), player.angle, player.thrust, player.hull, player.shield, player.shield_delay, player.boost_tick, player.boost_cooldown, player.invulnerable(CONFIG), player.cooldowns, player.charges, active, sim.projectiles.size(), sim.event_count, sim.events.size(), sim.dropped_events]
		_debug.text += "\nwave %d pending %d phase %d visits %s" % [sim.mission.wave, sim.mission.pending_wave, sim.mission.phase, sim.mission.phase_visits]
		for index in range(1, sim.ships.size()):
			_debug.text += "\n%d %s hull %.0f target %d role %d" % [index, sim.ships[index].data.id, sim.ships[index].hull, sim.arena.ships[index].target, sim.arena.ships[index].role]


func _unhandled_input(event: InputEvent) -> void:
	if sim == null or finished:
		return
	if event.is_action_pressed(&"debug_overlay"):
		_view.debug = not _view.debug
		_debug.visible = _view.debug
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"p1_pause") or (paused and event.is_action_pressed(&"ui_cancel")):
		if sim.ships[0].hull > 0.0:
			_set_paused(not paused)
		get_viewport().set_input_as_handled()
	elif not paused:
		controller.handle_input(event)


func _set_paused(value: bool) -> void:
	paused = value
	_accumulator = 0.0
	_view.animate = not value
	_pause_layer.visible = value
	_pause_list.set_process_unhandled_input(value)
	controller.discard_pending()
	_audio.set_paused(value)
	if not value:
		return
	_pause_title.text = tr("PAUSE_TITLE" if sim.ships[0].hull > 0.0 else "SPACE_DEFEATED")
	_pause_list.clear_items()
	if sim.ships[0].hull > 0.0:
		_pause_list.add_item(&"continue", tr("PAUSE_CONTINUE"))
	_pause_list.add_item(&"restart", tr("SPACE_RESTART"))
	_pause_list.add_item(&"back", tr("SPACE_BACK"))


func _on_pause_chosen(option: StringName) -> void:
	match option:
		&"continue":
			_set_paused(false)
		&"restart":
			sim = mode.create_simulation()
			enemy_controller = SpaceEnemyController.new(sim.ships.size())
			_view.setup(sim)
			_refusal_left = 0.0
			_set_paused(false)
		&"back":
			if mode.external:
				mode.exit_requested.emit()
			else:
				SceneRouter.change(&"space", {"mission": mode.data.id})


func _bar(parent: Node, top: float, color: Color) -> HudBar:
	var bar: HudBar = HudBar.new()
	bar.position = Vector2(HUD_MARGIN, top)
	bar.size = Vector2(HUD_WIDTH, 8.0)
	bar.fill_color = color
	parent.add_child(bar)
	return bar


func _label(text: String, variation: StringName) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.theme_type_variation = variation
	return label


func _exit_tree() -> void:
	if sim != null:
		SpaceBindings.uninstall()

