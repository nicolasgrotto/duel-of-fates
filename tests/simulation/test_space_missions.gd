extends TestCase


func _sim(index: int) -> SpaceSimulation:
	return SpaceMode.new(SpaceMode.MISSIONS[index], SpaceLoadout.new(), true).create_simulation()


func _run(index: int) -> SpaceSimulation:
	var sim: SpaceSimulation = _sim(index)
	var ai: SpaceEnemyController = SpaceEnemyController.new(sim.ships.size())
	var pilot: SpaceMissionPilot = SpaceMissionPilot.new()
	for tick in Ticks.from_seconds(sim.mission.data.limit_seconds) + 1:
		sim.step(ai.produce_all(sim, pilot.produce(sim)))
		if sim.mission.outcome != SpaceMissionState.Outcome.ACTIVE:
			break
	return sim


func test_all_five_missions_complete_with_base_loadout_and_real_commands() -> void:
	for index in SpaceMode.MISSIONS.size():
		var sim: SpaceSimulation = _run(index)
		assert_eq(sim.mission.outcome, SpaceMissionState.Outcome.COMPLETED, String(sim.mission.data.id))
		assert_true(sim.ships[0].hull > 0.0)
		assert_true(sim.mission.rating(sim) >= 1)
		assert_eq(sim.dropped_events, 0)


func test_wave_delay_and_formation_spawn_are_deterministic() -> void:
	var first: SpaceSimulation = _sim(0)
	var second: SpaceSimulation = _sim(0)
	var commands: Array[SpaceIntent] = SpaceFixture.commands(first.ships.size())
	for tick in 59:
		first.step(commands)
		second.step(commands)
	assert_false(first.ships[1].spawned)
	first.step(commands)
	second.step(commands)
	assert_true(first.ships[1].spawned)
	assert_eq(first.ships[2].position, first.arena.ships[2].position)
	assert_eq(first.state_hash(), second.state_hash())
	assert_eq(first.arena.ships[2].formation, 1)


func test_blocked_formation_slot_waits_until_clear() -> void:
	var sim: SpaceSimulation = _sim(0)
	sim.ships[0].position = sim.arena.ships[1].position
	sim.ships[0].previous = sim.ships[0].position
	var commands: Array[SpaceIntent] = SpaceFixture.commands(sim.ships.size())
	for tick in 60:
		sim.step(commands)
	assert_false(sim.ships[1].spawned)
	assert_eq(sim.mission.pending_wave, 1)
	sim.ships[0].position = Vector2(500, 900)
	sim.step(commands)
	assert_true(sim.ships[1].spawned)
	assert_eq(sim.mission.pending_wave, 0)


func test_enemy_controller_only_produces_reused_intents() -> void:
	var sim: SpaceSimulation = _sim(0)
	var ai: SpaceEnemyController = SpaceEnemyController.new(sim.ships.size())
	var player: SpaceIntent = SpaceIntent.new()
	var before: int = sim.state_hash()
	var first: Array[SpaceIntent] = ai.produce_all(sim, player)
	var identity: int = first[1].get_instance_id()
	for tick in 300:
		assert_eq(ai.produce_all(sim, player)[1].get_instance_id(), identity)
	assert_eq(sim.state_hash(), before)


func test_capital_generator_engine_and_turrets_are_independent() -> void:
	var sim: SpaceSimulation = _sim(3)
	sim._damage(2, 0, 1000.0, sim.ships[2].position)
	assert_almost(sim.ships[1].hull, 180.0)
	assert_almost(sim.ships[1].shield, 0.0)
	assert_true(sim.ships[3].hull > 0.0)
	assert_false(sim.mission.shield_online(sim, 1))
	var commands: Array[SpaceIntent] = SpaceFixture.commands(sim.ships.size())
	for tick in 180:
		sim.step(commands)
	assert_almost(sim.ships[1].shield, 0.0)
	sim._damage(3, 0, 1000.0, sim.ships[3].position)
	assert_almost(sim.mission.rotation_ratio(sim, 1), sim.config.damaged_engine_turn)
	sim._damage(4, 0, 1000.0, sim.ships[4].position)
	assert_true(sim.ships[5].hull > 0.0)
	assert_true(sim.ships[1].hull > 0.0)
	assert_eq(sim.ships[4].charges[0], -1)


func test_escort_ally_down_fails_and_seals_simulation() -> void:
	var sim: SpaceSimulation = _sim(2)
	sim._damage(1, 6, 1000.0, sim.ships[1].position)
	sim.step(SpaceFixture.commands(sim.ships.size()))
	assert_eq(sim.mission.outcome, SpaceMissionState.Outcome.ALLY_DOWN)
	var sealed: int = sim.state_hash()
	sim.step(SpaceFixture.commands(sim.ships.size()))
	assert_eq(sim.state_hash(), sealed)
	assert_eq(sim.mission.rating(sim), 0)


func test_ally_can_take_damage_from_enemy_commands() -> void:
	var sim: SpaceSimulation = _sim(2)
	var ai: SpaceEnemyController = SpaceEnemyController.new(sim.ships.size())
	var idle: SpaceIntent = SpaceIntent.new()
	var damaged: bool = false
	for tick in 3000:
		sim.step(ai.produce_all(sim, idle))
		if sim.ships[1].shield < sim.ships[1].data.shield or sim.ships[1].hull < sim.ships[1].data.hull:
			damaged = true
			break
	assert_true(damaged)


func test_player_failure_takes_priority_over_final_enemy_death() -> void:
	var sim: SpaceSimulation = _sim(4)
	sim.ships[0].hull = 0.0
	sim.ships[1].hull = 0.0
	sim.step(SpaceFixture.commands(sim.ships.size()))
	assert_eq(sim.mission.outcome, SpaceMissionState.Outcome.PLAYER_DOWN)


func test_timeout_is_inclusive_and_does_not_grant_rating() -> void:
	var sim: SpaceSimulation = _sim(4)
	sim.tick = Ticks.from_seconds(sim.mission.data.limit_seconds) - 1
	sim.step(SpaceFixture.commands(sim.ships.size()))
	assert_eq(sim.mission.outcome, SpaceMissionState.Outcome.TIMEOUT)
	assert_eq(sim.mission.rating(sim), 0)


func test_boss_opens_only_current_weakpoint_in_half_open_window() -> void:
	var sim: SpaceSimulation = _sim(4)
	var stage: SpaceBossPhase = sim.mission.data.phases[0]
	sim.mission.phase_ticks = Ticks.from_seconds(stage.open_start) - 1
	assert_false(sim.mission.can_damage(sim, 2))
	sim.mission.phase_ticks += 1
	assert_true(sim.mission.can_damage(sim, 2))
	assert_false(sim.mission.can_damage(sim, 1))
	assert_false(sim.mission.can_damage(sim, 3))
	sim.mission.phase_ticks = Ticks.from_seconds(stage.open_start + stage.open_seconds)
	assert_false(sim.mission.can_damage(sim, 2))
	var hull: float = sim.ships[2].hull
	sim._damage(2, 0, 1000.0, sim.ships[2].position)
	assert_almost(sim.ships[2].hull, hull)


func test_boss_thresholds_trigger_once_without_healing_or_double_damage() -> void:
	var sim: SpaceSimulation = _sim(4)
	var commands: Array[SpaceIntent] = SpaceFixture.commands(sim.ships.size())
	sim.mission.phase_ticks = 60
	sim._damage(2, 0, 1000.0, sim.ships[2].position)
	assert_almost(sim.ships[1].hull, 160.0)
	sim.step(commands)
	assert_eq(sim.mission.phase, 1)
	assert_eq(sim.mission.phase_visits, PackedInt32Array([1, 1, 0]))
	sim.mission.phase_ticks = 60
	sim._damage(3, 0, 1000.0, sim.ships[3].position)
	sim.step(commands)
	assert_eq(sim.mission.phase, 2)
	assert_almost(sim.ships[1].hull, 80.0)
	for tick in 200:
		sim.step(commands)
	assert_eq(sim.mission.phase_visits, PackedInt32Array([1, 1, 1]))
	assert_almost(sim.ships[2].hull, 0.0)
	assert_eq(sim.weapon(1, 0).count, 5)


func test_snapshot_restores_wave_boss_and_projectile_identity() -> void:
	var sim: SpaceSimulation = _sim(4)
	var ai: SpaceEnemyController = SpaceEnemyController.new(sim.ships.size())
	var pilot: SpaceMissionPilot = SpaceMissionPilot.new()
	for tick in 600:
		sim.step(ai.produce_all(sim, pilot.produce(sim)))
	var state: Dictionary = sim.capture()
	var hash_before: int = sim.state_hash()
	var object_id: int = sim.projectiles[0].get_instance_id()
	for tick in 30:
		sim.step(ai.produce_all(sim, pilot.produce(sim)))
	sim.restore(state)
	assert_eq(sim.state_hash(), hash_before)
	assert_eq(sim.projectiles[0].get_instance_id(), object_id)


func test_obstacle_separates_hull_and_consumes_projectiles() -> void:
	var sim: SpaceSimulation = _sim(0)
	var obstacle: SpaceObstacleData = sim.arena.obstacles[0]
	sim.ships[0].position = obstacle.position
	sim.step(SpaceFixture.commands(sim.ships.size()))
	assert_true(sim.ships[0].position.distance_to(obstacle.position) >= obstacle.radius + sim.ships[0].data.radius - 0.01)
	assert_almost(sim.ships[0].hull, sim.ships[0].data.hull)
	sim.ships[0].position = obstacle.position - Vector2(120, 0)
	sim.ships[0].angle = 0.0
	var commands: Array[SpaceIntent] = SpaceFixture.commands(sim.ships.size())
	commands[0].held = SpaceIntent.Command.PRIMARY
	sim.step(commands)
	commands[0].clear()
	for tick in 10:
		sim.step(commands)
	assert_false(sim.projectiles[0].active)
