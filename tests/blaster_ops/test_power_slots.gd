extends TestCase

const CONFIG: BlasterOpsConfig = BlasterOpsTraining.CONFIG


func _fixture(powers: Array[String], enemies: Array[BlasterOpsEnemyData] = [BlasterOpsFixture.enemy("soldier"), BlasterOpsFixture.enemy("soldier")]) -> BlasterOpsFixture:
	var equipment: BlasterOpsLoadout = BlasterOpsTraining.PISTOL.duplicate() as BlasterOpsLoadout
	equipment.power = load("res://data/blaster_ops/powers/%s.tres" % powers[0])
	var extra: Array[BlasterOpsPowerData] = []
	for index in range(1, powers.size()):
		extra.append(load("res://data/blaster_ops/powers/%s.tres" % powers[index]))
	equipment.extra_powers = extra
	var source: BlasterOpsArenaData = BlasterOpsFixture.arena(enemies)
	if not enemies.is_empty():
		source.enemies[0].position = Vector2(300, 416)
	if enemies.size() > 1:
		source.enemies[1].position = Vector2(420, 560)
	return BlasterOpsFixture.create(source, equipment)


func _cast(fixture: BlasterOpsFixture, command: int = Intent.Command.POWER) -> void:
	fixture.intent.pressed = command
	var slot: int = BlasterOpsSimulation.POWER_COMMANDS.find(command)
	fixture.step(fixture.sim.loadout.slot(slot).power.startup_ticks() + 1)


func test_every_selectable_character_brings_its_own_three_adapted_powers() -> void:
	for id in CharacterRoster.IDS:
		var character: CharacterData = CharacterRoster.character(id)
		var equipment: BlasterOpsLoadout = BlasterOpsTraining.mission_loadout(character)
		assert_eq(equipment.slot_count(), mini(character.powers.size(), 3), String(id))
		for index in equipment.slot_count():
			assert_eq(equipment.slot(index).power, character.powers[index], String(id))
	var shadow: BlasterOpsLoadout = BlasterOpsTraining.mission_loadout(CharacterRoster.character(&"shadow"))
	assert_eq(shadow.power.power.id, &"lightning")
	assert_eq(shadow.slot(2).power.id, &"choke")


func test_adapted_catalog_only_links_to_the_shared_power_resources() -> void:
	var ids: Dictionary = {}
	for entry in BlasterOpsTraining.ADAPTED_POWERS:
		assert_false(ids.has(entry.power.id))
		ids[entry.power.id] = true
		assert_gt(entry.cooldown, 0.0)
		assert_true(entry.power.icon != null, String(entry.power.id))
		assert_true(entry.power.resource_path.begins_with("res://data/powers/"))


func test_explicit_single_power_loadouts_keep_working() -> void:
	var equipment: BlasterOpsLoadout = BlasterOpsTraining.equipment(DuelMode.character(&"guardian"), 1)
	assert_eq(equipment.slot_count(), 1)
	assert_eq(equipment.slot(1), null)


func test_slots_cast_independently_with_their_own_cooldowns() -> void:
	var fixture: BlasterOpsFixture = _fixture(["repulse", "pull", "barrier"])
	var state: BlasterOpsState = fixture.sim.state
	fixture.intent.pressed = InfiltrationIntent.POWER_2
	fixture.step()
	assert_eq(state.cast_slot, 1)
	assert_eq(state.power_cooldown, 0)
	assert_eq(state.power_cooldown_2, Ticks.from_seconds(7.0))
	fixture.intent.pressed = Intent.Command.POWER
	fixture.step()
	assert_eq(state.cast_slot, 1)
	assert_eq(state.power_cooldown, 0)
	fixture.step(fixture.sim.loadout.slot(1).power.startup_ticks() + fixture.sim.loadout.slot(1).power.recovery_ticks())
	fixture.intent.pressed = InfiltrationIntent.POWER_3
	fixture.step()
	assert_eq(state.cast_slot, 2)
	assert_gt(state.power_cooldown_3, 0)
	assert_gt(state.power_cooldown_2, 0)


func test_empty_slots_refuse_without_charging_anything() -> void:
	var fixture: BlasterOpsFixture = _fixture(["repulse"])
	fixture.intent.pressed = InfiltrationIntent.POWER_3
	fixture.step()
	assert_eq(fixture.sim.state.power_ticks, 0)
	assert_eq(fixture.sim.state.power_cooldown_3, 0)


func test_infiltration_triples_the_cooldown_of_every_slot() -> void:
	var mission: InfiltrationMissionData = InfiltrationMissionData.new()
	mission.map = BlasterOpsFixture.arena()
	mission.extraction = Vector2(1300, 700)
	var equipment: BlasterOpsLoadout = BlasterOpsTraining.mission_loadout(CharacterRoster.character(&"shadow"))
	var sim: BlasterOpsSimulation = BlasterOpsSimulation.new(CONFIG, mission.map, equipment, mission)
	var intent: InfiltrationIntent = InfiltrationIntent.new()
	intent.pressed = InfiltrationIntent.POWER_3
	sim.step(intent)
	assert_eq(sim.state.power_cooldown_3, Ticks.from_seconds(equipment.slot(2).cooldown * CONFIG.stealth_power_cooldown_multiplier))


func test_throw_launches_an_allied_projectile_without_heat_or_accuracy_penalty() -> void:
	var fixture: BlasterOpsFixture = _fixture(["throw"])
	var health: float = fixture.sim.targets[0].health
	_cast(fixture)
	assert_eq(fixture.sim.state.heat, 0.0)
	fixture.step(30)
	assert_lt(fixture.sim.targets[0].health, health)
	assert_eq(fixture.count_events(InfiltrationEvent.Type.BOLT_HIT), 1)


func test_heal_restores_health_up_to_the_maximum_and_damage_interrupts_it() -> void:
	var fixture: BlasterOpsFixture = _fixture(["heal"], [])
	fixture.sim.player.health = 50.0
	_cast(fixture)
	fixture.step(Ticks.from_seconds(0.5))
	var partial: float = fixture.sim.player.health
	assert_gt(partial, 50.0)
	fixture.sim._hurt_player(1.0, 0, 1, fixture.sim.player.position)
	assert_eq(fixture.sim.state.heal_ticks, 0)
	assert_almost(fixture.sim.player.health, partial - 1.0)
	fixture.step(30)
	assert_almost(fixture.sim.player.health, partial - 1.0)
	var full: BlasterOpsFixture = _fixture(["heal"], [])
	full.sim.player.health = 99.0
	_cast(full)
	full.step(Ticks.from_seconds(2.0) + 2)
	assert_eq(full.sim.player.health, CONFIG.health)


func test_absorption_eats_bolts_and_refunds_cooldowns_but_not_melee() -> void:
	var fixture: BlasterOpsFixture = _fixture(["absorption", "repulse"], [])
	var state: BlasterOpsState = fixture.sim.state
	state.power_cooldown_2 = 300
	_cast(fixture)
	var before: int = state.power_cooldown_2
	var bolt: BlasterOpsBolt = fixture.incoming()
	fixture.sim._resolve_player_bolt(bolt)
	assert_false(bolt.active)
	assert_eq(fixture.sim.player.health, CONFIG.health)
	assert_eq(state.power_cooldown_2, before - Ticks.from_seconds(CONFIG.absorb_refund_seconds))
	fixture.sim._hurt_player(5.0, 0, 1, fixture.sim.player.position)
	assert_lt(fixture.sim.player.health, CONFIG.health)


func test_lightning_channel_pulses_the_nearest_target_and_dodge_cuts_it() -> void:
	var fixture: BlasterOpsFixture = _fixture(["lightning"])
	var power: PowerData = fixture.sim.loadout.power.power
	var health: float = fixture.sim.targets[0].health
	_cast(fixture)
	assert_gt(fixture.sim.state.channel_ticks, 0)
	fixture.step(Ticks.from_seconds(0.25))
	var hit: float = fixture.sim.targets[0].health
	assert_lt(hit, health)
	assert_eq(fixture.sim.targets[1].health, fixture.sim.target_data[1].health)
	assert_eq(fixture.sim.state.channel_target, 0)
	fixture.intent.pressed = Intent.Command.DODGE
	fixture.step()
	assert_eq(fixture.sim.state.channel_ticks, 0)
	assert_eq(fixture.sim.state.channel_target, -1)
	fixture.step(30)
	assert_eq(fixture.sim.targets[0].health, hit)
	assert_gt(power.damage, 0.0)


func test_choke_holds_the_target_for_the_whole_channel_and_blocks_other_casts() -> void:
	var fixture: BlasterOpsFixture = _fixture(["choke", "repulse"])
	_cast(fixture)
	fixture.step(Ticks.from_seconds(0.5))
	assert_gt((fixture.sim.targets[0] as BlasterOpsActor).stun_ticks, 0)
	fixture.intent.pressed = InfiltrationIntent.POWER_2
	fixture.step()
	assert_eq(fixture.sim.state.power_cooldown_2, 0)


func test_freeze_stuns_only_the_nearest_target_for_the_shared_duration() -> void:
	var fixture: BlasterOpsFixture = _fixture(["freeze"])
	_cast(fixture)
	assert_almost((fixture.sim.targets[0] as BlasterOpsActor).stun_ticks, Ticks.from_seconds(fixture.sim.loadout.power.power.duration), 2.0)
	assert_eq((fixture.sim.targets[1] as BlasterOpsActor).stun_ticks, 0)


func test_wrath_uses_the_flow_multipliers_for_dealt_and_taken_damage() -> void:
	var fixture: BlasterOpsFixture = _fixture(["wrath"], [BlasterOpsFixture.enemy("soldier")])
	var flow: FlowConfig = CONFIG.duel_config.flow
	_cast(fixture)
	assert_gt(fixture.sim.state.boost_ticks, 0)
	assert_almost(fixture.sim.swing_damage(), CONFIG.swing_damage * flow.wrath_dealt)
	var bolt: BlasterOpsBolt = fixture.sim._spawn_bolt(-1, fixture.sim.loadout.blaster.bolt, Vector2.RIGHT, fixture.sim.loadout.damage_scale * fixture.sim._dealt_scale())
	assert_almost(bolt.damage, fixture.sim.loadout.blaster.bolt.damage * fixture.sim.loadout.damage_scale * flow.wrath_dealt)
	fixture.sim._hurt_player(10.0, 0, 1, fixture.sim.player.position)
	assert_almost(fixture.sim.player.health, CONFIG.health - 10.0 * flow.wrath_taken)


func test_storm_strikes_through_the_area_rule_and_spares_allies() -> void:
	var fixture: BlasterOpsFixture = _fixture(["storm"], [BlasterOpsFixture.enemy("soldier")])
	var health: float = fixture.sim.targets[0].health
	_cast(fixture)
	fixture.step(Ticks.from_seconds(1.5))
	assert_gt(fixture.count_events(InfiltrationEvent.Type.AREA_BLAST), 0)
	assert_lt(fixture.sim.targets[0].health, health)
	assert_eq(fixture.sim.player.health, CONFIG.health)


func test_active_power_state_survives_a_snapshot_and_replays_identically() -> void:
	var fixture: BlasterOpsFixture = _fixture(["lightning", "wrath", "heal"])
	fixture.sim.player.health = 50.0
	_cast(fixture)
	var snapshot: Dictionary = fixture.sim.capture()
	fixture.step(12)
	var expected: Dictionary = fixture.sim.capture()
	fixture.sim.restore(snapshot)
	fixture.step(12)
	assert_eq(fixture.sim.capture(), expected)


func test_casting_does_not_mutate_the_shared_duel_power_data() -> void:
	var power: PowerData = load("res://data/powers/lightning.tres")
	var damage: float = power.damage
	var fixture: BlasterOpsFixture = _fixture(["lightning"])
	_cast(fixture)
	fixture.step(30)
	assert_eq(power.damage, damage)
