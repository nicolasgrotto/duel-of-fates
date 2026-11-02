extends TestCase


func test_movement_is_normalized_and_independent_of_aim() -> void:
	var fixture: BlasterOpsFixture = BlasterOpsFixture.create()
	fixture.intent.movement = Vector2(1, 1)
	fixture.intent.aim = Vector2.LEFT
	fixture.step(30)
	assert_almost(fixture.sim.player.velocity.length(), fixture.sim.config.walk_speed)
	assert_eq(fixture.sim.player.aim, Vector2.LEFT)
	assert_gt(fixture.sim.player.position.x, 160.0)


func test_primary_overheats_on_the_fifth_shot_and_resumes_at_the_threshold() -> void:
	var fixture: BlasterOpsFixture = BlasterOpsFixture.create()
	fixture.intent.held = Intent.Command.LIGHT
	fixture.step(41)
	assert_eq(fixture.count_events(InfiltrationEvent.Type.SHOT_FIRED), 5)
	assert_eq(fixture.count_events(InfiltrationEvent.Type.OVERHEATED), 1)
	assert_almost(fixture.sim.state.heat, 100.0)
	assert_true(fixture.sim.state.overheated)
	fixture.intent.clear()
	fixture.step(119)
	assert_true(fixture.sim.state.overheated)
	fixture.step()
	assert_false(fixture.sim.state.overheated)
	assert_almost(fixture.sim.state.heat, 40.0)
	fixture.intent.held = Intent.Command.LIGHT
	fixture.step()
	assert_eq(fixture.count_events(InfiltrationEvent.Type.SHOT_FIRED), 6)


func test_cooling_waits_for_the_configured_delay_and_repressing_does_not_unlock() -> void:
	var fixture: BlasterOpsFixture = BlasterOpsFixture.create()
	fixture.intent.held = Intent.Command.LIGHT
	fixture.step()
	fixture.intent.clear()
	fixture.step(14)
	assert_almost(fixture.sim.state.heat, 20.0)
	fixture.step()
	assert_almost(fixture.sim.state.heat, 19.5)
	fixture.sim.state.overheated = true
	fixture.sim.state.overheat_ticks = 10
	fixture.sim.state.heat = 30.0
	fixture.intent.held = Intent.Command.LIGHT
	fixture.step(9)
	assert_eq(fixture.count_events(InfiltrationEvent.Type.SHOT_FIRED), 1)
	fixture.step()
	assert_eq(fixture.count_events(InfiltrationEvent.Type.SHOT_FIRED), 2)


func test_full_pool_does_not_charge_heat_or_cadence_and_never_overwrites_a_bolt() -> void:
	var fixture: BlasterOpsFixture = BlasterOpsFixture.create()
	for candidate in fixture.sim.bolts:
		candidate.active = true
	var first: InfiltrationBolt = fixture.sim.bolts[0]
	first.position = Vector2(99, 99)
	fixture.sim._fire_primary()
	assert_almost(fixture.sim.state.heat, 0.0)
	assert_eq(fixture.sim.state.fire_ticks, 0)
	assert_eq(first.position, Vector2(99, 99))


func test_cadence_damage_and_range_come_from_the_equipped_data() -> void:
	for loadout in [BlasterOpsTraining.PISTOL, BlasterOpsTraining.RIFLE, BlasterOpsTraining.TEMPORARY]:
		var fixture: BlasterOpsFixture = BlasterOpsFixture.create(null, loadout)
		fixture.intent.held = Intent.Command.LIGHT
		fixture.step()
		var bolt: BlasterOpsBolt = fixture.sim.bolts[0] as BlasterOpsBolt
		assert_eq(bolt.data, loadout.blaster.bolt)
		assert_almost(bolt.damage, loadout.blaster.bolt.damage * loadout.damage_scale)
		assert_almost(bolt.velocity.length(), loadout.blaster.bolt.speed)
		assert_eq(bolt.shooter, -1)
		assert_eq(fixture.sim.state.fire_ticks, Ticks.from_seconds(loadout.fire_interval))
	assert_lt(BlasterOpsTraining.TEMPORARY.blaster.bolt.damage * BlasterOpsTraining.TEMPORARY.damage_scale, 10.0)


func test_dodge_locks_direction_and_requires_a_new_ready_activation() -> void:
	var fixture: BlasterOpsFixture = BlasterOpsFixture.create()
	fixture.intent.movement = Vector2.RIGHT
	fixture.intent.pressed = Intent.Command.DODGE
	fixture.step()
	assert_eq(fixture.sim.state.dodge_age, 0)
	assert_eq(fixture.sim.state.dodge_cooldown, 54)
	fixture.intent.movement = Vector2.LEFT
	fixture.step(8)
	assert_gt(fixture.sim.player.velocity.x, 0.0)
	fixture.step(8)
	assert_eq(fixture.sim.state.dodge_age, -1)
	fixture.intent.pressed = Intent.Command.DODGE
	fixture.step()
	assert_eq(fixture.sim.state.dodge_age, -1)
	fixture.step(37)
	fixture.intent.pressed = Intent.Command.DODGE
	fixture.step()
	assert_eq(fixture.sim.state.dodge_age, 0)
	assert_eq(fixture.sim.state.dodge_direction, Vector2.LEFT)


func test_dodge_invulnerability_and_precision_refund_have_exact_boundaries() -> void:
	for age in [2, 3, 8, 9, 11, 12]:
		var fixture: BlasterOpsFixture = BlasterOpsFixture.create()
		fixture.sim.state.dodge_age = age
		fixture.sim.state.dodge_cooldown = 40
		var bolt: BlasterOpsBolt = fixture.incoming()
		fixture.sim._resolve_player_bolt(bolt)
		var invulnerable: bool = age >= 3 and age < 12
		var precise: bool = age >= 3 and age < 9
		assert_almost(fixture.sim.player.health, 100.0 if invulnerable else 93.0)
		assert_eq(bolt.evaded, invulnerable)
		assert_eq(fixture.sim.state.dodge_cooldown, 0 if precise else 40)
		assert_eq(fixture.sim.state.precision_succeeded, precise)


func test_precision_refunds_once_and_an_evaded_bolt_keeps_flying() -> void:
	var fixture: BlasterOpsFixture = BlasterOpsFixture.create()
	fixture.sim.state.dodge_age = 4
	fixture.sim.state.dodge_cooldown = 40
	var bolt: BlasterOpsBolt = fixture.incoming()
	fixture.sim._resolve_player_bolt(bolt)
	assert_true(bolt.active)
	fixture.sim.state.dodge_cooldown = 20
	fixture.sim._resolve_player_bolt(fixture.incoming())
	assert_eq(fixture.sim.state.dodge_cooldown, 20)
	fixture.sim.state.dodge_age = -1
	fixture.sim.bolts[0] = bolt
	bolt.position = fixture.sim.player.position + Vector2(40, 0)
	bolt.previous = bolt.position
	fixture.step(8)
	assert_almost(fixture.sim.player.health, 100.0)
	assert_lt(bolt.position.x, fixture.sim.player.position.x)


func test_dodge_collides_with_walls_and_cover_without_tunneling() -> void:
	var fixture: BlasterOpsFixture = BlasterOpsFixture.create(BlasterOpsFixture.arena([], true))
	fixture.sim.player.position = Vector2(350, 416)
	fixture.intent.movement = Vector2.RIGHT
	fixture.intent.pressed = Intent.Command.DODGE
	fixture.step(16)
	assert_true(fixture.sim.player.position.x <= 384.0 - fixture.sim.player.radius)
	fixture.sim.player.position = Vector2(90, 300)
	fixture.sim.state.dodge_cooldown = 0
	fixture.intent.movement = Vector2.LEFT
	fixture.intent.pressed = Intent.Command.DODGE
	fixture.step(16)
	assert_true(fixture.sim.player.position.x >= 64.0 + fixture.sim.player.radius)


func test_timed_guard_reflects_along_aim_and_perfect_keeps_the_same_direction() -> void:
	for age in [0, 7]:
		var fixture: BlasterOpsFixture = BlasterOpsFixture.create()
		fixture.sim.player.guard = true
		fixture.sim.player.parry_age = age
		fixture.sim.player.aim = Vector2(0.6, 0.8)
		var bolt: BlasterOpsBolt = fixture.incoming()
		fixture.sim._resolve_player_bolt(bolt)
		assert_eq(bolt.owner, 0)
		assert_true(bolt.reflected)
		assert_true(bolt.velocity.normalized().is_equal_approx(fixture.sim.player.aim))
		assert_almost(bolt.velocity.length(), bolt.data.speed * (1.25 if age == 0 else 1.0))
		assert_almost(bolt.damage, 7.0)
		assert_almost(fixture.sim.player.vigor, 100.0)


func test_late_guard_spends_vigor_and_back_guard_does_not_protect() -> void:
	var fixture: BlasterOpsFixture = BlasterOpsFixture.create()
	fixture.sim.player.guard = true
	fixture.sim._resolve_player_bolt(fixture.incoming())
	assert_almost(fixture.sim.player.vigor, 89.0)
	assert_almost(fixture.sim.player.health, 100.0)
	fixture.sim.player.aim = Vector2.LEFT
	fixture.sim._resolve_player_bolt(fixture.incoming())
	assert_almost(fixture.sim.player.health, 93.0)


func test_guard_and_dodge_prevent_primary_fire() -> void:
	for command in [Intent.Command.BLOCK, Intent.Command.DODGE]:
		var fixture: BlasterOpsFixture = BlasterOpsFixture.create()
		fixture.intent.held = Intent.Command.LIGHT | command
		fixture.intent.pressed = command
		fixture.step()
		assert_eq(fixture.count_events(InfiltrationEvent.Type.SHOT_FIRED), 0)
		assert_almost(fixture.sim.state.heat, 0.0)


func test_destructible_cover_blocks_the_destroying_bolt_and_leaves_an_open_tile() -> void:
	var source: BlasterOpsArenaData = BlasterOpsFixture.arena([BlasterOpsFixture.enemy("soldier")], true)
	var original: PackedStringArray = source.rows.duplicate()
	var fixture: BlasterOpsFixture = BlasterOpsFixture.create(source)
	fixture.intent.held = Intent.Command.LIGHT
	for tick in 80:
		fixture.step()
		if fixture.count_events(InfiltrationEvent.Type.COVER_DESTROYED) > 0:
			break
	assert_eq(fixture.count_events(InfiltrationEvent.Type.COVER_HIT), 3)
	assert_eq(fixture.count_events(InfiltrationEvent.Type.COVER_DESTROYED), 1)
	assert_almost(fixture.sim.arena.covers[0].health, 0.0)
	assert_false(fixture.sim.map.is_solid(6, 6))
	assert_eq(fixture.count_events(InfiltrationEvent.Type.BOLT_HIT), 0)
	assert_eq(source.rows, original)
	assert_true(source.is_solid(6, 6))
	assert_almost(BlasterOpsFixture.create(source).sim.arena.covers[0].health, 30.0)


func test_cover_has_three_damage_steps_and_walls_absorb_without_cover_damage() -> void:
	var source: BlasterOpsArenaData = BlasterOpsFixture.arena([], true)
	var fixture: BlasterOpsFixture = BlasterOpsFixture.create(source)
	for health in [30.0, 20.0, 10.0, 0.0]:
		fixture.sim.arena.covers[0].health = health
		assert_eq(fixture.sim.arena.covers[0].damage_stage(), int((30.0 - health) / 10.0))
	source.rows[6] = source.rows[6].substr(0, 4) + "#" + source.rows[6].substr(5)
	fixture = BlasterOpsFixture.create(source)
	fixture.intent.held = Intent.Command.LIGHT
	fixture.step(90)
	assert_almost(fixture.sim.arena.covers[0].health, 30.0)
	assert_eq(fixture.count_events(InfiltrationEvent.Type.COVER_HIT), 0)


func test_cover_restore_invalidates_navigation_in_both_directions() -> void:
	var source: BlasterOpsArenaData = BlasterOpsFixture.arena([BlasterOpsFixture.enemy("rusher")], true)
	for y in source.rows.size():
		if y != 6:
			source.rows[y] = "#".repeat(source.width())
	var fixture: BlasterOpsFixture = BlasterOpsFixture.create(source)
	var ai: BlasterOpsEnemyController = BlasterOpsEnemyController.new(fixture.sim.map, 1)
	var snapshot: Dictionary = fixture.sim.capture()
	assert_eq(ai.produce_all(fixture.sim)[0].movement, Vector2.ZERO)
	fixture.sim._damage_cover(0, 30.0, Vector2(400, 416))
	assert_lt(ai.produce_all(fixture.sim)[0].movement.x, 0.0)
	fixture.sim.restore(snapshot)
	assert_eq(ai.produce_all(fixture.sim)[0].movement, Vector2.ZERO)


func test_every_enemy_attack_has_a_telegraph_before_the_first_shot() -> void:
	for id in ["soldier", "marksman", "heavy"]:
		var data: BlasterOpsEnemyData = BlasterOpsFixture.enemy(id)
		var fixture: BlasterOpsFixture = BlasterOpsFixture.create(BlasterOpsFixture.arena([data]))
		var ai: BlasterOpsEnemyController = BlasterOpsEnemyController.new(fixture.sim.map, 1)
		var prepared_tick: int = -1
		for tick in 250:
			fixture.step(1, ai)
			if fixture.count_events(InfiltrationEvent.Type.ATTACK_PREPARED) > 0:
				prepared_tick = fixture.sim.tick
				break
		assert_true(prepared_tick > 0)
		assert_eq(fixture.count_events(InfiltrationEvent.Type.SHOT_FIRED), 0)
		fixture.step(Ticks.from_seconds(data.telegraph_seconds) - 1, ai)
		assert_eq(fixture.count_events(InfiltrationEvent.Type.SHOT_FIRED), 0)
		fixture.step(1, ai)
		assert_eq(fixture.count_events(InfiltrationEvent.Type.SHOT_FIRED), 1)


func test_marksman_locks_aim_and_cancelled_attack_does_not_fire_late() -> void:
	var fixture: BlasterOpsFixture = BlasterOpsFixture.create(BlasterOpsFixture.arena([BlasterOpsFixture.enemy("marksman")]))
	fixture.sim.targets[0].fire_ticks = 0
	var ai: BlasterOpsEnemyController = BlasterOpsEnemyController.new(fixture.sim.map, 1)
	fixture.step(2, ai)
	var actor: BlasterOpsActor = fixture.sim.targets[0] as BlasterOpsActor
	var aim: Vector2 = actor.telegraph_aim
	fixture.sim.player.position += Vector2(0, 60)
	fixture.step(10, ai)
	assert_eq(actor.aim, aim)
	assert_eq(actor.telegraph_aim, aim)
	fixture.step(60)
	assert_eq(fixture.count_events(InfiltrationEvent.Type.SHOT_FIRED), 0)


func test_heavy_front_armor_reduces_shots_and_back_is_vulnerable() -> void:
	for front in [true, false]:
		var fixture: BlasterOpsFixture = BlasterOpsFixture.create(BlasterOpsFixture.arena([BlasterOpsFixture.enemy("heavy")]))
		fixture.sim.targets[0].aim = Vector2.LEFT if front else Vector2.RIGHT
		fixture.intent.held = Intent.Command.LIGHT
		fixture.step()
		fixture.intent.clear()
		fixture.step(50)
		assert_almost(fixture.sim.targets[0].health, 48.0 - (3.5 if front else 10.0))


func test_rusher_approaches_and_telegraphs_a_real_melee_hit() -> void:
	var fixture: BlasterOpsFixture = BlasterOpsFixture.create(BlasterOpsFixture.arena([BlasterOpsFixture.enemy("rusher")]))
	var ai: BlasterOpsEnemyController = BlasterOpsEnemyController.new(fixture.sim.map, 1)
	fixture.step(220, ai)
	assert_lt(fixture.sim.targets[0].position.x, 250.0)
	assert_lt(fixture.sim.player.health, 100.0)
	assert_gt(fixture.count_events(InfiltrationEvent.Type.ATTACK_PREPARED), 0.0)
	assert_eq(fixture.count_events(InfiltrationEvent.Type.SHOT_FIRED), 0)


func test_enemy_controllers_produce_only_intents_and_reproduce_the_same_run() -> void:
	var source: BlasterOpsArenaData = BlasterOpsFixture.arena([BlasterOpsFixture.enemy("soldier"), BlasterOpsFixture.enemy("rusher")])
	var first: BlasterOpsFixture = BlasterOpsFixture.create(source)
	var second: BlasterOpsFixture = BlasterOpsFixture.create(source)
	var ai: BlasterOpsEnemyController = BlasterOpsEnemyController.new(first.sim.map, first.sim.targets.size())
	var other: BlasterOpsEnemyController = BlasterOpsEnemyController.new(second.sim.map, second.sim.targets.size())
	var snapshot: Dictionary = first.sim.capture()
	ai.produce_all(first.sim)
	assert_eq(first.sim.capture(), snapshot)
	first.intent.movement = Vector2.UP
	second.intent.movement = Vector2.UP
	first.step(120, ai)
	second.step(120, other)
	assert_eq(first.sim.capture(), second.sim.capture())
