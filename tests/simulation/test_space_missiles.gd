extends TestCase


func _missile(sim: SpaceSimulation, point: Vector2, velocity: Vector2) -> SpaceProjectile:
	var data: SpaceWeaponData = preload("res://data/space/weapons/missile.tres")
	var shot: SpaceProjectile = sim.projectiles[1]
	shot.active = true
	shot.source = 1
	shot.slot = 0
	shot.weapon_index = sim.weapon_catalog.size()
	sim.weapon_catalog.append(data)
	shot.target = 0
	shot.hull = data.projectile_hull
	shot.position = point
	shot.previous = point
	shot.velocity = velocity
	return shot


func test_homing_turn_is_bounded_and_target_is_fixed() -> void:
	var sim: SpaceSimulation = SpaceFixture.make_sim()
	var shot: SpaceProjectile = _missile(sim, Vector2(500, 100), Vector2(300, 0))
	sim.step(SpaceFixture.commands(2))
	assert_almost(shot.velocity.angle(), deg_to_rad(65.0) * Ticks.DELTA)
	assert_eq(shot.target, 0)
	assert_almost(shot.velocity.length(), 300.0)
	sim.ships[0].hull = 0.0
	var direction: float = shot.velocity.angle()
	sim._steer_missile(shot, sim.projectile_data(shot))
	assert_almost(shot.velocity.angle(), direction)


func test_fast_bolt_intercepts_missile_before_it_can_hit_player() -> void:
	var sim: SpaceSimulation = SpaceFixture.make_sim()
	sim.ships[0].data.primary.speed = 12000.0
	var shot: SpaceProjectile = _missile(sim, Vector2(610, 500), Vector2(-300, 0))
	var commands: Array[SpaceIntent] = SpaceFixture.commands(2)
	commands[0].held = SpaceIntent.Command.PRIMARY
	sim.step(commands)
	assert_false(shot.active)
	assert_almost(sim.ships[0].shield, sim.ships[0].data.shield)
	assert_eq(sim.events[sim.event_count - 1].type, SpaceEvent.Type.MISSILE_DESTROYED)


func test_boost_can_dodge_homing_missile_in_invulnerability_window() -> void:
	var sim: SpaceSimulation = SpaceFixture.make_sim()
	var commands: Array[SpaceIntent] = SpaceFixture.commands(2)
	commands[0].pressed = SpaceIntent.Command.BOOST
	sim.step(commands)
	commands[0].clear()
	for tick in 3:
		sim.step(commands)
	var shot: SpaceProjectile = _missile(sim, sim.ships[0].position + Vector2(25, 0), Vector2(-300, 0))
	sim.step(commands)
	assert_false(shot.active)
	assert_almost(sim.ships[0].hull, 100.0)
	assert_almost(sim.ships[0].shield, 40.0)
	assert_eq(sim.events[0].type, SpaceEvent.Type.SHOT_EVADED)


func test_missile_damage_applies_outside_boost_window() -> void:
	var sim: SpaceSimulation = SpaceFixture.make_sim()
	_missile(sim, sim.ships[0].position + Vector2(25, 0), Vector2(-300, 0))
	sim.step(SpaceFixture.commands(2))
	assert_almost(sim.ships[0].shield, 28.0)


func test_spread_is_atomic_when_pool_cannot_fit_all_bolts() -> void:
	var sim: SpaceSimulation = SpaceFixture.make_sim()
	sim.ships[0].data.primary = preload("res://data/space/weapons/spread.tres")
	for index in range(2, sim.projectiles.size()):
		var shot: SpaceProjectile = sim.projectiles[index]
		shot.active = true
		shot.source = 1
		shot.position = Vector2(1700, 1200)
		shot.velocity = Vector2.ZERO
	assert_false(sim._fire(0, 0, sim.weapon(0, 0)))
	assert_false(sim.projectiles[0].active)
	assert_false(sim.projectiles[1].active)
	assert_eq(sim.ships[0].cooldowns[0], 0)


func test_existing_boss_projectiles_keep_original_pattern_after_phase_change() -> void:
	var mode: SpaceMode = SpaceMode.new(SpaceMode.MISSIONS[4], SpaceLoadout.new(), true)
	var sim: SpaceSimulation = mode.create_simulation()
	var original: SpaceWeaponData = sim.weapon(1, 0)
	assert_true(sim._fire(1, 0, original, 0))
	var shot: SpaceProjectile = sim.projectiles[0]
	sim.mission.phase = 1
	assert_eq(sim.weapon(1, 0).kind, SpaceWeaponData.Kind.MISSILE)
	assert_eq(sim.projectile_data(shot), original)
	assert_eq(sim.projectile_data(shot).kind, SpaceWeaponData.Kind.BOLT)


func test_player_secondary_fixes_current_objective_without_explicit_target() -> void:
	var mode: SpaceMode = SpaceMode.new(SpaceMode.MISSIONS[4], SpaceLoadout.new(), true)
	var sim: SpaceSimulation = mode.create_simulation()
	var commands: Array[SpaceIntent] = SpaceFixture.commands(sim.ships.size())
	commands[0].pressed = SpaceIntent.Command.SECONDARY
	sim.step(commands)
	assert_eq(sim.projectiles[0].target, 2)
	assert_eq(sim.projectile_data(sim.projectiles[0]).kind, SpaceWeaponData.Kind.MISSILE)
