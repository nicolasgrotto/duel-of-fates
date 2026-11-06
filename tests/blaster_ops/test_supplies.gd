extends TestCase

const TERMINAL: Vector2 = Vector2(200, 416)


func _sim(enemies: Array[BlasterOpsEnemyData] = [], terminals: bool = true, reserve: bool = false, loadout: BlasterOpsLoadout = null) -> BlasterOpsSimulation:
	var mission: BlasterOpsMissionData = BlasterOpsMissionData.new()
	mission.objective = InfiltrationMissionData.Objective.INCURSION
	mission.map = BlasterOpsFixture.arena(enemies)
	(mission.map as BlasterOpsArenaData).enemies_alerted = false
	mission.extraction = Vector2(1300, 700)
	mission.waves = [BlasterOpsWaveData.new(), BlasterOpsWaveData.new()] as Array[BlasterOpsWaveData]
	if terminals:
		mission.supply_terminals = PackedVector2Array([TERMINAL])
	if reserve:
		mission.prisoner_spawns = PackedVector2Array([Vector2(500, 500)])
		mission.ally_roles = [load("res://data/blaster_ops/allies/rifleman.tres")] as Array[BlasterOpsAllyData]
		mission.reserve_start = 0
	return BlasterOpsSimulation.new(BlasterOpsTraining.CONFIG, mission.map, loadout if loadout != null else BlasterOpsTraining.PISTOL.duplicate(), mission)


func _offer(id: StringName) -> int:
	for index in BlasterOpsTraining.SUPPLY_OFFERS.size():
		if BlasterOpsTraining.SUPPLY_OFFERS[index].id == id:
			return index
	return -1


func _progress(sim: BlasterOpsSimulation) -> BlasterOpsMissionState:
	return sim.mission as BlasterOpsMissionState


func test_every_offer_has_translated_text_and_a_positive_cost() -> void:
	for offer in BlasterOpsTraining.SUPPLY_OFFERS:
		assert_gt(offer.cost, 0)
		assert_ne(tr(offer.name_key), offer.name_key)
		assert_ne(tr(offer.description_key), offer.description_key)


func test_kills_and_new_waves_earn_supplies_only_where_terminals_exist() -> void:
	var sim: BlasterOpsSimulation = _sim([BlasterOpsFixture.enemy("soldier")])
	sim._damage_target(0, 999.0)
	assert_eq(_progress(sim).supplies, 1)
	_progress(sim)._start_wave(sim, 1)
	assert_eq(_progress(sim).supplies, 3)
	var plain: BlasterOpsSimulation = _sim([BlasterOpsFixture.enemy("soldier")], false)
	plain._damage_target(0, 999.0)
	assert_eq(_progress(plain).supplies, 0)


func test_tougher_roles_are_worth_more() -> void:
	var sim: BlasterOpsSimulation = _sim([BlasterOpsFixture.enemy("ironstride")])
	sim._damage_target(0, 9999.0)
	assert_eq(_progress(sim).supplies, BlasterOpsFixture.enemy("ironstride").supply_value)


func test_purchases_require_the_terminal_and_enough_supplies() -> void:
	var sim: BlasterOpsSimulation = _sim()
	var progress: BlasterOpsMissionState = _progress(sim)
	progress.supplies = 99
	sim.player.position = Vector2(900, 700)
	assert_false(progress.purchase(sim, _offer(&"barrier")))
	assert_eq(progress.supplies, 99)
	sim.player.position = TERMINAL + Vector2(40, 0)
	progress.supplies = 1
	assert_false(progress.purchase(sim, _offer(&"barrier")))
	progress.supplies = 2
	assert_true(progress.purchase(sim, _offer(&"barrier")))
	assert_eq(progress.supplies, 0)
	assert_eq(progress.barrier_charges, 1)


func test_each_offer_does_what_it_says() -> void:
	var sim: BlasterOpsSimulation = _sim()
	var progress: BlasterOpsMissionState = _progress(sim)
	progress.supplies = 99
	sim.player.position = TERMINAL + Vector2(40, 0)
	sim.player.health = 10.0
	assert_true(progress.purchase(sim, _offer(&"heal")))
	assert_eq(sim.player.health, 50.0)
	assert_true(progress.purchase(sim, _offer(&"bulwark")))
	assert_eq(progress.heavy_barrier_charges, 1)
	assert_true(progress.purchase(sim, _offer(&"coolant")))
	assert_almost(progress.heat_scale, 0.75)
	assert_true(progress.purchase(sim, _offer(&"combat_tune")))
	assert_almost(sim.swing_damage(), BlasterOpsTraining.CONFIG.swing_damage * 1.15)


func test_limits_and_availability_hide_useless_offers() -> void:
	var blade: BlasterOpsLoadout = BlasterOpsTraining.equipment(DuelMode.character(&"guardian"), 0)
	var sim: BlasterOpsSimulation = _sim([], true, false, blade)
	var progress: BlasterOpsMissionState = _progress(sim)
	progress.supplies = 99
	sim.player.position = TERMINAL + Vector2(40, 0)
	assert_false(progress.offer_available(sim, _offer(&"coolant")))
	assert_false(progress.offer_available(sim, _offer(&"reinforcement")))
	assert_false(progress.offer_available(sim, _offer(&"ally_upgrade")))
	assert_true(progress.purchase(sim, _offer(&"combat_tune")))
	assert_true(progress.purchase(sim, _offer(&"combat_tune")))
	assert_false(progress.purchase(sim, _offer(&"combat_tune")))


func test_reinforcement_calls_the_reserve_ally_to_the_terminal_once() -> void:
	var sim: BlasterOpsSimulation = _sim([], true, true)
	var progress: BlasterOpsMissionState = _progress(sim)
	progress.supplies = 99
	sim.player.position = TERMINAL + Vector2(40, 0)
	assert_true(progress.offer_available(sim, _offer(&"reinforcement")))
	assert_true(progress.purchase(sim, _offer(&"reinforcement")))
	assert_eq(progress.recruited[0], 1)
	assert_gt(sim.prisoners[0].health, 0.0)
	assert_lt(sim.prisoners[0].position.distance_to(TERMINAL), 80.0)
	assert_false(progress.offer_available(sim, _offer(&"reinforcement")))
	assert_true(progress.offer_available(sim, _offer(&"ally_upgrade")))
	sim.prisoners[0].health = 1.0
	assert_true(progress.purchase(sim, _offer(&"ally_upgrade")))
	assert_eq(sim.prisoners[0].health, sim._ally_max_health(0))
	assert_almost(progress.ally_scale, 1.25)


func test_purchase_arrives_only_as_an_intent_through_the_tick() -> void:
	var sim: BlasterOpsSimulation = _sim()
	var progress: BlasterOpsMissionState = _progress(sim)
	progress.supplies = 5
	sim.player.position = TERMINAL + Vector2(40, 0)
	var intent: InfiltrationIntent = InfiltrationIntent.new()
	intent.purchase = _offer(&"barrier")
	sim.step(intent)
	assert_eq(progress.barrier_charges, 1)
	assert_eq(progress.supplies, 3)
	intent.clear()
	assert_eq(intent.purchase, -1)


func test_interact_at_a_terminal_never_deploys_a_barrier() -> void:
	var sim: BlasterOpsSimulation = _sim()
	var progress: BlasterOpsMissionState = _progress(sim)
	progress.barrier_charges = 1
	sim.player.position = TERMINAL + Vector2(40, 0)
	progress.interact(sim)
	assert_eq(progress.barrier_charges, 1)


func test_supply_bonuses_survive_a_snapshot_and_a_new_attempt_starts_clean() -> void:
	var sim: BlasterOpsSimulation = _sim()
	var progress: BlasterOpsMissionState = _progress(sim)
	progress.supplies = 20
	sim.player.position = TERMINAL + Vector2(40, 0)
	var snapshot: Dictionary = sim.capture()
	assert_true(progress.purchase(sim, _offer(&"combat_tune")))
	sim.restore(snapshot)
	assert_eq(progress.supplies, 20)
	assert_eq(progress.damage_scale, 1.0)
	assert_eq(progress.offer_counts[_offer(&"combat_tune")], 0)
	var fresh: BlasterOpsSimulation = _sim()
	assert_eq(_progress(fresh).supplies, 0)


func test_supplies_never_reach_the_save_or_the_result() -> void:
	var source: String = FileAccess.get_file_as_string("res://core/save_service.gd")
	assert_eq(source.find("supplies"), -1)
	assert_eq(FileAccess.get_file_as_string("res://modes/blaster_ops_mission_result.gd").find("supplies"), -1)
