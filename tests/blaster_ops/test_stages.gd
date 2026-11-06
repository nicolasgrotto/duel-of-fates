extends TestCase


func _play(index: int) -> BlasterOpsSimulation:
	var sim: BlasterOpsSimulation = BlasterOpsMode.new(BlasterOpsMode.INCURSIONS[index], DuelMode.character(&"guardian"), null, true).create_simulation()
	return sim


func _stage_sim(stages: Array[BlasterOpsStageData], waves: int = 1) -> BlasterOpsSimulation:
	var enemies: Array[BlasterOpsEnemyData] = []
	for index in waves:
		enemies.append(BlasterOpsFixture.enemy("soldier"))
	var mission: BlasterOpsMissionData = BlasterOpsMissionData.new()
	mission.objective = InfiltrationMissionData.Objective.INCURSION
	var arena: BlasterOpsArenaData = BlasterOpsFixture.arena(enemies, true)
	arena.enemies_alerted = false
	arena.covers[0].door = true
	for placement in arena.enemies:
		placement.reinforcement = true
	mission.map = arena
	mission.extraction = Vector2(1300, 700)
	var list: Array[BlasterOpsWaveData] = []
	for index in waves:
		var wave: BlasterOpsWaveData = BlasterOpsWaveData.new()
		wave.indices = PackedInt32Array([index])
		list.append(wave)
	mission.waves = list
	mission.stages = stages
	mission.intermission_seconds = 0.0
	return BlasterOpsSimulation.new(BlasterOpsTraining.CONFIG, arena, BlasterOpsTraining.PISTOL.duplicate(), mission)


func _stage(objective: BlasterOpsStageData.Objective, first: int = -1) -> BlasterOpsStageData:
	var stage: BlasterOpsStageData = BlasterOpsStageData.new()
	stage.objective = objective
	stage.first_wave = first
	stage.last_wave = first
	stage.prep_seconds = 0.1
	stage.title_key = "OPS_GOAL"
	return stage


func _tick(sim: BlasterOpsSimulation, count: int = 12) -> void:
	var intent: InfiltrationIntent = InfiltrationIntent.new()
	for tick in count:
		sim.step(intent)


func test_every_mission_has_several_distinct_stages_and_translated_titles() -> void:
	for mission in BlasterOpsMode.INCURSIONS:
		assert_gt(mission.stages.size(), 3, String(mission.id))
		var kinds: Dictionary = {}
		for stage in mission.stages:
			kinds[stage.objective] = true
			assert_ne(tr(stage.title_key), stage.title_key, stage.title_key)
		assert_gt(kinds.size(), 1, String(mission.id))


func test_every_mission_mixes_enemy_roles_and_the_final_operation_has_the_most_stages() -> void:
	var longest: int = 0
	for mission in BlasterOpsMode.INCURSIONS:
		var roles: Dictionary = {}
		for placement in mission.map.enemies:
			roles[placement.enemy.id] = true
		assert_gt(roles.size(), 4, String(mission.id))
		longest = maxi(longest, mission.stages.size())
	assert_eq(BlasterOpsMode.INCURSIONS[6].stages.size(), longest)


func test_mission_ids_rewards_and_kinds_are_preserved() -> void:
	var ids: Array[StringName] = [&"encircled_yard", &"breach_line", &"defense_node", &"extraction_window", &"ally_corridor", &"retreat_vector", &"siege_core"]
	for index in ids.size():
		assert_eq(BlasterOpsMode.INCURSIONS[index].id, ids[index])
		assert_eq(int(BlasterOpsMode.INCURSIONS[index].kind), index)


func test_common_enemies_keep_their_health_so_length_does_not_come_from_inflation() -> void:
	assert_eq(BlasterOpsFixture.enemy("soldier").health, 24.0)
	assert_eq(BlasterOpsFixture.enemy("rusher").health, 28.0)
	assert_eq(BlasterOpsFixture.enemy("heavy").health, 48.0)


func test_allies_never_exceed_the_measured_limit() -> void:
	for mission in BlasterOpsMode.INCURSIONS:
		var count: int = mission.prisoner_spawns.size() - (1 if mission.protected_index >= 0 else 0)
		assert_true(count <= BlasterOpsTraining.CONFIG.max_allies, String(mission.id))


func test_supply_terminals_exist_only_in_selected_longer_missions() -> void:
	var with_terminals: int = 0
	for mission in BlasterOpsMode.INCURSIONS:
		with_terminals += int(not mission.supply_terminals.is_empty())
	assert_gt(with_terminals, 0)
	assert_lt(with_terminals, BlasterOpsMode.INCURSIONS.size())
	assert_false(BlasterOpsMode.INCURSIONS[6].supply_terminals.is_empty())


func test_clear_stage_waits_for_the_wave_and_opens_its_door() -> void:
	var stage: BlasterOpsStageData = _stage(BlasterOpsStageData.Objective.CLEAR, 0)
	stage.opens_covers = PackedInt32Array([0])
	var other: BlasterOpsStageData = _stage(BlasterOpsStageData.Objective.REACH)
	other.zone = Vector2(900, 900)
	other.zone_radius = 64.0
	var sim: BlasterOpsSimulation = _stage_sim([stage, other] as Array[BlasterOpsStageData])
	var progress: BlasterOpsMissionState = sim.mission as BlasterOpsMissionState
	_tick(sim)
	assert_eq(progress.stage_index, 0)
	assert_true(sim.targets[0].spawned)
	var cell: Vector2i = sim.arena.covers[0].data.cell
	assert_true(sim.map.is_solid(cell.x, cell.y))
	sim._damage_target(0, 999.0)
	var revision: int = sim.cover_revision
	_tick(sim, 2)
	assert_eq(progress.stage_index, 1)
	assert_false(sim.map.is_solid(cell.x, cell.y))
	assert_gt(sim.cover_revision, revision)


func test_doors_ignore_every_kind_of_damage() -> void:
	var sim: BlasterOpsSimulation = _stage_sim([_stage(BlasterOpsStageData.Objective.CLEAR, 0)] as Array[BlasterOpsStageData])
	var door: BlasterOpsCover = sim.arena.covers[0]
	sim._damage_cover(0, 999.0, Vector2.ZERO)
	sim.apply_area_damage(BlasterOpsFaction.Side.HOSTILE, sim.cover_center(0), 200.0, 999.0, 1)
	sim.apply_area_damage(BlasterOpsFaction.Side.ALLIED, sim.cover_center(0), 200.0, 999.0, 0)
	assert_gt(door.health, 0.0)


func test_hold_only_counts_inside_the_mark_and_shows_progress_through_state() -> void:
	var stage: BlasterOpsStageData = _stage(BlasterOpsStageData.Objective.HOLD)
	stage.hold_seconds = 0.5
	stage.zone = Vector2(160, 416)
	stage.zone_radius = 64.0
	var sim: BlasterOpsSimulation = _stage_sim([stage] as Array[BlasterOpsStageData])
	var progress: BlasterOpsMissionState = sim.mission as BlasterOpsMissionState
	sim.player.position = Vector2(700, 700)
	_tick(sim, 60)
	assert_eq(progress.hold_ticks, 0)
	sim.player.position = stage.zone
	_tick(sim, 20)
	assert_gt(progress.hold_ticks, 0)
	assert_false(progress.waves_finished)
	_tick(sim, 40)
	assert_true(progress.waves_finished)


func test_interact_stage_needs_all_its_terminals() -> void:
	var stage: BlasterOpsStageData = _stage(BlasterOpsStageData.Objective.INTERACT)
	stage.terminals = PackedInt32Array([0, 1])
	var sim: BlasterOpsSimulation = _stage_sim([stage] as Array[BlasterOpsStageData])
	var mission: BlasterOpsMissionData = sim.mission.definition
	mission.terminals = PackedVector2Array([Vector2(200, 200), Vector2(300, 300)])
	sim.mission.copied.resize(2)
	_tick(sim)
	sim.mission.copied[0] = 1
	_tick(sim, 2)
	assert_false((sim.mission as BlasterOpsMissionState).waves_finished)
	assert_eq((sim.mission as BlasterOpsMissionState).objective_point(sim), Vector2(300, 300))
	sim.mission.copied[1] = 1
	_tick(sim, 2)
	assert_true((sim.mission as BlasterOpsMissionState).waves_finished)


func test_stage_completion_repairs_earns_supplies_and_objectives_count_up() -> void:
	var stage: BlasterOpsStageData = _stage(BlasterOpsStageData.Objective.REACH)
	stage.zone = Vector2(160, 416)
	stage.zone_radius = 64.0
	stage.repair_on_complete = 30.0
	stage.supply_reward = 3
	var sim: BlasterOpsSimulation = _stage_sim([stage, _stage(BlasterOpsStageData.Objective.CLEAR, 0)] as Array[BlasterOpsStageData])
	var progress: BlasterOpsMissionState = sim.mission as BlasterOpsMissionState
	sim.mission.definition.supply_terminals = PackedVector2Array([Vector2(500, 500)])
	sim.player.health = 50.0
	_tick(sim)
	assert_eq(sim.player.health, 80.0)
	assert_eq(progress.supplies, 3)
	assert_eq(progress.completed_objectives(sim), 1)
	assert_eq(sim.mission.definition.objective_count(), 2)


func test_gap_timer_brings_the_next_wave_without_waiting_for_a_clear() -> void:
	var stage: BlasterOpsStageData = _stage(BlasterOpsStageData.Objective.HOLD, 0)
	stage.last_wave = 1
	stage.wave_gap_seconds = 0.2
	stage.hold_seconds = 99.0
	var sim: BlasterOpsSimulation = _stage_sim([stage] as Array[BlasterOpsStageData], 2)
	_tick(sim, 40)
	assert_true(sim.targets[0].spawned)
	assert_true(sim.targets[1].spawned)


func test_escort_goal_moves_only_on_escort_stages() -> void:
	var sim: BlasterOpsSimulation = _play(4)
	var progress: BlasterOpsMissionState = sim.mission as BlasterOpsMissionState
	_tick(sim, 1)
	assert_ne(progress.escort_goal(), Vector2.INF)
	progress.stage_index = 1
	assert_eq(progress.escort_goal(), Vector2.INF)


func test_stage_state_replays_identically_from_a_snapshot() -> void:
	var sim: BlasterOpsSimulation = _play(0)
	var intent: InfiltrationIntent = InfiltrationIntent.new()
	for tick in 500:
		sim.step(intent)
	var snapshot: Dictionary = sim.capture()
	for tick in 60:
		sim.step(intent)
	var expected: Dictionary = sim.capture()
	sim.restore(snapshot)
	for tick in 60:
		sim.step(intent)
	assert_eq(sim.capture(), expected)


func test_generated_maps_stay_within_the_measured_active_enemy_limit_per_wave() -> void:
	for mission in BlasterOpsMode.INCURSIONS:
		for wave in mission.waves:
			assert_true(wave.indices.size() <= BlasterOpsTraining.CONFIG.max_active_enemies)


func test_old_saved_records_keep_rating_and_lose_only_the_old_time() -> void:
	var service: Node = load("res://core/save_service.gd").new()
	var migrated: Dictionary = service._migrate_incursions({"breach_line": {"ticks": 900, "rating": 3, "bonuses": 5}})
	assert_false(migrated.breach_line.has("ticks"))
	assert_eq(migrated.breach_line.rating, 3)
	assert_eq(migrated.breach_line.bonuses, 5)
	var kept: Dictionary = service._migrate_incursions({"breach_line": {"ticks": 900, "rating": 3, "bonuses": 5, "layout": BlasterOpsMode.RECORD_LAYOUT}})
	assert_eq(kept.breach_line.ticks, 900)
	service.free()


func test_threat_markers_stay_inside_the_view_and_point_toward_the_enemy() -> void:
	var rect: Rect2 = Rect2(0, 0, 960, 540)
	var marker: Vector2 = BlasterOpsView.threat_marker(rect, Vector2(2000, 270), 26.0)
	assert_true(rect.grow(-25.0).has_point(marker))
	assert_almost(marker.x, 934.0)
	assert_almost(marker.y, 270.0)
	var corner: Vector2 = BlasterOpsView.threat_marker(rect, Vector2(-500, -500), 26.0)
	assert_true(rect.grow(-25.0).has_point(corner))
	assert_lt(corner.x, 480.0)
	assert_lt(corner.y, 270.0)
