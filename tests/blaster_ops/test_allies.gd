extends TestCase

const POINT: Vector2 = Vector2(300, 416)


func _role(name: String) -> BlasterOpsAllyData:
	return load("res://data/blaster_ops/allies/%s.tres" % name)


func _sim(roles: Array[BlasterOpsAllyData], enemies: Array[BlasterOpsEnemyData] = [], reserve_start: int = -1) -> BlasterOpsSimulation:
	var mission: BlasterOpsMissionData = BlasterOpsMissionData.new()
	mission.objective = InfiltrationMissionData.Objective.INCURSION
	mission.map = BlasterOpsFixture.arena(enemies)
	(mission.map as BlasterOpsArenaData).enemies_alerted = false
	var spawns: PackedVector2Array = []
	for index in roles.size():
		spawns.append(POINT + Vector2(0, 40.0 * index))
	mission.prisoner_spawns = spawns
	mission.ally_roles = roles
	mission.reserve_start = reserve_start
	mission.extraction = Vector2(1300, 700)
	var wave: BlasterOpsWaveData = BlasterOpsWaveData.new()
	mission.waves = [wave] as Array[BlasterOpsWaveData]
	return BlasterOpsSimulation.new(BlasterOpsTraining.CONFIG, mission.map, BlasterOpsTraining.PISTOL.duplicate(), mission)


func _run(sim: BlasterOpsSimulation, ticks: int, enemy_controller: BlasterOpsEnemyController = null) -> void:
	var escorts: InfiltrationEscortController = InfiltrationEscortController.new(sim)
	var intent: InfiltrationIntent = InfiltrationIntent.new()
	for tick in ticks:
		var empty: Array[InfiltrationIntent] = []
		sim.step(intent, enemy_controller.produce_all(sim) if enemy_controller != null else empty, escorts.produce_all(sim))


func test_each_role_has_its_own_sprite_stats_and_translated_name() -> void:
	var seen: Dictionary = {}
	for name in ["rifleman", "gunner", "sharpshooter", "medic", "blade"]:
		var role: BlasterOpsAllyData = _role(name)
		assert_true(role.texture != null, name)
		assert_ne(tr(role.name_key), role.name_key)
		seen[[role.bolt != null, role.melee_damage > 0.0, role.repair_per_second > 0.0, role.speed, role.fire_range]] = true
	assert_eq(seen.size(), 5)


func test_rifleman_fires_on_its_own_through_intents() -> void:
	var sim: BlasterOpsSimulation = _sim([_role("rifleman")], [BlasterOpsFixture.enemy("soldier")])
	sim.mission.recruited[0] = 1
	assert_eq(sim.prisoners[0].health, _role("rifleman").health)
	var health: float = sim.targets[0].health
	_run(sim, 90)
	assert_lt(sim.targets[0].health, health)
	assert_eq((sim.mission as BlasterOpsMissionState).attempts, 0)
	assert_eq(sim.player.health, BlasterOpsTraining.CONFIG.health)


func test_prisoner_without_a_role_keeps_the_original_fire_rule() -> void:
	var sim: BlasterOpsSimulation = _sim([null], [BlasterOpsFixture.enemy("soldier")])
	sim.mission.recruited[0] = 1
	assert_eq(sim.prisoners[0].health, BlasterOpsTraining.CONFIG.prisoner_health)
	var health: float = sim.targets[0].health
	_run(sim, 90)
	assert_lt(sim.targets[0].health, health)


func test_medic_never_fires_and_repairs_player_and_allies_without_exceeding_maximum() -> void:
	var sim: BlasterOpsSimulation = _sim([_role("medic"), _role("rifleman")])
	sim.mission.recruited[0] = 1
	sim.mission.recruited[1] = 1
	sim.player.position = POINT + Vector2(-60, 0)
	sim.player.health = 50.0
	sim.prisoners[1].health = 80.0
	_run(sim, 120)
	assert_gt(sim.player.health, 50.0)
	assert_gt(sim.prisoners[1].health, 80.0)
	assert_true(sim.prisoners[1].health <= _role("rifleman").health)
	for bolt in sim.bolts:
		assert_false(bolt.active)


func test_blade_guard_engages_nearby_enemies_and_cuts_them() -> void:
	var sim: BlasterOpsSimulation = _sim([_role("blade")], [BlasterOpsFixture.enemy("soldier")])
	sim.mission.recruited[0] = 1
	sim.targets[0].position = sim.player.position + Vector2(200, 0)
	sim.prisoners[0].position = sim.player.position + Vector2(40, 0)
	var health: float = sim.targets[0].health
	_run(sim, 120)
	assert_lt(sim.targets[0].health, health)


func test_blade_guard_stays_with_the_player_when_enemies_are_far() -> void:
	var sim: BlasterOpsSimulation = _sim([_role("blade")], [BlasterOpsFixture.enemy("soldier")])
	sim.mission.recruited[0] = 1
	sim.prisoners[0].position = sim.player.position + Vector2(100, 0)
	_run(sim, 60)
	assert_lt(sim.prisoners[0].position.distance_to(sim.player.position), 120.0)
	assert_eq(sim.targets[0].health, sim.target_data[0].health)


func test_escort_controller_produces_intents_without_touching_the_simulation() -> void:
	var sim: BlasterOpsSimulation = _sim([_role("gunner"), _role("blade"), _role("medic")], [BlasterOpsFixture.enemy("soldier")])
	for index in 3:
		sim.mission.recruited[index] = 1
	var controller: InfiltrationEscortController = InfiltrationEscortController.new(sim)
	var snapshot: Dictionary = sim.capture()
	controller.produce_all(sim)
	assert_eq(sim.capture(), snapshot)


func test_followers_move_at_the_speed_of_their_role() -> void:
	var slow: BlasterOpsSimulation = _sim([_role("gunner")])
	var fast: BlasterOpsSimulation = _sim([_role("blade")])
	for sim in [slow, fast]:
		sim.mission.recruited[0] = 1
		sim.prisoners[0].position = sim.player.position + Vector2(400, 0)
		sim.prisoners[0].previous = sim.prisoners[0].position
		_run(sim, 30)
	assert_gt(fast.player.position.distance_to(slow.prisoners[0].position), fast.player.position.distance_to(fast.prisoners[0].position))


func test_allies_keep_fighting_at_the_exit_until_the_waves_are_over() -> void:
	var sim: BlasterOpsSimulation = _sim([_role("rifleman")])
	sim.mission.recruited[0] = 1
	sim.prisoners[0].position = sim.mission.data.extraction
	var progress: BlasterOpsMissionState = sim.mission as BlasterOpsMissionState
	assert_false(progress.can_extract(0))
	progress.waves_finished = true
	assert_true(progress.can_extract(0))


func test_reserve_slots_are_hidden_inert_and_ignored_until_called() -> void:
	var sim: BlasterOpsSimulation = _sim([_role("rifleman"), _role("gunner")], [], 1)
	var progress: BlasterOpsMissionState = sim.mission as BlasterOpsMissionState
	assert_eq(sim.prisoners[1].health, 0.0)
	sim.player.position = sim.prisoners[1].position
	assert_ne(progress.nearby_object(sim), 1)
	progress.recruited[0] = 1
	assert_true(progress.bonus_objective(sim))
	assert_true(progress.call_reinforcement(sim, POINT))
	assert_eq(progress.recruited[1], 1)
	assert_eq(sim.prisoners[1].health, _role("gunner").health)
	assert_eq(sim.prisoners[1].position, POINT)
	assert_false(progress.call_reinforcement(sim, POINT))


func test_enemies_can_still_kill_allies_and_a_required_ally_fails_the_mission() -> void:
	var sim: BlasterOpsSimulation = _sim([_role("rifleman")])
	(sim.mission.data as BlasterOpsMissionData).minimum_prisoners = 1
	sim.mission.recruited[0] = 1
	sim.prisoners[0].health = 1.0
	sim.apply_area_damage(BlasterOpsFaction.Side.HOSTILE, sim.prisoners[0].position, 40.0, 5.0, 1)
	_run(sim, 1)
	assert_eq(sim.mission.outcome, InfiltrationMissionState.Outcome.PRISONER_DOWN)


func test_ally_state_replays_identically_from_a_snapshot() -> void:
	var sim: BlasterOpsSimulation = _sim([_role("rifleman"), _role("medic")], [BlasterOpsFixture.enemy("soldier")])
	sim.mission.recruited[0] = 1
	sim.mission.recruited[1] = 1
	sim.player.health = 40.0
	_run(sim, 30)
	var snapshot: Dictionary = sim.capture()
	_run(sim, 30)
	var expected: Dictionary = sim.capture()
	sim.restore(snapshot)
	_run(sim, 30)
	assert_eq(sim.capture(), expected)


func _order(sim: BlasterOpsSimulation) -> void:
	var intent: InfiltrationIntent = InfiltrationIntent.new()
	intent.pressed = InfiltrationIntent.ORDER_ALLIES
	sim.step(intent, [], [])


func _rifle_sim() -> BlasterOpsSimulation:
	var sim: BlasterOpsSimulation = _sim([_role("rifleman")] as Array[BlasterOpsAllyData])
	sim.mission.recruited[0] = 1
	sim.player.position = POINT
	sim.prisoners[0].position = POINT + Vector2(0.0, 60.0)
	return sim


func test_order_hold_keeps_allies_at_the_ordered_point() -> void:
	var sim: BlasterOpsSimulation = _rifle_sim()
	var progress: BlasterOpsMissionState = sim.mission as BlasterOpsMissionState
	_order(sim)
	assert_eq(progress.ally_order, BlasterOpsMissionState.AllyOrder.HOLD)
	var anchor: Vector2 = progress.ally_anchor
	sim.player.position = POINT + Vector2(700.0, 0.0)
	_run(sim, 180)
	assert_true(sim.prisoners[0].position.distance_to(anchor) < 150.0, "ally stayed at the point")


func test_order_follow_is_the_default_and_returns_after_the_cycle() -> void:
	var sim: BlasterOpsSimulation = _rifle_sim()
	var progress: BlasterOpsMissionState = sim.mission as BlasterOpsMissionState
	assert_eq(progress.ally_order, BlasterOpsMissionState.AllyOrder.FOLLOW)
	_order(sim)
	_order(sim)
	assert_eq(progress.ally_order, BlasterOpsMissionState.AllyOrder.FOLLOW, "nothing to protect, so guard is skipped")
	sim.player.position = POINT + Vector2(500.0, 0.0)
	_run(sim, 180)
	assert_true(sim.prisoners[0].position.distance_to(sim.player.position) < 200.0, "ally followed the player")


func test_order_guard_stands_by_the_hold_zone() -> void:
	var sim: BlasterOpsSimulation = _rifle_sim()
	var progress: BlasterOpsMissionState = sim.mission as BlasterOpsMissionState
	var stage: BlasterOpsStageData = BlasterOpsStageData.new()
	stage.objective = BlasterOpsStageData.Objective.HOLD
	stage.zone = POINT + Vector2(420.0, 0.0)
	stage.zone_radius = 100.0
	stage.hold_seconds = 60.0
	progress.definition.stages = [stage] as Array[BlasterOpsStageData]
	progress.stage_index = 0
	_order(sim)
	_order(sim)
	assert_eq(progress.ally_order, BlasterOpsMissionState.AllyOrder.GUARD)
	_run(sim, 240)
	assert_true(sim.prisoners[0].position.distance_to(stage.zone) < 150.0, "ally reached the zone")


func test_orders_ignored_without_free_allies() -> void:
	var sim: BlasterOpsSimulation = _sim([_role("rifleman")] as Array[BlasterOpsAllyData])
	_order(sim)
	assert_eq((sim.mission as BlasterOpsMissionState).ally_order, BlasterOpsMissionState.AllyOrder.FOLLOW)


func test_orders_end_when_extraction_opens() -> void:
	var sim: BlasterOpsSimulation = _rifle_sim()
	var progress: BlasterOpsMissionState = sim.mission as BlasterOpsMissionState
	_order(sim)
	assert_true(progress.order_point(sim) != Vector2.INF)
	progress.waves_finished = true
	assert_eq(progress.order_point(sim), Vector2.INF)


func test_order_survives_a_snapshot() -> void:
	var sim: BlasterOpsSimulation = _rifle_sim()
	var progress: BlasterOpsMissionState = sim.mission as BlasterOpsMissionState
	_order(sim)
	var snapshot: Dictionary = progress.capture()
	progress.ally_order = BlasterOpsMissionState.AllyOrder.FOLLOW
	progress.ally_anchor = Vector2.ZERO
	progress.restore(snapshot)
	assert_eq(progress.ally_order, BlasterOpsMissionState.AllyOrder.HOLD)
	assert_true(progress.ally_anchor != Vector2.ZERO)


func test_new_order_key_keeps_custom_bindings() -> void:
	var saved: Dictionary = {"fire": [KEY_J], "guard": [KEY_G]}
	var migrated: Dictionary = BlasterOpsBindings.migrate_keys(saved)
	assert_true(migrated.fire.has(KEY_J))
	assert_true(migrated.guard.has(KEY_G))
	assert_false(migrated.order_allies.has(KEY_G), "a key the player already uses is not taken")
	var free: Dictionary = BlasterOpsBindings.migrate_keys({"fire": [KEY_J]})
	assert_true(free.order_allies.has(KEY_G))


func _scenario(order: int, role: String, player_offset: Vector2, enemies: Array[BlasterOpsEnemyData] = []) -> BlasterOpsSimulation:
	var sim: BlasterOpsSimulation = _sim([_role(role)] as Array[BlasterOpsAllyData], enemies)
	var progress: BlasterOpsMissionState = sim.mission as BlasterOpsMissionState
	var stage: BlasterOpsStageData = BlasterOpsStageData.new()
	stage.objective = BlasterOpsStageData.Objective.HOLD
	stage.zone = POINT + Vector2(0.0, 300.0)
	stage.zone_radius = 100.0
	stage.hold_seconds = 600.0
	progress.definition.stages = [stage] as Array[BlasterOpsStageData]
	progress.stage_index = 0
	progress.recruited[0] = 1
	sim.player.position = POINT
	sim.prisoners[0].position = POINT + Vector2(40.0, 0.0)
	progress.set_ally_order(sim, order)
	sim.player.position = POINT + player_offset
	return sim


func test_three_orders_put_the_same_ally_in_three_different_places() -> void:
	var away: Vector2 = Vector2(600.0, 0.0)
	var places: Array[Vector2] = []
	for order in [BlasterOpsMissionState.AllyOrder.FOLLOW, BlasterOpsMissionState.AllyOrder.HOLD, BlasterOpsMissionState.AllyOrder.GUARD]:
		var sim: BlasterOpsSimulation = _scenario(order, "rifleman", away)
		_run(sim, 300)
		places.append(sim.prisoners[0].position)
		print("order %d rifleman at %s, %.0f from player, %.0f from hold point, %.0f from zone" % [order, sim.prisoners[0].position, sim.prisoners[0].position.distance_to(sim.player.position), sim.prisoners[0].position.distance_to(POINT), sim.prisoners[0].position.distance_to(POINT + Vector2(0.0, 300.0))])
	var follow: BlasterOpsSimulation = _scenario(BlasterOpsMissionState.AllyOrder.FOLLOW, "rifleman", away)
	assert_true(places[0].distance_to(POINT + away) < 150.0, "follow stays with the player")
	assert_true(places[1].distance_to(POINT) < 150.0, "hold stays at the ordered point")
	assert_true(places[2].distance_to(POINT + Vector2(0.0, 300.0)) < 150.0, "protect stands at the objective")
	assert_true(places[0].distance_to(places[1]) > 300.0)
	assert_true(places[1].distance_to(places[2]) > 150.0)
	assert_true(follow != null)


func _field_enemy(health: float = 2000.0) -> BlasterOpsEnemyData:
	var enemy: BlasterOpsEnemyData = load("res://data/blaster_ops/enemies/soldier.tres").duplicate() as BlasterOpsEnemyData
	enemy.health = health
	return enemy


func test_orders_change_who_the_blade_guard_engages() -> void:
	var enemies: Array[BlasterOpsEnemyData] = [_field_enemy()]
	var results: Array[float] = []
	for order in [BlasterOpsMissionState.AllyOrder.FOLLOW, BlasterOpsMissionState.AllyOrder.HOLD]:
		var sim: BlasterOpsSimulation = _scenario(order, "blade", Vector2(900.0, 0.0), enemies)
		sim.targets[0].position = POINT + Vector2(150.0, 0.0)
		sim.targets[0].previous = sim.targets[0].position
		sim.targets[0].spawned = true
		var before: float = sim.targets[0].health
		var escorts: InfiltrationEscortController = InfiltrationEscortController.new(sim)
		var idle: InfiltrationIntent = InfiltrationIntent.new()
		for tick in 240:
			sim.step(idle, [], escorts.produce_all(sim))
		results.append(before - sim.targets[0].health)
		print("order %d blade guard damage to an enemy near the ordered point: %.0f" % [order, results[-1]])
	assert_eq(results[0], 0.0, "following: the enemy is too far from the player")
	assert_gt(results[1], 0.0, "holding: the enemy is inside the guard's reach")


func test_orders_change_who_the_medic_repairs() -> void:
	var healed: Array[float] = []
	for order in [BlasterOpsMissionState.AllyOrder.FOLLOW, BlasterOpsMissionState.AllyOrder.HOLD]:
		var sim: BlasterOpsSimulation = _scenario(order, "medic", Vector2(900.0, 0.0))
		sim.player.health = 40.0
		_run(sim, 480)
		healed.append(sim.player.health - 40.0)
		print("order %d medic healed the far player by %.0f" % [order, healed[-1]])
	assert_gt(healed[0], 0.0, "following: the medic comes along and repairs")
	assert_eq(healed[1], 0.0, "holding: the medic stays behind")


func test_protect_tracks_a_moving_protected_ally() -> void:
	var sim: BlasterOpsSimulation = _sim([_role("rifleman"), _role("rifleman")] as Array[BlasterOpsAllyData])
	var progress: BlasterOpsMissionState = sim.mission as BlasterOpsMissionState
	progress.definition.protected_index = 1
	progress.recruited[0] = 1
	progress.recruited[1] = 1
	progress.set_ally_order(sim, BlasterOpsMissionState.AllyOrder.GUARD)
	assert_eq(progress.ally_order, BlasterOpsMissionState.AllyOrder.GUARD)
	sim.player.position = POINT + Vector2(700.0, 0.0)
	sim.prisoners[1].position = POINT + Vector2(0.0, 240.0)
	_run(sim, 300)
	assert_true(sim.prisoners[0].position.distance_to(sim.prisoners[1].position) < 150.0, "stays by the protected ally, not the player")
