extends Node2D

const CONFIG: BlasterOpsConfig = BlasterOpsTraining.CONFIG
const TRAINING_MAP: InfiltrationMapData = preload("res://data/infiltration/patrol_map.tres")
const MUSIC: MusicData = preload("res://data/audio/duel_music.tres")
const SUSPICION_SOUND: AudioStream = preload("res://assets/audio/infiltration/suspicion.wav")
const ALARM_SOUND: AudioStream = preload("res://assets/audio/infiltration/alarm.wav")
const PALETTE: UiPalette = preload("res://ui/palette.tres")
const MAX_STEPS: int = 5
const HUD_MARGIN: float = 56.0
const HUD_WIDTH: float = 320.0
const GUIDE_REFRESH_FRAMES: int = 15
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
var _objective: Label
var _finished: bool = false
var controller: InfiltrationPlayerController
var enemy_controller: InfiltrationEnemyController
var intent: InfiltrationIntent = InfiltrationIntent.new()
var paused: bool = false
var _stage: PixelStage
var _view: BlasterOpsView
var _map_view: BlasterOpsMapView
var _operations_status: Label
var _camera: Camera2D
var _health: HudBar
var _vigor: HudBar
var _status: Label
var _debug: Label
var _pause_layer: CanvasLayer
var _pause_title: Label
var _pause_list: MenuList
var _hum: AudioStreamPlayer
var _alarm: AudioStreamPlayer
var _notice: AudioStreamPlayer
var _music: Array[AudioStreamPlayer] = []
var _context: Label
var _accumulator: float = 0.0
var _guide_navigation: InfiltrationNavigation
var _guide_age: int = 0
var _guide_text: String = ""
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
	enemy_controller = BlasterOpsEnemyController.new(sim.map, sim.targets.size())
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
	_view.emitter = (mode.character if mode != null and mode.character != null else InfiltrationMode.look_character()).weapon.sidearm == WeaponData.Sidearm.HILT_EMITTER
	_view.reduced = Settings.reduced_effects
	_camera = Camera2D.new()
	_camera.zoom = Vector2.ONE * CONFIG.camera_zoom
	add_child(_camera)
	_camera.make_current()
	_stage.rig = _camera
	_build_hud()
	_build_pause()
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
	var title: Label = _label(tr(mode.data.title_key if mode != null else "INFILTRATION_TRAINING").to_upper(), &"ScreenTitleLabel")
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.offset_top = 30.0
	hud.add_child(title)
	_status = _label(tr("INFILTRATION_STATUS"), &"InfiltrationLabel")
	_status.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_status.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_status.offset_left = -HUD_MARGIN
	_status.offset_right = -HUD_MARGIN
	_status.offset_top = 90.0
	hud.add_child(_status)
	_health = _bar(hud, 40.0, PALETTE.text)
	_vigor = _bar(hud, 66.0, PALETTE.accent)
	_operations_status = _label("", &"InfiltrationLabel")
	_operations_status.position = Vector2(HUD_MARGIN, 88.0)
	hud.add_child(_operations_status)
	var objective: Label = _label(tr("INFILTRATION_OBJECTIVE"), &"InfiltrationLabel")
	objective.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective.offset_top = 128.0
	hud.add_child(objective)
	_objective = objective
	_context = _label("", &"InfiltrationLabel")
	_context.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_context.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_context.offset_top = -154.0
	hud.add_child(_context)
	var footer: Label = _label(_hints(), &"InfiltrationLabel")
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.offset_top = -98.0
	hud.add_child(footer)
	_debug = _label("", &"DebugLabel")
	_debug.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_debug.offset_left = HUD_MARGIN
	_debug.offset_top = 190.0
	_debug.visible = false
	hud.add_child(_debug)


func _label(text: String, variation: StringName) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.theme_type_variation = variation
	return label


func _bar(parent: Node, top: float, color: Color) -> HudBar:
	var bar: HudBar = HudBar.new()
	bar.position = Vector2(HUD_MARGIN, top)
	bar.size = Vector2(HUD_WIDTH, 8.0)
	bar.fill_color = color
	parent.add_child(bar)
	return bar


func _hints() -> String:
	var movement: String = TranslationServer.translate("INFILTRATION_MOVE").format({
		"left": ControlHints.key_label(&"infiltration_left"), "right": ControlHints.key_label(&"infiltration_right"),
		"up": ControlHints.key_label(&"infiltration_up"), "down": ControlHints.key_label(&"infiltration_down"),
	})
	return ControlHints.line(PackedStringArray([
		movement,
		ControlHints.blaster_ops_hint("run"), ControlHints.blaster_ops_hint("sneak"),
		ControlHints.blaster_ops_hint("dodge"),
	])) + "\n" + ControlHints.line(PackedStringArray([
		ControlHints.blaster_ops_hint("fire"), ControlHints.blaster_ops_hint("guard"),
		ControlHints.blaster_ops_hint("strike"), ControlHints.blaster_ops_hint("interact"),
		ControlHints.blaster_ops_hint("power"),
	]))


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
	var legend: Label = _label(tr("INFILTRATION_LEGEND"), &"InfiltrationLabel")
	legend.text += "\n" + ControlHints.line(PackedStringArray([
		ControlHints.blaster_ops_hint("strike"), ControlHints.blaster_ops_hint("interact"),
		ControlHints.blaster_ops_hint("power"),
	]))
	legend.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(legend)
	var center: CenterContainer = CenterContainer.new()
	column.add_child(center)
	_pause_list = MenuList.new()
	center.add_child(_pause_list)
	_pause_list.chosen.connect(_on_pause_chosen)
	_set_paused(false)


func _process(delta: float) -> void:
	if sim == null:
		return
	if not paused and not _finished and sim.player.health > 0.0:
		_accumulator += delta
		var steps: int = 0
		while _accumulator >= Ticks.DELTA and steps < MAX_STEPS:
			_accumulator -= Ticks.DELTA
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
	sim.step(command, enemy_controller.produce_all(sim), escort_controller.produce_all(sim))
	_present_events()
	if mode != null and sim.mission.outcome != InfiltrationMissionState.Outcome.ACTIVE:
		_finished = true
		mode.finish(sim)
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
		if BlasterOpsAudio.SOUNDS.has(event.type) and not SOUNDS.has(event.type):
			AudioDirector.play(BlasterOpsAudio.SOUNDS[event.type], event.position, CONFIG.effects_db)
		elif event.type == InfiltrationEvent.Type.POWER_RELEASED:
			var sound: StringName = &"power_repulse" if int(event.amount) == PowerData.Kind.REPULSE else (&"power_pull" if int(event.amount) == PowerData.Kind.PULL else &"power_barrier_absorb")
			AudioDirector.play(sound, event.position, CONFIG.effects_db)
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
	_health.ratio = sim.player.health / CONFIG.health
	_health.ghost_ratio = _health.ratio
	_health.fill_color = PALETTE.danger if _health.ratio < 0.25 else PALETTE.text
	_health.queue_redraw()
	_vigor.ratio = sim.player.vigor / CONFIG.vigor
	_vigor.ghost_ratio = _vigor.ratio
	_vigor.queue_redraw()
	var cooldowns: PackedStringArray = [tr("BOPS_COOLDOWN").format({"action": tr("BOPS_ACTION_DODGE"), "time": _cooldown(sim.state.dodge_cooldown)})]
	if sim.loadout.power != null:
		cooldowns.append(tr("BOPS_COOLDOWN").format({"action": tr(sim.loadout.power.power.name_key), "time": _cooldown(sim.state.power_cooldown)}))
	if sim.loadout.blaster != null:
		cooldowns.append(tr("OPS_HEAT_STATE").format({"value": tr("BOPS_COOLING") if sim.state.overheated else str(roundi(sim.state.heat))}))
	_operations_status.text = ControlHints.line(cooldowns)
	_update_security_hud()
	if mode != null:
		_objective.text = tr("INF_PROGRESS").format({"done": sim.mission.completed_objectives(sim), "total": mode.data.objective_count(), "time": ChallengeMode.format_time(sim.tick * Ticks.DELTA)})
	_update_audio()
	if _view.debug:
		var player: InfiltrationActor = sim.player
		_debug.text = "FPS %d  tick %d\npos %s  velocity %s\naim %s  guard %s  parry %d / lockout %d\nswing %d  health %.0f  vigor %.0f  dropped %d" % [
			Engine.get_frames_per_second(), sim.tick, str(player.position), str(player.velocity), str(player.aim), player.guard,
			player.parry_age, player.parry_cooldown, player.swing_tick, player.health, player.vigor, sim.dropped_events,
		]
		_debug.text += "\nalarm %s  reinforcements %d" % [sim.alarm_active(), sim.reinforcement_ticks]
		_debug.text += "\nheat %.1f  burst %d / %d  dodge %d / %d  power %d / %d" % [sim.state.heat, sim.state.burst_left, sim.state.burst_ticks, sim.state.dodge_age, sim.state.dodge_cooldown, sim.state.power_ticks, sim.state.power_cooldown]
		if sim.mission != null:
			_debug.text += "\nmission %s  alarm history %s  takedowns %d  copied %s  recruited %s  extracted %s" % [InfiltrationMissionState.Outcome.keys()[sim.mission.outcome], sim.mission.alarm_raised, sim.mission.takedowns, sim.mission.copied, sim.mission.recruited, sim.mission.extracted]
		for index in range(sim.map.targets.size(), sim.targets.size()):
			var actor: InfiltrationActor = sim.targets[index]
			_debug.text += "\n%d %s %.3f  %s  waypoint %d" % [index + 1, InfiltrationActor.Awareness.keys()[actor.awareness], actor.suspicion, InfiltrationActor.Decision.keys()[actor.decision], actor.waypoint]


func _cooldown(ticks: int) -> String:
	return tr("BOPS_READY") if ticks == 0 else tr("BOPS_SECONDS").format({"seconds": snappedf(ticks * Ticks.DELTA, 0.1)})


func _unhandled_input(event: InputEvent) -> void:
	if sim == null or _finished:
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
			enemy_controller = BlasterOpsEnemyController.new(sim.map, sim.targets.size())
			escort_controller = InfiltrationEscortController.new(sim)
			_guide_navigation = InfiltrationNavigation.new(sim.map)
			_guide_text = ""
			_map_view.attach(sim)
			_view.setup(sim, mode.mission_look() if mode != null else InfiltrationMode.current_look())
			_set_paused(false)
		&"back":
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
	if mode != null:
		_status.text = tr("INF_SECURITY_ACTIVE" if sim.alarm_active() else "INF_SECURITY_DISABLED" if disabled else "INF_SECURITY_READY")
	else:
		_status.text = tr("INFILTRATION_ALARM_ACTIVE" if sim.alarm_active() else "INFILTRATION_ALARM_DISABLED" if disabled else "INFILTRATION_STATUS")
	_status.modulate = PALETTE.danger if sim.alarm_active() else PALETTE.text
	var hints: PackedStringArray = []
	if sim.takedown_target() >= 0:
		hints.append(ControlHints.hint(&"infiltration_takedown", "INFILTRATION_TAKEDOWN"))
	if sim.nearby_panel() >= 0:
		hints.append(ControlHints.hint(&"infiltration_interact", "INFILTRATION_DISABLE"))
	elif sim.mission != null:
		var object: int = sim.mission.nearby_object(sim)
		if sim.mission.locked_prisoner_nearby(sim):
			hints.append(tr("INF_LOCKED"))
		elif object >= 0:
			hints.append(ControlHints.hint(&"infiltration_interact", "INF_COPY" if object < mode.data.terminals.size() else "INF_RECRUIT"))
	if sim.mission != null and hints.is_empty():
		hints.append(_mission_guide())
	if not sim.prisoners.is_empty():
		hints.append(_escort_guide())
	_context.text = ControlHints.line(hints)


func _escort_guide() -> String:
	var following: int = 0
	var lowest: float = CONFIG.prisoner_health
	for index in sim.prisoners.size():
		var alive: bool = sim.prisoners[index].health > 0.0
		following += int(alive and sim.mission.recruited[index] != 0 and sim.mission.extracted[index] == 0)
		if alive and sim.mission.recruited[index] != 0:
			lowest = minf(lowest, sim.prisoners[index].health)
	return tr("INF_ESCORT_GUIDE").format({"safe": sim.mission.rescued(), "total": sim.prisoners.size(), "minimum": mode.data.required_prisoners(), "following": following, "health": roundi(lowest)})


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
	_guide_text = tr("INF_TARGET_GUIDE").format({"objective": tr(_guide_key).format({"index": _guide_number}), "direction": direction, "distance": roundi(maxi(_guide_tiles, 0) * sim.map.tile_size)})
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
