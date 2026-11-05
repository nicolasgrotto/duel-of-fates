extends TestCase

const PRISONER_POINT: Vector2 = Vector2(300, 416)


func _mission(enemies: Array[BlasterOpsEnemyData] = [], cover: bool = false) -> InfiltrationMissionData:
	var mission: InfiltrationMissionData = InfiltrationMissionData.new()
	mission.objective = InfiltrationMissionData.Objective.INCURSION
	mission.map = BlasterOpsFixture.arena(enemies, cover)
	(mission.map as BlasterOpsArenaData).enemies_alerted = false
	mission.prisoner_spawns = PackedVector2Array([PRISONER_POINT])
	mission.extraction = Vector2(1300, 700)
	return mission


func _sim(enemies: Array[BlasterOpsEnemyData] = [], cover: bool = false) -> BlasterOpsSimulation:
	var mission: InfiltrationMissionData = _mission(enemies, cover)
	return BlasterOpsSimulation.new(BlasterOpsTraining.CONFIG, mission.map, BlasterOpsTraining.PISTOL.duplicate(), mission)


func _step(sim: BlasterOpsSimulation, ticks: int) -> void:
	var intent: InfiltrationIntent = InfiltrationIntent.new()
	for tick in ticks:
		sim.step(intent)


func _barrier(sim: BlasterOpsSimulation, cell: Vector2i) -> int:
	sim.arena.reserve_barriers(1, 60.0)
	var index: int = sim.arena.covers.size() - 1
	sim.arena.covers[index].data.cell = cell
	sim.arena.covers[index].health = 60.0
	sim.arena.rebuild_cells()
	return index


func _hostile_bolt(sim: BlasterOpsSimulation, start: Vector2, direction: Vector2) -> BlasterOpsBolt:
	var bolt: BlasterOpsBolt = sim._spawn_bolt(-1, sim.loadout.blaster.bolt, direction)
	bolt.owner = 1
	bolt.shooter = 0
	bolt.position = start
	bolt.previous = start
	return bolt


func test_player_bolts_pass_freed_prisoners_and_hit_the_enemy_behind() -> void:
	var sim: BlasterOpsSimulation = _sim([BlasterOpsFixture.enemy("soldier")])
	sim.mission.recruited[0] = 1
	var enemy_health: float = sim.targets[0].health
	sim._spawn_bolt(-1, sim.loadout.blaster.bolt, Vector2.RIGHT)
	_step(sim, 50)
	assert_eq(sim.prisoners[0].health, BlasterOpsTraining.CONFIG.prisoner_health)
	assert_lt(sim.targets[0].health, enemy_health)
	assert_eq(sim.mission.outcome, InfiltrationMissionState.Outcome.ACTIVE)


func test_reflected_bolts_belong_to_the_player_and_spare_prisoners() -> void:
	var sim: BlasterOpsSimulation = _sim()
	sim.mission.recruited[0] = 1
	var bolt: BlasterOpsBolt = _hostile_bolt(sim, Vector2(200, 416), Vector2.LEFT)
	sim.player.guard = true
	sim.player.parry_age = 0
	sim.player.aim = Vector2.RIGHT
	sim._resolve_player_bolt(bolt)
	assert_eq(BlasterOpsFaction.of_bolt(bolt), BlasterOpsFaction.Side.ALLIED)
	assert_true(bolt.reflected)
	sim.player.guard = false
	_step(sim, 30)
	assert_eq(sim.prisoners[0].health, BlasterOpsTraining.CONFIG.prisoner_health)


func test_ally_bolts_never_hurt_the_player_or_other_allies() -> void:
	var sim: BlasterOpsSimulation = _sim()
	sim.mission.recruited[0] = 1
	sim.player.position = PRISONER_POINT + Vector2(120, 0)
	var bolt: BlasterOpsBolt = sim._spawn_bolt(-2, BlasterOpsTraining.CONFIG.ally_bolt, Vector2.RIGHT, 1.0, sim.prisoners[0])
	assert_eq(BlasterOpsFaction.of_bolt(bolt), BlasterOpsFaction.Side.ALLIED)
	_step(sim, 30)
	assert_eq(sim.player.health, BlasterOpsTraining.CONFIG.health)
	assert_eq(sim.prisoners[0].health, BlasterOpsTraining.CONFIG.prisoner_health)


func test_hostile_bolts_hurt_freed_prisoners_but_not_caged_ones() -> void:
	for recruited in [0, 1]:
		var sim: BlasterOpsSimulation = _sim()
		sim.mission.recruited[0] = recruited
		_hostile_bolt(sim, PRISONER_POINT + Vector2(60, 0), Vector2.LEFT).velocity = Vector2.LEFT * 900.0
		_step(sim, 6)
		if recruited == 0:
			assert_eq(sim.prisoners[0].health, BlasterOpsTraining.CONFIG.prisoner_health)
		else:
			assert_lt(sim.prisoners[0].health, BlasterOpsTraining.CONFIG.prisoner_health)


func test_deployed_barrier_stops_hostile_fire_and_lets_allied_fire_through() -> void:
	var sim: BlasterOpsSimulation = _sim()
	var cell: Vector2i = Vector2i(6, 6)
	var index: int = _barrier(sim, cell)
	var center: Vector2 = (Vector2(cell) + Vector2.ONE * 0.5) * sim.map.tile_size
	var allied: BlasterOpsBolt = sim._spawn_bolt(-1, sim.loadout.blaster.bolt, Vector2.RIGHT)
	allied.position = center - Vector2(60, 0)
	allied.previous = allied.position
	_step(sim, 12)
	assert_eq(sim.arena.covers[index].health, 60.0)
	assert_true(allied.position.x > center.x)
	var hostile: BlasterOpsBolt = _hostile_bolt(sim, center + Vector2(80, 0), Vector2.LEFT)
	hostile.velocity = Vector2.LEFT * 900.0
	_step(sim, 12)
	assert_false(hostile.active)
	assert_lt(sim.arena.covers[index].health, 60.0)


func test_player_blade_ignores_own_barrier_but_cuts_map_crates() -> void:
	var sim: BlasterOpsSimulation = _sim([], true)
	var crate: BlasterOpsCover = sim.arena.covers[0]
	var crate_point: Vector2 = (Vector2(crate.data.cell) + Vector2.ONE * 0.5) * sim.map.tile_size
	sim.player.position = crate_point - Vector2(70, 0)
	sim.player.previous = sim.player.position
	var health: float = crate.health
	var intent: InfiltrationIntent = InfiltrationIntent.new()
	intent.aim = Vector2.RIGHT
	intent.pressed = Intent.Command.HEAVY
	sim.step(intent)
	intent.pressed = 0
	for tick in 20:
		sim.step(intent)
	assert_lt(crate.health, health)
	var other: BlasterOpsSimulation = _sim()
	var index: int = _barrier(other, Vector2i(6, 6))
	other.player.position = (Vector2(6, 6) + Vector2.ONE * 0.5) * other.map.tile_size - Vector2(70, 0)
	other.player.previous = other.player.position
	intent.pressed = Intent.Command.HEAVY
	other.step(intent)
	intent.pressed = 0
	for tick in 20:
		other.step(intent)
	assert_eq(other.arena.covers[index].health, 60.0)


func test_allied_area_damage_only_reaches_enemies_and_crates() -> void:
	var sim: BlasterOpsSimulation = _sim([BlasterOpsFixture.enemy("soldier")], true)
	sim.mission.recruited[0] = 1
	var barrier: int = _barrier(sim, Vector2i(10, 6))
	sim.player.position = sim.targets[0].position - Vector2(60, 0)
	sim.prisoners[0].position = sim.targets[0].position + Vector2(60, 0)
	var enemy_health: float = sim.targets[0].health
	sim.apply_area_damage(BlasterOpsFaction.Side.ALLIED, sim.targets[0].position, 200.0, 5.0, 0)
	assert_lt(sim.targets[0].health, enemy_health)
	assert_eq(sim.player.health, BlasterOpsTraining.CONFIG.health)
	assert_eq(sim.prisoners[0].health, BlasterOpsTraining.CONFIG.prisoner_health)
	assert_eq(sim.arena.covers[barrier].health, 60.0)


func test_hostile_area_damage_hits_player_prisoners_and_barriers_but_never_enemies() -> void:
	var sim: BlasterOpsSimulation = _sim([BlasterOpsFixture.enemy("soldier")])
	sim.mission.recruited[0] = 1
	var center: Vector2 = Vector2(500, 416)
	var barrier: int = _barrier(sim, Vector2i(int(center.x / sim.map.tile_size), 8))
	sim.player.position = center + Vector2(-80, 0)
	sim.prisoners[0].position = center + Vector2(80, 0)
	sim.targets[0].position = center + Vector2(0, -80)
	var enemy_health: float = sim.targets[0].health
	sim.apply_area_damage(BlasterOpsFaction.Side.HOSTILE, center, 200.0, 5.0, 1)
	assert_lt(sim.player.health, BlasterOpsTraining.CONFIG.health)
	assert_lt(sim.prisoners[0].health, BlasterOpsTraining.CONFIG.prisoner_health)
	assert_lt(sim.arena.covers[barrier].health, 60.0)
	assert_eq(sim.targets[0].health, enemy_health)


func test_hostile_area_is_blocked_by_walls_and_skipped_by_invulnerable_dodge() -> void:
	var sim: BlasterOpsSimulation = _sim()
	var cell: Vector2i = Vector2i(6, 6)
	var center: Vector2 = (Vector2(cell) + Vector2.ONE * 0.5) * sim.map.tile_size
	_barrier(sim, cell)
	sim.player.position = center + Vector2(80, 0)
	sim.apply_area_damage(BlasterOpsFaction.Side.HOSTILE, center - Vector2(80, 0), 400.0, 5.0, 1)
	assert_eq(sim.player.health, BlasterOpsTraining.CONFIG.health)
	var open: BlasterOpsSimulation = _sim()
	open.state.dodge_age = BlasterOpsTraining.CONFIG.invulnerable_from
	open.apply_area_damage(BlasterOpsFaction.Side.HOSTILE, open.player.position, 100.0, 5.0, 1)
	assert_eq(open.player.health, BlasterOpsTraining.CONFIG.health)


func test_prisoner_death_still_fails_the_mission_through_enemy_area_damage() -> void:
	var mission: InfiltrationMissionData = _mission()
	mission.minimum_prisoners = 1
	var sim: BlasterOpsSimulation = BlasterOpsSimulation.new(BlasterOpsTraining.CONFIG, mission.map, BlasterOpsTraining.PISTOL.duplicate(), mission)
	sim.mission.recruited[0] = 1
	sim.prisoners[0].health = 1.0
	sim.apply_area_damage(BlasterOpsFaction.Side.HOSTILE, sim.prisoners[0].position, 40.0, 5.0, 1)
	_step(sim, 1)
	assert_eq(sim.mission.outcome, InfiltrationMissionState.Outcome.PRISONER_DOWN)
