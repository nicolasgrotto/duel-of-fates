extends TestCase


func _sim(index: int = 0) -> BlasterOpsSimulation:
	return BlasterOpsMode.new(BlasterOpsMode.INCURSIONS[index], DuelMode.character(&"guardian"), null, true).create_simulation()


func _play(index: int, armed: bool = false) -> BlasterOpsSimulation:
	var hero: CharacterData = DuelMode.character(&"corsair" if armed else &"guardian")
	var sim: BlasterOpsSimulation = BlasterOpsMode.new(BlasterOpsMode.INCURSIONS[index], hero, null, true).create_simulation()
	var pilot: BlasterOpsMissionPilot = BlasterOpsMissionPilot.new(sim)
	var enemies: BlasterOpsMissionController = BlasterOpsMissionController.new(sim.map, sim.targets.size())
	var allies: InfiltrationEscortController = InfiltrationEscortController.new(sim)
	for tick in 18000:
		sim.step(pilot.produce(sim), enemies.produce_all(sim), allies.produce_all(sim))
		if sim.mission.outcome != InfiltrationMissionState.Outcome.ACTIVE:
			break
	print("Incursion route %s: outcome %d tick %d health %.1f kills %d wave %d vigor %.1f" % [sim.mission.data.id, sim.mission.outcome, sim.tick, sim.player.health, sim.mission.takedowns, (sim.mission as BlasterOpsMissionState).wave_index, sim.player.vigor])
	if sim.mission.outcome != InfiltrationMissionState.Outcome.COMPLETED:
		for target_index in sim.targets.size():
			print("  target %d health %.1f at %s player %s" % [target_index, sim.targets[target_index].health, sim.targets[target_index].position, sim.player.position])
	return sim


func test_all_seven_missions_are_completable_with_saber_only_intents() -> void:
	for index in BlasterOpsMode.INCURSIONS.size():
		var sim: BlasterOpsSimulation = _play(index)
		assert_eq(sim.mission.outcome, InfiltrationMissionState.Outcome.COMPLETED, String(sim.mission.data.id) + " tick " + str(sim.tick))
		assert_eq(sim.loadout.blaster, null)
		assert_true((sim.mission as BlasterOpsMissionState).waves_finished)


func test_wave_spawn_order_and_snapshot_replay_are_deterministic() -> void:
	var sim: BlasterOpsSimulation = _sim()
	var command: InfiltrationIntent = InfiltrationIntent.new()
	var before: Dictionary = sim.capture()
	for tick in 420:
		sim.step(command)
	var expected: Dictionary = sim.capture()
	assert_eq((sim.mission as BlasterOpsMissionState).wave_index, 0)
	assert_true(sim.targets[0].spawned)
	assert_false(sim.targets[2].spawned)
	sim.restore(before)
	for tick in 420:
		sim.step(command)
	assert_eq(sim.capture(), expected)


func test_occupied_spawn_waits_without_overlapping_player() -> void:
	var sim: BlasterOpsSimulation = _sim()
	sim.player.position = sim.targets[0].position
	for tick in 361:
		sim.step(InfiltrationIntent.new())
	assert_false(sim.targets[0].spawned)
	sim.player.position += Vector2(100, 0)
	sim.step(InfiltrationIntent.new())
	assert_true(sim.targets[0].spawned)


func test_barriers_are_limited_to_preparation_empty_cells_and_two_per_attempt() -> void:
	var sim: BlasterOpsSimulation = _sim(2)
	var progress: BlasterOpsMissionState = sim.mission as BlasterOpsMissionState
	sim.player.position = Vector2(352, 352)
	sim.player.aim = Vector2.RIGHT
	assert_true(sim.deploy_barrier())
	assert_false(sim.deploy_barrier())
	var snapshot: Dictionary = sim.capture()
	sim.player.position.y += 128.0
	assert_true(sim.deploy_barrier())
	sim.player.position.y += 128.0
	assert_false(sim.deploy_barrier())
	assert_eq(progress.barriers_placed, 2)
	sim.restore(snapshot)
	assert_eq(progress.barriers_placed, 1)
	assert_false(sim.map.is_solid(7, 7))
	progress.intermission_ticks = 0
	assert_false(sim.deploy_barrier())


func test_player_and_protected_deaths_beat_completion_and_seal_state() -> void:
	for protected in [false, true]:
		var sim: BlasterOpsSimulation = _sim(2)
		if protected:
			sim.prisoners[0].health = 0.0
		else:
			sim.player.health = 0.0
		sim.step(InfiltrationIntent.new())
		assert_eq(sim.mission.outcome, InfiltrationMissionState.Outcome.PRISONER_DOWN if protected else InfiltrationMissionState.Outcome.PLAYER_DOWN)
		var snapshot: Dictionary = sim.capture()
		sim.step(InfiltrationIntent.new())
		assert_eq(sim.capture(), snapshot)


func test_rival_and_boss_thresholds_are_inclusive_monotonic_and_restore_attack_data() -> void:
	for index in [5, 6]:
		var sim: BlasterOpsSimulation = _sim(index)
		var progress: BlasterOpsMissionState = sim.mission as BlasterOpsMissionState
		progress.intermission_ticks = 1
		sim.step(InfiltrationIntent.new())
		var actor: BlasterOpsActor = sim.targets[0] as BlasterOpsActor
		actor.health = progress.phase_health * 0.65
		sim.step(InfiltrationIntent.new())
		assert_eq(progress.phase_index, 1)
		assert_eq(sim.target_data[0], progress.definition.phases[1].enemy)
		var snapshot: Dictionary = sim.capture()
		actor.health = progress.phase_health * 0.3
		sim.step(InfiltrationIntent.new())
		assert_eq(progress.phase_index, 2)
		actor.health = progress.phase_health
		sim.step(InfiltrationIntent.new())
		assert_eq(progress.phase_index, 2)
		sim.restore(snapshot)
		assert_eq(progress.phase_index, 1)
		assert_eq(sim.target_data[0], progress.definition.phases[1].enemy)


func test_allies_receive_only_intent_and_fire_without_friendly_fire_or_player_accuracy() -> void:
	var sim: BlasterOpsSimulation = _sim()
	var progress: BlasterOpsMissionState = sim.mission as BlasterOpsMissionState
	progress.intermission_ticks = 1
	sim.step(InfiltrationIntent.new())
	progress.recruited[0] = 1
	sim.prisoners[0].position = sim.targets[0].position - Vector2(140, 0)
	var controller: InfiltrationEscortController = InfiltrationEscortController.new(sim)
	var snapshot: Dictionary = sim.capture()
	var commands: Array[InfiltrationIntent] = controller.produce_all(sim)
	assert_eq(sim.capture(), snapshot)
	assert_true((commands[0].held & Intent.Command.LIGHT) != 0)
	for tick in 30:
		sim.step(InfiltrationIntent.new(), [], controller.produce_all(sim))
	assert_lt(sim.targets[0].health, sim.target_data[0].health)
	assert_eq(progress.attempts, 0)
	assert_eq(progress.hits, 0)


func test_external_result_matches_standalone_and_is_emitted_only_once() -> void:
	var sim: BlasterOpsSimulation = _sim()
	var progress: BlasterOpsMissionState = sim.mission as BlasterOpsMissionState
	progress.waves_finished = true
	progress.attempts = 10
	progress.hits = 5
	for index in progress.recruited.size():
		progress.recruited[index] = 1
	progress.outcome = InfiltrationMissionState.Outcome.COMPLETED
	progress.finished_tick = Ticks.from_seconds(progress.data.bonus_seconds)
	var embedded: BlasterOpsMode = BlasterOpsMode.new(progress.definition, DuelMode.character(&"guardian"), null, true)
	var calls: Array[int] = [0]
	embedded.finished.connect(func(_result: BlasterOpsMissionResult) -> void: calls[0] += 1)
	var records: Dictionary = SaveService.incursion_best.duplicate(true)
	embedded.finish(sim)
	embedded.finish(sim)
	assert_eq(calls[0], 1)
	assert_eq(SaveService.incursion_best, records)
	assert_eq(embedded.sealed.rating, 4)
	assert_eq(embedded.sealed.bonuses, 15)
	var original_path: String = SaveService.path
	var unlocked: Dictionary = SaveService.unlocked.duplicate(true)
	SaveService.path = "user://task18_result_test.cfg"
	var standalone: BlasterOpsMode = BlasterOpsMode.new(progress.definition)
	standalone.finish(sim)
	assert_eq(standalone.sealed.to_dict(), embedded.sealed.to_dict())
	assert_true(SaveService.incursion_best.has(String(progress.data.id)))
	SaveService.path = original_path
	SaveService.incursion_best = records
	SaveService.unlocked = unlocked


func test_save_migrates_by_absence_and_merges_time_rating_bonuses_and_cosmetics() -> void:
	var script: GDScript = load("res://core/save_service.gd")
	var save: Node = script.new()
	save.path = "user://task18_progress_test.cfg"
	var file: ConfigFile = ConfigFile.new()
	file.set_value("progress", "version", 1)
	file.set_value("progress", "infiltration_best", {"first_access": {"ticks": 123, "bonuses": 3}})
	file.save(save.path)
	save.load_progress()
	assert_true(save.incursion_best.is_empty())
	assert_eq(save.infiltration_best.first_access.ticks, 123)
	for data in BlasterOpsMode.INCURSIONS:
		assert_true(save.record_incursion(data.id, 200, 2, 1))
		assert_true(save.record_incursion(data.id, 100, 4, 2))
		assert_false(save.record_incursion(data.id, 300, 1, 1))
	assert_true(save.unlocked.has("color:guardian:1"))
	assert_true(save.unlocked.has("costume:guardian:traveler"))
	save.load_progress()
	assert_eq(save.incursion_best.encircled_yard, {"ticks": 100, "rating": 4, "bonuses": 3})
	save.free()


func test_hold_out_opens_the_final_wave_at_the_inclusive_timer_only() -> void:
	var sim: BlasterOpsSimulation = _sim(3)
	var progress: BlasterOpsMissionState = sim.mission as BlasterOpsMissionState
	progress.intermission_ticks = 1
	sim.step(InfiltrationIntent.new())
	for actor in sim.targets:
		if actor.spawned:
			actor.health = 0.0
	sim.tick = Ticks.from_seconds(progress.definition.hold_seconds) - 2
	sim.step(InfiltrationIntent.new())
	assert_eq(progress.wave_index, 0)
	assert_false(progress.waves_finished)
	sim.step(InfiltrationIntent.new())
	assert_eq(progress.wave_index, 1)
	assert_true(sim.targets[-1].spawned)
	assert_false(progress.waves_finished)


func test_rating_boundaries_and_failure_never_award_a_grade() -> void:
	var sim: BlasterOpsSimulation = _sim()
	var progress: BlasterOpsMissionState = sim.mission as BlasterOpsMissionState
	progress.finished_tick = Ticks.from_seconds(progress.data.bonus_seconds)
	progress.damage_taken = 25.0
	progress.attempts = 2
	progress.hits = 1
	assert_eq(progress.bonuses(progress.finished_tick), 7)
	progress.damage_taken = 25.01
	assert_eq(progress.bonuses(progress.finished_tick + 1), 4)
	progress.hits = 0
	assert_eq(progress.bonuses(progress.finished_tick + 1), 0)
	progress.outcome = InfiltrationMissionState.Outcome.PLAYER_DOWN
	var mode: BlasterOpsMode = BlasterOpsMode.new(progress.definition, DuelMode.character(&"guardian"), null, true)
	mode.finish(sim)
	assert_eq(mode.sealed.rating, 0)
	assert_false(mode.sealed.won)


func test_fan_phase_prepares_before_emitting_three_distinct_projectiles() -> void:
	var sim: BlasterOpsSimulation = _sim(6)
	var progress: BlasterOpsMissionState = sim.mission as BlasterOpsMissionState
	progress.intermission_ticks = 1
	sim.step(InfiltrationIntent.new())
	sim.targets[0].health = progress.phase_health * 0.65
	sim.step(InfiltrationIntent.new())
	var controller: BlasterOpsMissionController = BlasterOpsMissionController.new(sim.map, sim.targets.size())
	var prepared: int = -1
	var fired: int = 0
	for tick in 80:
		sim.step(InfiltrationIntent.new(), controller.produce_all(sim))
		for event_index in sim.event_count:
			var event: InfiltrationEvent = sim.events[event_index]
			if event.type == InfiltrationEvent.Type.ATTACK_PREPARED:
				prepared = sim.tick
			if event.type == InfiltrationEvent.Type.SHOT_FIRED:
				fired += 1
		if fired > 0:
			break
	assert_eq(fired, 3)
	assert_true(prepared >= 0)
	assert_true(sim.tick - prepared >= Ticks.from_seconds(progress.definition.phases[1].enemy.telegraph_seconds))
	assert_ne(sim.bolts[0].velocity, sim.bolts[1].velocity)


func test_protected_escort_reuses_navigation_and_terminal_never_fires() -> void:
	for index in [2, 4]:
		var sim: BlasterOpsSimulation = _sim(index)
		var controller: InfiltrationEscortController = InfiltrationEscortController.new(sim)
		var before: Dictionary = sim.capture()
		var intent: InfiltrationIntent = controller.produce_all(sim)[0]
		assert_eq(sim.capture(), before)
		if index == 2:
			assert_eq(intent.movement, Vector2.ZERO)
			assert_eq(intent.held, 0)
		else:
			assert_gt(intent.movement.length(), 0.0)
			sim.step(InfiltrationIntent.new(), [], controller.produce_all(sim))
			assert_gt(sim.prisoners[0].position.x, before.prisoners[0].position.x)


func test_catalog_has_thirteen_unique_missions_with_translated_briefings_and_previews() -> void:
	var missions: Array[InfiltrationMissionData] = BlasterOpsMode.all_missions()
	assert_eq(missions.size(), 13)
	var ids: Dictionary = {}
	var locale: String = TranslationServer.get_locale()
	for mission in missions:
		assert_false(ids.has(mission.id))
		ids[mission.id] = true
		assert_true(mission.preview != null)
		for language in ["pt_BR", "en"]:
			TranslationServer.set_locale(language)
			assert_ne(TranslationServer.translate(mission.title_key), mission.title_key)
			assert_ne(TranslationServer.translate(mission.briefing_key), mission.briefing_key)
	TranslationServer.set_locale(locale)
