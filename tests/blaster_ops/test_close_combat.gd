extends TestCase

const NEAR: Vector2 = Vector2(200, 416)
const POINT: Vector2 = Vector2(248, 416)


func _fixture(name: String, at: Vector2 = POINT) -> BlasterOpsFixture:
	var source: BlasterOpsArenaData = BlasterOpsFixture.arena([BlasterOpsFixture.enemy(name)] as Array[BlasterOpsEnemyData])
	source.enemies[0].position = at
	var fixture: BlasterOpsFixture = BlasterOpsFixture.create(source)
	fixture.sim.player.position = NEAR
	return fixture


func _run_enemies(fixture: BlasterOpsFixture, ticks: int, player_intent: InfiltrationIntent = InfiltrationIntent.new()) -> void:
	var enemies: BlasterOpsEnemyController = BlasterOpsEnemyController.new(fixture.sim.map, fixture.sim.targets.size())
	for tick in ticks:
		fixture.sim.step(player_intent, enemies.produce_all(fixture.sim), [])


func test_shooters_strike_when_the_player_touches_them() -> void:
	for name in ["soldier", "heavy", "marksman", "warden", "repairer"]:
		var fixture: BlasterOpsFixture = _fixture(name)
		_run_enemies(fixture, 240)
		assert_lt(fixture.sim.player.health, BlasterOpsTraining.CONFIG.health, name)


func test_shooters_keep_shooting_from_afar() -> void:
	var fixture: BlasterOpsFixture = _fixture("soldier", Vector2(620, 416))
	fixture.sim.player.position = NEAR
	var enemies: BlasterOpsEnemyController = BlasterOpsEnemyController.new(fixture.sim.map, fixture.sim.targets.size())
	var shots: int = 0
	for tick in 240:
		fixture.sim.step(InfiltrationIntent.new(), enemies.produce_all(fixture.sim), [])
		for index in fixture.sim.event_count:
			shots += int(fixture.sim.events[index].type == InfiltrationEvent.Type.SHOT_FIRED)
	assert_gt(shots, 0)


func test_close_strike_always_gives_a_readable_warning() -> void:
	var data: BlasterOpsEnemyData = BlasterOpsFixture.enemy("heavy")
	var fixture: BlasterOpsFixture = _fixture("heavy")
	assert_almost(fixture.sim._telegraph_seconds(data, fixture.sim.targets[0] as BlasterOpsActor), BlasterOpsTraining.CONFIG.close_strike_telegraph_seconds)
	assert_true(data.telegraph_seconds < BlasterOpsTraining.CONFIG.close_strike_telegraph_seconds)


func test_guard_stops_a_close_strike() -> void:
	var fixture: BlasterOpsFixture = _fixture("soldier")
	var intent: InfiltrationIntent = InfiltrationIntent.new()
	intent.aim = Vector2.RIGHT
	intent.held = Intent.Command.BLOCK
	_run_enemies(fixture, 240, intent)
	assert_almost(fixture.sim.player.health, BlasterOpsTraining.CONFIG.health)


func test_a_blade_hit_interrupts_a_close_strike() -> void:
	var fixture: BlasterOpsFixture = _fixture("soldier")
	var actor: BlasterOpsActor = fixture.sim.targets[0] as BlasterOpsActor
	actor.telegraph_ticks = 5
	fixture.sim._emit(InfiltrationEvent.Type.SWING_HIT, 0, 1, actor.position, 5.0)
	assert_eq(actor.telegraph_ticks, -1)
	assert_gt(actor.fire_ticks, 0)


func test_a_swinging_player_is_not_hit_by_a_shooter_close_strike() -> void:
	var fixture: BlasterOpsFixture = _fixture("soldier")
	var actor: BlasterOpsActor = fixture.sim.targets[0] as BlasterOpsActor
	var data: BlasterOpsEnemyData = BlasterOpsFixture.enemy("soldier")
	actor.aim = Vector2.LEFT
	actor.telegraph_aim = Vector2.LEFT
	fixture.sim.player.swing_tick = 3
	var before: float = fixture.sim.player.health
	fixture.sim._release_enemy_attack(0, data, actor)
	assert_eq(fixture.sim.player.health, before)
	fixture.sim.player.swing_tick = -1
	fixture.sim._release_enemy_attack(0, data, actor)
	assert_lt(fixture.sim.player.health, before)


func test_a_crowd_of_shooters_lands_one_close_strike_per_gap() -> void:
	var fixture: BlasterOpsFixture = _fixture("soldier")
	var actor: BlasterOpsActor = fixture.sim.targets[0] as BlasterOpsActor
	var data: BlasterOpsEnemyData = BlasterOpsFixture.enemy("soldier")
	actor.aim = Vector2.LEFT
	actor.telegraph_aim = Vector2.LEFT
	fixture.sim._release_enemy_attack(0, data, actor)
	var after_first: float = fixture.sim.player.health
	fixture.sim._release_enemy_attack(0, data, actor)
	assert_eq(fixture.sim.player.health, after_first)
	fixture.sim.tick += Ticks.from_seconds(fixture.sim.operations.close_strike_gap_seconds)
	fixture.sim._release_enemy_attack(0, data, actor)
	assert_lt(fixture.sim.player.health, after_first)


func test_turrets_have_no_close_strike() -> void:
	assert_eq(BlasterOpsFixture.enemy("turret").melee_damage, 0.0)


func test_crusher_is_melee_only_and_hits_hard() -> void:
	var data: BlasterOpsEnemyData = BlasterOpsFixture.enemy("crusher")
	assert_eq(data.bolt, null)
	assert_gt(data.melee_damage, BlasterOpsFixture.enemy("rusher").melee_damage)
	assert_true(data.texture != null)
	var fixture: BlasterOpsFixture = _fixture("crusher")
	_run_enemies(fixture, 180)
	assert_lt(fixture.sim.player.health, BlasterOpsTraining.CONFIG.health)


func test_duelist_defends_shots_from_the_front_but_not_from_behind() -> void:
	var fixture: BlasterOpsFixture = _fixture("duelist", Vector2(500, 416))
	var actor: BlasterOpsActor = fixture.sim.targets[0] as BlasterOpsActor
	actor.spawned = true
	actor.aim = Vector2.LEFT
	var bolt: BlasterOpsBolt = BlasterOpsBolt.new()
	bolt.origin = Vector2(200, 416)
	assert_true(fixture.sim._deflects_bolt(0, bolt), "front")
	bolt.origin = Vector2(800, 416)
	assert_false(fixture.sim._deflects_bolt(0, bolt), "behind")
	bolt.origin = Vector2(200, 416)
	actor.telegraph_ticks = 5
	assert_false(fixture.sim._deflects_bolt(0, bolt), "open while preparing an attack")
	actor.telegraph_ticks = -1
	actor.stun_ticks = 5
	assert_false(fixture.sim._deflects_bolt(0, bolt), "open while stunned")


func test_duelist_power_warns_then_hurts_and_pushes() -> void:
	var fixture: BlasterOpsFixture = _fixture("duelist", Vector2(330, 416))
	var data: BlasterOpsEnemyData = BlasterOpsFixture.enemy("duelist")
	var actor: BlasterOpsActor = fixture.sim.targets[0] as BlasterOpsActor
	var before: float = fixture.sim.player.health
	fixture.sim._begin_enemy_power(0, data, actor)
	if not actor.casting_power:
		actor.casting_power = true
	var distance: float = fixture.sim.player.position.distance_to(actor.position)
	fixture.sim._release_enemy_power(0, data, actor)
	assert_lt(fixture.sim.player.health, before)
	assert_gt(fixture.sim.player.position.distance_to(actor.position), distance)
	assert_false(actor.casting_power)


func test_duelist_can_be_beaten_by_the_blade() -> void:
	var fixture: BlasterOpsFixture = _fixture("duelist")
	var enemies: BlasterOpsEnemyController = BlasterOpsEnemyController.new(fixture.sim.map, fixture.sim.targets.size())
	var intent: InfiltrationIntent = InfiltrationIntent.new()
	var actor: InfiltrationActor = fixture.sim.targets[0]
	fixture.sim.player.health = 1000.0
	for tick in 60 * 40:
		intent.clear()
		intent.aim = (actor.position - fixture.sim.player.position).normalized()
		intent.pressed = Intent.Command.HEAVY if fixture.sim.player.swing_tick < 0 else 0
		fixture.sim.step(intent, enemies.produce_all(fixture.sim), [])
		if actor.health <= 0.0:
			break
	assert_eq(actor.health, 0.0)


func test_missions_gained_enemies_and_stay_within_the_limit() -> void:
	var found: Dictionary = {}
	for mission in BlasterOpsMode.INCURSIONS:
		for wave in mission.waves:
			assert_true(wave.indices.size() <= 24, String(mission.id))
		for placement in mission.map.enemies:
			found[placement.enemy.id] = true
	assert_true(found.has(&"crusher"))
	assert_true(found.has(&"duelist"))


func test_pointer_follows_the_camera_and_the_stick_turns_it_off() -> void:
	var fixture: BlasterOpsFixture = BlasterOpsFixture.create()
	var controller: BlasterOpsPlayerController = BlasterOpsPlayerController.new()
	var intent: InfiltrationIntent = InfiltrationIntent.new()
	BlasterOpsBindings.install()
	controller.point_at(fixture.sim.player.position + Vector2(100.0, 0.0))
	controller.produce(fixture.sim, intent)
	assert_eq(intent.aim, Vector2.RIGHT)
	fixture.sim.player.position += Vector2(0.0, 200.0)
	controller.track_pointer(fixture.sim.player.position + Vector2(100.0, 0.0))
	controller.produce(fixture.sim, intent)
	assert_eq(intent.aim, Vector2.RIGHT, "walking with a still mouse keeps the aim")
	BlasterOpsBindings.uninstall()
