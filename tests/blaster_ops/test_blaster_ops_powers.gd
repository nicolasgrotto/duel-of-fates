extends TestCase


func _fixture(index: int) -> BlasterOpsFixture:
	var equipment: BlasterOpsLoadout = BlasterOpsTraining.PISTOL.duplicate() as BlasterOpsLoadout
	equipment.power = BlasterOpsTraining.POWERS[index]
	var source: BlasterOpsArenaData = BlasterOpsFixture.arena([BlasterOpsFixture.enemy("soldier"), BlasterOpsFixture.enemy("soldier")])
	source.enemies[0].position = Vector2(360, 416)
	source.enemies[1].position = Vector2(430, 430)
	return BlasterOpsFixture.create(source, equipment)


func test_repulse_waits_for_startup_then_pushes_targets_using_the_shared_power_data() -> void:
	var fixture: BlasterOpsFixture = _fixture(0)
	var power: PowerData = fixture.sim.loadout.power.power
	fixture.intent.pressed = Intent.Command.POWER
	fixture.step()
	assert_eq(fixture.sim.state.power_cooldown, 360)
	fixture.step(power.startup_ticks() - 1)
	assert_almost(fixture.sim.targets[0].health, 24.0)
	fixture.step()
	assert_almost(fixture.sim.targets[0].health, 24.0 - power.damage)
	assert_eq(fixture.sim.targets[0].stun_ticks, Ticks.from_seconds(power.stagger) - 1)
	var before: Vector2 = fixture.sim.targets[0].position
	fixture.step(8)
	assert_gt(fixture.sim.targets[0].position.x, before.x)


func test_pull_affects_only_the_nearest_visible_target_and_respects_cover() -> void:
	var fixture: BlasterOpsFixture = _fixture(1)
	fixture.intent.pressed = Intent.Command.POWER
	fixture.step(20)
	assert_almost(fixture.sim.targets[0].health, 20.0)
	assert_almost(fixture.sim.targets[1].health, 24.0)
	assert_lt(fixture.sim.targets[0].position.x, 360.0)
	var source: BlasterOpsArenaData = BlasterOpsFixture.arena([BlasterOpsFixture.enemy("soldier")], true)
	source.enemies[0].position = Vector2(450, 416)
	fixture = BlasterOpsFixture.create(source)
	fixture.intent.pressed = Intent.Command.POWER
	fixture.step(25)
	assert_almost(fixture.sim.targets[0].health, 24.0)


func test_barrier_absorbs_bolts_and_excess_damage_reaches_health() -> void:
	var fixture: BlasterOpsFixture = _fixture(2)
	fixture.intent.pressed = Intent.Command.POWER
	fixture.step(fixture.sim.loadout.power.power.startup_ticks() + 1)
	assert_almost(fixture.sim.state.barrier_health, 95.0)
	fixture.sim.state.barrier_health = 5.0
	fixture.sim._resolve_player_bolt(fixture.incoming())
	assert_almost(fixture.sim.state.barrier_health, 0.0)
	assert_almost(fixture.sim.player.health, 98.0)
	fixture.sim.state.barrier_health = 20.0
	fixture.sim.state.barrier_ticks = 1
	fixture.step()
	assert_almost(fixture.sim.state.barrier_health, 0.0)


func test_dodge_cancels_power_startup_but_keeps_the_spent_cooldown() -> void:
	var fixture: BlasterOpsFixture = _fixture(0)
	fixture.intent.pressed = Intent.Command.POWER
	fixture.step()
	fixture.intent.pressed = Intent.Command.DODGE
	fixture.step()
	assert_eq(fixture.sim.state.power_ticks, 0)
	assert_eq(fixture.sim.state.power_cooldown, 359)
	fixture.step(30)
	assert_eq(fixture.count_events(InfiltrationEvent.Type.POWER_RELEASED), 0)
	assert_almost(fixture.sim.targets[0].health, 24.0)


func test_projectile_damage_cancels_power_preparation_and_fire_waits_for_recovery() -> void:
	var fixture: BlasterOpsFixture = _fixture(0)
	fixture.intent.pressed = Intent.Command.POWER
	fixture.intent.held = Intent.Command.LIGHT
	fixture.step()
	assert_eq(fixture.count_events(InfiltrationEvent.Type.SHOT_FIRED), 0)
	fixture.sim._resolve_player_bolt(fixture.incoming())
	assert_eq(fixture.sim.state.power_ticks, 0)
	assert_eq(fixture.sim.state.power_cooldown, 360)
	fixture.intent.clear()
	fixture.step(20)
	fixture.sim.state.power_cooldown = 0
	fixture.intent.pressed = Intent.Command.POWER
	fixture.intent.held = Intent.Command.LIGHT
	fixture.step(18)
	assert_gt(fixture.sim.state.power_recovery_ticks, 0.0)
	assert_eq(fixture.count_events(InfiltrationEvent.Type.SHOT_FIRED), 0)
	fixture.step(fixture.sim.loadout.power.power.recovery_ticks())
	assert_gt(fixture.count_events(InfiltrationEvent.Type.SHOT_FIRED), 0.0)


func test_power_impulse_collides_with_a_wall_and_does_not_teleport() -> void:
	var fixture: BlasterOpsFixture = _fixture(0)
	fixture.sim.targets[0].position = Vector2(1430, 416)
	fixture.sim.targets[0].previous = fixture.sim.targets[0].position
	fixture.sim.player.position = Vector2(1240, 416)
	fixture.intent.pressed = Intent.Command.POWER
	fixture.step(40)
	assert_true(fixture.sim.targets[0].position.x <= 1472.0 - fixture.sim.targets[0].radius)


func test_snapshot_restores_heat_dodge_power_enemy_charge_cover_and_player_bolts() -> void:
	var source: BlasterOpsArenaData = BlasterOpsFixture.arena([BlasterOpsFixture.enemy("soldier")], true)
	var fixture: BlasterOpsFixture = BlasterOpsFixture.create(source)
	var ai: BlasterOpsEnemyController = BlasterOpsEnemyController.new(fixture.sim.map, 1)
	fixture.intent.held = Intent.Command.LIGHT
	fixture.step(28, ai)
	fixture.intent.pressed = Intent.Command.DODGE
	fixture.step(4, ai)
	var snapshot: Dictionary = fixture.sim.capture()
	fixture.intent.clear()
	fixture.step(150, ai)
	var expected: Dictionary = fixture.sim.capture()
	fixture.sim.restore(snapshot)
	fixture.step(150, ai)
	assert_eq(fixture.sim.capture(), expected)
	assert_eq(fixture.sim.state_hash(), hash(expected))


func test_simulation_reuses_all_actor_bolt_and_event_objects_after_warmup() -> void:
	var fixture: BlasterOpsFixture = BlasterOpsFixture.create()
	var ids: PackedInt64Array = []
	for object in fixture.sim.bolts + fixture.sim.events:
		ids.append(object.get_instance_id())
	fixture.intent.held = Intent.Command.LIGHT
	fixture.step(1800)
	var after: PackedInt64Array = []
	for object in fixture.sim.bolts + fixture.sim.events:
		after.append(object.get_instance_id())
	assert_eq(after, ids)


func test_training_loadouts_support_blaster_styles_and_do_not_mutate_shared_weapons() -> void:
	for id in [&"corsair", &"lynx", &"holster", &"guardian"]:
		var character: CharacterData = DuelMode.character(id)
		var equipment: BlasterOpsLoadout = BlasterOpsTraining.equipment(character, 1)
		assert_true(equipment.can_deflect)
		assert_eq(equipment.power, BlasterOpsTraining.POWERS[1])
		if id == &"guardian":
			assert_eq(equipment.blaster, null)
		else:
			assert_almost(equipment.blaster.bolt.damage * equipment.damage_scale, {&"corsair": 16.0, &"lynx": 13.0}.get(id, 10.0))
	var story: StoryCampaign = StoryCampaign.create("Iria", 0, 3, 3, 0, 1)
	story.blaster_id = &"back_rifle"
	var equipment: BlasterOpsLoadout = BlasterOpsTraining.equipment(story.protagonist(), 2)
	assert_eq(equipment.blaster.id, &"back_rifle")
	assert_almost(equipment.fire_interval, 0.42)
	assert_eq(DuelMode.character(&"holster").weapon.blaster.id, &"holster_pistol")
