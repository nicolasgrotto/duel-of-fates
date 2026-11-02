extends TestCase

const CONFIG: InfiltrationConfig = preload("res://data/balance/infiltration_config.tres")
const PATROL: InfiltrationEnemyData = preload("res://data/infiltration/enemies/patrol_trooper.tres")
const SENTRY: InfiltrationEnemyData = preload("res://data/infiltration/enemies/sentry.tres")
const HEAVY: InfiltrationEnemyData = preload("res://data/infiltration/enemies/heavy.tres")
const MAP: InfiltrationMapData = preload("res://data/infiltration/patrol_map.tres")

var _controllers: Dictionary = {}


func _map(enemy: InfiltrationEnemyData = SENTRY) -> InfiltrationMapData:
	var map: InfiltrationMapData = InfiltrationMapData.new()
	map.rows = PackedStringArray(["################", "#..............#", "#..............#", "#..............#", "#..............#", "#..............#", "#..............#", "#..............#", "#..............#", "#..............#", "#..............#", "################"])
	map.player_spawn = Vector2(160, 352)
	var placement: InfiltrationEnemyPlacement = InfiltrationEnemyPlacement.new()
	placement.enemy = enemy.duplicate() as InfiltrationEnemyData
	placement.enemy.rotation_degrees = 0.0
	placement.position = Vector2(480, 352)
	placement.direction = Vector2.LEFT
	map.enemies.append(placement)
	return map


func _step(sim: InfiltrationSimulation, intent: InfiltrationIntent) -> void:
	var id: int = sim.get_instance_id()
	if not _controllers.has(id):
		_controllers[id] = InfiltrationEnemyController.new(sim.map, sim.targets.size())
	var controller: InfiltrationEnemyController = _controllers[id]
	sim.step(intent, controller.produce_all(sim))


func _steps(sim: InfiltrationSimulation, count: int, intent: InfiltrationIntent = null) -> void:
	var command: InfiltrationIntent = intent if intent != null else InfiltrationIntent.new()
	for tick in count:
		_step(sim, command)
		command.pressed = 0


func _event_count(sim: InfiltrationSimulation, type: InfiltrationEvent.Type) -> int:
	var count: int = 0
	for index in sim.event_count:
		if sim.events[index].type == type:
			count += 1
	return count


func _panel(map: InfiltrationMapData, position: Vector2) -> void:
	var panel: InfiltrationPanelData = InfiltrationPanelData.new()
	panel.position = position
	map.panels.append(panel)


func _reserve(map: InfiltrationMapData, position: Vector2) -> void:
	var placement: InfiltrationEnemyPlacement = InfiltrationEnemyPlacement.new()
	placement.enemy = PATROL
	placement.position = position
	placement.direction = Vector2.RIGHT
	placement.reinforcement = true
	map.enemies.append(placement)


func test_archetypes_and_extended_map_are_valid_original_data() -> void:
	assert_true(PATROL.speed > HEAVY.speed)
	assert_eq(SENTRY.speed, 0.0)
	assert_true(HEAVY.health > PATROL.health)
	assert_eq(HEAVY.bolt.count, 3)
	assert_eq(MAP.enemies.size(), 5)
	assert_eq(MAP.panels.size(), 1)
	assert_eq(MAP.enemy_sprites.get_size(), Vector2(144, 28))
	for placement in MAP.enemies:
		assert_eq(InfiltrationGeometry.wall_fraction(MAP, placement.position, placement.position, CONFIG.body_radius), INF)
		for point in placement.route:
			assert_eq(InfiltrationGeometry.wall_fraction(MAP, point, point, CONFIG.body_radius), INF)
	for panel in MAP.panels:
		assert_eq(InfiltrationGeometry.wall_fraction(MAP, panel.position, panel.position), INF)


func test_scripted_unseen_sneaking_path_never_builds_suspicion() -> void:
	var map: InfiltrationMapData = _map()
	map.player_spawn = Vector2(640, 416)
	var sim: InfiltrationSimulation = InfiltrationSimulation.new(CONFIG, map)
	var intent: InfiltrationIntent = InfiltrationIntent.new()
	intent.movement = Vector2.RIGHT
	intent.held = Intent.Command.SPECIAL
	_steps(sim, 90, intent)
	assert_eq(sim.targets[0].suspicion, 0.0)
	assert_eq(sim.targets[0].awareness, InfiltrationActor.Awareness.UNAWARE)


func test_crossing_cone_accumulates_suspicion_then_alert() -> void:
	var sim: InfiltrationSimulation = InfiltrationSimulation.new(CONFIG, _map())
	_steps(sim, 20)
	assert_eq(sim.targets[0].awareness, InfiltrationActor.Awareness.SUSPICIOUS)
	assert_true(sim.targets[0].suspicion < 1.0)
	_steps(sim, 42)
	assert_eq(sim.targets[0].awareness, InfiltrationActor.Awareness.ALERTED)
	assert_eq(sim.targets[0].last_known, sim.player.position)


func test_sneaking_reduces_visual_accumulation_without_invisibility() -> void:
	var first: InfiltrationSimulation = InfiltrationSimulation.new(CONFIG, _map())
	var second: InfiltrationSimulation = InfiltrationSimulation.new(CONFIG, _map())
	var sneak: InfiltrationIntent = InfiltrationIntent.new()
	sneak.held = Intent.Command.SPECIAL
	_steps(first, 30)
	_steps(second, 30, sneak)
	assert_almost(second.targets[0].suspicion, first.targets[0].suspicion * CONFIG.sneak_visibility)
	_steps(second, 80, sneak)
	assert_eq(second.targets[0].awareness, InfiltrationActor.Awareness.ALERTED)


func test_vision_respects_range_and_cone_angle() -> void:
	var sim: InfiltrationSimulation = InfiltrationSimulation.new(CONFIG, _map())
	var actor: InfiltrationActor = sim.targets[0]
	sim.player.position = actor.position + Vector2.LEFT * (SENTRY.vision_range + 1.0)
	assert_false(InfiltrationPerception.sees(sim, 0))
	sim.player.position = actor.position + Vector2.LEFT.rotated(deg_to_rad(51.0)) * 200.0
	assert_false(InfiltrationPerception.sees(sim, 0))
	sim.player.position = actor.position + Vector2.LEFT.rotated(deg_to_rad(49.0)) * 200.0
	assert_true(InfiltrationPerception.sees(sim, 0))


func test_suspicious_patrol_investigates_noise_then_resumes_route() -> void:
	var map: InfiltrationMapData = _map(PATROL)
	map.player_spawn = Vector2(864, 640)
	map.enemies[0].route = PackedVector2Array([Vector2(608, 352), Vector2(480, 352)])
	var sim: InfiltrationSimulation = InfiltrationSimulation.new(CONFIG, map)
	var point: Vector2 = Vector2(480, 480)
	InfiltrationPerception.noise(sim, point, CONFIG.run_noise, 0)
	_steps(sim, 40)
	assert_eq(sim.targets[0].decision, InfiltrationActor.Decision.INVESTIGATE)
	assert_eq(sim.targets[0].last_known, point)
	assert_true(sim.targets[0].position.y > 400.0)
	_steps(sim, 200)
	assert_eq(sim.targets[0].awareness, InfiltrationActor.Awareness.UNAWARE)
	assert_eq(sim.targets[0].decision, InfiltrationActor.Decision.PATROL)


func test_wall_and_crate_block_vision_and_memory_does_not_track_hidden_player() -> void:
	for obstacle in ["#", "C"]:
		var map: InfiltrationMapData = _map()
		map.rows[5] = "#...." + obstacle + ".........#"
		var sim: InfiltrationSimulation = InfiltrationSimulation.new(CONFIG, map)
		_steps(sim, 90)
		assert_eq(sim.targets[0].suspicion, 0.0)
		assert_false(sim.targets[0].visible_player)
	var sim: InfiltrationSimulation = InfiltrationSimulation.new(CONFIG, _map())
	_steps(sim, 62)
	var known: Vector2 = sim.targets[0].last_known
	sim.player.position = Vector2(800, 640)
	_steps(sim, 120)
	assert_eq(sim.targets[0].last_known, known)
	assert_eq(sim.targets[0].awareness, InfiltrationActor.Awareness.ALERTED)
	_steps(sim, 600)
	assert_eq(sim.targets[0].awareness, InfiltrationActor.Awareness.UNAWARE)


func test_noise_has_exact_radius_and_only_raises_suspicion() -> void:
	var sim: InfiltrationSimulation = InfiltrationSimulation.new(CONFIG, _map())
	var point: Vector2 = sim.targets[0].position + Vector2.RIGHT * CONFIG.run_noise
	InfiltrationPerception.noise(sim, point, CONFIG.run_noise - 1.0, 0)
	assert_eq(sim.targets[0].suspicion, 0.0)
	InfiltrationPerception.noise(sim, point, CONFIG.run_noise, 0)
	assert_eq(sim.targets[0].suspicion, CONFIG.noise_suspicion)
	assert_eq(sim.targets[0].last_known, point)
	for repeat in 10:
		InfiltrationPerception.noise(sim, point, CONFIG.run_noise, 0)
	assert_eq(sim.targets[0].awareness, InfiltrationActor.Awareness.SUSPICIOUS)
	assert_eq(_event_count(sim, InfiltrationEvent.Type.NOISE_EMITTED), 12)


func test_running_and_sneaking_footsteps_emit_different_noise_events() -> void:
	for command in [Intent.Command.DODGE, Intent.Command.SPECIAL, Intent.Command.DODGE | Intent.Command.BLOCK, Intent.Command.SPECIAL | Intent.Command.BLOCK]:
		var map: InfiltrationMapData = _map()
		map.enemies.clear()
		var sim: InfiltrationSimulation = InfiltrationSimulation.new(CONFIG, map)
		var intent: InfiltrationIntent = InfiltrationIntent.new()
		intent.movement = Vector2.DOWN
		intent.held = command
		var radius: float = 0.0
		for tick in 60:
			_step(sim, intent)
			for index in sim.event_count:
				if sim.events[index].type == InfiltrationEvent.Type.NOISE_EMITTED:
					radius = sim.events[index].amount
		var sneaking: bool = (command & Intent.Command.SPECIAL) != 0
		var guarding: bool = (command & Intent.Command.BLOCK) != 0
		assert_eq(radius, CONFIG.sneak_noise if sneaking else CONFIG.walk_noise if guarding else CONFIG.run_noise)
		assert_almost(sim.player.velocity.length(), CONFIG.sneak_speed if sneaking else CONFIG.walk_speed * CONFIG.guard_speed_ratio if guarding else CONFIG.run_speed)


func test_takedown_requires_unaware_rear_range_aim_and_line_of_sight() -> void:
	var sim: InfiltrationSimulation = InfiltrationSimulation.new(CONFIG, _map())
	sim.player.position = Vector2(536, 352)
	sim.player.aim = Vector2.LEFT
	assert_eq(sim.takedown_target(), 0)
	sim.targets[0].awareness = InfiltrationActor.Awareness.SUSPICIOUS
	assert_eq(sim.takedown_target(), -1)
	sim.targets[0].awareness = InfiltrationActor.Awareness.ALERTED
	assert_eq(sim.takedown_target(), -1)
	sim.targets[0].awareness = InfiltrationActor.Awareness.UNAWARE
	sim.player.position = Vector2(424, 352)
	assert_eq(sim.takedown_target(), -1)
	sim.player.position = Vector2(560, 352)
	assert_eq(sim.takedown_target(), -1)
	sim.player.position = Vector2(536, 352)
	sim.player.aim = Vector2.RIGHT
	assert_eq(sim.takedown_target(), -1)
	sim.player.position = Vector2(416, 352)
	sim.targets[0].position = Vector2(480, 352)
	sim.targets[0].aim = Vector2.RIGHT
	sim.player.aim = Vector2.RIGHT
	sim.map.rows[5] = "#......C.......#"
	assert_eq(sim.takedown_target(), -1)


func test_silent_takedown_is_instant_without_noise_or_respawn() -> void:
	var sim: InfiltrationSimulation = InfiltrationSimulation.new(CONFIG, _map())
	sim.player.position = Vector2(536, 352)
	var intent: InfiltrationIntent = InfiltrationIntent.new()
	intent.aim = Vector2.LEFT
	intent.pressed = Intent.Command.HEAVY
	_step(sim, intent)
	assert_eq(sim.targets[0].health, 0.0)
	assert_eq(_event_count(sim, InfiltrationEvent.Type.TAKEDOWN_LANDED), 1)
	assert_eq(_event_count(sim, InfiltrationEvent.Type.NOISE_EMITTED), 0)
	assert_eq(sim.targets[0].respawn_ticks, 0)
	_steps(sim, 240)
	assert_eq(sim.targets[0].health, 0.0)


func test_normal_blade_hit_alerts_a_surviving_enemy() -> void:
	var sim: InfiltrationSimulation = InfiltrationSimulation.new(CONFIG, _map())
	sim.player.position = Vector2(536, 352)
	var intent: InfiltrationIntent = InfiltrationIntent.new()
	intent.aim = Vector2.LEFT
	intent.pressed = Intent.Command.LIGHT
	_steps(sim, 12, intent)
	assert_eq(sim.targets[0].health, SENTRY.health - CONFIG.swing_damage)
	assert_eq(sim.targets[0].awareness, InfiltrationActor.Awareness.ALERTED)


func test_simulation_never_runs_enemy_ai_without_provided_intents() -> void:
	var sim: InfiltrationSimulation = InfiltrationSimulation.new(CONFIG, MAP)
	var start: Vector2 = sim.targets[2].position
	InfiltrationPerception.alert(sim, 2, sim.player.position)
	for tick in 120:
		sim.step(InfiltrationIntent.new())
	assert_eq(sim.targets[2].position, start)
	assert_eq(sim.targets[2].velocity, Vector2.ZERO)
	assert_false(sim.alarm_active())


func test_simulation_rejects_unaware_enemy_fire_and_alarm_requests() -> void:
	var map: InfiltrationMapData = _map(PATROL)
	map.player_spawn = Vector2(800, 640)
	_panel(map, Vector2(480, 352))
	var sim: InfiltrationSimulation = InfiltrationSimulation.new(CONFIG, map)
	var enemy: InfiltrationIntent = InfiltrationIntent.new()
	enemy.aim = sim.player.position - sim.targets[0].position
	enemy.held = Intent.Command.LIGHT
	enemy.panel = 0
	var intents: Array[InfiltrationIntent] = [enemy]
	for tick in 50:
		sim.step(InfiltrationIntent.new(), intents)
		assert_eq(_event_count(sim, InfiltrationEvent.Type.SHOT_FIRED), 0)
	assert_false(sim.alarm_active())
	assert_eq(sim.panels[0].activation_ticks, 0)


func test_all_enemy_intents_are_sampled_without_mutating_simulation() -> void:
	var sim: InfiltrationSimulation = InfiltrationSimulation.new(CONFIG, MAP)
	var controller: InfiltrationEnemyController = InfiltrationEnemyController.new(sim.map, sim.targets.size())
	var before: Dictionary = sim.capture()
	var intents: Array[InfiltrationIntent] = controller.produce_all(sim)
	assert_eq(sim.capture(), before)
	assert_eq(intents.size(), sim.targets.size())
	var first_id: int = intents[2].get_instance_id()
	controller.produce_all(sim)
	assert_eq(controller.intents[2].get_instance_id(), first_id)


func test_enemy_controller_only_produces_intents() -> void:
	var sim: InfiltrationSimulation = InfiltrationSimulation.new(CONFIG, MAP)
	var controller: InfiltrationEnemyController = InfiltrationEnemyController.new(sim.map, sim.targets.size())
	var intent: InfiltrationIntent = InfiltrationIntent.new()
	var before: Dictionary = sim.capture()
	for index in range(sim.map.targets.size(), sim.targets.size()):
		controller.produce(sim, index, intent)
	assert_eq(sim.capture(), before)


func test_patrol_advances_waypoints_sentry_rotates_and_heavy_is_slower() -> void:
	var map: InfiltrationMapData = _map(PATROL)
	map.player_spawn = Vector2(800, 640)
	map.enemies[0].route = PackedVector2Array([Vector2(544, 352), Vector2(480, 352)])
	var sim: InfiltrationSimulation = InfiltrationSimulation.new(CONFIG, map)
	_steps(sim, 35)
	assert_eq(sim.targets[0].waypoint, 1)
	assert_true(sim.targets[0].velocity.x < 0.0)
	map = _map(SENTRY)
	map.enemies[0].enemy.rotation_degrees = 35.0
	map.player_spawn = Vector2(800, 640)
	sim = InfiltrationSimulation.new(CONFIG, map)
	var start: Vector2 = sim.targets[0].position
	_steps(sim, 60)
	assert_eq(sim.targets[0].position, start)
	assert_almost(rad_to_deg(Vector2.LEFT.angle_to(sim.targets[0].aim)), 35.0)


func test_grid_navigation_goes_around_cover_without_crossing_walls() -> void:
	var map: InfiltrationMapData = _map(PATROL)
	map.rows[5] = "#....CCC.......#"
	map.enemies[0].position = Vector2(608, 352)
	map.enemies[0].route = PackedVector2Array([Vector2(224, 352)])
	map.player_spawn = Vector2(864, 640)
	var sim: InfiltrationSimulation = InfiltrationSimulation.new(CONFIG, map)
	for tick in 350:
		_step(sim, InfiltrationIntent.new())
		assert_eq(InfiltrationGeometry.wall_fraction(map, sim.targets[0].position, sim.targets[0].position, CONFIG.body_radius - 0.1), INF)
	assert_true(sim.targets[0].position.distance_to(Vector2(224, 352)) <= CONFIG.waypoint_radius)


func test_alerted_patrol_reaches_and_activates_panel_after_channel() -> void:
	var map: InfiltrationMapData = _map(PATROL)
	_panel(map, Vector2(608, 352))
	var sim: InfiltrationSimulation = InfiltrationSimulation.new(CONFIG, map)
	InfiltrationPerception.alert(sim, 0, sim.player.position)
	_steps(sim, 30)
	assert_false(sim.alarm_active())
	_steps(sim, 90)
	assert_true(sim.alarm_active())
	assert_true(sim.reinforcement_called)


func test_disabling_a_panel_prevents_activation_and_stops_active_alarm() -> void:
	var map: InfiltrationMapData = _map(PATROL)
	_panel(map, Vector2(208, 352))
	var sim: InfiltrationSimulation = InfiltrationSimulation.new(CONFIG, map)
	var intent: InfiltrationIntent = InfiltrationIntent.new()
	intent.pressed = Intent.Command.POWER
	_step(sim, intent)
	assert_true(sim.panels[0].disabled)
	InfiltrationPerception.alert(sim, 0, sim.player.position)
	_steps(sim, 240)
	assert_false(sim.alarm_active())
	assert_false(sim.reinforcement_called)
	sim = InfiltrationSimulation.new(CONFIG, map)
	sim.panels[0].active = true
	sim.reinforcement_ticks = 60
	intent.pressed = Intent.Command.POWER
	_step(sim, intent)
	assert_false(sim.alarm_active())
	assert_eq(sim.reinforcement_ticks, -1)
	assert_eq(_event_count(sim, InfiltrationEvent.Type.PANEL_DISABLED), 1)


func test_panel_interaction_respects_range_walls_and_other_active_panels() -> void:
	var map: InfiltrationMapData = _map()
	_panel(map, Vector2(480, 352))
	_panel(map, Vector2(208, 352))
	var sim: InfiltrationSimulation = InfiltrationSimulation.new(CONFIG, map)
	assert_eq(sim.nearby_panel(), 1)
	sim.panels[0].active = true
	sim.panels[1].active = true
	sim.reinforcement_ticks = 60
	var intent: InfiltrationIntent = InfiltrationIntent.new()
	intent.pressed = Intent.Command.POWER
	_step(sim, intent)
	assert_true(sim.alarm_active())
	assert_eq(sim.reinforcement_ticks, 59)
	sim.map.rows[5] = "#..C...........#"
	sim.panels[1].disabled = false
	assert_eq(sim.nearby_panel(), -1)


func test_reinforcements_spawn_once_at_fixed_accesses_and_restore_deterministically() -> void:
	var map: InfiltrationMapData = _map()
	_panel(map, Vector2(608, 352))
	_reserve(map, Vector2(800, 544))
	var sim: InfiltrationSimulation = InfiltrationSimulation.new(CONFIG, map)
	sim.panels[0].active = true
	sim.reinforcement_called = true
	sim.reinforcement_ticks = 3
	var before: Dictionary = sim.capture()
	_steps(sim, 2)
	assert_false(sim.targets[1].spawned)
	_steps(sim, 1)
	assert_true(sim.targets[1].spawned)
	assert_eq(sim.targets[1].position, map.enemies[1].position)
	assert_eq(_event_count(sim, InfiltrationEvent.Type.REINFORCEMENT_ARRIVED), 1)
	var result: Dictionary = sim.capture()
	sim.restore(before)
	_steps(sim, 3)
	assert_eq(sim.capture(), result)
	sim._damage_target(1, 100.0)
	_steps(sim, 240)
	assert_eq(sim.targets[1].health, 0.0)


func test_occupied_access_waits_and_disabling_cancels_pending_reinforcement() -> void:
	var map: InfiltrationMapData = _map()
	_panel(map, Vector2(208, 352))
	_reserve(map, map.player_spawn)
	var sim: InfiltrationSimulation = InfiltrationSimulation.new(CONFIG, map)
	sim.panels[0].active = true
	sim.reinforcement_ticks = 1
	sim.reinforcement_called = true
	_step(sim, InfiltrationIntent.new())
	assert_false(sim.targets[1].spawned)
	assert_eq(sim.reinforcement_ticks, 0)
	var intent: InfiltrationIntent = InfiltrationIntent.new()
	intent.pressed = Intent.Command.POWER
	_step(sim, intent)
	assert_eq(sim.reinforcement_ticks, -1)
	sim.player.position = Vector2(224, 352)
	_steps(sim, 10)
	assert_false(sim.targets[1].spawned)


func test_occupied_access_spawns_when_cleared_and_never_adds_a_body() -> void:
	var map: InfiltrationMapData = _map()
	_panel(map, Vector2(608, 352))
	_reserve(map, map.player_spawn)
	var sim: InfiltrationSimulation = InfiltrationSimulation.new(CONFIG, map)
	sim.panels[0].active = true
	sim.reinforcement_ticks = 1
	sim.reinforcement_called = true
	var reserve_id: int = sim.targets[1].get_instance_id()
	_step(sim, InfiltrationIntent.new())
	assert_false(sim.targets[1].spawned)
	sim.player.position = map.player_spawn + Vector2(32, 32)
	_step(sim, InfiltrationIntent.new())
	assert_false(sim.targets[1].spawned)
	sim.player.position = map.player_spawn + Vector2(40, 32)
	_step(sim, InfiltrationIntent.new())
	assert_true(sim.targets[1].spawned)
	assert_eq(sim.targets.size(), 2)
	assert_eq(sim.targets[1].get_instance_id(), reserve_id)


func test_reflected_damage_remembers_parry_point_without_revealing_hidden_player() -> void:
	var map: InfiltrationMapData = _map()
	map.enemies[0].position = Vector2(320, 352)
	var sim: InfiltrationSimulation = InfiltrationSimulation.new(CONFIG, map)
	var bolt: InfiltrationBolt = sim.fire_bolt(0)
	bolt.position = sim.player.position + Vector2.RIGHT * 30.0
	var point: Vector2 = sim.player.position
	var intent: InfiltrationIntent = InfiltrationIntent.new()
	intent.aim = Vector2.RIGHT
	intent.held = Intent.Command.BLOCK
	intent.pressed = Intent.Command.BLOCK
	_step(sim, intent)
	assert_eq(bolt.origin, point)
	sim.player.position = Vector2(160, 640)
	_steps(sim, 20)
	assert_eq(sim.targets[0].health, SENTRY.health - SENTRY.bolt.damage)
	assert_eq(sim.targets[0].last_known, point)
	assert_false(sim.targets[0].visible_player)


func test_enemy_muzzle_cannot_emit_through_adjacent_cover() -> void:
	var map: InfiltrationMapData = _map()
	map.rows[5] = "#.....C........#"
	map.enemies[0].position = Vector2(470, 352)
	var sim: InfiltrationSimulation = InfiltrationSimulation.new(CONFIG, map)
	assert_eq(sim.fire_bolt(0), null)
	assert_eq(_event_count(sim, InfiltrationEvent.Type.SHOT_FIRED), 0)


func test_heavy_fires_a_timed_three_bolt_burst_and_hidden_player_is_not_shot() -> void:
	var map: InfiltrationMapData = _map(HEAVY)
	map.enemies[0].enemy.speed = 0.0
	var sim: InfiltrationSimulation = InfiltrationSimulation.new(CONFIG, map)
	InfiltrationPerception.alert(sim, 0, sim.player.position)
	sim.targets[0].fire_ticks = 0
	var shot_ticks: PackedInt32Array = []
	for tick in 20:
		_step(sim, InfiltrationIntent.new())
		if _event_count(sim, InfiltrationEvent.Type.SHOT_FIRED) > 0:
			shot_ticks.append(sim.tick)
	assert_eq(shot_ticks, PackedInt32Array([2, 8, 14]))
	sim.player.position = Vector2(864, 640)
	for tick in 160:
		_step(sim, InfiltrationIntent.new())
		assert_eq(_event_count(sim, InfiltrationEvent.Type.SHOT_FIRED), 0)


func test_enemy_bolt_is_reflected_into_shooter_and_snapshot_keeps_data() -> void:
	var map: InfiltrationMapData = _map()
	map.enemies[0].position = Vector2(320, 352)
	map.enemies[0].enemy.health = 4.0
	var sim: InfiltrationSimulation = InfiltrationSimulation.new(CONFIG, map)
	var bolt: InfiltrationBolt = sim.fire_bolt(0)
	bolt.position = sim.player.position + Vector2.RIGHT * 30.0
	bolt.velocity = Vector2.LEFT * bolt.data.speed
	var before: Dictionary = sim.capture()
	sim.restore(before)
	assert_eq(sim.bolts[0].data, SENTRY.bolt)
	var intent: InfiltrationIntent = InfiltrationIntent.new()
	intent.aim = Vector2.RIGHT
	intent.held = Intent.Command.BLOCK
	intent.pressed = Intent.Command.BLOCK
	_step(sim, intent)
	assert_eq(_event_count(sim, InfiltrationEvent.Type.BOLT_REFLECTED), 1)
	assert_eq(sim.bolts[0].owner, 0)
	_steps(sim, 20, intent)
	assert_eq(sim.targets[0].health, 0.0)


func test_reflected_wall_impact_emits_noise_at_impact_position() -> void:
	var sim: InfiltrationSimulation = InfiltrationSimulation.new(CONFIG, _map())
	var bolt: InfiltrationBolt = sim.fire_bolt(0)
	bolt.owner = 0
	bolt.position = Vector2(75, 352)
	bolt.velocity = Vector2.LEFT * bolt.data.speed
	_step(sim, InfiltrationIntent.new())
	assert_false(bolt.active)
	assert_eq(_event_count(sim, InfiltrationEvent.Type.NOISE_EMITTED), 1)
	assert_eq(sim.events[0].amount, CONFIG.reflected_wall_noise)
	assert_almost(sim.events[0].position.x, 64.0 + bolt.data.size)


func test_full_map_with_scripted_intents_is_deterministic_including_ai_and_events() -> void:
	var first: InfiltrationSimulation = InfiltrationSimulation.new(CONFIG, MAP)
	var second: InfiltrationSimulation = InfiltrationSimulation.new(CONFIG, MAP)
	var intent: InfiltrationIntent = InfiltrationIntent.new()
	for tick in 1800:
		intent.movement = Vector2.from_angle(floorf(tick / 150.0) * PI * 0.5)
		intent.aim = Vector2.from_angle(tick * 0.04)
		intent.held = Intent.Command.DODGE if tick % 100 < 50 else Intent.Command.SPECIAL
		intent.pressed = Intent.Command.LIGHT if tick % 45 == 0 else Intent.Command.POWER if tick % 300 == 0 else 0
		_step(first, intent)
		_step(second, intent)
		assert_eq(first.event_count, second.event_count)
		for index in first.event_count:
			assert_eq(first.events[index].type, second.events[index].type)
			assert_eq(first.events[index].position, second.events[index].position)
	assert_eq(first.capture(), second.capture())
	assert_eq(first.dropped_events, 0)
