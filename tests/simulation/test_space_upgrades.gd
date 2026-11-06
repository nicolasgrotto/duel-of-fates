extends TestCase

const MAX_LEVEL: int = 2


func _built(ship: SpaceShipData, weapon: int, shield: int, speed: int) -> SpaceShipData:
	var loadout: SpaceLoadout = SpaceLoadout.new()
	loadout.ship = ship
	loadout.weapon_level = weapon
	loadout.shield_level = shield
	loadout.speed_level = speed
	return loadout.build_ship(SpaceProgress.CONFIG, ship)


func _fly(ship: SpaceShipData, ticks: int) -> float:
	var sim: SpaceSimulation = _sim_with(ship)
	var intents: Array[SpaceIntent] = [SpaceIntent.new()]
	intents[0].thrust = 1.0
	var start: Vector2 = sim.ships[0].position
	for tick in ticks:
		sim.step(intents)
	return sim.ships[0].position.distance_to(start)


func _sim_with(ship: SpaceShipData) -> SpaceSimulation:
	var loadout: SpaceLoadout = SpaceLoadout.new()
	loadout.ship = ship
	var sim: SpaceSimulation = SpaceFixture.make_sim()
	var arena: SpaceArenaData = SpaceArenaData.new()
	arena.size = Vector2(20000.0, 2000.0)
	var placement: SpaceShipPlacement = SpaceShipPlacement.new()
	placement.ship = ship
	placement.position = Vector2(500.0, 1000.0)
	arena.ships = [placement] as Array[SpaceShipPlacement]
	sim = SpaceSimulation.new(sim.config, arena)
	return sim


func _kill_ticks(ship: SpaceShipData) -> int:
	var target: SpaceShipData = load("res://data/space/ships/gunship.tres").duplicate() as SpaceShipData
	target.primary = null
	target.secondary = null
	target.speed = 0.0
	target.acceleration = 0.0
	var arena: SpaceArenaData = SpaceArenaData.new()
	arena.size = Vector2(4000.0, 2000.0)
	var mine: SpaceShipPlacement = SpaceShipPlacement.new()
	mine.ship = ship
	mine.position = Vector2(800.0, 1000.0)
	var theirs: SpaceShipPlacement = SpaceShipPlacement.new()
	theirs.ship = target
	theirs.position = Vector2(1300.0, 1000.0)
	theirs.team = 1
	arena.ships = [mine, theirs] as Array[SpaceShipPlacement]
	var sim: SpaceSimulation = SpaceSimulation.new(SpaceFixture.make_sim().config, arena)
	var intents: Array[SpaceIntent] = [SpaceIntent.new(), SpaceIntent.new()]
	intents[0].held = SpaceIntent.Command.PRIMARY
	for tick in 60 * 120:
		sim.step(intents)
		if sim.ships[1].hull <= 0.0:
			return tick
	return -1


func test_each_track_changes_real_flight_and_combat_on_every_ship() -> void:
	for ship in SpaceProgress.SHIPS:
		var plain: SpaceShipData = _built(ship, 0, 0, 0)
		var weapon: SpaceShipData = _built(ship, MAX_LEVEL, 0, 0)
		var shield: SpaceShipData = _built(ship, 0, MAX_LEVEL, 0)
		var speed: SpaceShipData = _built(ship, 0, 0, MAX_LEVEL)
		var kill_plain: int = _kill_ticks(plain)
		var kill_weapon: int = _kill_ticks(weapon)
		var fly_plain: float = _fly(plain, 240)
		var fly_speed: float = _fly(speed, 240)
		print("%s: time to destroy a gunship %.1f s -> %.1f s (%+d%%); shield %d -> %d (%+d%%), recharge %.0f -> %.0f/s; 4 s of thrust %.0f -> %.0f (%+d%%)" % [ship.id, kill_plain / 60.0, kill_weapon / 60.0, roundi((float(kill_weapon) / kill_plain - 1.0) * 100.0), roundi(plain.shield), roundi(shield.shield), roundi((shield.shield / plain.shield - 1.0) * 100.0), plain.shield_regeneration, shield.shield_regeneration, fly_plain, fly_speed, roundi((fly_speed / fly_plain - 1.0) * 100.0)])
		assert_gt(kill_plain, 0, String(ship.id))
		assert_lt(float(kill_weapon), kill_plain * 0.8, "%s weapon cuts the time to kill by over 20%%" % ship.id)
		assert_gt(shield.shield, plain.shield * 1.3, "%s shield" % ship.id)
		assert_gt(fly_speed, fly_plain * 1.05, "%s speed" % ship.id)


func test_mission_flies_the_chosen_ship_with_its_own_upgrades() -> void:
	var progress: SpaceProgress = SpaceProgress.new()
	for id in SpaceProgress.IDS:
		progress.record(StringName(id), 60, 3)
	assert_true(progress.buy(0, &"anvil"))
	assert_true(progress.buy(0, &"anvil"))
	assert_true(progress.buy(2, &"needle"))
	for pair in [[&"anvil", 2, 0], [&"needle", 0, 1], [&"spear", 0, 0], [&"anvil", 2, 0]]:
		assert_true(progress.select_ship(pair[0]))
		var mode: SpaceMode = SpaceMode.new(SpaceMode.MISSIONS[0], progress.loadout())
		var sim: SpaceSimulation = mode.create_simulation()
		var base: SpaceShipData = progress.selected_ship()
		var upgrades: SpaceUpgradeConfig = SpaceProgress.CONFIG
		assert_eq(sim.ships[0].data.id, pair[0])
		assert_almost(sim.ships[0].data.primary.damage, base.primary.damage + upgrades.weapon_damage * pair[1])
		assert_almost(sim.ships[0].data.speed, base.speed + upgrades.speed * pair[2])
	assert_eq(SpaceProgress.SHIPS[2].primary.damage, 16.0, "the shared ship resource is never modified")
