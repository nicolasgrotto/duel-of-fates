extends Node2D

const CONFIG: CombatConfig = preload("res://data/balance/combat_config.tres")
const EFFECTS: EffectsConfig = preload("res://data/balance/effects_config.tres")
const TRAINING: TrainingConfig = preload("res://data/balance/training_config.tres")
const POWER_VFX: PowerVfxConfig = preload("res://data/balance/power_vfx_config.tres")
const MODES: ModesConfig = preload("res://data/balance/modes_config.tres")
const SKY_ANCHOR: NodePath = ^"SkyAnchor"
const DEBRIS_DEPTH: int = 60
const REFLECTION_DEPTH: int = -9
const SKY_FALLBACK_DEPTH: int = -5
const ENVIRONMENT: Environment = preload("res://presentation/duel_environment.tres")
const PLAYER_INDEX: int = 0
const WEB_FEATURE: String = "web"

var mode: DuelMode
var setup: DuelSetup
var sim: MatchSimulation
var stats: StatsTracker = StatsTracker.new()

var _runner: TickRunner
var _world: Node2D
var _views: Array[FighterView] = []
var _effects: EffectsDirector
var _powers: PowerView
var _debris: DebrisLayer
var _sky: StormSky
var _camera: CameraRig
var _hud: Hud
var _screen: ScreenEffects
var _debug: DebugOverlay
var _training: TrainingPanel
var _gallery: GalleryPanel
var _glow_layer: CanvasLayer
var _stage: PixelStage
var _desaturation: Desaturation
var _audio: DuelAudio
var _rumble: DuelRumble
var _ai: Array[AiController] = []
var _reflections: Array[FighterReflection] = []
var _dummy: DummyController
var _objective: DuelObjective
var _awakened: Array[bool] = [false, false]
var _death_index: int = -1
var _replaying: bool = false
var _replay_controllers: Array[FighterController] = []
var _replay_end: int = 0
var _finished: bool = false


func open(params: Dictionary) -> void:
	mode = params["mode"]
	setup = mode.build_setup()
	setup.fill_default_looks()
	sim = MatchSimulation.new(CONFIG, setup.rules, setup.characters, setup.match_seed)
	for i in sim.fighters.size():
		sim.fighters[i].hold_to_lock = setup.hold_to_lock[i]
		var custom: Array[PowerData] = []
		custom.assign(setup.power_sets[i])
		if not custom.is_empty():
			sim.fighters[i].equip_powers(custom)
	sim.start_match()
	if setup.two_players:
		InputBindings.apply_two_player_keyboard()
	_build_scene()
	_runner.start(sim, _build_controllers())
	_objective = mode.create_objective(_dummy)
	if _objective != null:
		_objective.finished.connect(_on_objective_finished)
	_bind_presentation(sim)


func _build_scene() -> void:
	_stage = PixelStage.new(EFFECTS.units_per_pixel)
	add_child(_stage)
	if EFFECTS.web_glow or not OS.has_feature(WEB_FEATURE):
		var environment: WorldEnvironment = WorldEnvironment.new()
		environment.environment = ENVIRONMENT
		_stage.viewport.add_child(environment)
	_world = Node2D.new()
	_stage.viewport.add_child(_world)
	var arena: Node = setup.arena.scene.instantiate()
	_world.add_child(arena)
	_sky = StormSky.new()
	_sky.config = POWER_VFX
	var anchor: Node = arena.get_node_or_null(SKY_ANCHOR)
	if anchor != null:
		anchor.add_child(_sky)
	else:
		_sky.z_index = SKY_FALLBACK_DEPTH
		_world.add_child(_sky)
	var ambient: CanvasModulate = CanvasModulate.new()
	ambient.color = setup.arena.ambient
	_world.add_child(ambient)
	_desaturation = Desaturation.new()
	_desaturation.layer = 1
	_stage.viewport.add_child(_desaturation)
	_glow_layer = CanvasLayer.new()
	_glow_layer.layer = 2
	_glow_layer.follow_viewport_enabled = true
	_stage.viewport.add_child(_glow_layer)
	for i in 2:
		var view: FighterView = FighterView.new()
		view.show_finishers = Settings.show_finishers
		view.reduced_effects = Settings.reduced_effects
		_world.add_child(view)
		_views.append(view)
	_debris = DebrisLayer.new()
	_debris.config = POWER_VFX
	_debris.z_index = DEBRIS_DEPTH
	_world.add_child(_debris)
	_powers = PowerView.new()
	_powers.z_index = 10
	_powers.vfx = POWER_VFX
	_powers.debris = _debris
	_powers.sky = _sky
	_sky.flashed.connect(_powers.on_sky_flash)
	_powers.ambient = ambient
	_powers.base_ambient = setup.arena.ambient
	_glow_layer.add_child(_powers)
	_effects = EffectsDirector.new()
	_effects.config = EFFECTS
	_effects.reduced = Settings.reduced_effects
	_effects.z_index = 20
	_glow_layer.add_child(_effects)
	_camera = CameraRig.new()
	add_child(_camera)
	_camera.make_current()
	_stage.rig = _camera
	_hud = Hud.new()
	add_child(_hud)
	_screen = ScreenEffects.new()
	_screen.layer = 30
	add_child(_screen)
	_screen.setup(EFFECTS)
	_debug = DebugOverlay.new()
	add_child(_debug)
	_audio = DuelAudio.new()
	add_child(_audio)
	AudioDirector.play_music(setup.arena.music)
	AudioDirector.play_ambience(setup.arena.ambience)
	_runner = TickRunner.new()
	add_child(_runner)
	_runner.ticked.connect(_on_ticked)
	_runner.combat_event.connect(_on_combat_event)
	_effects.camera_impulse.connect(_camera.impulse)
	_effects.screen_flash.connect(_screen.flash)
	_rumble = DuelRumble.new()
	add_child(_rumble)
	_rumble.setup(setup.controllers, setup.player_slots)
	_effects.rumbled.connect(_rumble.on_rumbled)


func _build_controllers() -> Array[FighterController]:
	if setup.gallery:
		_gallery = GalleryPanel.new()
		add_child(_gallery)
		_gallery.setup(_runner, TRAINING)
		return _gallery.controllers()
	var controllers: Array[FighterController] = []
	for i in setup.controllers.size():
		match setup.controllers[i]:
			DuelSetup.ControllerKind.PLAYER:
				controllers.append(PlayerController.new(setup.player_slots[i]))
			DuelSetup.ControllerKind.AI:
				var ai: AiController = AiController.new(setup.difficulty, setup.characters[i].ai_profile, setup.match_seed + i)
				ai.awakening = setup.awakening[i]
				controllers.append(ai)
				_ai.append(ai)
			DuelSetup.ControllerKind.DUMMY:
				var dummy: DummyController = DummyController.new(TRAINING, setup.match_seed)
				controllers.append(dummy)
				_dummy = dummy
				if not setup.objective:
					_add_training_panel(dummy)
	return controllers


func _add_training_panel(dummy: DummyController) -> void:
	_training = TrainingPanel.new()
	add_child(_training)
	_training.setup(_runner, dummy, TRAINING)


func _bind_presentation(simulation: MatchSimulation) -> void:
	for i in 2:
		_views[i].setup(simulation.fighters[i], simulation.fighters[1 - i], _runner, EFFECTS, _glow_layer, setup.costumes[i], setup.arena.reflective_floor)
		_views[i].set_blade_color(setup.blade_colors[i])
		_views[i].rig.wind = setup.arena.wind
		_views[i].reset_round(simulation.phase == MatchSimulation.Phase.INTRO)
	if _reflections.is_empty() and setup.arena.fighter_reflection > 0.0:
		for view in _views:
			var reflection: FighterReflection = FighterReflection.new()
			reflection.z_index = REFLECTION_DEPTH
			reflection.setup(view, setup.arena.fighter_reflection, setup.arena.reflection_shade)
			_world.add_child(reflection)
			_reflections.append(reflection)
	_effects.sim = simulation
	_effects.views = _views
	_powers.sim = simulation
	_debris.sim = simulation
	_debris.views = _views
	_debris.arena = setup.arena
	_powers.views = _views
	_powers.blade_colors = [setup.blade_colors[0], setup.blade_colors[1]]
	_effects.blade_colors = [setup.blade_colors[0], setup.blade_colors[1]]
	_camera.setup(simulation, EFFECTS)
	_audio.setup(simulation, _views, PLAYER_INDEX)
	_hud.setup(simulation, not setup.training)
	_hud.set_banner(setup.banner)
	if setup.two_players:
		_hud.tag_players()
	_hud.set_footer(ControlHints.hint(&"p1_pause", "HINT_PAUSE") if not setup.gallery else "")
	if setup.gallery:
		_hud.show_flow_only(_gallery.caster_index)
		_gallery.caster_changed.connect(_hud.show_flow_only)
	_debug.attach(_world, simulation, _runner)


func _unhandled_input(event: InputEvent) -> void:
	if _finished:
		return
	if _replaying:
		if event.is_action_pressed(&"ui_accept"):
			_finish_replay()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(&"p1_pause") or event.is_action_pressed(&"p2_pause"):
		SceneRouter.push(&"pause", {"mode": mode})
		get_viewport().set_input_as_handled()


func _exit_tree() -> void:
	if setup != null and setup.two_players:
		Settings.apply()
	AudioDirector.stop_music()
	AudioDirector.stop_ambience()


func _on_ticked() -> void:
	for view in _views:
		view.on_ticked()
	_audio.on_ticked()
	if _replaying:
		if _replay_controllers[0] is ReplayController and (_replay_controllers[0] as ReplayController).cursor >= _replay_end:
			_finish_replay()
		return
	stats.on_tick(sim)
	_check_awakening()
	if _objective != null:
		_objective.on_tick(sim)
		_hud.set_banner(_objective.instruction())
		_hud.set_progress(_objective.progress_line())
	var cinematic: bool = sim.phase == MatchSimulation.Phase.INTRO or sim.phase == MatchSimulation.Phase.KO
	_screen.letterbox_target = 1.0 if cinematic and not setup.training else 0.0
	if _training != null:
		_training.on_ticked()
	if _gallery != null:
		_gallery.on_ticked()


func _on_objective_finished() -> void:
	if not _finished:
		_show_result.call_deferred()


func _check_awakening() -> void:
	for i in _ai.size():
		if _ai[i].awakened and not _awakened[i]:
			_awakened[i] = true
			_hud.announce(tr("HUD_BOSS_AWAKENS"), MODES.boss_message_seconds)
			_screen.pulse_letterbox(MODES.boss_letterbox)


func _on_combat_event(event: CombatEvent) -> void:
	for view in _views:
		view.on_event(event)
	_effects.on_event(event)
	_powers.on_event(event)
	_debris.on_event(event)
	_audio.on_event(event)
	if _replaying:
		return
	_hud.on_event(event)
	stats.on_event(event)
	if _objective != null:
		_objective.on_event(event, sim)
	if _training != null:
		_training.on_event(event)
	match event.type:
		CombatEvent.Type.PERFECT_PARRY:
			_screen.pulse_letterbox(EFFECTS.perfect_parry_letterbox)
			_desaturation.pulse(EFFECTS.desaturation)
		CombatEvent.Type.POWER_ACTIVE:
			if event.power.kind == PowerData.Kind.MASS_TELEKINESIS:
				_screen.pulse_letterbox(EFFECTS.mass_letterbox)
				_camera.pull_back(EFFECTS.mass_pull_back, EFFECTS.mass_letterbox)
				_camera.sky_shot(POWER_VFX.mass_sky_offset, POWER_VFX.mass_rise, POWER_VFX.mass_hold, POWER_VFX.mass_descend)
		CombatEvent.Type.DEATH:
			_death_index = _runner.recording.length()
		CombatEvent.Type.MATCH_ENDED:
			_on_match_ended.call_deferred()


func _on_match_ended() -> void:
	if Settings.final_blow_replay and _death_index > 0:
		_start_replay()
	else:
		_show_result()


func _start_replay() -> void:
	var recording: IntentRecording = IntentRecording.new(2)
	recording.data = _runner.recording.data.duplicate()
	var replay_sim: MatchSimulation = MatchSimulation.new(CONFIG, setup.rules, setup.characters, setup.match_seed)
	replay_sim.restore(_runner.round_snapshot)
	var start: int = maxi(_death_index - Ticks.from_seconds(CONFIG.replay_length), 0)
	var intents: Array[Intent] = [Intent.new(), Intent.new()]
	for tick in start:
		intents[0].unpack(recording.packed_at(tick, 0))
		intents[1].unpack(recording.packed_at(tick, 1))
		replay_sim.step(intents[0], intents[1])
		if tick % EFFECTS.replay_ticks_per_frame == EFFECTS.replay_ticks_per_frame - 1:
			await get_tree().process_frame
			if not is_inside_tree():
				return
	_replay_controllers = [ReplayController.new(recording, 0, start), ReplayController.new(recording, 1, start)]
	_replay_end = mini(_death_index + Ticks.from_seconds(CONFIG.replay_tail), recording.length())
	_replaying = true
	_rumble.setup([], [])
	_runner.records = false
	_runner.allows_slow_motion = false
	_runner.time_scale = CONFIG.replay_speed
	_runner.start(replay_sim, _replay_controllers)
	_bind_presentation(replay_sim)
	_hud.visible = false
	_screen.letterbox_target = 1.0
	_screen.show_replay(true, ControlHints.hint(&"ui_accept", "HINT_SKIP"))


func _finish_replay() -> void:
	if not _replaying:
		return
	_replaying = false
	_screen.show_replay(false)
	_show_result()


func _show_result() -> void:
	_finished = true
	mode.finish(sim.match_winner, sim, Ticks.to_seconds(stats.fight_ticks))
	var unlocked: PackedStringArray = mode.unlock_messages()
	var against_ai: bool = setup.controllers.size() > 1 and setup.controllers[1] == DuelSetup.ControllerKind.AI
	if against_ai and sim.match_winner == PLAYER_INDEX:
		unlocked.append_array(Unlocks.after_duel_against_ai(setup.characters[PLAYER_INDEX], stats.stats[PLAYER_INDEX]))
	_runner.set_process(false)
	SceneRouter.push(&"result", {
		"mode": mode,
		"stats": stats.stats,
		"names": [tr(setup.characters[0].name_key), tr(setup.characters[1].name_key)],
		"winner": sim.match_winner,
		"player_index": -1 if setup.two_players else PLAYER_INDEX,
		"duration": Ticks.to_seconds(stats.fight_ticks),
		"title": mode.result_title(),
		"note": mode.result_note(),
		"unlocks": unlocked,
	})
