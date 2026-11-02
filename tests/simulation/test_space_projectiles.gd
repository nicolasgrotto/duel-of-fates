extends TestCase


func test_swept_shot_cannot_tunnel_through_target() -> void:
	var sim: SpaceSimulation = SpaceFixture.make_sim()
	sim.ships[0].data.primary.speed = 100000.0
	var commands: Array[SpaceIntent] = SpaceFixture.commands(2)
	commands[0].held = SpaceIntent.Command.PRIMARY
	sim.step(commands)
	assert_almost(sim.ships[1].hull, 20.0)
	assert_false(sim.projectiles[0].active)


func test_first_victim_along_segment_wins_independent_of_ship_order() -> void:
	var initial: SpaceSimulation = SpaceFixture.make_sim()
	var near: SpaceShipPlacement = SpaceShipPlacement.new()
	near.ship = initial.ships[1].data
	near.position = Vector2(680, 500)
	near.team = 1
	initial.arena.ships.append(near)
	var sim: SpaceSimulation = SpaceSimulation.new(SpaceFixture.CONFIG, initial.arena)
	sim.ships[0].data.primary.speed = 100000.0
	var commands: Array[SpaceIntent] = SpaceFixture.commands(3)
	commands[0].held = SpaceIntent.Command.PRIMARY
	sim.step(commands)
	assert_almost(sim.ships[1].hull, 30.0)
	assert_almost(sim.ships[2].hull, 20.0)


func test_friendly_shot_ignores_same_team_ship() -> void:
	var sim: SpaceSimulation = SpaceFixture.make_sim()
	sim.ships[1].team = 0
	var commands: Array[SpaceIntent] = SpaceFixture.commands(2)
	commands[0].held = SpaceIntent.Command.PRIMARY
	sim.step(commands)
	commands[0].held = 0
	for tick in 50:
		sim.step(commands)
	assert_almost(sim.ships[1].hull, 30.0)


func test_range_and_arena_boundary_retire_projectiles() -> void:
	var sim: SpaceSimulation = SpaceFixture.make_sim()
	sim.ships[0].data.primary.max_range = 20.0
	var commands: Array[SpaceIntent] = SpaceFixture.commands(2)
	commands[0].held = SpaceIntent.Command.PRIMARY
	sim.step(commands)
	commands[0].held = 0
	sim.step(commands)
	assert_false(sim.projectiles[0].active)
	sim.ships[0].position = Vector2(1970, 700)
	sim.ships[0].cooldowns[0] = 0
	sim.ships[0].data.primary.max_range = 1400.0
	commands[0].held = SpaceIntent.Command.PRIMARY
	sim.step(commands)
	assert_false(sim.projectiles[0].active)


func test_secondary_is_optional_data_and_uses_separate_cooldown() -> void:
	var sim: SpaceSimulation = SpaceFixture.make_sim()
	var secondary: SpaceWeaponData = SpaceWeaponData.new()
	secondary.damage = 30.0
	secondary.interval = 1.0
	sim.ships[0].data.secondary = secondary
	var commands: Array[SpaceIntent] = SpaceFixture.commands(2)
	commands[0].held = SpaceIntent.Command.SECONDARY
	sim.step(commands)
	commands[0].held = 0
	for tick in 20:
		sim.step(commands)
	assert_almost(sim.ships[1].hull, 0.0)
	assert_eq(sim.ships[0].cooldowns[0], 0)
	assert_true(sim.ships[0].cooldowns[1] > 0)


func test_circle_intersection_handles_tangent_zero_motion_and_behind_segment() -> void:
	assert_almost(SpaceGeometry.segment_circle_fraction(Vector2(-10, 5), Vector2(10, 5), Vector2.ZERO, 5.0), 0.5)
	assert_eq(SpaceGeometry.segment_circle_fraction(Vector2(0, 0), Vector2(0, 0), Vector2.ZERO, 5.0), 0.0)
	assert_eq(SpaceGeometry.segment_circle_fraction(Vector2(10, 0), Vector2(10, 0), Vector2.ZERO, 5.0), INF)
	assert_eq(SpaceGeometry.segment_circle_fraction(Vector2(10, 0), Vector2(20, 0), Vector2.ZERO, 5.0), INF)


func test_swept_relative_circle_detects_ship_crossing_shot_between_ticks() -> void:
	var sim: SpaceSimulation = SpaceFixture.make_sim()
	var actor: SpaceShipState = sim.ships[1]
	actor.data.immobile = false
	actor.data.drag = 0.0
	actor.data.speed = 12000.0
	actor.position = Vector2(600, 600)
	actor.velocity = Vector2(0, -12000)
	var projectile: SpaceProjectile = sim.projectiles[0]
	projectile.active = true
	projectile.position = Vector2(590, 500)
	projectile.velocity = Vector2(1200, 0)
	projectile.age = 1
	sim.step(SpaceFixture.commands(2))
	assert_almost(actor.hull, 20.0)


func test_empty_event_pool_does_not_change_damage_or_destroyed_count() -> void:
	var initial: SpaceSimulation = SpaceFixture.make_sim()
	var config: SpaceConfig = SpaceFixture.CONFIG.duplicate() as SpaceConfig
	config.event_capacity = 0
	var sim: SpaceSimulation = SpaceSimulation.new(config, initial.arena)
	var commands: Array[SpaceIntent] = SpaceFixture.commands(2)
	commands[0].held = SpaceIntent.Command.PRIMARY
	for tick in 60:
		sim.step(commands)
	assert_almost(sim.ships[1].hull, 0.0)
	assert_eq(sim.destroyed_targets, 1)
	assert_true(sim.dropped_events > 0)


func test_fixed_tick_reuses_ships_events_projectiles_and_controller_intents() -> void:
	var sim: SpaceSimulation = SpaceFixture.make_sim()
	var controller: SpaceDroneController = SpaceDroneController.new(sim.ships.size())
	var player: SpaceIntent = SpaceIntent.new()
	player.held = SpaceIntent.Command.PRIMARY
	player.turn = 0.4
	for tick in 100:
		sim.step(controller.produce_all(sim, player))
	var identities: PackedInt64Array = []
	for ship in sim.ships:
		identities.append(ship.get_instance_id())
	for event in sim.events:
		identities.append(event.get_instance_id())
	for projectile in sim.projectiles:
		identities.append(projectile.get_instance_id())
	for intent in controller.produce_all(sim, player):
		identities.append(intent.get_instance_id())
	var count: int = int(Performance.get_monitor(Performance.OBJECT_COUNT))
	for tick in 3000:
		sim.step(controller.produce_all(sim, player))
	assert_eq(int(Performance.get_monitor(Performance.OBJECT_COUNT)), count)
	var after: PackedInt64Array = []
	for ship in sim.ships:
		after.append(ship.get_instance_id())
	for event in sim.events:
		after.append(event.get_instance_id())
	for projectile in sim.projectiles:
		after.append(projectile.get_instance_id())
	for intent in controller.produce_all(sim, player):
		after.append(intent.get_instance_id())
	assert_eq(after, identities)
