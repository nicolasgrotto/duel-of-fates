extends TestCase

const CONFIG: InfiltrationConfig = preload("res://data/balance/infiltration_config.tres")
const MAP: InfiltrationMapData = preload("res://data/infiltration/training_map.tres")


func _sim(map: InfiltrationMapData = MAP, quiet: bool = true) -> InfiltrationSimulation:
	var sim: InfiltrationSimulation = InfiltrationSimulation.new(CONFIG, map)
	if quiet:
		for target in sim.targets:
			target.fire_ticks = 100000
	return sim


func _open_map() -> InfiltrationMapData:
	var map: InfiltrationMapData = InfiltrationMapData.new()
	map.rows = PackedStringArray(["################", "#..............#", "#..............#", "#..............#", "#..............#", "#..............#", "#..............#", "#..............#", "#..............#", "#..............#", "#..............#", "################"])
	map.player_spawn = Vector2(160, 160)
	return map


func _steps(sim: InfiltrationSimulation, count: int, intent: InfiltrationIntent = null) -> void:
	var command: InfiltrationIntent = intent if intent != null else InfiltrationIntent.new()
	for tick in count:
		sim.step(command)
		command.pressed = 0


func _incoming(sim: InfiltrationSimulation, offset: Vector2 = Vector2(30, 0)) -> InfiltrationBolt:
	var bolt: InfiltrationBolt = sim.fire_bolt(1)
	bolt.position = sim.player.position + offset
	bolt.previous = bolt.position
	bolt.velocity = Vector2.LEFT * bolt.data.speed if offset.x > 0.0 else Vector2.RIGHT * bolt.data.speed
	return bolt


func _guard() -> InfiltrationIntent:
	var intent: InfiltrationIntent = InfiltrationIntent.new()
	intent.aim = Vector2.RIGHT
	intent.held = Intent.Command.BLOCK
	intent.pressed = Intent.Command.BLOCK
	return intent


func _events(sim: InfiltrationSimulation, type: InfiltrationEvent.Type) -> int:
	var total: int = 0
	for index in sim.event_count:
		if sim.events[index].type == type:
			total += 1
	return total


func test_training_map_and_original_atlases_load_with_valid_spawns() -> void:
	assert_eq(MAP.width(), 30)
	assert_eq(MAP.rows.size(), 20)
	assert_eq(MAP.tile_size, 64.0)
	for row in MAP.rows:
		assert_eq(row.length(), MAP.width())
	assert_false(MAP.is_solid(floori(MAP.player_spawn.x / MAP.tile_size), floori(MAP.player_spawn.y / MAP.tile_size)))
	for target in MAP.targets:
		assert_false(MAP.is_solid(floori(target.position.x / MAP.tile_size), floori(target.position.y / MAP.tile_size)))
	assert_true(MAP.is_solid(-1, 0))
	assert_true(MAP.is_solid(30, 0))
	assert_eq(MAP.tiles.get_size(), Vector2(128, 32))
	assert_eq(MAP.sprites.get_size(), Vector2(72, 28))


func test_same_intents_produce_the_same_state_hash_and_events() -> void:
	var first: InfiltrationSimulation = _sim(MAP, false)
	var second: InfiltrationSimulation = _sim(MAP, false)
	var intent: InfiltrationIntent = InfiltrationIntent.new()
	for tick in 1500:
		intent.movement = Vector2.from_angle(floorf(tick / 90.0) * PI * 0.5)
		intent.aim = Vector2.from_angle(tick * 0.03)
		intent.held = Intent.Command.BLOCK if tick % 100 < 40 else Intent.Command.DODGE
		intent.pressed = Intent.Command.LIGHT if tick % 45 == 0 else 0
		first.step(intent)
		second.step(intent)
		assert_eq(first.event_count, second.event_count)
		for index in first.event_count:
			assert_eq(first.events[index].type, second.events[index].type)
			assert_eq(first.events[index].position, second.events[index].position)
	assert_eq(first.tick, 1500)
	assert_eq(first.state_hash(), second.state_hash())
	assert_eq(first.capture(), second.capture())


func test_snapshot_restores_a_live_bolt_and_guard_sequence() -> void:
	var sim: InfiltrationSimulation = _sim()
	var intent: InfiltrationIntent = _guard()
	sim.step(intent)
	_incoming(sim)
	var snapshot: Dictionary = sim.capture()
	intent.pressed = 0
	_steps(sim, 20, intent)
	var result: Dictionary = sim.capture()
	sim.restore(snapshot)
	assert_eq(sim.capture(), snapshot)
	_steps(sim, 20, intent)
	assert_eq(sim.capture(), result)


func test_walk_run_sneak_and_diagonal_speeds_are_bounded() -> void:
	var command: InfiltrationIntent = InfiltrationIntent.new()
	for held in [0, Intent.Command.DODGE, Intent.Command.SPECIAL, Intent.Command.DODGE | Intent.Command.SPECIAL]:
		var sim: InfiltrationSimulation = _sim(_open_map())
		command.movement = Vector2.ONE
		command.held = held
		_steps(sim, 20, command)
		var expected: float = CONFIG.sneak_speed if (held & Intent.Command.SPECIAL) != 0 else (CONFIG.run_speed if held == Intent.Command.DODGE else CONFIG.walk_speed)
		assert_almost(sim.player.velocity.length(), expected, 0.01)
		assert_almost(sim.player.velocity.x, sim.player.velocity.y)
		assert_almost(sim.player.vigor, CONFIG.vigor)


func test_collision_blocks_walls_and_map_edges_without_tunneling() -> void:
	var map: InfiltrationMapData = _open_map()
	map.rows[2] = "#....#.........#"
	var sim: InfiltrationSimulation = _sim(map)
	var intent: InfiltrationIntent = InfiltrationIntent.new()
	intent.movement = Vector2.RIGHT
	intent.held = Intent.Command.DODGE
	_steps(sim, 100, intent)
	assert_almost(sim.player.position.x, 5.0 * map.tile_size - CONFIG.body_radius)
	intent.movement = Vector2.LEFT
	_steps(sim, 200, intent)
	assert_almost(sim.player.position.x, map.tile_size + CONFIG.body_radius)
	var far: Vector2 = InfiltrationGeometry.move_body(map, Vector2(160, 160), Vector2(1000, 0), CONFIG.body_radius, [])
	assert_almost(far.x, 5.0 * map.tile_size - CONFIG.body_radius)


func test_collision_slides_along_a_wall_and_stops_at_a_corner() -> void:
	var map: InfiltrationMapData = _open_map()
	for y in range(1, 6):
		map.rows[y] = "#....#.........#"
	var result: Vector2 = InfiltrationGeometry.move_body(map, Vector2(290, 160), Vector2(60, 60), CONFIG.body_radius, [])
	assert_almost(result.x, 302.0)
	assert_almost(result.y, 220.0)
	var blocked: Vector2 = InfiltrationGeometry.move_body(map, Vector2(82, 82), Vector2(-100, -100), CONFIG.body_radius, [])
	assert_eq(blocked, Vector2(82, 82))


func test_targets_are_solid_bodies() -> void:
	var sim: InfiltrationSimulation = _sim()
	sim.player.position = sim.targets[0].position - Vector2(80, 0)
	var intent: InfiltrationIntent = InfiltrationIntent.new()
	intent.movement = Vector2.RIGHT
	_steps(sim, 40, intent)
	assert_almost(sim.player.position.x, sim.targets[0].position.x - CONFIG.body_radius * 2.0)


func test_swing_hits_each_front_target_once_but_never_side_or_back() -> void:
	var map: InfiltrationMapData = _open_map()
	for offset in [Vector2(60, 0), Vector2(-60, 0), Vector2(0, 60), Vector2(130, 0)]:
		var data: InfiltrationTargetData = InfiltrationTargetData.new()
		data.position = map.player_spawn + offset
		map.targets.append(data)
	var sim: InfiltrationSimulation = _sim(map)
	var intent: InfiltrationIntent = InfiltrationIntent.new()
	intent.aim = Vector2.RIGHT
	intent.pressed = Intent.Command.LIGHT
	_steps(sim, 24, intent)
	assert_almost(sim.targets[0].health, 20.0)
	for index in range(1, 4):
		assert_almost(sim.targets[index].health, 30.0)
	assert_almost(sim.player.vigor, 92.0)


func test_swing_locks_direction_and_respects_obstructing_tiles() -> void:
	var map: InfiltrationMapData = _open_map()
	map.rows[2] = "#..#...........#"
	var target: InfiltrationTargetData = InfiltrationTargetData.new()
	target.position = Vector2(250, 160)
	map.targets = [target]
	var sim: InfiltrationSimulation = _sim(map)
	var intent: InfiltrationIntent = InfiltrationIntent.new()
	intent.aim = Vector2.RIGHT
	intent.pressed = Intent.Command.LIGHT
	sim.step(intent)
	intent.pressed = 0
	intent.aim = Vector2.LEFT
	_steps(sim, 15, intent)
	assert_eq(sim.player.swing_aim, Vector2.RIGHT)
	assert_almost(sim.targets[0].health, 30.0)


func test_swing_reaches_targets_in_the_order_the_blade_sweeps() -> void:
	var map: InfiltrationMapData = _open_map()
	for degrees in [-40.0, 0.0, 40.0]:
		var target: InfiltrationTargetData = InfiltrationTargetData.new()
		target.position = map.player_spawn + Vector2.from_angle(deg_to_rad(degrees)) * 80.0
		map.targets.append(target)
	var sim: InfiltrationSimulation = _sim(map)
	var intent: InfiltrationIntent = InfiltrationIntent.new()
	intent.aim = Vector2.RIGHT
	intent.pressed = Intent.Command.LIGHT
	_steps(sim, 7, intent)
	assert_almost(sim.targets[0].health, 20.0)
	assert_almost(sim.targets[1].health, 30.0)
	assert_almost(sim.targets[2].health, 30.0)
	_steps(sim, 2)
	assert_almost(sim.targets[1].health, 20.0)
	assert_almost(sim.targets[2].health, 30.0)
	_steps(sim, 3)
	assert_almost(sim.targets[2].health, 20.0)


func test_guard_blocks_only_the_front_and_works_without_vigor() -> void:
	for back in [false, true]:
		var sim: InfiltrationSimulation = _sim()
		var guard: InfiltrationIntent = _guard()
		_steps(sim, 14, guard)
		sim.player.vigor = 0.0
		_incoming(sim, Vector2(-30 if back else 30, 0))
		sim.step(guard)
		assert_almost(sim.player.health, 96.0 if back else 100.0)
		assert_eq(_events(sim, InfiltrationEvent.Type.BOLT_BLOCKED), 0 if back else 1)
	assert_false(InfiltrationGeometry.in_sector(Vector2.ZERO, Vector2.RIGHT, Vector2.DOWN, INF, CONFIG.guard_degrees))


func test_regular_parry_reverses_the_line_without_changing_speed() -> void:
	var sim: InfiltrationSimulation = _sim()
	var guard: InfiltrationIntent = _guard()
	_steps(sim, 7, guard)
	var bolt: InfiltrationBolt = _incoming(sim, Vector2(30, 8))
	var velocity: Vector2 = bolt.velocity
	sim.step(guard)
	assert_true(bolt.active)
	assert_eq(bolt.owner, 0)
	assert_eq(bolt.velocity, -velocity)
	assert_eq(_events(sim, InfiltrationEvent.Type.BOLT_REFLECTED), 1)
	assert_eq(sim.events[0].amount, 0.0)


func test_perfect_parry_aims_at_emitter_with_shared_speed_bonus() -> void:
	var sim: InfiltrationSimulation = _sim()
	var bolt: InfiltrationBolt = _incoming(sim, Vector2(30, 12))
	var guard: InfiltrationIntent = _guard()
	sim.step(guard)
	var expected: Vector2 = (sim.targets[bolt.shooter].position - bolt.position).normalized()
	assert_almost(bolt.velocity.normalized().distance_to(expected), 0.0)
	assert_almost(bolt.velocity.length(), bolt.data.speed * bolt.data.perfect_reflect_speed)
	assert_true(bolt.velocity.y < 0.0)
	assert_eq(sim.events[0].amount, 1.0)
	assert_almost(sim.player.health, 100.0)
	assert_almost(sim.player.vigor, 100.0)


func test_parry_boundaries_rearming_and_held_guard() -> void:
	for age in [4, 5, 11, 12]:
		var sim: InfiltrationSimulation = _sim()
		var guard: InfiltrationIntent = _guard()
		_steps(sim, age, guard)
		var bolt: InfiltrationBolt = _incoming(sim)
		sim.step(guard)
		assert_eq(bolt.owner == 0, age < 12)
		if age < 12:
			assert_eq(sim.events[0].amount, 1.0 if age < 5 else 0.0)
	var sim: InfiltrationSimulation = _sim()
	var guard: InfiltrationIntent = _guard()
	sim.step(guard)
	sim.step(InfiltrationIntent.new())
	sim.step(guard)
	assert_eq(sim.player.parry_age, -1)
	assert_gt(sim.player.parry_cooldown, 0)


func test_aim_rotates_the_guard_and_parry_can_return_a_burst() -> void:
	var sim: InfiltrationSimulation = _sim()
	var guard: InfiltrationIntent = _guard()
	guard.aim = Vector2.LEFT
	for index in 3:
		_incoming(sim, Vector2(-30, 0))
	sim.step(guard)
	assert_eq(_events(sim, InfiltrationEvent.Type.BOLT_REFLECTED), 3)
	assert_eq(sim.player.parry_age, 0)
	assert_almost(sim.player.health, 100.0)


func test_reflected_bolt_damages_and_disables_the_emitter() -> void:
	var sim: InfiltrationSimulation = _sim()
	var bolt: InfiltrationBolt = _incoming(sim)
	sim.targets[1].health = bolt.data.damage
	sim.step(_guard())
	_steps(sim, 60)
	assert_almost(sim.targets[1].health, 0.0)
	assert_gt(sim.targets[1].respawn_ticks, 0)
	assert_false(bolt.active)


func test_swept_bolts_hit_walls_before_the_player_and_respect_range() -> void:
	var map: InfiltrationMapData = MAP.duplicate(true) as InfiltrationMapData
	map.rows[5] = "#....C...........#...........#"
	var sim: InfiltrationSimulation = _sim(map)
	var bolt: InfiltrationBolt = sim.fire_bolt(1)
	_steps(sim, 100)
	assert_false(bolt.active)
	assert_almost(sim.player.health, 100.0)
	var open: InfiltrationMapData = _open_map()
	var fraction: float = InfiltrationGeometry.wall_fraction(open, Vector2(100, 100), Vector2(1100, 100), 6.0)
	assert_almost(fraction, (15.0 * 64.0 - 6.0 - 100.0) / 1000.0)
	var ranged_map: InfiltrationMapData = MAP.duplicate(true) as InfiltrationMapData
	ranged_map.targets[1].bolt.max_range = 20.0
	var ranged: InfiltrationSimulation = _sim(ranged_map)
	var short_bolt: InfiltrationBolt = ranged.fire_bolt(1)
	_steps(ranged, 2)
	assert_false(short_bolt.active)
	assert_almost(short_bolt.travelled, 20.0)


func test_burst_count_and_interval_come_from_bolt_data() -> void:
	var map: InfiltrationMapData = MAP.duplicate(true) as InfiltrationMapData
	map.targets[1].bolt.count = 3
	map.targets[1].initial_delay = 0.0
	var sim: InfiltrationSimulation = _sim(map, false)
	var neutral: InfiltrationIntent = InfiltrationIntent.new()
	var shot_ticks: Array[int] = []
	for tick in 90:
		sim.step(neutral)
		if _events(sim, InfiltrationEvent.Type.SHOT_FIRED) > 0:
			shot_ticks.append(sim.tick)
	assert_eq(shot_ticks, [1, 7, 13])
	assert_eq(sim.targets[1].burst_left, 0)


func test_a_lethal_burst_emits_one_defeat_and_never_revives_player() -> void:
	var sim: InfiltrationSimulation = _sim()
	sim.player.health = 4.0
	for index in 3:
		_incoming(sim)
	sim.step(InfiltrationIntent.new())
	assert_eq(_events(sim, InfiltrationEvent.Type.DEFEATED), 1)
	assert_eq(_events(sim, InfiltrationEvent.Type.BOLT_HIT), 1)
	assert_almost(sim.player.health, 0.0)


func test_bolt_damage_never_interrupts_startup_or_active_but_flinches_recovery() -> void:
	for swing_tick in [0, 6, 13]:
		var sim: InfiltrationSimulation = _sim()
		sim.player.swing_tick = swing_tick
		_incoming(sim)
		sim.step(InfiltrationIntent.new())
		assert_almost(sim.player.health, 96.0)
		assert_eq(sim.player.stun_ticks > 0, swing_tick >= 12)
		assert_eq(sim.player.swing_tick < 0, swing_tick >= 12)


func test_death_freezes_simulation_and_target_respawn_is_deterministic() -> void:
	var sim: InfiltrationSimulation = _sim()
	var bolt: InfiltrationBolt = _incoming(sim)
	sim.player.health = bolt.data.damage
	sim.step(InfiltrationIntent.new())
	assert_almost(sim.player.health, 0.0)
	assert_eq(_events(sim, InfiltrationEvent.Type.DEFEATED), 1)
	var snapshot: Dictionary = sim.capture()
	_steps(sim, 100)
	assert_eq(sim.capture(), snapshot)
	var practice: InfiltrationSimulation = _sim()
	practice.targets[0].health = 0.0
	practice.targets[0].respawn_ticks = 2
	_steps(practice, 2)
	assert_almost(practice.targets[0].health, MAP.targets[0].health)
	assert_eq(_events(practice, InfiltrationEvent.Type.TARGET_RESTORED), 1)


func test_projectile_and_event_pools_keep_their_instances() -> void:
	var sim: InfiltrationSimulation = _sim(MAP, false)
	var projectile_ids: PackedInt64Array = []
	var event_ids: PackedInt64Array = []
	for bolt in sim.bolts:
		projectile_ids.append(bolt.get_instance_id())
	for event in sim.events:
		event_ids.append(event.get_instance_id())
	_steps(sim, 600, _guard())
	assert_eq(sim.bolts.size(), CONFIG.projectile_capacity)
	assert_eq(sim.events.size(), CONFIG.event_capacity)
	for index in sim.bolts.size():
		assert_eq(sim.bolts[index].get_instance_id(), projectile_ids[index])
	for index in sim.events.size():
		assert_eq(sim.events[index].get_instance_id(), event_ids[index])
	assert_eq(sim.dropped_events, 0)
