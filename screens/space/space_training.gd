extends Node2D

const CONFIG: SpaceConfig = preload("res://data/balance/space_config.tres")
const ARENA: SpaceArenaData = preload("res://data/space/training_arena.tres")
const PALETTE: UiPalette = preload("res://ui/palette.tres")
const MAX_STEPS: int = 5
const HUD_MARGIN: float = 56.0
const HUD_WIDTH: float = 290.0

var sim: SpaceSimulation
var controller: SpacePlayerController
var drone_controller: SpaceDroneController
var intent: SpaceIntent = SpaceIntent.new()
var paused: bool = false
var _stage: PixelStage
var _camera: Camera2D
var _backdrop: SpaceBackdrop
var _view: SpaceView
var _audio: SpaceAudio
var _hull: HudBar
var _shield: HudBar
var _objective: Label
var _status: Label
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
		open({})


func open(params: Dictionary) -> void:
	if sim != null:
		return
	SpaceBindings.install()
	controller = SpacePlayerController.new()
	sim = SpaceSimulation.new(CONFIG, params.get("arena", ARENA))
	drone_controller = SpaceDroneController.new(sim.ships.size())
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
	var title: Label = _label(tr(sim.arena.title_key).to_upper(), &"ScreenTitleLabel")
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.offset_top = 30.0
	hud.add_child(title)
	_hull = _bar(hud, 50.0, PALETTE.text)
	_shield = _bar(hud, 90.0, PALETTE.menu_blade_a)
	for index in 2:
		var name_label: Label = _label(tr("SPACE_HULL" if index == 0 else "SPACE_SHIELD"), &"InfiltrationLabel")
		name_label.position = Vector2(HUD_MARGIN, 14.0 + index * 40.0)
		hud.add_child(name_label)
	_status = _label("", &"InfiltrationLabel")
	_status.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_status.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_status.offset_left = -HUD_MARGIN
	_status.offset_right = -HUD_MARGIN
	_status.offset_top = 86.0
	hud.add_child(_status)
	_objective = _label("", &"InfiltrationLabel")
	_objective.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_objective.offset_top = 130.0
	hud.add_child(_objective)
	var footer: Label = _label(_hints(), &"InfiltrationLabel")
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.offset_top = -96.0
	hud.add_child(footer)
	_debug = _label("", &"DebugLabel")
	_debug.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_debug.offset_left = HUD_MARGIN
	_debug.offset_top = 200.0
	_debug.visible = false
	hud.add_child(_debug)


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
	if sim == null:
		return
	if not paused:
		_refusal_left = maxf(_refusal_left - delta, 0.0)
		_accumulator += delta
		var steps: int = 0
		while _accumulator >= Ticks.DELTA and steps < MAX_STEPS:
			_accumulator -= Ticks.DELTA
			controller.produce(intent)
			step_once(intent)
			steps += 1
			if paused:
				break
		if steps == MAX_STEPS:
			_accumulator = 0.0
	_update_presentation(_accumulator / Ticks.DELTA)


func step_once(command: SpaceIntent) -> void:
	if paused:
		return
	sim.step(drone_controller.produce_all(sim, command))
	for index in sim.event_count:
		var event: SpaceEvent = sim.events[index]
		_view.on_event(event)
		_audio.on_event(event)
		if event.source == 0 and event.type == SpaceEvent.Type.ACTION_REFUSED:
			_refusal_key = "SPACE_NO_SECONDARY" if int(event.amount) == SpaceEvent.Refusal.NO_SECONDARY else "SPACE_POOL_FULL"
			_refusal_left = CONFIG.refusal_seconds
	if sim.ships[0].hull <= 0.0:
		_set_paused(true)


func _update_presentation(alpha: float) -> void:
	if paused:
		alpha = 1.0
	_view.alpha = alpha
	var player: SpaceShipState = sim.ships[0]
	var half: Vector2 = (get_viewport_rect().size / CONFIG.camera_zoom * 0.5).min(sim.arena.size * 0.5)
	_camera.position = player.previous.lerp(player.position, alpha).clamp(half, sim.arena.size - half)
	_backdrop.center = _camera.position
	_backdrop.queue_redraw()
	_hull.ratio = player.hull / player.data.hull
	_hull.ghost_ratio = _hull.ratio
	_hull.fill_color = PALETTE.danger if _hull.ratio < 0.25 else PALETTE.text
	_hull.queue_redraw()
	_shield.ratio = player.shield / player.data.shield if player.data.shield > 0.0 else 0.0
	_shield.ghost_ratio = _shield.ratio
	_shield.queue_redraw()
	_objective.text = tr("SPACE_OBJECTIVE").format({"count": sim.destroyed_targets})
	_status.text = tr(_refusal_key) if _refusal_left > 0.0 else tr("SPACE_BOOST_READY") if player.boost_cooldown == 0 else tr("SPACE_BOOST_COOLDOWN").format({"seconds": snappedf(player.boost_cooldown * Ticks.DELTA, 0.1)})
	if not paused:
		_audio.update(player)
	if _view.debug:
		var active: int = 0
		for projectile in sim.projectiles:
			active += int(projectile.active)
		_debug.text = "FPS %d  tick %d\npos %s  velocity %s  speed %.2f\nangle %.3f  thrust %.2f\nhull %.1f  shield %.1f  recharge %d\nboost %d / %d  invulnerable %s\nweapons %s  windup %s\nprojectiles %d/%d  events %d/%d  dropped %d" % [Engine.get_frames_per_second(), sim.tick, player.position, player.velocity, player.velocity.length(), player.angle, player.thrust, player.hull, player.shield, player.shield_delay, player.boost_tick, player.boost_cooldown, player.invulnerable(CONFIG), player.cooldowns, player.charges, active, sim.projectiles.size(), sim.event_count, sim.events.size(), sim.dropped_events]


func _unhandled_input(event: InputEvent) -> void:
	if sim == null:
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
			sim = SpaceSimulation.new(CONFIG, sim.arena)
			drone_controller = SpaceDroneController.new(sim.ships.size())
			_view.setup(sim)
			_refusal_left = 0.0
			_set_paused(false)
		&"back":
			SceneRouter.change(&"menu", {"group": &"special"})


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

