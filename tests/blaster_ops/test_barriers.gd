extends TestCase


func _sim(charges: int, heavy: int = 0, prep_only: bool = false, enemies: Array[BlasterOpsEnemyData] = []) -> BlasterOpsSimulation:
	var mission: BlasterOpsMissionData = BlasterOpsMissionData.new()
	mission.objective = InfiltrationMissionData.Objective.INCURSION
	mission.map = BlasterOpsFixture.arena(enemies)
	(mission.map as BlasterOpsArenaData).enemies_alerted = false
	mission.extraction = Vector2(1300, 700)
	mission.barrier_charges = charges
	mission.heavy_barrier_charges = heavy
	mission.barrier_prep_only = prep_only
	mission.waves = [BlasterOpsWaveData.new()] as Array[BlasterOpsWaveData]
	var sim: BlasterOpsSimulation = BlasterOpsSimulation.new(BlasterOpsTraining.CONFIG, mission.map, BlasterOpsTraining.PISTOL.duplicate(), mission)
	sim.player.position = Vector2(352, 416)
	sim.player.aim = Vector2.RIGHT
	return sim


func _deployed(sim: BlasterOpsSimulation) -> Array[int]:
	var result: Array[int] = []
	for index in sim.arena.covers.size():
		if sim.arena.covers[index].deployed and sim.arena.covers[index].health > 0.0:
			result.append(index)
	return result


func test_charges_limit_deployment_and_are_spent() -> void:
	var sim: BlasterOpsSimulation = _sim(1)
	var progress: BlasterOpsMissionState = sim.mission as BlasterOpsMissionState
	assert_true(sim.deploy_barrier())
	assert_eq(progress.barrier_charges, 0)
	sim.player.position.y += 128.0
	assert_false(sim.deploy_barrier())


func test_no_charges_means_interact_does_nothing() -> void:
	var sim: BlasterOpsSimulation = _sim(0)
	assert_false(sim.deploy_barrier())
	assert_true(_deployed(sim).is_empty())


func test_preparation_only_missions_refuse_outside_the_preparation() -> void:
	var sim: BlasterOpsSimulation = _sim(2, 0, true)
	var progress: BlasterOpsMissionState = sim.mission as BlasterOpsMissionState
	progress.intermission_ticks = 0
	assert_false(sim.deploy_barrier())
	progress.intermission_ticks = 10
	assert_true(sim.deploy_barrier())


func test_bulwark_covers_three_tiles_across_the_aim_and_is_used_first() -> void:
	var sim: BlasterOpsSimulation = _sim(1, 1)
	var progress: BlasterOpsMissionState = sim.mission as BlasterOpsMissionState
	assert_true(sim.deploy_barrier())
	var built: Array[int] = _deployed(sim)
	assert_eq(built.size(), 3)
	assert_eq(progress.heavy_barrier_charges, 0)
	assert_eq(progress.barrier_charges, 1)
	assert_eq(sim.arena.covers[built[0]].health, BlasterOpsTraining.CONFIG.bulwark_barrier.health)
	assert_eq(sim.arena.covers[built[0]].data.cell.x, sim.arena.covers[built[2]].data.cell.x)
	var upward: BlasterOpsSimulation = _sim(0, 1)
	upward.player.aim = Vector2.UP
	assert_true(upward.deploy_barrier())
	var cells: Array[int] = _deployed(upward)
	assert_eq(upward.arena.covers[cells[0]].data.cell.y, upward.arena.covers[cells[2]].data.cell.y)


func test_destroyed_slots_are_reused_so_covers_never_grow() -> void:
	var sim: BlasterOpsSimulation = _sim(20)
	var total: int = sim.arena.covers.size()
	for attempt in 12:
		assert_true(sim.deploy_barrier())
		for index in _deployed(sim):
			sim._damage_cover(index, 999.0, sim.player.position)
	assert_eq(sim.arena.covers.size(), total)


func test_barrier_refuses_walls_and_occupied_tiles() -> void:
	var sim: BlasterOpsSimulation = _sim(2)
	sim.player.position = Vector2(100, 416)
	sim.player.aim = Vector2.LEFT
	assert_false(sim.deploy_barrier())
	var body: BlasterOpsSimulation = _sim(2, 0, false, [BlasterOpsFixture.enemy("soldier")])
	body.targets[0].position = body.player.position + Vector2(96, 0)
	assert_false(body.deploy_barrier())


func test_barrier_blocks_bodies_and_navigation_until_destroyed() -> void:
	var sim: BlasterOpsSimulation = _sim(1)
	assert_true(sim.deploy_barrier())
	var index: int = _deployed(sim)[0]
	var cell: Vector2i = sim.arena.covers[index].data.cell
	assert_true(sim.map.is_solid(cell.x, cell.y))
	var revision: int = sim.cover_revision
	sim._damage_cover(index, 999.0, sim.player.position)
	assert_false(sim.map.is_solid(cell.x, cell.y))
	assert_gt(sim.cover_revision, revision)


func test_interact_prefers_objects_and_then_deploys() -> void:
	var sim: BlasterOpsSimulation = _sim(1)
	var progress: BlasterOpsMissionState = sim.mission as BlasterOpsMissionState
	progress.interact(sim)
	assert_eq(_deployed(sim).size(), 1)


func test_enemy_without_a_target_attacks_the_barrier_through_intents() -> void:
	var sim: BlasterOpsSimulation = _sim(1, 0, false, [BlasterOpsFixture.enemy("soldier")])
	assert_true(sim.deploy_barrier())
	var cover: int = _deployed(sim)[0]
	var center: Vector2 = sim.cover_center(cover)
	sim.player.position = Vector2(100, 150)
	sim.targets[0].position = center + Vector2(200, 0)
	sim.targets[0].previous = sim.targets[0].position
	InfiltrationPerception.alert(sim, 0, center)
	var controller: BlasterOpsEnemyController = BlasterOpsEnemyController.new(sim.map, sim.targets.size())
	sim.targets[0].visible_player = false
	var snapshot: Dictionary = sim.capture()
	var commands: Array[InfiltrationIntent] = controller.produce_all(sim)
	assert_eq(sim.capture(), snapshot)
	assert_eq(commands[0].cover_target, cover)
	var health: float = sim.arena.covers[cover].health
	var intent: InfiltrationIntent = InfiltrationIntent.new()
	for tick in 240:
		sim.player.position = Vector2(100, 150)
		sim.targets[0].visible_player = false
		sim.step(intent, controller.produce_all(sim))
	assert_lt(sim.arena.covers[cover].health, health)


func test_melee_enemy_runs_to_the_barrier_and_breaks_it() -> void:
	var sim: BlasterOpsSimulation = _sim(1, 0, false, [BlasterOpsFixture.enemy("rusher")])
	assert_true(sim.deploy_barrier())
	var cover: int = _deployed(sim)[0]
	sim.player.position = Vector2(100, 150)
	sim.targets[0].position = sim.cover_center(cover) + Vector2(180, 0)
	sim.targets[0].previous = sim.targets[0].position
	InfiltrationPerception.alert(sim, 0, sim.cover_center(cover))
	var controller: BlasterOpsEnemyController = BlasterOpsEnemyController.new(sim.map, sim.targets.size())
	var intent: InfiltrationIntent = InfiltrationIntent.new()
	var health: float = sim.arena.covers[cover].health
	for tick in 180:
		sim.player.position = Vector2(100, 150)
		sim.targets[0].visible_player = false
		sim.step(intent, controller.produce_all(sim))
	assert_lt(sim.arena.covers[cover].health, health)


func test_sapper_detonates_at_the_barrier() -> void:
	var sim: BlasterOpsSimulation = _sim(1, 0, false, [BlasterOpsFixture.enemy("sapper")])
	assert_true(sim.deploy_barrier())
	var cover: int = _deployed(sim)[0]
	sim.player.position = Vector2(100, 150)
	sim.targets[0].position = sim.cover_center(cover) + Vector2(140, 0)
	sim.targets[0].previous = sim.targets[0].position
	InfiltrationPerception.alert(sim, 0, sim.cover_center(cover))
	var controller: BlasterOpsEnemyController = BlasterOpsEnemyController.new(sim.map, sim.targets.size())
	var intent: InfiltrationIntent = InfiltrationIntent.new()
	for tick in 180:
		sim.player.position = Vector2(100, 150)
		if sim.targets[0].health > 0.0:
			sim.targets[0].visible_player = false
		sim.step(intent, controller.produce_all(sim))
	assert_eq(sim.targets[0].health, 0.0)
	assert_lt(sim.arena.covers[cover].health, BlasterOpsTraining.CONFIG.field_barrier.health)


func test_barrier_charges_survive_a_snapshot() -> void:
	var sim: BlasterOpsSimulation = _sim(3, 1)
	var snapshot: Dictionary = sim.capture()
	assert_true(sim.deploy_barrier())
	sim.player.position.y += 200.0
	assert_true(sim.deploy_barrier())
	sim.restore(snapshot)
	var progress: BlasterOpsMissionState = sim.mission as BlasterOpsMissionState
	assert_eq(progress.barrier_charges, 3)
	assert_eq(progress.heavy_barrier_charges, 1)
	assert_true(_deployed(sim).is_empty())
