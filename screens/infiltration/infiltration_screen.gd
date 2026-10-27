extends Node2D

const CONFIG: InfiltrationConfig = preload("res://data/balance/infiltration_config.tres")
const TRAINING_MAP: InfiltrationMapData = preload("res://data/infiltration/training_map.tres")
const PALETTE: UiPalette = preload("res://ui/palette.tres")
const MAX_STEPS: int = 5
const HUD_MARGIN: float = 56.0
const HUD_WIDTH: float = 320.0
const SOUNDS: Dictionary = {
	InfiltrationEvent.Type.SWING_STARTED: &"swing_light",
	InfiltrationEvent.Type.SWING_HIT: &"hit_light",
	InfiltrationEvent.Type.SHOT_FIRED: &"bolt_shot",
	InfiltrationEvent.Type.BOLT_BLOCKED: &"bolt_deflect",
	InfiltrationEvent.Type.BOLT_REFLECTED: &"bolt_reflect",
	InfiltrationEvent.Type.BOLT_HIT: &"bolt_hit",
	InfiltrationEvent.Type.FOOTSTEP: &"step",
}

var sim: InfiltrationSimulation
var controller: InfiltrationPlayerController
var intent: InfiltrationIntent = InfiltrationIntent.new()
var paused: bool = false
var _stage: PixelStage
var _view: InfiltrationView
var _camera: Camera2D
var _health: HudBar
var _vigor: HudBar
var _status: Label
var _debug: Label
var _pause_layer: CanvasLayer
var _pause_title: Label
var _pause_list: MenuList
var _hum: AudioStreamPlayer
var _accumulator: float = 0.0


func open(params: Dictionary) -> void:
	InfiltrationBindings.install()
	controller = InfiltrationPlayerController.new()
	sim = InfiltrationSimulation.new(CONFIG, params.get("map", TRAINING_MAP))
	_stage = PixelStage.new(CONFIG.units_per_pixel)
	add_child(_stage)
	var map_view: InfiltrationMapView = InfiltrationMapView.new()
	_stage.viewport.add_child(map_view)
	map_view.setup(sim.map, CONFIG)
	_view = InfiltrationView.new()
	_stage.viewport.add_child(_view)
	_view.setup(sim)
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
	_update_presentation(1.0)


func _build_hud() -> void:
	var hud: CanvasLayer = CanvasLayer.new()
	hud.layer = 10
	add_child(hud)
	var title: Label = _label(tr("INFILTRATION_TRAINING").to_upper(), &"ScreenTitleLabel")
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
	var objective: Label = _label(tr("INFILTRATION_OBJECTIVE"), &"InfiltrationLabel")
	objective.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective.offset_top = 128.0
	hud.add_child(objective)
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
		ControlHints.hint(&"infiltration_run", "INFILTRATION_RUN"),
		ControlHints.hint(&"infiltration_sneak", "INFILTRATION_SNEAK"),
	])) + "\n" + ControlHints.line(PackedStringArray([
		ControlHints.hint(&"infiltration_attack", "INFILTRATION_SWING"),
		ControlHints.hint(&"infiltration_guard", "INFILTRATION_GUARD"),
		tr("INFILTRATION_AIM"), ControlHints.hint(&"p1_pause", "HINT_PAUSE"),
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
	if not paused and sim.player.health > 0.0:
		_accumulator += delta
		var steps: int = 0
		while _accumulator >= Ticks.DELTA and steps < MAX_STEPS:
			_accumulator -= Ticks.DELTA
			controller.produce(sim, intent)
			step_once(intent)
			steps += 1
			if sim.player.health <= 0.0:
				_set_paused(true)
				break
		if steps == MAX_STEPS:
			_accumulator = 0.0
	_update_presentation(_accumulator / Ticks.DELTA)


func step_once(command: InfiltrationIntent) -> void:
	sim.step(command)
	for index in sim.event_count:
		var event: InfiltrationEvent = sim.events[index]
		_view.on_event(event)
		if SOUNDS.has(event.type):
			var volume: float = CONFIG.effects_db
			if event.type == InfiltrationEvent.Type.FOOTSTEP:
				volume = CONFIG.footstep_db - (8.0 if int(event.amount) == InfiltrationActor.Locomotion.SNEAK else 0.0)
			AudioDirector.play(SOUNDS[event.type], event.position, volume)


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
	if _view.debug:
		var player: InfiltrationActor = sim.player
		_debug.text = "FPS %d  tick %d\npos %s  velocity %s\naim %s  guard %s  parry %d / lockout %d\nswing %d  health %.0f  vigor %.0f  dropped %d" % [
			Engine.get_frames_per_second(), sim.tick, str(player.position), str(player.velocity), str(player.aim), player.guard,
			player.parry_age, player.parry_cooldown, player.swing_tick, player.health, player.vigor, sim.dropped_events,
		]


func _unhandled_input(event: InputEvent) -> void:
	if sim == null:
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
	if not value:
		return
	_pause_title.text = tr("PAUSE_TITLE" if sim.player.health > 0.0 else "INFILTRATION_DEFEATED")
	_pause_list.clear_items()
	if sim.player.health > 0.0:
		_pause_list.add_item(&"continue", tr("PAUSE_CONTINUE"))
	_pause_list.add_item(&"restart", tr("INFILTRATION_RESTART"))
	_pause_list.add_item(&"back", tr("INFILTRATION_BACK"))


func _on_pause_chosen(option: StringName) -> void:
	match option:
		&"continue":
			_set_paused(false)
		&"restart":
			sim = InfiltrationSimulation.new(CONFIG, sim.map)
			_view.setup(sim)
			_set_paused(false)
		&"back":
			SceneRouter.change(&"menu", {"group": &"learn", "focus": &"infiltration_training"})


func _exit_tree() -> void:
	InfiltrationBindings.uninstall()
	if is_instance_valid(_hum):
		_hum.stop()
