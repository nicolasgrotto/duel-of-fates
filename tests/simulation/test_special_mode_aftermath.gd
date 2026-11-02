extends TestCase

const CONFIG: InfiltrationConfig = preload("res://data/balance/infiltration_config.tres")


func test_infiltration_world_keeps_moving_after_a_sealed_result() -> void:
	var data: InfiltrationMissionData = InfiltrationMode.MISSIONS[1]
	var sim: InfiltrationSimulation = InfiltrationSimulation.new(CONFIG, data.map, data)
	var enemies: InfiltrationEnemyController = InfiltrationEnemyController.new(sim.map, sim.targets.size())
	sim.player.health = 0.0
	sim.step(InfiltrationIntent.new(), enemies.produce_all(sim))
	assert_eq(sim.mission.outcome, InfiltrationMissionState.Outcome.PLAYER_DOWN)
	var finished: int = sim.mission.finished_tick
	var moved: float = 0.0
	var start: Array[Vector2] = []
	for actor in sim.targets:
		start.append(actor.position)
	for tick in 120:
		sim.step_aftermath(enemies.produce_all(sim))
	for index in sim.targets.size():
		moved += start[index].distance_to(sim.targets[index].position)
	assert_gt(moved, 10.0)
	assert_eq(sim.mission.outcome, InfiltrationMissionState.Outcome.PLAYER_DOWN)
	assert_eq(sim.mission.finished_tick, finished)


func test_infiltration_aftermath_never_hurts_the_player() -> void:
	var data: InfiltrationMissionData = InfiltrationMode.MISSIONS[0]
	var sim: InfiltrationSimulation = InfiltrationSimulation.new(CONFIG, data.map, data)
	var bolt: InfiltrationBolt = sim.bolts[0]
	bolt.data = load("res://data/infiltration/bolts/trooper_bolt.tres")
	bolt.active = true
	bolt.owner = 1
	bolt.position = sim.player.position - Vector2(40, 0)
	bolt.velocity = Vector2(900, 0)
	var no_enemies: Array[InfiltrationIntent] = []
	for tick in 6:
		sim.step_aftermath(no_enemies)
	assert_almost(sim.player.health, CONFIG.health)
	assert_false(bolt.active)


func test_space_world_keeps_moving_and_keeps_the_result_sealed() -> void:
	var sim: SpaceSimulation = SpaceMode.new(SpaceMode.MISSIONS[0], SpaceLoadout.new(), true).create_simulation()
	var ai: SpaceEnemyController = SpaceEnemyController.new(sim.ships.size())
	var idle: SpaceIntent = SpaceIntent.new()
	for tick in 240:
		sim.step(ai.produce_all(sim, idle))
	sim.ships[0].hull = 0.0
	sim.step(ai.produce_all(sim, idle))
	assert_eq(sim.mission.outcome, SpaceMissionState.Outcome.PLAYER_DOWN)
	var finished: int = sim.mission.finished_tick
	var sealed: Vector2 = sim.ships[1].position
	sim.step(ai.produce_all(sim, idle))
	assert_eq(sim.ships[1].position, sealed)
	for tick in 60:
		sim.step_aftermath(ai.produce_all(sim, idle))
	assert_ne(sim.ships[1].position, sealed)
	assert_eq(sim.mission.outcome, SpaceMissionState.Outcome.PLAYER_DOWN)
	assert_eq(sim.mission.finished_tick, finished)


func test_space_aftermath_never_hurts_the_player() -> void:
	var sim: SpaceSimulation = SpaceMode.new(SpaceMode.MISSIONS[0], SpaceLoadout.new(), true).create_simulation()
	sim.aftermath = true
	var hull: float = sim.ships[0].hull
	var shield: float = sim.ships[0].shield
	sim._damage(0, 1, 500.0, sim.ships[0].position)
	sim._apply_contact(1, sim.ships[0].position)
	assert_almost(sim.ships[0].hull, hull)
	assert_almost(sim.ships[0].shield, shield)
