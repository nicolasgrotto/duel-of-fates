extends TestCase


func _fixture(names: Array[String], points: Array[Vector2]) -> BlasterOpsFixture:
	var enemies: Array[BlasterOpsEnemyData] = []
	for name in names:
		enemies.append(BlasterOpsFixture.enemy(name))
	var source: BlasterOpsArenaData = BlasterOpsFixture.arena(enemies)
	for index in points.size():
		source.enemies[index].position = points[index]
	return BlasterOpsFixture.create(source)


func test_every_new_enemy_has_its_own_sprite_and_a_distinct_role() -> void:
	var roles: Dictionary = {}
	for name in ["warden", "sapper", "repairer", "ironstride"]:
		var data: BlasterOpsEnemyData = BlasterOpsFixture.enemy(name)
		assert_true(data.texture != null, name)
		roles[[data.aura, data.blast_radius > 0.0, data.flee_range > 0.0, data.stride > 0.0]] = true
	assert_eq(roles.size(), 4)


func test_warden_field_halves_blade_and_bolt_damage_on_others_but_not_on_itself() -> void:
	var fixture: BlasterOpsFixture = _fixture(["soldier", "warden"], [Vector2(400, 416), Vector2(460, 416)])
	var sim: BlasterOpsSimulation = fixture.sim
	assert_almost(sim._armored_damage(0, 10.0, sim.player.position), 5.0)
	assert_almost(sim._armored_damage(1, 10.0, sim.player.position), 10.0)
	sim.targets[0].position = Vector2(700, 416)
	assert_almost(sim._armored_damage(0, 10.0, sim.player.position), 10.0)
	sim.targets[0].position = Vector2(400, 416)
	sim.targets[1].health = 0.0
	assert_almost(sim._armored_damage(0, 10.0, sim.player.position), 10.0)


func test_powers_ignore_the_warden_field() -> void:
	var fixture: BlasterOpsFixture = _fixture(["soldier", "warden"], [Vector2(300, 416), Vector2(360, 416)])
	var health: float = fixture.sim.targets[0].health
	fixture.intent.pressed = Intent.Command.POWER
	fixture.step(fixture.sim.loadout.power.power.startup_ticks() + 1)
	assert_almost(fixture.sim.targets[0].health, health - fixture.sim.loadout.power.power.damage)


func test_repairer_heals_wounded_allies_but_never_above_maximum_or_itself() -> void:
	var fixture: BlasterOpsFixture = _fixture(["soldier", "repairer"], [Vector2(600, 416), Vector2(660, 416)])
	var sim: BlasterOpsSimulation = fixture.sim
	var maximum: float = sim.target_data[0].health
	sim.targets[0].health = maximum - 1.0
	sim.targets[1].health = 10.0
	fixture.step(Ticks.from_seconds(0.6))
	assert_eq(sim.targets[0].health, maximum)
	assert_eq(sim.targets[1].health, 10.0)
	assert_gt(fixture.count_events(InfiltrationEvent.Type.AURA_PULSE), 0)


func test_repairer_never_heals_the_boss_phase_target() -> void:
	var mission: BlasterOpsMissionData = BlasterOpsMode.INCURSIONS[6]
	var sim: BlasterOpsSimulation = BlasterOpsMode.new(mission, DuelMode.character(&"guardian"), null, true).create_simulation()
	sim.aura_indices = PackedInt32Array([1])
	var original: InfiltrationTargetData = sim.target_data[1]
	sim.target_data[1] = BlasterOpsFixture.enemy("repairer")
	sim.targets[0].health = 10.0
	sim.targets[0].position = Vector2(400, 400)
	sim.targets[1].health = 10.0
	sim.targets[1].position = Vector2(440, 400)
	sim._refresh_live_bodies()
	sim._advance_auras()
	assert_eq(sim.targets[0].health, 10.0)
	sim.target_data[1] = original


func test_repairer_flees_through_intents_only() -> void:
	var fixture: BlasterOpsFixture = _fixture(["repairer"], [Vector2(300, 416)])
	var sim: BlasterOpsSimulation = fixture.sim
	var controller: BlasterOpsEnemyController = BlasterOpsEnemyController.new(sim.map, sim.targets.size())
	InfiltrationPerception.alert(sim, 0, sim.player.position)
	var snapshot: Dictionary = sim.capture()
	var commands: Array[InfiltrationIntent] = controller.produce_all(sim)
	assert_eq(sim.capture(), snapshot)
	assert_gt(commands[0].movement.dot((sim.targets[0].position - sim.player.position).normalized()), 0.0)


func test_sapper_arms_visibly_then_detonates_and_dies() -> void:
	var fixture: BlasterOpsFixture = _fixture(["sapper"], [Vector2(210, 416)])
	var sim: BlasterOpsSimulation = fixture.sim
	var controller: BlasterOpsEnemyController = BlasterOpsEnemyController.new(sim.map, sim.targets.size())
	InfiltrationPerception.alert(sim, 0, sim.player.position)
	fixture.intent.aim = Vector2.RIGHT
	fixture.step(Ticks.from_seconds(0.3), controller)
	assert_gt(fixture.count_events(InfiltrationEvent.Type.ATTACK_PREPARED), 0)
	assert_eq(sim.player.health, BlasterOpsTraining.CONFIG.health)
	fixture.step(Ticks.from_seconds(1.0), controller)
	assert_eq(sim.targets[0].health, 0.0)
	assert_eq(fixture.count_events(InfiltrationEvent.Type.AREA_BLAST), 1)
	assert_almost(sim.player.health, BlasterOpsTraining.CONFIG.health - BlasterOpsFixture.enemy("sapper").blast_damage)


func test_killing_a_sapper_detonates_it_where_it_stands_and_spares_other_enemies() -> void:
	var fixture: BlasterOpsFixture = _fixture(["sapper", "soldier"], [Vector2(600, 416), Vector2(650, 416)])
	var sim: BlasterOpsSimulation = fixture.sim
	var health: float = sim.targets[1].health
	sim._damage_target(0, 100.0)
	assert_eq(fixture.sim.event_count > 0, true)
	assert_eq(sim.targets[1].health, health)
	assert_eq(sim.player.health, BlasterOpsTraining.CONFIG.health)


func test_ironstride_shell_explodes_on_impact_and_breaks_cover() -> void:
	var source: BlasterOpsArenaData = BlasterOpsFixture.arena([BlasterOpsFixture.enemy("ironstride")], true)
	source.enemies[0].position = Vector2(800, 416)
	var fixture: BlasterOpsFixture = BlasterOpsFixture.create(source)
	var sim: BlasterOpsSimulation = fixture.sim
	var crate: BlasterOpsCover = sim.arena.covers[0]
	var point: Vector2 = (Vector2(crate.data.cell) + Vector2.ONE * 0.5) * sim.map.tile_size
	assert_true(sim._spawn_enemy_shot(0, BlasterOpsFixture.enemy("ironstride"), (point - sim.targets[0].position).normalized()))
	var health: float = crate.health
	fixture.step(120)
	assert_lt(crate.health, health)
	assert_eq(fixture.count_events(InfiltrationEvent.Type.AREA_BLAST), 1)


func test_ironstride_is_slow_armored_immune_to_takedown_and_stomps_up_close() -> void:
	var data: BlasterOpsEnemyData = BlasterOpsFixture.enemy("ironstride")
	assert_lt(data.speed, BlasterOpsFixture.enemy("soldier").speed)
	assert_true(data.takedown_immune)
	var fixture: BlasterOpsFixture = _fixture(["ironstride"], [Vector2(250, 416)])
	var sim: BlasterOpsSimulation = fixture.sim
	sim.targets[0].aim = Vector2.LEFT
	assert_almost(sim._armored_damage(0, 10.0, sim.player.position), 10.0 * data.front_damage_ratio)
	assert_almost(sim._armored_damage(0, 10.0, sim.targets[0].position + Vector2(200, 0)), 10.0)
	var actor: BlasterOpsActor = sim.targets[0] as BlasterOpsActor
	actor.telegraph_aim = Vector2.LEFT
	actor.burst_left = 1
	sim._release_enemy_attack(0, data, actor)
	assert_almost(sim.player.health, BlasterOpsTraining.CONFIG.health - data.melee_damage)


func test_reflected_shell_explodes_on_the_player_side() -> void:
	var fixture: BlasterOpsFixture = _fixture(["soldier"], [Vector2(420, 416)])
	var sim: BlasterOpsSimulation = fixture.sim
	var bolt: BlasterOpsBolt = sim._spawn_bolt(-1, sim.loadout.blaster.bolt, Vector2.RIGHT)
	bolt.blast_radius = 80.0
	bolt.blast_damage = 3.0
	var health: float = sim.targets[0].health
	fixture.step(30)
	assert_lt(sim.targets[0].health, health)
	assert_eq(sim.player.health, BlasterOpsTraining.CONFIG.health)
