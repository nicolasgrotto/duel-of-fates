extends Node2D

const CONFIG: BlasterOpsConfig = BlasterOpsTraining.CONFIG
const PALETTE: UiPalette = preload("res://ui/palette.tres")
const MAX_STEPS: int = 5
const MARGIN: float = 56.0
const BAR_WIDTH: float = 250.0

var sim: BlasterOpsSimulation
var controller: BlasterOpsPlayerController
var enemy_controller: BlasterOpsEnemyController
var intent: InfiltrationIntent = InfiltrationIntent.new()
var paused: bool = false
var _character: CharacterData
var _character_index: int = 0
var _power_index: int = 0
var _arena: BlasterOpsArenaData
var _equipment: BlasterOpsLoadout
var _stage: PixelStage
var _view: BlasterOpsView
var _map_view: BlasterOpsMapView
var _camera: Camera2D
var _audio: BlasterOpsAudio
var _health: HudBar
var _heat: HudBar
var _vigor: HudBar
var _heat_text: Label
var _cooldowns: Label
var _footer: Label
var _debug: Label
var _pause_layer: CanvasLayer
var _pause_title: Label
var _pause_list: MenuList
var _accumulator: float = 0.0


func _ready() -> void:
	_open_default.call_deferred()


func _open_default() -> void:
	if sim == null:
		open({})


func open(params: Dictionary) -> void:
	if sim != null:
		return
	BlasterOpsBindings.install(Settings.blaster_ops_keys, Settings.blaster_ops_buttons)
	_character = params.get("character", DuelMode.character(BlasterOpsTraining.CHARACTERS[0]))
	_character_index = maxi(BlasterOpsTraining.CHARACTERS.find(_character.id), 0)
	_power_index = clampi(params.get("power", 0), 0, BlasterOpsTraining.POWERS.size() - 1)
	_arena = params.get("arena", BlasterOpsTraining.ARENA)
	_equipment = params.get("loadout", BlasterOpsTraining.equipment(_character, _power_index))
	controller = BlasterOpsPlayerController.new()
	sim = BlasterOpsSimulation.new(CONFIG, _arena, _equipment)
	enemy_controller = BlasterOpsEnemyController.new(sim.map, sim.targets.size())
	_stage = PixelStage.new(CONFIG.units_per_pixel)
	_stage.viewport.world_2d = World2D.new()
	_stage.viewport.audio_listener_enable_2d = true
	add_child(_stage)
	_map_view = BlasterOpsMapView.new()
	_stage.viewport.add_child(_map_view)
	_map_view.attach(sim)
	_view = BlasterOpsView.new()
	_stage.viewport.add_child(_view)
	_view.setup(sim, BlasterOpsTraining.look(_character))
	_view.emitter = _character.weapon.sidearm == WeaponData.Sidearm.HILT_EMITTER
	_view.reduced = Settings.reduced_effects
	_camera = Camera2D.new()
	_camera.zoom = Vector2.ONE * CONFIG.camera_zoom
	add_child(_camera)
	_camera.make_current()
	_stage.rig = _camera
	_audio = BlasterOpsAudio.new()
	_stage.viewport.add_child(_audio)
	_audio.setup(CONFIG)
	_build_hud()
	_build_pause()
	_update_presentation(1.0)


func _build_hud() -> void:
	var hud: CanvasLayer = CanvasLayer.new()
	hud.layer = 10
	add_child(hud)
	var title: Label = _label(hud, tr("BOPS_TRAINING").to_upper(), &"ScreenTitleLabel")
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.offset_top = 30.0
	_health = _bar(hud, 48.0, PALETTE.text)
	_heat = _bar(hud, 86.0, PALETTE.potential)
	_vigor = _bar(hud, 124.0, PALETTE.accent)
	for index in 3:
		var text: Label = _label(hud, tr(["BOPS_HEALTH", "BOPS_HEAT", "BOPS_VIGOR"][index]), &"InfiltrationLabel")
		text.position = Vector2(MARGIN, 30.0 + index * 38.0)
		if index == 1:
			_heat_text = text
	_cooldowns = _label(hud, "", &"InfiltrationLabel")
	_cooldowns.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_cooldowns.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_cooldowns.offset_left = -MARGIN
	_cooldowns.offset_right = -MARGIN
	_cooldowns.offset_top = 40.0
	_cooldowns.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var goal: Label = _label(hud, tr("BOPS_OBJECTIVE"), &"InfiltrationLabel")
	goal.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	goal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	goal.offset_top = 168.0
	_footer = _label(hud, "", &"InfiltrationLabel")
	_footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_footer.offset_top = -104.0
	_update_hints()
	_debug = _label(hud, "", &"DebugLabel")
	_debug.position = Vector2(MARGIN, 230.0)
	_debug.visible = false


func _label(parent: Node, text: String, variation: StringName) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.theme_type_variation = variation
	parent.add_child(label)
	return label


func _bar(parent: Node, top: float, color: Color) -> HudBar:
	var bar: HudBar = HudBar.new()
	bar.position = Vector2(MARGIN + 150.0, top)
	bar.size = Vector2(BAR_WIDTH, 8.0)
	bar.fill_color = color
	parent.add_child(bar)
	return bar


func _update_hints() -> void:
	var move: String = tr("INFILTRATION_MOVE").format({"left": ControlHints.key_label(&"blaster_ops_left"), "right": ControlHints.key_label(&"blaster_ops_right"), "up": ControlHints.key_label(&"blaster_ops_up"), "down": ControlHints.key_label(&"blaster_ops_down")})
	_footer.text = ControlHints.line(PackedStringArray([move, tr("BOPS_AIM_CONTROLS"), ControlHints.blaster_ops_hint("fire")]))
	_footer.text += "\n" + ControlHints.line(PackedStringArray([ControlHints.blaster_ops_hint("guard"), ControlHints.blaster_ops_hint("dodge"), ControlHints.blaster_ops_hint("power"), ControlHints.hint(&"p1_pause", "HINT_PAUSE")]))

	_footer.text += "\n" + ControlHints.line(PackedStringArray([ControlHints.blaster_ops_hint("run"), ControlHints.blaster_ops_hint("sneak"), ControlHints.blaster_ops_hint("strike"), ControlHints.blaster_ops_hint("interact")]))
	_footer.offset_top = -138.0

func _build_pause() -> void:
	_pause_layer = CanvasLayer.new()
	_pause_layer.layer = 30
	add_child(_pause_layer)
	var overlay: ColorRect = ColorRect.new()
	overlay.color = Color(PALETTE.background, 0.92)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_layer.add_child(overlay)
	_pause_title = _label(_pause_layer, tr("PAUSE_TITLE"), &"ScreenTitleLabel")
	_pause_title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_pause_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pause_title.offset_top = 200.0
	_pause_list = MenuList.new()
	_pause_list.position = Vector2(960.0, 390.0)
	_pause_list.centered = true
	_pause_layer.add_child(_pause_list)
	_pause_list.chosen.connect(_on_pause_chosen)
	var legend: Label = _label(_pause_layer, tr("BOPS_PAUSE_LEGEND"), &"InfiltrationLabel")
	legend.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	legend.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	legend.offset_top = -220.0
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
	_update_presentation(1.0 if paused else _accumulator / Ticks.DELTA)


func step_once(command: InfiltrationIntent) -> void:
	if paused:
		return
	sim.step(command, enemy_controller.produce_all(sim))
	for index in sim.event_count:
		_view.on_event(sim.events[index])
		_audio.on_event(sim.events[index], sim)


func _update_presentation(alpha: float) -> void:
	_view.alpha = alpha
	var half: Vector2 = get_viewport_rect().size / CONFIG.camera_zoom * 0.5
	var desired: Vector2 = sim.player.previous.lerp(sim.player.position, alpha)
	_camera.position = desired.clamp(half, sim.map.world_size() - half)
	_health.ratio = sim.player.health / CONFIG.health
	_heat.ratio = sim.state.heat / CONFIG.heat_capacity
	_heat.visible = sim.loadout.blaster != null
	_heat_text.visible = _heat.visible
	_vigor.ratio = sim.player.vigor / CONFIG.vigor
	_heat.fill_color = PALETTE.danger if sim.state.overheated else PALETTE.potential
	_heat_text.text = tr("BOPS_COOLING" if sim.state.overheated else "BOPS_HEAT")
	for bar in [_health, _heat, _vigor]:
		bar.ghost_ratio = bar.ratio
		bar.queue_redraw()
	_cooldowns.text = tr("BOPS_COOLDOWN").format({"action": tr("BOPS_ACTION_DODGE"), "time": _cooldown(sim.state.dodge_cooldown)})
	_cooldowns.text += "\n" + tr("BOPS_COOLDOWN").format({"action": tr(sim.loadout.power.power.name_key), "time": _cooldown(sim.state.power_cooldown)})
	if _view.debug:
		_update_debug()


func _cooldown(ticks: int) -> String:
	return tr("BOPS_READY") if ticks == 0 else tr("BOPS_SECONDS").format({"seconds": "%.1f" % Ticks.to_seconds(ticks)})


func _update_debug() -> void:
	_debug.text = "FPS %d  tick %d\nposition %s  velocity %s  aim %s\nheat %.1f  locked %s (%d)  fire %d\ndodge age %d  cooldown %d  precision %s\npower %d / %d  barrier %.1f (%d)\nguard %s  parry %d  vigor %.1f" % [Engine.get_frames_per_second(), sim.tick, sim.player.position, sim.player.velocity, sim.player.aim, sim.state.heat, sim.state.overheated, sim.state.overheat_ticks, sim.state.fire_ticks, sim.state.dodge_age, sim.state.dodge_cooldown, sim.state.precision_succeeded, sim.state.power_ticks, sim.state.power_cooldown, sim.state.barrier_health, sim.state.barrier_ticks, sim.player.guard, sim.player.parry_age, sim.player.vigor]
	for index in sim.targets.size():
		var actor: BlasterOpsActor = sim.targets[index] as BlasterOpsActor
		_debug.text += "\n%d %s  state %s  target %s  windup %d  health %.0f" % [index + 1, sim.target_data[index].id, InfiltrationActor.Decision.find_key(actor.decision), actor.last_known, actor.telegraph_ticks, actor.health]
	for index in sim.arena.covers.size():
		_debug.text += "\ncover %d  health %.0f  stage %d" % [index, sim.arena.covers[index].health, sim.arena.covers[index].damage_stage()]


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
	_audio.set_paused(value)
	if not value:
		return
	_pause_title.text = tr("PAUSE_TITLE" if sim.player.health > 0.0 else "BOPS_DEFEATED")
	_pause_list.clear_items()
	if sim.player.health > 0.0:
		_pause_list.add_item(&"continue", tr("PAUSE_CONTINUE"))
	_pause_list.add_item(&"restart", tr("BOPS_RESTART"))
	_pause_list.add_item(&"character", tr("BOPS_CHARACTER").format({"name": tr(_character.name_key)}))
	_pause_list.add_item(&"power", tr("BOPS_POWER").format({"name": tr(BlasterOpsTraining.POWERS[_power_index].power.name_key)}))
	_pause_list.add_item(&"back", tr("BOPS_BACK"))


func _on_pause_chosen(option: StringName) -> void:
	if option == &"continue":
		_set_paused(false)
	elif option == &"back":
		SceneRouter.change(&"menu", {"group": &"special", "focus": &"operations"})
	else:
		if option == &"character":
			_character_index = (_character_index + 1) % BlasterOpsTraining.CHARACTERS.size()
			_character = DuelMode.character(BlasterOpsTraining.CHARACTERS[_character_index])
		elif option == &"power":
			_power_index = (_power_index + 1) % BlasterOpsTraining.POWERS.size()
		_equipment = BlasterOpsTraining.equipment(_character, _power_index)
		_restart()


func _restart() -> void:
	sim = BlasterOpsSimulation.new(CONFIG, _arena, _equipment)
	enemy_controller = BlasterOpsEnemyController.new(sim.map, sim.targets.size())
	_map_view.attach(sim)
	_view.setup(sim, BlasterOpsTraining.look(_character))
	_view.emitter = _character.weapon.sidearm == WeaponData.Sidearm.HILT_EMITTER
	_update_presentation(1.0)
	_set_paused(false)


func _exit_tree() -> void:
	if sim != null:
		BlasterOpsBindings.uninstall()
