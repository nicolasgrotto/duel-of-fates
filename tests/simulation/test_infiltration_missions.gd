extends TestCase

const CONFIG: InfiltrationConfig = preload("res://data/balance/infiltration_config.tres")


func _sim(index: int = 0) -> InfiltrationSimulation:
	var mission: InfiltrationMissionData = InfiltrationMode.MISSIONS[index]
	return InfiltrationSimulation.new(CONFIG, mission.map, mission)


func _play(index: int, aggressive: bool = false) -> InfiltrationSimulation:
	var sim: InfiltrationSimulation = _sim(index)
	var route: InfiltrationRoute = InfiltrationRoute.new(sim, aggressive)
	var enemies: InfiltrationEnemyController = InfiltrationEnemyController.new(sim.map, sim.targets.size())
	var escorts: InfiltrationEscortController = InfiltrationEscortController.new(sim)
	for tick in 18000:
		sim.step(route.produce(sim), enemies.produce_all(sim), escorts.produce_all(sim))
		if sim.mission.outcome != InfiltrationMissionState.Outcome.ACTIVE:
			break
	return sim


func test_tutorial_stealth_route_completes_without_alarm_or_takedowns() -> void:
	var sim: InfiltrationSimulation = _play(0)
	assert_eq(sim.mission.outcome, InfiltrationMissionState.Outcome.COMPLETED)
	assert_eq(sim.mission.bonuses(sim.tick), 7)


func test_sabotage_stealth_route_completes_both_panels() -> void:
	var sim: InfiltrationSimulation = _play(1)
	assert_eq(sim.mission.outcome, InfiltrationMissionState.Outcome.COMPLETED)
	assert_true(sim.panels[0].disabled and sim.panels[1].disabled)
	assert_eq(sim.mission.bonuses(sim.tick), 7)


func test_information_stealth_route_copies_then_extracts() -> void:
	var sim: InfiltrationSimulation = _play(2)
	assert_eq(sim.mission.outcome, InfiltrationMissionState.Outcome.COMPLETED)
	assert_eq(sim.mission.copied[0], 1)
	assert_eq(sim.mission.bonuses(sim.tick), 7)


func test_rescue_stealth_route_escorts_prisoner_to_exit() -> void:
	var sim: InfiltrationSimulation = _play(3)
	assert_eq(sim.mission.outcome, InfiltrationMissionState.Outcome.COMPLETED)
	assert_eq(sim.mission.recruited[0], 1)
	assert_eq(sim.mission.extracted[0], 1)
	assert_true(sim.prisoners[0].position.distance_to(sim.mission.data.extraction) <= sim.mission.data.extraction_radius)
	assert_eq(sim.mission.bonuses(sim.tick), 7)


func test_tutorial_aggressive_route_can_neutralize_guard_and_extract() -> void:
	var sim: InfiltrationSimulation = _play(0, true)
	assert_eq(sim.mission.outcome, InfiltrationMissionState.Outcome.COMPLETED)
	assert_true(sim.mission.takedowns > 0)
	assert_eq(sim.mission.bonuses(sim.tick) & InfiltrationMissionState.Bonus.NO_TAKEDOWNS, 0)


func test_sabotage_aggressive_route_completes_after_alarm() -> void:
	var sim: InfiltrationSimulation = _play(1, true)
	assert_eq(sim.mission.outcome, InfiltrationMissionState.Outcome.COMPLETED)
	assert_true(sim.mission.alarm_raised)
	assert_true(sim.mission.takedowns > 0)


func test_information_aggressive_route_completes_after_alarm() -> void:
	var sim: InfiltrationSimulation = _play(2, true)
	assert_eq(sim.mission.outcome, InfiltrationMissionState.Outcome.COMPLETED)
	assert_true(sim.mission.alarm_raised)


func test_rescue_aggressive_route_keeps_escort_alive() -> void:
	var sim: InfiltrationSimulation = _play(3, true)
	assert_eq(sim.mission.outcome, InfiltrationMissionState.Outcome.COMPLETED)
	assert_true(sim.mission.alarm_raised)
	assert_true(sim.prisoners[0].health > 0.0)


func test_exit_does_not_complete_missing_objectives() -> void:
	for index in 4:
		var sim: InfiltrationSimulation = _sim(index)
		sim.player.position = sim.mission.data.extraction
		sim.step(InfiltrationIntent.new())
		assert_eq(sim.mission.outcome, InfiltrationMissionState.Outcome.ACTIVE)


func test_interaction_requires_range_and_clear_line_and_only_one_object() -> void:
	var sim: InfiltrationSimulation = _sim(2)
	var intent: InfiltrationIntent = InfiltrationIntent.new()
	intent.pressed = Intent.Command.POWER
	sim.step(intent)
	assert_eq(sim.mission.copied[0], 0)
	sim.player.position = sim.mission.data.terminals[0]
	sim.step(intent)
	assert_eq(sim.mission.copied[0], 1)
	assert_false(sim.panels[0].disabled)


func test_player_downed_has_priority_over_exit_and_freezes_ticks() -> void:
	var sim: InfiltrationSimulation = _sim()
	sim.panels[0].disabled = true
	sim.player.position = sim.mission.data.extraction
	sim.player.health = 0.0
	sim.step(InfiltrationIntent.new())
	assert_eq(sim.mission.outcome, InfiltrationMissionState.Outcome.PLAYER_DOWN)
	var sealed: int = sim.state_hash()
	sim.step(InfiltrationIntent.new())
	assert_eq(sim.state_hash(), sealed)


func test_prisoner_downed_fails_before_success() -> void:
	var sim: InfiltrationSimulation = _sim(3)
	sim.mission.recruited[0] = 1
	sim.prisoners[0].position = sim.mission.data.extraction
	sim.prisoners[0].health = 0.0
	sim.player.position = sim.mission.data.extraction
	sim.step(InfiltrationIntent.new())
	assert_eq(sim.mission.outcome, InfiltrationMissionState.Outcome.PRISONER_DOWN)


func test_enemy_and_reflected_bolts_can_down_prisoner_without_friendly_swing_damage() -> void:
	for owner in [0, 1]:
		var sim: InfiltrationSimulation = _sim(3)
		var actor: InfiltrationActor = sim.prisoners[0]
		var bolt: InfiltrationBolt = sim.bolts[0]
		bolt.data = sim.target_data[0].bolt.duplicate() as BoltData
		bolt.data.damage = CONFIG.prisoner_health
		bolt.active = true
		bolt.owner = owner
		bolt.position = actor.position - Vector2(40, 0)
		bolt.velocity = Vector2(900, 0)
		for tick in 4:
			sim.step(InfiltrationIntent.new())
		assert_eq(sim.mission.outcome, InfiltrationMissionState.Outcome.PRISONER_DOWN)


func test_alarm_history_survives_disabling_sirens_and_time_bonus_is_inclusive() -> void:
	var sim: InfiltrationSimulation = _sim()
	sim.panels[0].active = true
	sim.mission.advance(sim, [])
	sim.panels[0].active = false
	sim.panels[0].disabled = true
	assert_true(sim.mission.alarm_raised)
	assert_eq(sim.mission.bonuses(Ticks.from_seconds(45.0)), 6)
	assert_eq(sim.mission.bonuses(Ticks.from_seconds(45.0) + 1), 2)


func test_mission_snapshot_restores_copies_escort_and_history_without_aliases() -> void:
	var sim: InfiltrationSimulation = _sim(3)
	sim.mission.recruited[0] = 1
	var saved: Dictionary = sim.capture()
	var before: int = sim.state_hash()
	sim.mission.recruited[0] = 0
	sim.mission.alarm_raised = true
	sim.prisoners[0].position += Vector2(50, 0)
	sim.restore(saved)
	assert_eq(sim.state_hash(), before)
	sim.mission.recruited[0] = 0
	assert_eq(saved.mission.recruited[0], 1)


func test_mission_replay_is_deterministic_with_external_controllers() -> void:
	var first: InfiltrationSimulation = _sim(3)
	var second: InfiltrationSimulation = _sim(3)
	var route: InfiltrationRoute = InfiltrationRoute.new(first)
	var enemies: InfiltrationEnemyController = InfiltrationEnemyController.new(first.map, first.targets.size())
	var escorts: InfiltrationEscortController = InfiltrationEscortController.new(first)
	for tick in 3000:
		var command: InfiltrationIntent = route.produce(first)
		var enemy_intents: Array[InfiltrationIntent] = enemies.produce_all(first)
		var escort_intents: Array[InfiltrationIntent] = escorts.produce_all(first)
		first.step(command, enemy_intents, escort_intents)
		second.step(command, enemy_intents, escort_intents)
		if tick % 120 == 0:
			assert_eq(first.state_hash(), second.state_hash())
	assert_eq(first.state_hash(), second.state_hash())


func test_interaction_cannot_copy_through_wall_inside_interaction_radius() -> void:
	var data: InfiltrationMissionData = InfiltrationMode.MISSIONS[2].duplicate() as InfiltrationMissionData
	data.map = InfiltrationMapData.new()
	data.map.rows = PackedStringArray(["#####", "#.#.#", "#...#", "#...#", "#####"])
	data.map.player_spawn = Vector2(108, 96)
	data.terminals = PackedVector2Array([Vector2(160, 146)])
	data.extraction = Vector2(96, 224)
	var sim: InfiltrationSimulation = InfiltrationSimulation.new(CONFIG, data.map, data)
	var command: InfiltrationIntent = InfiltrationIntent.new()
	command.pressed = Intent.Command.POWER
	sim.step(command)
	assert_eq(sim.mission.copied[0], 0)
	sim.player.position = Vector2(160, 190)
	sim.step(command)
	assert_eq(sim.mission.copied[0], 1)


func test_panel_priority_does_not_recruit_with_same_interaction_press() -> void:
	var data: InfiltrationMissionData = InfiltrationMode.MISSIONS[3].duplicate() as InfiltrationMissionData
	data.map = data.map.duplicate() as InfiltrationMapData
	var panel: InfiltrationPanelData = InfiltrationPanelData.new()
	panel.position = data.prisoner_spawns[0]
	data.map.panels = [panel]
	data.map.player_spawn = panel.position
	var sim: InfiltrationSimulation = InfiltrationSimulation.new(CONFIG, data.map, data)
	var command: InfiltrationIntent = InfiltrationIntent.new()
	command.pressed = Intent.Command.POWER
	sim.step(command)
	assert_true(sim.panels[0].disabled)
	assert_eq(sim.mission.recruited[0], 0)
	sim.step(command)
	assert_eq(sim.mission.recruited[0], 1)


func test_recruiting_does_not_extract_prisoner_left_behind() -> void:
	var sim: InfiltrationSimulation = _sim(3)
	sim.mission.recruited[0] = 1
	sim.player.position = sim.mission.data.extraction
	sim.step(InfiltrationIntent.new())
	assert_eq(sim.mission.outcome, InfiltrationMissionState.Outcome.ACTIVE)
	assert_eq(sim.mission.extracted[0], 0)


func test_escort_controller_only_produces_intents_and_simulation_clips_walls() -> void:
	var sim: InfiltrationSimulation = _sim(3)
	sim.mission.recruited[0] = 1
	sim.player.position = Vector2(1632, 672)
	var controller: InfiltrationEscortController = InfiltrationEscortController.new(sim)
	var before: int = sim.state_hash()
	var commands: Array[InfiltrationIntent] = controller.produce_all(sim)
	assert_eq(sim.state_hash(), before)
	assert_true(commands[0].movement.length_squared() > 0.0)
	var start: Vector2 = sim.prisoners[0].position
	for tick in 600:
		var previous: Vector2 = sim.prisoners[0].position
		sim.step(InfiltrationIntent.new(), [], controller.produce_all(sim))
		assert_eq(InfiltrationGeometry.wall_fraction(sim.map, sim.prisoners[0].position, sim.prisoners[0].position, CONFIG.body_radius), INF)
		assert_true(previous.distance_to(sim.prisoners[0].position) <= CONFIG.escort_speed * Ticks.DELTA + 0.001)
	assert_true(sim.prisoners[0].position.distance_to(start) > 100.0)


func test_snapshot_replay_restores_mission_then_repeats_escort_ticks() -> void:
	var first: InfiltrationSimulation = _sim(3)
	first.mission.recruited[0] = 1
	first.player.position = Vector2(224, 1056)
	var saved: Dictionary = first.capture()
	var escort: InfiltrationEscortController = InfiltrationEscortController.new(first)
	for tick in 600:
		first.step(InfiltrationIntent.new(), [], escort.produce_all(first))
	var expected: int = first.state_hash()
	first.restore(saved)
	for tick in 600:
		first.step(InfiltrationIntent.new(), [], escort.produce_all(first))
	assert_eq(first.state_hash(), expected)


func test_friendly_swing_never_damages_prisoner() -> void:
	var sim: InfiltrationSimulation = _sim(3)
	sim.player.position = sim.prisoners[0].position - Vector2(50, 0)
	var command: InfiltrationIntent = InfiltrationIntent.new()
	command.aim = Vector2.RIGHT
	command.pressed = Intent.Command.LIGHT
	sim.step(command)
	command.pressed = 0
	for tick in 30:
		sim.step(command)
	assert_eq(sim.prisoners[0].health, CONFIG.prisoner_health)


func test_mission_rules_work_when_presentation_event_pool_is_exhausted() -> void:
	var config: InfiltrationConfig = CONFIG.duplicate() as InfiltrationConfig
	config.event_capacity = 0
	var data: InfiltrationMissionData = InfiltrationMode.MISSIONS[0]
	var sim: InfiltrationSimulation = InfiltrationSimulation.new(config, data.map, data)
	var route: InfiltrationRoute = InfiltrationRoute.new(sim, true)
	var enemies: InfiltrationEnemyController = InfiltrationEnemyController.new(sim.map, sim.targets.size())
	for tick in 6000:
		sim.step(route.produce(sim), enemies.produce_all(sim))
		if sim.mission.outcome != InfiltrationMissionState.Outcome.ACTIVE:
			break
	assert_eq(sim.mission.outcome, InfiltrationMissionState.Outcome.COMPLETED)
	assert_true(sim.mission.takedowns > 0)
	assert_true(sim.dropped_events > 0)
	assert_eq(sim.mission.bonuses(sim.tick) & InfiltrationMissionState.Bonus.NO_TAKEDOWNS, 0)
