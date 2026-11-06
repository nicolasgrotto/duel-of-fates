extends TestCase

const LIMIT_TICKS: int = 60 * 60 * 8
const PARRY_DISTANCE: float = 360.0


class Pilot:
	extends RefCounted

	var intent: InfiltrationIntent = InfiltrationIntent.new()
	var mission_pilot: BlasterOpsMissionPilot
	var navigation: InfiltrationNavigation
	var revision: int = -1

	func _init(sim: BlasterOpsSimulation) -> void:
		mission_pilot = BlasterOpsMissionPilot.new(sim)
		navigation = InfiltrationNavigation.new(sim.map)

	func _go(sim: BlasterOpsSimulation, point: Vector2) -> bool:
		intent.aim = (point - sim.player.position).normalized()
		if sim.player.position.distance_to(point) <= 40.0:
			return true
		intent.movement = navigation.direction(sim.player.position, point, sim.player.radius)
		return false

	func produce(sim: BlasterOpsSimulation) -> InfiltrationIntent:
		var progress: BlasterOpsMissionState = sim.mission as BlasterOpsMissionState
		var stage: BlasterOpsStageData = progress.current_stage()
		if stage == null or stage.objective != BlasterOpsStageData.Objective.ACTION:
			return mission_pilot.produce(sim)
		if revision != sim.cover_revision:
			navigation.invalidate()
			revision = sim.cover_revision
		intent.clear()
		intent.aim = Vector2.RIGHT
		var swing: float = 1.0 if (sim.tick / 40) % 2 == 0 else -1.0
		match stage.action:
			BlasterOpsStageData.Action.MOVE:
				intent.movement = Vector2(swing, 0.0)
			BlasterOpsStageData.Action.RUN:
				intent.movement = Vector2(swing, 0.0)
				intent.held = InfiltrationIntent.RUN
			BlasterOpsStageData.Action.SNEAK:
				intent.movement = Vector2(swing, 0.0)
				intent.held = InfiltrationIntent.SNEAK
			BlasterOpsStageData.Action.FIRE:
				intent.held = Intent.Command.LIGHT
			BlasterOpsStageData.Action.CUT:
				intent.pressed = Intent.Command.HEAVY if sim.player.swing_tick < 0 else 0
			BlasterOpsStageData.Action.GUARD:
				intent.held = Intent.Command.BLOCK
			BlasterOpsStageData.Action.PARRY:
				var point: Vector2 = progress.objective_point(sim)
				if point != Vector2.INF:
					_go(sim, point + (sim.player.position - point).limit_length(PARRY_DISTANCE))
					intent.aim = (point - sim.player.position).normalized()
				intent.held = Intent.Command.BLOCK
			BlasterOpsStageData.Action.DODGE:
				intent.pressed = Intent.Command.DODGE
			BlasterOpsStageData.Action.POWER:
				intent.pressed = Intent.Command.POWER
			BlasterOpsStageData.Action.SWITCH:
				intent.pressed = InfiltrationIntent.SWITCH_WEAPON if sim.state.switch_ticks == 0 else 0
			BlasterOpsStageData.Action.DEPLOY:
				intent.aim = Vector2.LEFT.rotated(PI * 0.5 * ((sim.tick / 30) % 4))
				intent.pressed = InfiltrationIntent.INTERACT
			BlasterOpsStageData.Action.ORDER:
				intent.pressed = InfiltrationIntent.ORDER_ALLIES
			BlasterOpsStageData.Action.BUY:
				if _go(sim, progress.objective_point(sim)) or progress.nearby_terminal(sim) >= 0:
					intent.movement = Vector2.ZERO
					intent.purchase = 1
			BlasterOpsStageData.Action.PANEL, BlasterOpsStageData.Action.RECRUIT:
				if _go(sim, progress.objective_point(sim)):
					intent.pressed = InfiltrationIntent.INTERACT
			BlasterOpsStageData.Action.TAKEDOWN:
				_takedown(sim, progress)
		return intent

	func _takedown(sim: BlasterOpsSimulation, progress: BlasterOpsMissionState) -> void:
		var target: InfiltrationActor = sim.targets[progress.current_stage().targets[0]]
		intent.held = InfiltrationIntent.SNEAK
		if sim.takedown_target() >= 0:
			intent.aim = (target.position - sim.player.position).normalized()
			intent.pressed = Intent.Command.HEAVY
			return
		if sim.player.position.distance_to(target.position) > sim.config.takedown_range * 0.8:
			intent.movement = navigation.direction(sim.player.position, target.position - target.aim * sim.config.takedown_range * 0.5, sim.player.radius)
		intent.aim = (target.position - sim.player.position).normalized()


func _walk(mission: BlasterOpsMissionData, character_id: StringName) -> BlasterOpsSimulation:
	var hero: CharacterData = CharacterRoster.character(character_id)
	var mode: BlasterOpsMode = BlasterOpsMode.new(mission, hero)
	var sim: BlasterOpsSimulation = mode.create_simulation()
	var enemies: BlasterOpsMissionController = BlasterOpsMissionController.new(sim.map, sim.targets.size())
	var escorts: InfiltrationEscortController = InfiltrationEscortController.new(sim)
	var pilot: Pilot = Pilot.new(sim)
	for tick in LIMIT_TICKS:
		sim.step(pilot.produce(sim), enemies.produce_all(sim), escorts.produce_all(sim))
		if sim.mission.outcome != InfiltrationMissionState.Outcome.ACTIVE:
			break
	return sim


func test_infiltration_tutorial_walks_every_step_without_an_alarm() -> void:
	var sim: BlasterOpsSimulation = _walk(BlasterOpsMode.TUTORIALS[0], &"guardian")
	var progress: BlasterOpsMissionState = sim.mission as BlasterOpsMissionState
	assert_eq(sim.mission.outcome, InfiltrationMissionState.Outcome.COMPLETED, "stage %d" % progress.stage_index)
	assert_false(sim.mission.alarm_raised)
	assert_eq(progress.skip_report(), "", "the normal route skips nothing")
	assert_true(sim.stealth_objective())


func test_incursion_tutorial_walks_every_step() -> void:
	var sim: BlasterOpsSimulation = _walk(BlasterOpsMode.TUTORIALS[1], &"guardian")
	var progress: BlasterOpsMissionState = sim.mission as BlasterOpsMissionState
	assert_eq(sim.mission.outcome, InfiltrationMissionState.Outcome.COMPLETED, "stage %d" % progress.stage_index)


func test_incursion_tutorial_works_for_a_two_handed_blade() -> void:
	var sim: BlasterOpsSimulation = _walk(BlasterOpsMode.TUTORIALS[1], &"lance")
	assert_eq(sim.mission.outcome, InfiltrationMissionState.Outcome.COMPLETED)


func test_tutorials_stay_out_of_records_and_rewards() -> void:
	var service: Node = Engine.get_main_loop().root.get_node("SaveService")
	var before: Dictionary = service.incursion_best.duplicate(true)
	for mission in BlasterOpsMode.TUTORIALS:
		assert_true(mission.tutorial)
		assert_false(BlasterOpsMode.all_missions().has(mission))
		var mode: BlasterOpsMode = BlasterOpsMode.new(mission, CharacterRoster.character(&"guardian"))
		var sim: BlasterOpsSimulation = mode.create_simulation()
		sim.mission.outcome = InfiltrationMissionState.Outcome.COMPLETED
		sim.mission.finished_tick = 100
		mode.finish(sim)
		assert_true(mode.sealed.won)
	assert_eq(service.incursion_best, before)


func test_tutorial_text_has_a_placeholder_for_each_key() -> void:
	for mission in BlasterOpsMode.TUTORIALS:
		for stage in mission.stages:
			assert_false(TranslationServer.translate(stage.title_key) == stage.title_key, stage.title_key)
			for index in stage.hint_actions.size():
				assert_true(TranslationServer.translate(stage.title_key).contains("{%d}" % index), stage.title_key)
				assert_true(BlasterOpsBindings.ACTIONS.has(stage.hint_actions[index]), stage.hint_actions[index])


func test_stage_progress_survives_a_snapshot() -> void:
	var mode: BlasterOpsMode = BlasterOpsMode.new(BlasterOpsMode.TUTORIALS[0], CharacterRoster.character(&"guardian"))
	var sim: BlasterOpsSimulation = mode.create_simulation()
	var progress: BlasterOpsMissionState = sim.mission as BlasterOpsMissionState
	progress.action_progress = 7
	var snapshot: Dictionary = progress.capture()
	progress.action_progress = 0
	progress.restore(snapshot)
	assert_eq(progress.action_progress, 7)


func _at_step(mission: BlasterOpsMissionData, action: BlasterOpsStageData.Action) -> BlasterOpsSimulation:
	var mode: BlasterOpsMode = BlasterOpsMode.new(mission, CharacterRoster.character(&"guardian"))
	var sim: BlasterOpsSimulation = mode.create_simulation()
	var progress: BlasterOpsMissionState = sim.mission as BlasterOpsMissionState
	for index in mission.stages.size():
		if mission.stages[index].objective == BlasterOpsStageData.Objective.ACTION and mission.stages[index].action == action:
			progress._enter_stage(index)
			progress.intermission_ticks = 0
			return sim
	assert_true(false, "no such step")
	return sim


func _step_idle(sim: BlasterOpsSimulation) -> void:
	sim.step(InfiltrationIntent.new(), [], [])


func test_step_does_not_complete_without_the_action() -> void:
	for action in [BlasterOpsStageData.Action.DEPLOY, BlasterOpsStageData.Action.BUY, BlasterOpsStageData.Action.ORDER, BlasterOpsStageData.Action.RECRUIT, BlasterOpsStageData.Action.POWER, BlasterOpsStageData.Action.FIRE, BlasterOpsStageData.Action.PARRY]:
		var sim: BlasterOpsSimulation = _at_step(BlasterOpsMode.TUTORIALS[1], action)
		var progress: BlasterOpsMissionState = sim.mission as BlasterOpsMissionState
		var index: int = progress.stage_index
		if action == BlasterOpsStageData.Action.ORDER:
			progress.recruited[0] = 1
		for tick in 120:
			_step_idle(sim)
		assert_eq(progress.stage_index, index, "step %s waited for the player" % BlasterOpsStageData.Action.keys()[action])
		assert_eq(progress.skip_report(), "")


func test_spent_barriers_complete_the_step_only_if_the_player_used_them() -> void:
	var sim: BlasterOpsSimulation = _at_step(BlasterOpsMode.TUTORIALS[1], BlasterOpsStageData.Action.DEPLOY)
	var progress: BlasterOpsMissionState = sim.mission as BlasterOpsMissionState
	var index: int = progress.stage_index
	progress.barrier_charges = 0
	var previous: int = progress._reported_stuck_stage
	assert_eq(progress._step_skip_reason(sim, progress.current_stage()), BlasterOpsMissionState.StepSkip.NONE, "no charges with no prior use is a data error")
	assert_true(progress._reported_stuck_stage != previous, "the data error is reported")
	assert_eq(progress.stage_index, index)
	progress.performed_actions |= 1 << BlasterOpsStageData.Action.DEPLOY
	_step_idle(sim)
	assert_true(progress.stage_index > index)
	assert_eq(progress.skip_report(), "%d:ALREADY_DONE" % (index + 1))


func test_order_step_waits_for_a_living_ally_to_be_freed() -> void:
	var sim: BlasterOpsSimulation = _at_step(BlasterOpsMode.TUTORIALS[1], BlasterOpsStageData.Action.ORDER)
	var progress: BlasterOpsMissionState = sim.mission as BlasterOpsMissionState
	var index: int = progress.stage_index
	_step_idle(sim)
	assert_eq(progress.stage_index, index, "an ally still waits to be freed")
	sim.prisoners[0].health = 0.0
	_step_idle(sim)
	assert_true(progress.stage_index > index)
	assert_true(progress.skip_report().contains("ALLY_LOST"))


func test_regular_missions_never_auto_complete_an_action_objective() -> void:
	for mission in BlasterOpsMode.INCURSIONS:
		assert_false(mission.tutorial, String(mission.id))
		for stage in mission.stages:
			assert_true(stage.objective != BlasterOpsStageData.Objective.ACTION, String(mission.id))
	var sim: BlasterOpsSimulation = _at_step(BlasterOpsMode.TUTORIALS[1], BlasterOpsStageData.Action.DEPLOY)
	var progress: BlasterOpsMissionState = sim.mission as BlasterOpsMissionState
	var index: int = progress.stage_index
	progress.definition = progress.definition.duplicate() as BlasterOpsMissionData
	progress.definition.tutorial = false
	progress.barrier_charges = 0
	progress.performed_actions = -1
	for tick in 60:
		_step_idle(sim)
	assert_eq(progress.stage_index, index)
	assert_eq(progress.skip_report(), "")


func test_firing_with_the_blade_drawn_does_not_count_as_a_shot() -> void:
	var sim: BlasterOpsSimulation = _at_step(BlasterOpsMode.TUTORIALS[1], BlasterOpsStageData.Action.FIRE)
	var progress: BlasterOpsMissionState = sim.mission as BlasterOpsMissionState
	var intent: InfiltrationIntent = InfiltrationIntent.new()
	intent.pressed = Intent.Command.HEAVY
	sim.step(intent, [], [])
	for tick in 90:
		_step_idle(sim)
	assert_eq(progress.action_progress, 0)


func test_every_character_finishes_the_incursion_tutorial_without_skips() -> void:
	for id in [&"shadow", &"wasp", &"reaper", &"corsair", &"foretold"]:
		var sim: BlasterOpsSimulation = _walk(BlasterOpsMode.TUTORIALS[1], id)
		var progress: BlasterOpsMissionState = sim.mission as BlasterOpsMissionState
		assert_eq(sim.mission.outcome, InfiltrationMissionState.Outcome.COMPLETED, "%s stage %d" % [id, progress.stage_index])
		assert_false(progress.skip_report().contains("LOST"), "%s %s" % [id, progress.skip_report()])
