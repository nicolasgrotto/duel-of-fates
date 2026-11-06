extends TestCase

const ARSENAL: BlasterOpsArsenal = preload("res://data/blaster_ops/arsenal.tres")


func _character(id: StringName) -> CharacterData:
	return CharacterRoster.character(id)


func _fixture(character: StringName, weapon: StringName) -> BlasterOpsFixture:
	var source: BlasterOpsArenaData = BlasterOpsFixture.arena([BlasterOpsFixture.enemy("soldier")])
	source.enemies[0].position = Vector2(240, 416)
	return BlasterOpsFixture.create(source, BlasterOpsTraining.mission_loadout(_character(character), weapon))


func _switch(fixture: BlasterOpsFixture) -> void:
	fixture.intent.pressed = InfiltrationIntent.SWITCH_WEAPON
	fixture.step()
	fixture.step(fixture.sim.state.switch_ticks + 1)


func test_blade_only_stays_the_default_and_builtin_sidearms_are_kept() -> void:
	assert_eq(BlasterOpsTraining.mission_loadout(_character(&"guardian")).blaster, null)
	assert_ne(BlasterOpsTraining.mission_loadout(_character(&"corsair")).blaster, null)
	assert_true(BlasterOpsTraining.mission_loadout(_character(&"lynx")).integrated)
	assert_eq(BlasterOpsTraining.weapon_name_key(_character(&"guardian"), &""), "OPS_WEAPON_BLADE")
	assert_eq(BlasterOpsTraining.weapon_name_key(_character(&"corsair"), &""), "OPS_WEAPON_OWN_BLASTER")


func test_the_arsenal_offers_exactly_the_five_story_blasters() -> void:
	var ids: Array[StringName] = []
	for entry in ARSENAL.weapons:
		ids.append(entry.blaster.id)
	assert_eq(ids, [&"holster_pistol", &"thigh_revolver", &"lumbar_carbine", &"back_rifle", &"back_sniper"] as Array[StringName])


func test_every_selectable_character_has_training_and_nobody_is_trained_with_everything() -> void:
	var rows: Dictionary = {}
	for id in CharacterRoster.IDS:
		assert_true(ARSENAL.training.has(id), String(id))
		var row: Array = ARSENAL.training[id]
		assert_eq(row.size(), 3)
		assert_false(row == [0, 0, 0], String(id))
		rows[str(row)] = true
	assert_gt(rows.size(), 4)


func test_training_changes_handling_but_never_damage() -> void:
	var trained: BlasterOpsLoadout = BlasterOpsTraining.mission_loadout(_character(&"lance"), &"back_rifle")
	var untrained: BlasterOpsLoadout = BlasterOpsTraining.mission_loadout(_character(&"heron"), &"back_rifle")
	assert_eq(trained.damage_scale, untrained.damage_scale)
	assert_gt(untrained.heat_per_shot, trained.heat_per_shot)
	assert_gt(untrained.fire_interval, trained.fire_interval)
	assert_gt(untrained.spread_degrees, trained.spread_degrees)
	assert_gt(untrained.switch_scale, trained.switch_scale)
	assert_eq(trained.spread_degrees, 0.0)


func test_hands_decide_between_hybrid_and_switching() -> void:
	assert_false(BlasterOpsTraining.mission_loadout(_character(&"guardian"), &"holster_pistol").switchable)
	assert_true(BlasterOpsTraining.mission_loadout(_character(&"guardian"), &"lumbar_carbine").switchable)
	assert_true(BlasterOpsTraining.mission_loadout(_character(&"guardian"), &"back_sniper").switchable)
	for id in [&"wasp", &"ember", &"lance", &"reaper"]:
		assert_true(BlasterOpsTraining.mission_loadout(_character(id), &"holster_pistol").switchable, String(id))


func test_applying_a_weapon_never_touches_the_shared_blaster_or_character() -> void:
	var rifle: BlasterData = load("res://data/blasters/back_rifle.tres")
	var multiplier: float = rifle.vigor_multiplier
	var sidearm: BlasterData = _character(&"corsair").weapon.blaster
	var built: BlasterOpsLoadout = BlasterOpsTraining.mission_loadout(_character(&"corsair"), &"back_rifle")
	assert_eq(built.blaster, rifle)
	assert_eq(rifle.vigor_multiplier, multiplier)
	assert_eq(_character(&"corsair").weapon.blaster, sidearm)
	assert_eq(BlasterOpsTraining.PISTOL.heat_per_shot, 14.0)


func test_two_handed_weapon_fires_in_ranged_mode_and_cuts_in_blade_mode() -> void:
	var fixture: BlasterOpsFixture = _fixture(&"lance", &"back_rifle")
	var state: BlasterOpsState = fixture.sim.state
	assert_false(state.blade_drawn)
	fixture.intent.held = Intent.Command.LIGHT
	fixture.step(3)
	assert_gt(fixture.count_events(InfiltrationEvent.Type.SHOT_FIRED), 0)
	fixture.intent.held = 0
	fixture.step(120)
	_switch(fixture)
	assert_true(state.blade_drawn)
	assert_eq(fixture.count_events(InfiltrationEvent.Type.WEAPON_SWITCHED), 1)
	var shots: int = fixture.count_events(InfiltrationEvent.Type.SHOT_FIRED)
	var heat: float = state.heat
	fixture.intent.held = Intent.Command.LIGHT
	fixture.step(5)
	assert_eq(fixture.count_events(InfiltrationEvent.Type.SHOT_FIRED), shots)
	assert_gt(fixture.count_events(InfiltrationEvent.Type.SWING_STARTED), 0)
	assert_true(state.heat <= heat)
	fixture.intent.held = 0
	fixture.step(30)
	_switch(fixture)
	assert_false(state.blade_drawn)


func test_switch_time_comes_from_the_weapon_and_training() -> void:
	var fixture: BlasterOpsFixture = _fixture(&"heron", &"back_rifle")
	var blaster: BlasterData = fixture.sim.loadout.blaster
	fixture.intent.pressed = InfiltrationIntent.SWITCH_WEAPON
	fixture.step()
	assert_almost(fixture.sim.state.switch_ticks, Ticks.from_seconds(blaster.holster_time * 1.5), 1.5)


func test_nothing_fires_cuts_or_guards_during_a_switch() -> void:
	var fixture: BlasterOpsFixture = _fixture(&"lance", &"back_sniper")
	fixture.intent.pressed = InfiltrationIntent.SWITCH_WEAPON
	fixture.step()
	fixture.intent.held = Intent.Command.LIGHT | Intent.Command.BLOCK
	fixture.step(3)
	assert_gt(fixture.sim.state.switch_ticks, 0)
	assert_false(fixture.sim.player.guard)
	assert_eq(fixture.sim.player.swing_tick, -1)
	assert_eq(fixture.count_events(InfiltrationEvent.Type.SHOT_FIRED), 0)


func test_melee_from_ranged_mode_switches_then_cuts_by_itself() -> void:
	var fixture: BlasterOpsFixture = _fixture(&"lance", &"back_rifle")
	fixture.intent.pressed = Intent.Command.HEAVY
	fixture.step()
	assert_gt(fixture.sim.state.switch_ticks, 0)
	assert_true(fixture.sim.state.strike_queued)
	fixture.step(fixture.sim.state.switch_ticks + 2)
	assert_true(fixture.sim.state.blade_drawn)
	assert_gt(fixture.count_events(InfiltrationEvent.Type.SWING_STARTED), 0)
	assert_false(fixture.sim.state.strike_queued)


func test_guard_from_ranged_mode_switches_and_only_guards_while_held() -> void:
	var fixture: BlasterOpsFixture = _fixture(&"lance", &"back_rifle")
	fixture.intent.held = Intent.Command.BLOCK
	fixture.intent.pressed = Intent.Command.BLOCK
	fixture.step()
	assert_false(fixture.sim.player.guard)
	fixture.step(fixture.sim.state.switch_ticks + 1)
	assert_true(fixture.sim.player.guard)
	fixture.intent.held = 0
	fixture.step()
	assert_false(fixture.sim.player.guard)


func test_hybrid_weapon_keeps_the_blade_and_ignores_the_switch_key() -> void:
	var fixture: BlasterOpsFixture = _fixture(&"guardian", &"holster_pistol")
	fixture.intent.pressed = InfiltrationIntent.SWITCH_WEAPON
	fixture.step()
	assert_eq(fixture.sim.state.switch_ticks, 0)
	assert_false(fixture.sim.state.blade_drawn)
	fixture.intent.held = Intent.Command.LIGHT
	fixture.step(2)
	assert_gt(fixture.count_events(InfiltrationEvent.Type.SHOT_FIRED), 0)
	fixture.intent.held = Intent.Command.BLOCK
	fixture.step(30)
	assert_true(fixture.sim.player.guard)
	fixture.intent.held = 0
	fixture.intent.pressed = Intent.Command.HEAVY
	fixture.step(2)
	assert_gt(fixture.count_events(InfiltrationEvent.Type.SWING_STARTED), 0)


func test_blade_only_character_ignores_the_switch_key() -> void:
	var fixture: BlasterOpsFixture = _fixture(&"guardian", &"")
	fixture.intent.pressed = InfiltrationIntent.SWITCH_WEAPON
	fixture.step()
	assert_eq(fixture.sim.state.switch_ticks, 0)
	assert_eq(fixture.count_events(InfiltrationEvent.Type.WEAPON_SWITCHED), 0)


func test_untrained_spread_follows_a_fixed_pattern_and_replays_identically() -> void:
	var fixture: BlasterOpsFixture = BlasterOpsFixture.create(BlasterOpsFixture.arena(), BlasterOpsTraining.mission_loadout(_character(&"heron"), &"back_rifle"))
	var snapshot: Dictionary = fixture.sim.capture()
	fixture.intent.held = Intent.Command.LIGHT
	fixture.step(30)
	var expected: Dictionary = fixture.sim.capture()
	var directions: Dictionary = {}
	for bolt in fixture.sim.bolts:
		if bolt.active:
			directions[bolt.velocity.normalized().snappedf(0.001)] = true
	assert_gt(directions.size(), 1)
	fixture.sim.restore(snapshot)
	fixture.intent.held = Intent.Command.LIGHT
	fixture.step(30)
	assert_eq(fixture.sim.capture(), expected)


func test_weapon_mode_works_in_both_mission_objectives() -> void:
	for objective in [InfiltrationMissionData.Objective.INFILTRATION, InfiltrationMissionData.Objective.INCURSION]:
		var mission: InfiltrationMissionData = InfiltrationMissionData.new()
		mission.objective = objective
		mission.map = BlasterOpsFixture.arena()
		mission.extraction = Vector2(1300, 700)
		var sim: BlasterOpsSimulation = InfiltrationMode.new(mission, _character(&"lance"), BlasterOpsTraining.mission_loadout(_character(&"lance"), &"back_rifle")).create_simulation()
		var intent: InfiltrationIntent = InfiltrationIntent.new()
		intent.held = Intent.Command.LIGHT
		sim.step(intent)
		assert_gt(sim.state.heat, 0.0)
		intent.held = 0
		intent.pressed = InfiltrationIntent.SWITCH_WEAPON
		sim.step(intent)
		intent.pressed = 0
		for tick in 60:
			sim.step(intent)
		assert_true(sim.state.blade_drawn)


func test_saved_weapon_is_only_a_preference_and_absence_means_own_equipment() -> void:
	var look: Dictionary = SaveService.infiltration_look.duplicate()
	SaveService.infiltration_look = {"character": "guardian", "costume": 0, "blade": 0}
	assert_eq(InfiltrationMode.look_weapon(), &"")
	SaveService.infiltration_look["weapon"] = "back_rifle"
	var sim: BlasterOpsSimulation = InfiltrationMode.new(BlasterOpsMode.INCURSIONS[0]).create_simulation()
	assert_eq(sim.loadout.blaster.id, &"back_rifle")
	SaveService.infiltration_look["weapon"] = "removed_weapon"
	assert_eq(InfiltrationMode.new(BlasterOpsMode.INCURSIONS[0]).create_simulation().loadout.blaster, null)
	SaveService.infiltration_look = look


func test_view_state_follows_the_weapon_mode_not_the_input() -> void:
	var rifle: BlasterOpsLoadout = BlasterOpsTraining.mission_loadout(_character(&"lance"), &"back_rifle")
	assert_eq(BlasterOpsView.weapon_state(rifle, false), BlasterOpsView.WeaponState.BLASTER | BlasterOpsView.WeaponState.BELT_HILT | BlasterOpsView.WeaponState.SUPPORT_HAND)
	assert_eq(BlasterOpsView.weapon_state(rifle, true), BlasterOpsView.WeaponState.BLADE)
	var pistol: BlasterOpsLoadout = BlasterOpsTraining.mission_loadout(_character(&"wasp"), &"holster_pistol")
	assert_eq(BlasterOpsView.weapon_state(pistol, false), BlasterOpsView.WeaponState.BLASTER | BlasterOpsView.WeaponState.BELT_HILT)


func _rate(loadout: BlasterOpsLoadout) -> float:
	return loadout.blaster.bolt.damage * loadout.damage_scale * maxi(loadout.blaster.shot_count, 1) / loadout.fire_interval


func test_corsair_signature_beats_every_arsenal_weapon_and_stays_hers() -> void:
	var corsair: CharacterData = _character(&"corsair")
	var signature: BlasterOpsLoadout = BlasterOpsTraining.mission_loadout(corsair)
	for entry in BlasterOpsTraining.ARSENAL.weapons:
		var shop: BlasterOpsLoadout = BlasterOpsTraining.mission_loadout(corsair, entry.blaster.id)
		assert_gt(_rate(signature), _rate(shop), String(entry.blaster.id))
	var pistol: BlasterOpsLoadout = BlasterOpsTraining.mission_loadout(corsair, &"holster_pistol")
	assert_lt(signature.heat_per_shot / signature.fire_interval, pistol.heat_per_shot / pistol.fire_interval)
	var lynx: BlasterOpsLoadout = BlasterOpsTraining.equipment(_character(&"lynx"), 0)
	assert_true(lynx.integrated, "the emitter stays integrated in the hilt")
	assert_gt(_rate(lynx), _rate(BlasterOpsTraining.mission_loadout(_character(&"lynx"), &"holster_pistol")), "better than the shop pistol")
	assert_lt(_rate(lynx), _rate(signature), "the Corsair remains the strongest sidearm")
	assert_eq(BlasterOpsTraining.PISTOL.damage_scale, 2.5, "the shared pistol set keeps its damage")


func test_buffs_do_not_change_the_duel_blasters() -> void:
	var damage: Dictionary = {&"holster_pistol": 4.0, &"back_rifle": 6.0}
	for id: StringName in damage:
		var blaster: BlasterData = load("res://data/blasters/%s.tres" % id)
		assert_almost(blaster.bolt.damage, damage[id])
