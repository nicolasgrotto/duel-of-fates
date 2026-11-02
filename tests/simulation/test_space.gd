extends TestCase

var _sim: SpaceSimulation
var _commands: Array[SpaceIntent]


func before_each() -> void:
	_sim = SpaceFixture.make_sim()
	_commands = SpaceFixture.commands(_sim.ships.size())


func _steps(count: int) -> void:
	for tick in count:
		_sim.step(_commands)


func _events(kind: SpaceEvent.Type) -> int:
	var count: int = 0
	for index in _sim.event_count:
		count += int(_sim.events[index].type == kind)
	return count


func test_thrust_then_drag_matches_fixed_step_math() -> void:
	_commands[0].thrust = 1.0
	_sim.step(_commands)
	assert_almost(_sim.ships[0].velocity.x, (600.0 - 100.0) / 60.0)
	assert_almost(_sim.ships[0].position.x, 500.0 + 500.0 / 3600.0)
	assert_almost(_sim.ships[0].velocity.y, 0.0)


func test_reverse_uses_reduced_acceleration() -> void:
	_commands[0].thrust = -1.0
	_sim.step(_commands)
	assert_almost(_sim.ships[0].velocity.x, -(600.0 * 0.55 - 100.0) / 60.0)


func test_release_preserves_inertia_then_stops_without_reversing() -> void:
	_commands[0].thrust = 1.0
	_steps(12)
	var speed: float = _sim.ships[0].velocity.length()
	_commands[0].thrust = 0.0
	_sim.step(_commands)
	assert_almost(_sim.ships[0].velocity.length(), speed - 100.0 / 60.0)
	_steps(120)
	assert_eq(_sim.ships[0].velocity, Vector2.ZERO)


func test_turn_rotates_thrust_before_movement_and_clamps_inputs() -> void:
	_commands[0].turn = 8.0
	_commands[0].thrust = 9.0
	_sim.step(_commands)
	assert_almost(_sim.ships[0].angle, deg_to_rad(210.0) / 60.0)
	assert_almost(_sim.ships[0].velocity.length(), 500.0 / 60.0)
	assert_true(_sim.ships[0].velocity.y > 0.0)


func test_full_thrust_is_speed_limited() -> void:
	_sim.ships[1].hull = 0.0
	_commands[0].thrust = 1.0
	_steps(70)
	assert_almost(_sim.ships[0].velocity.length(), 360.0)


func test_all_arena_bounds_stop_outward_velocity_without_damage() -> void:
	for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		_sim = SpaceFixture.make_sim()
		var ship: SpaceShipState = _sim.ships[0]
		ship.position = Vector2(26, 26) if direction.x < 0.0 or direction.y < 0.0 else _sim.arena.size - Vector2.ONE * 26.0
		ship.angle = direction.angle()
		_commands[0].thrust = 1.0
		_sim.step(_commands)
		assert_almost(ship.velocity.length(), 0.0)
		assert_almost(ship.hull, 100.0)
		assert_true(ship.position.x >= 26.0 and ship.position.x <= _sim.arena.size.x - 26.0)
		assert_true(ship.position.y >= 26.0 and ship.position.y <= _sim.arena.size.y - 26.0)


func test_body_contact_preserves_stationary_drone_and_prevents_overlap() -> void:
	_sim.ships[0].position = Vector2(752, 500)
	_commands[0].thrust = 1.0
	_steps(20)
	assert_eq(_sim.ships[1].position, Vector2(800, 500))
	assert_true(_sim.ships[0].position.distance_to(_sim.ships[1].position) >= 50.0 - 0.001)
	assert_almost(_sim.ships[0].hull, 100.0)


func test_collision_costs_shield_only_on_a_cooldown_and_resets_regeneration() -> void:
	_sim.ships[0].position = Vector2(752, 500)
	_commands[0].thrust = 1.0
	var shield: float = _sim.ships[0].shield
	_steps(1)
	assert_almost(_sim.ships[0].shield, shield - SpaceFixture.CONFIG.contact_shield_damage)
	assert_almost(_sim.ships[0].hull, 100.0)
	assert_almost(_sim.ships[1].hull, 30.0)
	assert_eq(_sim.ships[0].shield_delay, Ticks.from_seconds(_sim.ships[0].data.shield_delay))
	_steps(Ticks.from_seconds(SpaceFixture.CONFIG.contact_cooldown) - 2)
	assert_almost(_sim.ships[0].shield, shield - SpaceFixture.CONFIG.contact_shield_damage)
	_steps(3)
	assert_almost(_sim.ships[0].shield, shield - SpaceFixture.CONFIG.contact_shield_damage * 2.0)


func test_collision_never_reaches_the_hull_and_respects_the_ship_ratio() -> void:
	_sim.ships[0].data.contact_ratio = 2.0
	_sim.ships[0].shield = 5.0
	_sim.ships[0].position = Vector2(752, 500)
	_commands[0].thrust = 1.0
	_steps(1)
	assert_almost(_sim.ships[0].shield, 0.0)
	assert_almost(_sim.ships[0].hull, 100.0)
	_sim.ships[0].shield = 50.0
	_steps(Ticks.from_seconds(SpaceFixture.CONFIG.contact_cooldown))
	assert_almost(_sim.ships[0].shield, 50.0 - SpaceFixture.CONFIG.contact_shield_damage * 2.0)


func test_boost_window_avoids_the_collision_cost() -> void:
	var shield: float = _sim.ships[0].shield
	_sim.ships[0].boost_tick = Ticks.from_seconds(SpaceFixture.CONFIG.boost_invulnerable_start)
	_sim.ships[0].position = Vector2(752, 500)
	_steps(1)
	assert_almost(_sim.ships[0].shield, shield)
	assert_eq(_sim.ships[0].contact_cooldown, 0)


func test_debris_contact_stays_free() -> void:
	var obstacle: SpaceObstacleData = SpaceObstacleData.new()
	obstacle.position = Vector2(500, 500)
	obstacle.radius = 40.0
	_sim.arena.obstacles.append(obstacle)
	var shield: float = _sim.ships[0].shield
	_steps(1)
	assert_almost(_sim.ships[0].shield, shield)


func test_ship_boost_recharge_follows_its_ratio() -> void:
	_sim.ships[0].data.boost_cooldown_ratio = 2.0
	_commands[0].pressed = SpaceIntent.Command.BOOST
	_steps(1)
	assert_eq(_sim.ships[0].boost_cooldown, Ticks.from_seconds(SpaceFixture.CONFIG.boost_cooldown * 2.0))


func test_projectile_hits_drone_once_and_three_shots_destroy_it() -> void:
	for tick in 60:
		_commands[0].held = SpaceIntent.Command.PRIMARY if tick == 0 or tick == 11 or tick == 22 else 0
		_sim.step(_commands)
		if tick == 18:
			assert_almost(_sim.ships[1].hull, 20.0)
	assert_almost(_sim.ships[1].hull, 0.0)
	assert_eq(_sim.destroyed_targets, 1)


func test_primary_cadence_and_release_are_tick_exact() -> void:
	_commands[0].held = SpaceIntent.Command.PRIMARY
	_sim.step(_commands)
	assert_eq(_events(SpaceEvent.Type.SHOT_FIRED), 1)
	_steps(10)
	assert_eq(_events(SpaceEvent.Type.SHOT_FIRED), 0)
	_sim.step(_commands)
	assert_eq(_events(SpaceEvent.Type.SHOT_FIRED), 1)
	_commands[0].held = 0
	_steps(20)
	assert_eq(_events(SpaceEvent.Type.SHOT_FIRED), 0)


func test_pool_exhaustion_does_not_overwrite_active_shot_or_spend_cooldown() -> void:
	for projectile in _sim.projectiles:
		projectile.active = true
		projectile.source = 0
		projectile.position = Vector2(1100, 1100)
		projectile.velocity = Vector2.RIGHT * 1000.0
	_commands[0].held = SpaceIntent.Command.PRIMARY
	_sim.step(_commands)
	assert_eq(_sim.ships[0].cooldowns[0], 0)
	assert_eq(_events(SpaceEvent.Type.ACTION_REFUSED), 1)
	assert_eq(_events(SpaceEvent.Type.SHOT_FIRED), 0)
	assert_true(_sim.projectiles[0].position.x > 1100.0)


func test_projectile_pool_reuses_same_objects_after_warmup() -> void:
	var identities: PackedInt64Array = []
	for projectile in _sim.projectiles:
		identities.append(projectile.get_instance_id())
	_commands[0].held = SpaceIntent.Command.PRIMARY
	_commands[0].turn = 0.3
	_steps(1000)
	assert_eq(_sim.projectiles.size(), 96)
	for index in identities.size():
		assert_eq(_sim.projectiles[index].get_instance_id(), identities[index])


func test_shield_absorbs_before_hull_and_excess_damage_carries_over() -> void:
	SpaceFixture.incoming(_sim, 55.0)
	_steps(2)
	assert_almost(_sim.ships[0].shield, 0.0)
	assert_almost(_sim.ships[0].hull, 85.0)
	assert_eq(_events(SpaceEvent.Type.SHIELD_HIT), 1)
	assert_eq(_events(SpaceEvent.Type.HULL_HIT), 1)


func test_shield_recharges_only_after_delay_and_never_repairs_hull() -> void:
	SpaceFixture.incoming(_sim, 55.0)
	_steps(2)
	_steps(119)
	assert_almost(_sim.ships[0].shield, 0.0)
	_sim.step(_commands)
	assert_almost(_sim.ships[0].shield, 0.2)
	_steps(300)
	assert_almost(_sim.ships[0].shield, 40.0)
	assert_almost(_sim.ships[0].hull, 85.0)


func test_new_hit_resets_recharge_delay() -> void:
	SpaceFixture.incoming(_sim, 10.0)
	_steps(2)
	_steps(100)
	SpaceFixture.incoming(_sim, 10.0)
	_steps(2)
	assert_eq(_sim.ships[0].shield_delay, 120)
	_steps(119)
	assert_almost(_sim.ships[0].shield, 20.0)


func test_boost_start_and_tail_are_vulnerable_with_inclusive_inner_window() -> void:
	var ship: SpaceShipState = _sim.ships[0]
	for age in range(-1, 19):
		ship.boost_tick = age
		assert_eq(ship.invulnerable(_sim.config), age >= 3 and age < 12)


func test_boost_locks_direction_prevents_fire_and_expires_after_eighteen_ticks() -> void:
	_commands[0].pressed = SpaceIntent.Command.BOOST
	_commands[0].held = SpaceIntent.Command.PRIMARY
	_sim.step(_commands)
	_commands[0].pressed = 0
	_commands[0].turn = 1.0
	_steps(17)
	assert_almost(_sim.ships[0].angle, 0.0)
	assert_almost(_sim.ships[0].position.x, 716.0)
	assert_eq(_sim.ships[0].boost_tick, 17)
	assert_eq(_events(SpaceEvent.Type.SHOT_FIRED), 0)
	_sim.step(_commands)
	assert_eq(_sim.ships[0].boost_tick, -1)
	assert_true(_sim.ships[0].velocity.length() <= 360.0)
	assert_true(_sim.ships[0].angle > 0.0)


func test_boost_requires_new_press_and_respects_cooldown() -> void:
	_commands[0].pressed = SpaceIntent.Command.BOOST
	_commands[0].held = SpaceIntent.Command.BOOST
	_sim.step(_commands)
	_commands[0].pressed = 0
	_steps(89)
	assert_eq(_sim.ships[0].boost_cooldown, 1)
	_sim.step(_commands)
	assert_eq(_sim.ships[0].boost_cooldown, 0)
	assert_eq(_sim.ships[0].boost_tick, -1)
	_commands[0].pressed = SpaceIntent.Command.BOOST
	_sim.step(_commands)
	assert_eq(_sim.ships[0].boost_tick, 0)


func test_reverse_boost_moves_backward_without_turning() -> void:
	_commands[0].thrust = -1.0
	_commands[0].pressed = SpaceIntent.Command.BOOST
	_sim.step(_commands)
	assert_almost(_sim.ships[0].position.x, 488.0)
	assert_almost(_sim.ships[0].angle, 0.0)


func test_invulnerable_boost_prevents_hull_damage_and_recharge_reset() -> void:
	var ship: SpaceShipState = _sim.ships[0]
	ship.boost_tick = 4
	ship.boost_direction = Vector2.RIGHT
	ship.shield_delay = 15
	SpaceFixture.incoming(_sim, 200.0, 0.0)
	_sim.step(_commands)
	assert_almost(ship.hull, 100.0)
	assert_almost(ship.shield, 40.0)
	assert_eq(ship.shield_delay, 14)
	assert_eq(_events(SpaceEvent.Type.SHOT_EVADED), 1)


func test_vulnerable_boost_tail_can_be_destroyed() -> void:
	_sim.ships[0].boost_tick = 12
	_sim.ships[0].boost_direction = Vector2.RIGHT
	SpaceFixture.incoming(_sim, 200.0, 0.0)
	_sim.step(_commands)
	assert_almost(_sim.ships[0].hull, 0.0)
	assert_eq(_events(SpaceEvent.Type.SHIP_DESTROYED), 1)
	var sealed: int = _sim.state_hash()
	_steps(50)
	assert_eq(_sim.state_hash(), sealed)


func test_drone_does_not_act_without_external_intent() -> void:
	_sim.ships[1].data.primary = SpaceWeaponData.new()
	_steps(100)
	assert_eq(_sim.ships[1].angle, 0.0)
	for projectile in _sim.projectiles:
		assert_false(projectile.active)


func test_weapon_windup_is_telegraphed_and_cancelled_on_release() -> void:
	var weapon: SpaceWeaponData = SpaceWeaponData.new()
	weapon.windup = 0.45
	_sim.ships[0].data.primary = weapon
	_commands[0].held = SpaceIntent.Command.PRIMARY
	_sim.step(_commands)
	assert_eq(_events(SpaceEvent.Type.WEAPON_PRIMED), 1)
	_steps(25)
	assert_eq(_events(SpaceEvent.Type.SHOT_FIRED), 0)
	_commands[0].held = 0
	_sim.step(_commands)
	assert_eq(_sim.ships[0].charges[0], -1)
	_commands[0].held = SpaceIntent.Command.PRIMARY
	_steps(27)
	assert_eq(_events(SpaceEvent.Type.SHOT_FIRED), 0)
	_sim.step(_commands)
	assert_eq(_events(SpaceEvent.Type.SHOT_FIRED), 1)


func test_secondary_absence_is_explicit_and_does_not_fire() -> void:
	_commands[0].pressed = SpaceIntent.Command.SECONDARY
	_commands[0].held = SpaceIntent.Command.SECONDARY
	_sim.step(_commands)
	assert_eq(_events(SpaceEvent.Type.ACTION_REFUSED), 1)
	assert_eq(_events(SpaceEvent.Type.SHOT_FIRED), 0)
	assert_eq(_sim.ships[0].cooldowns[1], 0)


func test_drone_respawns_after_exact_delay_and_waits_for_clear_spawn() -> void:
	_sim.arena.ships[1].respawn_seconds = 3.0
	_sim.ships[1].hull = 0.0
	_sim.ships[1].respawn_ticks = 180
	_steps(179)
	assert_almost(_sim.ships[1].hull, 0.0)
	_sim.ships[0].position = _sim.arena.ships[1].position
	_steps(20)
	assert_almost(_sim.ships[1].hull, 0.0)
	_sim.ships[0].position = Vector2(500, 500)
	_sim.step(_commands)
	assert_almost(_sim.ships[1].hull, 30.0)
	assert_eq(_events(SpaceEvent.Type.SHIP_RESTORED), 1)


func test_snapshot_restore_has_no_packed_array_aliases() -> void:
	_commands[0].held = SpaceIntent.Command.PRIMARY
	_steps(2)
	var saved: Dictionary = _sim.capture()
	var before: int = _sim.state_hash()
	_steps(50)
	_sim.restore(saved)
	assert_eq(_sim.state_hash(), before)
	_sim.ships[0].cooldowns[0] = 900
	assert_true(saved.ships[0].cooldowns[0] != 900)


func test_identical_intents_and_restored_state_produce_same_flight_and_damage() -> void:
	var other: SpaceSimulation = SpaceFixture.make_sim()
	var checkpoint: Dictionary
	for tick in 600:
		_commands[0].thrust = 0.8 if tick % 120 < 80 else -0.3
		_commands[0].turn = 0.4
		_commands[0].held = SpaceIntent.Command.PRIMARY
		_commands[0].pressed = SpaceIntent.Command.BOOST if tick % 100 == 0 else 0
		_sim.step(_commands)
		other.step(_commands)
		if tick == 300:
			checkpoint = _sim.capture()
		if tick == 350:
			other.restore(checkpoint)
			for replay_tick in range(301, 351):
				var replay: SpaceIntent = SpaceIntent.new()
				replay.thrust = 0.8 if replay_tick % 120 < 80 else -0.3
				replay.turn = 0.4
				replay.held = SpaceIntent.Command.PRIMARY
				replay.pressed = SpaceIntent.Command.BOOST if replay_tick % 100 == 0 else 0
				other.step([replay, _commands[1]])
		assert_eq(_sim.state_hash(), other.state_hash())
