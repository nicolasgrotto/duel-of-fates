extends TestCase

const CONFIG: InfiltrationConfig = preload("res://data/balance/infiltration_config.tres")
const WAY_BACK: int = 3
const CELL_BLOCK: int = 4
const CORE: int = 5
const STANDARD_BOLT: BoltData = preload("res://data/bolts/standard_bolt.tres")


func _sim(mission: int) -> InfiltrationSimulation:
	var data: InfiltrationMissionData = InfiltrationMode.MISSIONS[mission]
	return InfiltrationSimulation.new(CONFIG, data.map, data)


func _enemy(sim: InfiltrationSimulation, id: StringName) -> int:
	for index in sim.targets.size():
		if sim.target_data[index].id == id and sim.targets[index].health > 0.0:
			return index
	assert_true(false, "missing enemy %s" % id)
	return -1


func _place_open(sim: InfiltrationSimulation, actor: InfiltrationActor) -> Vector2:
	var point: Vector2 = sim.map.player_spawn
	actor.position = point
	actor.previous = point
	return point


func test_prisoners_are_slower_than_the_player_but_faster_than_before() -> void:
	assert_gt(CONFIG.escort_speed, 180.0)
	assert_lt(CONFIG.escort_speed, CONFIG.walk_speed)


func test_mode_bolts_hit_harder_without_changing_the_duel_bolt() -> void:
	assert_almost(STANDARD_BOLT.damage, 4.0)
	assert_almost(STANDARD_BOLT.guard_vigor, 4.0)
	var trooper: InfiltrationEnemyData = load("res://data/infiltration/enemies/patrol_trooper.tres")
	assert_gt(trooper.bolt.damage, STANDARD_BOLT.damage)
	assert_gt(trooper.bolt.guard_vigor, STANDARD_BOLT.guard_vigor)


func test_later_missions_use_the_new_enemy_types() -> void:
	var found: Dictionary = {}
	for mission in InfiltrationMode.MISSIONS:
		for placement in mission.map.enemies:
			found[placement.enemy.id] = true
	for id in [&"marksman", &"drone", &"shield", &"walker"]:
		assert_true(found.has(id), String(id))


func test_enemy_targets_recruited_prisoner_but_not_one_still_in_the_cell() -> void:
	var sim: InfiltrationSimulation = _sim(WAY_BACK)
	var index: int = _enemy(sim, &"patrol_trooper")
	var actor: InfiltrationActor = sim.targets[index]
	var prisoner: InfiltrationActor = sim.prisoners[0]
	actor.position = prisoner.position + Vector2(-120, 0)
	actor.aim = Vector2.RIGHT
	assert_eq(InfiltrationPerception.visible_prisoner(sim, index), -1)
	sim.mission.recruited[0] = 1
	assert_eq(InfiltrationPerception.visible_prisoner(sim, index), 0)
	sim.mission.extracted[0] = 1
	assert_eq(InfiltrationPerception.visible_prisoner(sim, index), -1)


func test_alerted_enemy_fires_at_the_prisoner_through_intents() -> void:
	var sim: InfiltrationSimulation = _sim(WAY_BACK)
	var index: int = _enemy(sim, &"marksman")
	var actor: InfiltrationActor = sim.targets[index]
	var prisoner: InfiltrationActor = sim.prisoners[0]
	sim.mission.recruited[0] = 1
	actor.position = prisoner.position + Vector2(-200, 0)
	actor.aim = Vector2.RIGHT
	InfiltrationPerception.alert(sim, index, prisoner.position)
	var enemies: InfiltrationEnemyController = InfiltrationEnemyController.new(sim.map, sim.targets.size())
	var health: float = prisoner.health
	for tick in 300:
		prisoner.position = actor.position + Vector2(200, 0)
		sim.step(InfiltrationIntent.new(), enemies.produce_all(sim))
	assert_lt(prisoner.health, health)


func test_mission_survives_prisoner_losses_until_below_the_minimum() -> void:
	var sim: InfiltrationSimulation = _sim(CELL_BLOCK)
	assert_eq(sim.mission.data.required_prisoners(), 2)
	sim.prisoners[0].health = 0.0
	sim.prisoners[1].health = 0.0
	sim.step(InfiltrationIntent.new())
	assert_eq(sim.mission.outcome, InfiltrationMissionState.Outcome.ACTIVE)
	sim.prisoners[2].health = 0.0
	sim.step(InfiltrationIntent.new())
	assert_eq(sim.mission.outcome, InfiltrationMissionState.Outcome.PRISONER_DOWN)


func test_minimum_rescue_completes_and_only_everyone_earns_the_bonus() -> void:
	var sim: InfiltrationSimulation = _sim(CELL_BLOCK)
	var exit: Vector2 = sim.mission.data.extraction
	for index in 2:
		sim.mission.recruited[index] = 1
		sim.prisoners[index].position = exit
	sim.player.position = exit
	sim.step(InfiltrationIntent.new())
	assert_eq(sim.mission.outcome, InfiltrationMissionState.Outcome.COMPLETED)
	assert_eq(sim.mission.bonuses(sim.tick) & InfiltrationMissionState.Bonus.ALL_RESCUED, 0)
	var full: InfiltrationSimulation = _sim(WAY_BACK)
	full.mission.extracted.fill(1)
	assert_eq(full.mission.bonuses(full.tick) & InfiltrationMissionState.Bonus.ALL_RESCUED, int(InfiltrationMissionState.Bonus.ALL_RESCUED))


func test_mission_waits_for_a_recruited_prisoner_still_on_the_way() -> void:
	var sim: InfiltrationSimulation = _sim(CELL_BLOCK)
	var exit: Vector2 = sim.mission.data.extraction
	for index in 3:
		sim.mission.recruited[index] = 1
	sim.prisoners[0].position = exit
	sim.prisoners[1].position = exit
	sim.player.position = exit
	sim.step(InfiltrationIntent.new())
	assert_eq(sim.mission.outcome, InfiltrationMissionState.Outcome.ACTIVE)


func test_shield_stops_frontal_cuts_and_falls_from_behind() -> void:
	var sim: InfiltrationSimulation = _sim(CELL_BLOCK)
	var index: int = _enemy(sim, &"shield")
	var actor: InfiltrationActor = sim.targets[index]
	actor.aim = Vector2.RIGHT
	assert_almost(sim._armored_damage(index, 10.0, actor.position + Vector2(80, 0)), 0.0)
	assert_almost(sim._armored_damage(index, 10.0, actor.position + Vector2(-80, 0)), 10.0)


func test_walker_resists_from_the_front_and_refuses_silent_takedown() -> void:
	var sim: InfiltrationSimulation = _sim(WAY_BACK)
	var index: int = _enemy(sim, &"walker")
	var actor: InfiltrationActor = sim.targets[index]
	var data: InfiltrationEnemyData = sim.target_data[index]
	assert_gt(actor.radius, CONFIG.body_radius)
	actor.aim = Vector2.RIGHT
	assert_almost(sim._armored_damage(index, 10.0, actor.position + Vector2(80, 0)), 10.0 * data.front_damage_ratio)
	assert_almost(sim._armored_damage(index, 10.0, actor.position + Vector2(-80, 0)), 10.0)
	sim.player.position = actor.position - actor.aim * 40.0
	sim.player.aim = actor.aim
	assert_eq(sim.takedown_target(), -1)


func test_walker_turns_slowly_toward_its_target() -> void:
	var sim: InfiltrationSimulation = _sim(WAY_BACK)
	var index: int = _enemy(sim, &"walker")
	var actor: InfiltrationActor = sim.targets[index]
	var data: InfiltrationEnemyData = sim.target_data[index]
	actor.aim = Vector2.RIGHT
	var turned: Vector2 = sim._turned_aim(actor, data, Vector2.LEFT)
	assert_almost(absf(actor.aim.angle_to(turned)), deg_to_rad(data.turn_degrees) * Ticks.DELTA, 0.001)


func test_drone_hurts_at_contact_and_guard_costs_vigor_instead() -> void:
	var sim: InfiltrationSimulation = _sim(CORE)
	var index: int = _enemy(sim, &"drone")
	var actor: InfiltrationActor = sim.targets[index]
	var data: InfiltrationEnemyData = sim.target_data[index]
	var intent: InfiltrationIntent = InfiltrationIntent.new()
	intent.held = Intent.Command.LIGHT
	actor.awareness = InfiltrationActor.Awareness.ALERTED
	actor.fire_ticks = 0
	actor.position = sim.player.position + Vector2(30, 0)
	sim.player.aim = Vector2.LEFT
	sim._step_melee(index, data, intent)
	assert_almost(sim.player.health, CONFIG.health - data.melee_damage)
	assert_gt(float(actor.fire_ticks), 0.0)
	sim._step_melee(index, data, intent)
	assert_almost(sim.player.health, CONFIG.health - data.melee_damage)
	actor.fire_ticks = 0
	sim.player.aim = Vector2.RIGHT
	sim.player.guard = true
	var vigor: float = sim.player.vigor
	sim._step_melee(index, data, intent)
	assert_almost(sim.player.health, CONFIG.health - data.melee_damage)
	assert_almost(sim.player.vigor, vigor - data.melee_guard_vigor)


func test_replay_with_new_enemies_stays_deterministic() -> void:
	var first: InfiltrationSimulation = _sim(CORE)
	var second: InfiltrationSimulation = _sim(CORE)
	var enemies_a: InfiltrationEnemyController = InfiltrationEnemyController.new(first.map, first.targets.size())
	var enemies_b: InfiltrationEnemyController = InfiltrationEnemyController.new(second.map, second.targets.size())
	var idle: InfiltrationIntent = InfiltrationIntent.new()
	for tick in 600:
		first.step(idle, enemies_a.produce_all(first))
		second.step(idle, enemies_b.produce_all(second))
	assert_eq(first.state_hash(), second.state_hash())
