extends TestCase


func _duel(first: StringName = &"guardian", second: StringName = &"shadow") -> DuelFixture:
	return DuelFixture.versus(first, second)


func _started_power(duel: DuelFixture) -> StringName:
	for entry in duel.events_log:
		if entry["type"] == CombatEvent.Type.POWER_STARTED:
			return duel.fighter(entry["source"]).power.id if duel.fighter(entry["source"]).power != null else &""
	return &""


func test_meter_starts_each_round_at_twenty() -> void:
	var fresh: DuelFixture = DuelFixture.create()
	assert_almost(fresh.fighter(0).flow, 20.0)


func test_meter_regenerates_and_grows_on_hits() -> void:
	var duel: DuelFixture = _duel()
	var start: float = duel.fighter(0).flow
	duel.step(60)
	assert_gt(duel.fighter(0).flow, start + 2.0)
	duel.place(60.0)
	var before_attacker: float = duel.fighter(0).flow
	var before_defender: float = duel.fighter(1).flow
	duel.press(0, Intent.Command.LIGHT)
	duel.step(7)
	assert_gt(duel.fighter(0).flow - before_attacker, 7.0)
	assert_gt(duel.fighter(1).flow - before_defender, 9.0)


func test_cast_without_meter_is_rejected() -> void:
	var duel: DuelFixture = _duel()
	duel.fighter(0).flow = 10.0
	duel.cast(0)
	assert_eq(duel.count_events(CombatEvent.Type.POWER_REJECTED), 1)
	assert_eq(duel.fighter(0).state, FighterState.State.IDLE)


func test_shared_cooldown_blocks_a_second_power() -> void:
	var duel: DuelFixture = _duel()
	duel.fighter(0).flow = 100.0
	duel.cast(0)
	duel.step_until(func() -> bool: return duel.fighter(0).is_free(), 60)
	duel.cast(0)
	assert_eq(duel.count_events(CombatEvent.Type.POWER_REJECTED), 1)


func test_direction_picks_the_slot_and_empty_falls_back() -> void:
	var duel: DuelFixture = _duel()
	duel.fighter(0).flow = 100.0
	duel.cast(0, 1)
	assert_eq(duel.fighter(0).power.id, &"heal")
	var other: DuelFixture = _duel()
	other.fighter(0).flow = 100.0
	other.cast(0, -1)
	assert_eq(other.fighter(0).power.id, &"barrier")
	var empty: DuelFixture = _duel()
	empty.fighter(0).flow = 100.0
	empty.fighter(0).powers[1] = null
	empty.cast(0, 1)
	assert_eq(empty.fighter(0).power.id, &"repulse")


func test_minimum_level_is_required() -> void:
	var duel: DuelFixture = _duel()
	duel.give_power(0, &"mass_telekinesis")
	duel.cast(0)
	assert_eq(duel.count_events(CombatEvent.Type.POWER_REJECTED), 1)


func test_interaction_table_bands() -> void:
	var table: InteractionTable = DuelFixture.CONFIG.flow.basic_table
	assert_almost(table.band_for(0).scale, 1.0)
	assert_almost(table.band_for(-2).scale, 0.5)
	assert_true(table.band_for(-3).resisted)


func test_repulse_pushes_and_staggers() -> void:
	var duel: DuelFixture = _duel()
	duel.place(100.0)
	duel.give_power(0, &"repulse")
	duel.cast(0)
	duel.step(20)
	assert_eq(duel.count_events(CombatEvent.Type.POWER_HIT), 1)
	assert_eq(duel.fighter(1).state, FighterState.State.STAGGERED)
	duel.step(20)
	assert_gt(duel.fighter(1).x, 200.0)


func test_repulse_against_guard_at_equal_flow_holds() -> void:
	var duel: DuelFixture = _duel()
	duel.place(100.0)
	duel.give_power(0, &"repulse")
	duel.hold(1, Intent.Command.BLOCK)
	duel.step(1)
	var health: float = duel.fighter(1).health
	duel.cast(0)
	duel.step(20)
	assert_eq(duel.count_events(CombatEvent.Type.POWER_BLOCKED), 1)
	assert_almost(duel.fighter(1).health, health)


func test_much_stronger_repulse_breaks_through_guard() -> void:
	var duel: DuelFixture = _duel()
	duel.place(100.0)
	duel.give_power(0, &"repulse")
	duel.set_level(0, 8)
	duel.hold(1, Intent.Command.BLOCK)
	duel.step(1)
	duel.cast(0)
	duel.step(20)
	assert_eq(duel.count_events(CombatEvent.Type.POWER_HIT), 1)


func test_much_weaker_power_is_resisted() -> void:
	var duel: DuelFixture = _duel()
	duel.place(100.0)
	duel.give_power(0, &"repulse")
	duel.set_level(0, 2)
	duel.cast(0)
	duel.step(20)
	assert_eq(duel.count_events(CombatEvent.Type.POWER_RESISTED), 1)
	assert_eq(duel.fighter(1).state, FighterState.State.IDLE)


func test_pull_brings_the_target_closer() -> void:
	var duel: DuelFixture = _duel()
	duel.place(300.0)
	duel.give_power(0, &"pull")
	duel.cast(0)
	duel.step(40)
	assert_lt(duel.fighter(1).x - duel.fighter(0).x, 250.0)


func test_throw_launches_rocks_by_tier() -> void:
	var duel: DuelFixture = _duel()
	duel.place(300.0)
	duel.give_power(0, &"throw")
	duel.cast(0)
	duel.step(90)
	assert_eq(duel.count_events(CombatEvent.Type.PROJECTILE_SPAWNED), 2)
	assert_gt(duel.count_events(CombatEvent.Type.POWER_HIT), 0.0)


func test_guard_lets_a_quarter_of_the_rock_through() -> void:
	var duel: DuelFixture = _duel()
	duel.place(300.0)
	duel.give_power(0, &"throw")
	duel.hold(1, Intent.Command.BLOCK)
	duel.step(1)
	var health: float = duel.fighter(1).health
	duel.cast(0)
	duel.step(90)
	var blocked: int = duel.count_events(CombatEvent.Type.POWER_BLOCKED)
	assert_gt(blocked, 0.0)
	assert_almost(health - duel.fighter(1).health, 2.0 * blocked, 0.01)


func test_mind_twist_inverts_walking() -> void:
	var duel: DuelFixture = _duel()
	duel.place(100.0)
	duel.give_power(0, &"mind_twist")
	duel.cast(0)
	duel.step(20)
	assert_gt(duel.fighter(1).twisted_ticks, 0.0)
	var x: float = duel.fighter(1).x
	duel.intents[1].move_x = 1
	duel.step(10)
	assert_lt(duel.fighter(1).x, x)


func test_supreme_push_escapes_while_hit() -> void:
	var duel: DuelFixture = _duel()
	duel.place(60.0)
	duel.give_power(0, &"supreme_push")
	duel.press(1, Intent.Command.LIGHT)
	duel.step(7)
	assert_eq(duel.fighter(0).state, FighterState.State.HIT)
	var health: float = duel.fighter(1).health
	duel.press(0, Intent.Command.POWER)
	duel.step(20)
	assert_eq(duel.fighter(0).power_escape or duel.count_events(CombatEvent.Type.POWER_HIT) > 0, true)
	assert_almost(health - duel.fighter(1).health, 4.0, 0.01)


func test_fracture_only_hits_grounded_targets_through_guard() -> void:
	var guarded: DuelFixture = _duel()
	guarded.place(250.0)
	guarded.give_power(0, &"fracture")
	guarded.hold(1, Intent.Command.BLOCK)
	guarded.cast(0)
	guarded.step(60)
	assert_eq(guarded.count_events(CombatEvent.Type.POWER_HIT), 1)
	var jumper: DuelFixture = _duel()
	jumper.place(250.0)
	jumper.give_power(0, &"fracture")
	jumper.cast(0)
	jumper.step(25)
	jumper.press(1, Intent.Command.JUMP)
	jumper.step(25)
	assert_eq(jumper.count_events(CombatEvent.Type.POWER_HIT), 0)


func test_barrier_holds_blades_and_costs_meter() -> void:
	var duel: DuelFixture = _duel()
	duel.place(60.0)
	duel.give_power(1, &"barrier")
	duel.cast(1)
	duel.step(10)
	assert_eq(duel.fighter(1).state, FighterState.State.CHANNELING)
	var health: float = duel.fighter(1).health
	duel.press(0, Intent.Command.LIGHT)
	duel.step(7)
	assert_eq(duel.count_events(CombatEvent.Type.POWER_BLOCKED), 1)
	assert_almost(duel.fighter(1).health, health)
	assert_lt(duel.fighter(1).flow, 90.0)


func test_heal_restores_part_of_the_lost_health() -> void:
	var duel: DuelFixture = _duel()
	duel.fighter(0).health = 50.0
	duel.give_power(0, &"heal")
	duel.cast(0)
	duel.step(160)
	var expected: float = minf(14.0 * duel.fighter(0).flow_potency, (duel.fighter(0).max_health - 50.0) * 0.35)
	assert_almost(duel.fighter(0).health, 50.0 + expected, 0.1)


func test_heal_stops_when_hit() -> void:
	var duel: DuelFixture = _duel()
	duel.place(60.0)
	duel.fighter(0).health = 50.0
	duel.give_power(0, &"heal")
	duel.cast(0)
	duel.step(25)
	duel.press(1, Intent.Command.LIGHT)
	duel.step(8)
	assert_eq(duel.fighter(0).heal_ticks, 0)


func test_focus_halves_vigor_costs_and_evades_alone() -> void:
	var duel: DuelFixture = _duel()
	duel.give_power(0, &"focus")
	duel.cast(0)
	duel.step(40)
	assert_gt(duel.fighter(0).focus_ticks, 0.0)
	var vigor: float = duel.fighter(0).vigor
	duel.press(0, Intent.Command.DODGE)
	duel.step(1)
	assert_almost(vigor - duel.fighter(0).vigor, DuelFixture.CONFIG.dodge_vigor * 0.5, 0.5)
	duel.release(0)
	duel.step(40)
	duel.place(60.0)
	duel.fighter(0).flow = 100.0
	duel.press(1, Intent.Command.LIGHT)
	duel.step(8)
	assert_eq(duel.count_events(CombatEvent.Type.EVADE_SUCCESS), 1)


func test_absorption_swallows_a_power() -> void:
	var duel: DuelFixture = _duel()
	duel.place(100.0)
	duel.give_power(0, &"repulse")
	duel.give_power(1, &"absorption")
	duel.cast(1)
	duel.step(4)
	duel.cast(0)
	duel.step(20)
	assert_eq(duel.count_events(CombatEvent.Type.POWER_ABSORBED), 1)
	assert_ne(duel.fighter(1).state, FighterState.State.STAGGERED)


func test_sanctuary_absorbs_blade_damage() -> void:
	var duel: DuelFixture = _duel()
	duel.give_power(1, &"sanctuary")
	duel.cast(1)
	duel.step(30)
	duel.place(60.0)
	var health: float = duel.fighter(1).health
	duel.press(0, Intent.Command.LIGHT)
	duel.step(7)
	assert_almost(duel.fighter(1).health, health)
	assert_eq(duel.count_events(CombatEvent.Type.POWER_ABSORBED), 1)


func test_mass_telekinesis_rains_impacts() -> void:
	var duel: DuelFixture = _duel()
	duel.place(200.0)
	duel.give_power(0, &"mass_telekinesis")
	duel.set_level(0, 6)
	duel.cast(0)
	duel.step(200)
	var impacts: int = 0
	for entry in duel.events_log:
		if entry["type"] == CombatEvent.Type.HAZARD_TRIGGERED:
			impacts += 1
	assert_eq(impacts, 5)
	assert_gt(duel.count_events(CombatEvent.Type.POWER_HIT), 0.0)


func test_perfect_parry_returns_the_flow_cleave() -> void:
	var duel: DuelFixture = _duel()
	duel.place(300.0)
	duel.give_power(0, &"flow_cleave")
	duel.cast(0)
	var close: bool = duel.step_until(func() -> bool:
		for projectile in duel.sim.projectiles:
			if projectile.active and absf(projectile.x - duel.fighter(1).x) < 70.0:
				return true
		return false, 120)
	assert_true(close)
	duel.press(1, Intent.Command.BLOCK)
	duel.step(1)
	duel.step(60)
	assert_eq(duel.count_events(CombatEvent.Type.PROJECTILE_REFLECTED), 1)
	assert_gt(duel.count_events(CombatEvent.Type.POWER_HIT), 0.0)
	assert_lt(duel.fighter(0).health, duel.fighter(0).max_health)


func test_lightning_pulses_while_held() -> void:
	var duel: DuelFixture = _duel(&"shadow", &"guardian")
	duel.place(200.0)
	duel.give_power(0, &"lightning")
	duel.cast(0)
	duel.step(50)
	assert_gt(duel.count_events(CombatEvent.Type.POWER_HIT), 3.0)
	assert_lt(duel.fighter(0).flow, 70.0)


func test_choke_lifts_and_releases() -> void:
	var duel: DuelFixture = _duel(&"shadow", &"guardian")
	duel.place(100.0)
	duel.give_power(0, &"choke")
	var health: float = duel.fighter(1).health
	duel.cast(0)
	duel.step(50)
	assert_eq(duel.fighter(1).state, FighterState.State.HELD)
	assert_gt(duel.fighter(1).y, 10.0)
	assert_lt(duel.fighter(1).health, health)
	duel.release(0)
	duel.step(60)
	assert_true(duel.fighter(1).is_free())


func test_freeze_breaks_on_the_first_hit() -> void:
	var duel: DuelFixture = _duel(&"ember", &"guardian")
	duel.place(80.0)
	duel.give_power(0, &"freeze")
	duel.cast(0)
	duel.step(20)
	assert_eq(duel.fighter(1).state, FighterState.State.HELD)
	duel.step_until(func() -> bool: return duel.fighter(0).is_free(), 40)
	duel.press(0, Intent.Command.LIGHT)
	duel.step(7)
	assert_eq(duel.fighter(1).state, FighterState.State.HIT)


func test_storm_shields_the_caster_and_strikes() -> void:
	var duel: DuelFixture = _duel(&"shadow", &"guardian")
	duel.place(200.0)
	duel.give_power(0, &"storm")
	duel.set_level(0, 6)
	duel.cast(0)
	duel.step(40)
	assert_eq(duel.fighter(0).state, FighterState.State.CHANNELING)
	duel.place(60.0)
	duel.press(1, Intent.Command.LIGHT)
	duel.step(10)
	assert_eq(duel.fighter(0).state, FighterState.State.CHANNELING, "immune during the storm")
	duel.step(240)
	assert_gt(duel.count_events(CombatEvent.Type.HAZARD_TRIGGERED), 4.0)


func test_wrath_raises_damage_and_soaks_blades() -> void:
	var duel: DuelFixture = _duel(&"shadow", &"guardian")
	duel.give_power(0, &"wrath")
	duel.cast(0)
	duel.step(45)
	duel.place(60.0)
	var health: float = duel.fighter(1).health
	duel.press(0, Intent.Command.LIGHT)
	duel.step(8)
	assert_almost(health - duel.fighter(1).health, 10.0 * duel.fighter(0).blade_multiplier * 1.2, 0.01)
	duel.step(30)
	duel.press(1, Intent.Command.LIGHT)
	duel.step(8)
	assert_eq(duel.count_events(CombatEvent.Type.ARMOR_ABSORBED), 1)


func test_drain_steals_meter() -> void:
	var duel: DuelFixture = _duel(&"shadow", &"guardian")
	duel.place(150.0)
	duel.give_power(0, &"drain")
	duel.fighter(1).flow = 80.0
	duel.cast(0)
	duel.fighter(0).flow = 40.0
	duel.step(60)
	assert_lt(duel.fighter(1).flow, 75.0)
	assert_gt(duel.fighter(0).flow, 40.0)


func test_arsenal_launches_and_catches() -> void:
	var duel: DuelFixture = _duel(&"shadow", &"guardian")
	duel.place(300.0)
	duel.give_power(0, &"arsenal")
	duel.cast(0)
	duel.step(40)
	assert_eq(duel.fighter(0).arsenal_count, 2)
	duel.cast(0)
	assert_eq(duel.fighter(0).arsenal_count, 1)
	assert_eq(duel.count_events(CombatEvent.Type.PROJECTILE_SPAWNED), 1)
	duel.step(60)
	duel.give_power(1, &"throw")
	duel.cast(1)
	duel.step(80)
	assert_eq(duel.fighter(0).arsenal_count, 0, "orbiting blades catch rocks")


func test_spin_hits_from_behind() -> void:
	var duel: DuelFixture = _duel(&"shadow", &"guardian")
	duel.place(20.0)
	duel.fighter(0).facing = -1
	duel.intents[0].move_x = 1
	duel.press(0, Intent.Command.SPECIAL)
	duel.step(1)
	duel.intents[0].move_x = 0
	duel.step(25)
	assert_eq(duel.fighter(0).move.id if duel.fighter(0).move != null else &"spin", &"spin")
	assert_eq(duel.count_events(CombatEvent.Type.HIT), 1)


func test_flurry_hits_four_times() -> void:
	var duel: DuelFixture = _duel(&"wasp", &"guardian")
	duel.place(60.0)
	duel.intents[0].move_x = 1
	duel.press(0, Intent.Command.SPECIAL)
	duel.step(1)
	duel.intents[0].move_x = 0
	duel.step(40)
	assert_eq(duel.count_events(CombatEvent.Type.HIT), 4)


func test_sweep_is_gone_from_the_cast() -> void:
	var catalog: PowerCatalog = load("res://data/powers/catalog.tres")
	for technique in catalog.techniques:
		assert_ne(technique.id, &"sweep_low")
	assert_eq(DuelFixture.character(&"ember").technique_back.id, &"rising_cut")
	assert_eq(DuelFixture.character(&"echo").technique_back.id, &"spin")
	assert_eq(DuelFixture.character(&"foretold_eclipse").technique_forward.id, &"dash_slash")


func test_lance_charge_lunges_to_the_tip_and_counts_as_heavy() -> void:
	for id in [&"lance", &"sovereign"]:
		var duel: DuelFixture = _duel(id, &"guardian")
		var charge: MoveData = duel.fighter(0).character.ability.move
		assert_eq(charge.reach, duel.fighter(0).character.heavy.reach + 60.0)
		assert_true(charge.is_heavy())
		assert_eq(charge.finisher_limb, MoveData.Limb.LEG)
		duel.place(charge.reach + 100.0)
		var health: float = duel.fighter(1).health
		duel.press(0, Intent.Command.SPECIAL)
		var hit: bool = duel.step_until(func() -> bool: return duel.count_events(CombatEvent.Type.HIT) > 0, 60)
		assert_true(hit, "%s reaches past the heavy with the lunge" % id)
		assert_gt(health - duel.fighter(1).health, charge.damage * duel.fighter(0).blade_multiplier, "the tip lands for the sweet spot bonus")


func test_lance_charge_is_parried_like_a_heavy() -> void:
	var duel: DuelFixture = _duel(&"lance", &"guardian")
	var charge: MoveData = duel.fighter(0).character.ability.move
	duel.place(charge.reach - 20.0)
	duel.press(0, Intent.Command.SPECIAL)
	duel.step(charge.startup_ticks() - 2)
	duel.press(1, Intent.Command.BLOCK)
	duel.hold(1, Intent.Command.BLOCK)
	duel.step(10)
	assert_eq(duel.count_events(CombatEvent.Type.PERFECT_PARRY), 1)
	assert_eq(duel.fighter(0).state, FighterState.State.STAGGERED)


func test_rising_cut_launches_airborne_targets() -> void:
	var duel: DuelFixture = _duel(&"bastion", &"guardian")
	duel.place(60.0)
	duel.intents[0].move_x = 1
	duel.press(0, Intent.Command.SPECIAL)
	duel.step(1)
	duel.intents[0].move_x = 0
	duel.step(5)
	duel.press(1, Intent.Command.JUMP)
	var hit: bool = duel.step_until(func() -> bool: return duel.count_events(CombatEvent.Type.HIT) > 0, 40)
	assert_true(hit)
	assert_gt(duel.fighter(1).vy, 300.0)


func test_blade_throw_leaves_the_thrower_unarmed_until_it_returns() -> void:
	var duel: DuelFixture = _duel(&"guardian", &"shadow")
	duel.place(300.0)
	duel.intents[0].move_x = -1
	duel.press(0, Intent.Command.SPECIAL)
	duel.step(1)
	duel.intents[0].move_x = 0
	duel.step(20)
	assert_true(duel.fighter(0).blade_out)
	duel.hold(0, Intent.Command.BLOCK)
	duel.step(5)
	assert_ne(duel.fighter(0).state, FighterState.State.BLOCKING)
	duel.release(0)
	var back: bool = duel.step_until(func() -> bool: return not duel.fighter(0).blade_out, 150)
	assert_true(back)


func test_plunge_keeps_its_recovery_after_landing() -> void:
	var duel: DuelFixture = _duel(&"shadow", &"guardian")
	duel.press(0, Intent.Command.JUMP)
	duel.step(10)
	duel.press(0, Intent.Command.SPECIAL)
	duel.step(1)
	assert_eq(duel.fighter(0).move.id, &"plunge")
	duel.step_until(func() -> bool: return duel.fighter(0).on_ground, 60)
	duel.step(1)
	assert_eq(duel.fighter(0).move_phase, FighterState.Phase.RECOVERY)


func test_techniques_clash_big() -> void:
	var duel: DuelFixture = _duel(&"shadow", &"guardian")
	duel.place(150.0)
	for i in 2:
		duel.intents[i].move_x = duel.fighter(i).facing
		duel.press(i, Intent.Command.SPECIAL)
	duel.step(1)
	duel.release(0)
	duel.release(1)
	duel.step_until(func() -> bool: return duel.count_events(CombatEvent.Type.TECHNIQUE_CLASH) > 0, 30)
	assert_eq(duel.count_events(CombatEvent.Type.TECHNIQUE_CLASH), 1)
	assert_eq(duel.fighter(0).state, FighterState.State.STAGGERED)


func test_fourth_power_needs_the_chord() -> void:
	var duel: DuelFixture = _duel(&"foretold", &"guardian")
	duel.fighter(0).flow = 100.0
	duel.press(0, Intent.Command.POWER)
	duel.press(0, Intent.Command.SPECIAL)
	duel.step(1)
	assert_eq(duel.fighter(0).power.id, &"mass_telekinesis")
	var single: DuelFixture = _duel(&"foretold", &"guardian")
	single.fighter(0).flow = 100.0
	single.press(0, Intent.Command.POWER)
	single.step(1)
	assert_eq(single.fighter(0).state, FighterState.State.IDLE, "waits for the chord window")
	single.step(8)
	assert_eq(single.fighter(0).power.id, &"repulse")


func test_without_powers_special_stays_the_ability() -> void:
	var rules: MatchRules = MatchRules.new()
	rules.powers = false
	var cast: Array[CharacterData] = [DuelFixture.GUARDIAN, DuelFixture.SHADOW]
	var duel: DuelFixture = DuelFixture.create(rules, null, 7, cast)
	duel.skip_intro()
	duel.intents[0].move_x = 1
	duel.press(0, Intent.Command.SPECIAL)
	duel.step(1)
	assert_eq(duel.fighter(0).move.kind, MoveData.Kind.STANCE)
	assert_almost(duel.fighter(0).flow, 0.0)


func test_dash_slash_dashes_in_startup_and_cuts_at_the_end() -> void:
	var duel: DuelFixture = _duel(&"guardian", &"shadow")
	var dash: MoveData = duel.fighter(0).character.technique_forward
	assert_eq(dash.id, &"dash_slash")
	duel.place(260.0)
	var start_x: float = duel.fighter(0).x
	duel.intents[0].move_x = 1
	duel.press(0, Intent.Command.SPECIAL)
	duel.step(1)
	duel.intents[0].move_x = 0
	duel.step(dash.startup_ticks() - 1)
	assert_eq(duel.fighter(0).move_phase, FighterState.Phase.STARTUP)
	assert_gt(duel.fighter(0).x - start_x, dash.lunge * 0.8, "the dash happens before the cut")
	assert_eq(duel.count_events(CombatEvent.Type.HIT), 0)
	duel.step(dash.active_ticks() + 1)
	assert_eq(duel.count_events(CombatEvent.Type.HIT), 1)
	assert_lt(absf(duel.fighter(0).vx), 1.0, "the cut lands from a planted stance")


func test_apex_flow_cleave_spaces_its_two_cuts() -> void:
	var duel: DuelFixture = _duel(&"foretold", &"shadow")
	duel.place(500.0)
	var cleave: PowerData = duel.give_power(0, &"flow_cleave")
	duel.set_level(0, 10)
	duel.cast(0)
	var spawns: Array[int] = []
	for tick in cleave.startup_ticks() + cleave.recovery_ticks_at(true) + 12:
		duel.step(1)
		var last: Dictionary = duel.last_event(CombatEvent.Type.PROJECTILE_SPAWNED)
		if not last.is_empty() and not spawns.has(last["tick"]):
			spawns.append(last["tick"])
	assert_eq(spawns.size(), 2)
	assert_true(spawns.size() == 2 and spawns[1] - spawns[0] >= Ticks.from_seconds(cleave.apex_repeat_delay), "the second cut waits for its own full arc")
	assert_ne(duel.fighter(0).state, FighterState.State.CASTING)


func test_mass_telekinesis_freezes_the_duel_for_its_cinematic() -> void:
	var duel: DuelFixture = _duel(&"foretold", &"shadow")
	duel.place(200.0)
	var power: PowerData = duel.give_power(0, &"mass_telekinesis", FighterState.FOURTH_SLOT)
	duel.press(0, Intent.Command.POWER)
	duel.press(0, Intent.Command.SPECIAL)
	var active: bool = duel.step_until(func() -> bool: return duel.count_events(CombatEvent.Type.POWER_ACTIVE) > 0, 120)
	assert_true(active)
	var freeze: int = Ticks.from_seconds(power.cinematic_freeze)
	assert_eq(duel.sim.cinematic_ticks, freeze)
	var snapshot: Dictionary = duel.sim.capture()
	duel.intents[1].move_x = 1
	duel.step(freeze - 1)
	assert_almost(duel.fighter(1).x, snapshot["fighters"][1]["x"], 0.001, "nobody moves during the cinematic")
	var first_delay: int = -1
	for hazard in duel.sim.hazards:
		if hazard.active:
			first_delay = maxi(first_delay, hazard.delay_ticks)
	assert_eq(first_delay, snapshot["hazards"].map(func(item: Dictionary) -> int: return item["delay_ticks"] if item["active"] else -1).max(), "the marks wait for the cinematic")
	duel.step(2)
	assert_eq(duel.sim.cinematic_ticks, 0)
	assert_ne(duel.fighter(1).x, snapshot["fighters"][1]["x"])
