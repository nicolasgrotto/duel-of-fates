extends TestCase

const CAST: Array[StringName] = [
	&"guardian", &"shadow", &"bastion", &"wasp", &"mirror", &"lance", &"ember", &"forge", &"heron",
	&"reaper", &"echo", &"awakened_shadow", &"sovereign", &"elder", &"foretold", &"foretold_eclipse",
]


func _light_from(duel: DuelFixture, attacker: int, gap: float) -> void:
	duel.place(gap)
	duel.press(attacker, Intent.Command.LIGHT)


func test_every_character_is_complete() -> void:
	for id in CAST:
		var data: CharacterData = DuelFixture.character(id)
		assert_true(data != null, String(id))
		assert_false(data.light_chain.is_empty(), "%s chain" % id)
		assert_true(data.heavy != null and data.forward_heavy != null, "%s heavies" % id)
		assert_true(data.ability != null and (data.ability.move != null or data.ability.kind == AbilityData.Kind.DASH or data.ability.kind == AbilityData.Kind.LEAP), "%s ability" % id)
		assert_true(data.art != null and data.family != null and data.weapon != null, "%s look" % id)
		assert_false(data.costumes.is_empty() and data.selectable, "%s costumes" % id)
		assert_false(data.blade_colors.is_empty(), "%s blades" % id)
		assert_true(data.ai_profile != null, "%s ai" % id)
		assert_eq(data.blade_colors.size(), data.blade_color_keys.size(), "%s blade names" % id)


func test_chain_lengths_follow_the_cast_sheet() -> void:
	var expected: Dictionary = {&"guardian": 2, &"shadow": 3, &"bastion": 2, &"wasp": 5, &"mirror": 2, &"lance": 2,
		&"ember": 3, &"forge": 2, &"heron": 3, &"reaper": 3, &"echo": 2, &"sovereign": 2, &"elder": 3, &"foretold": 2}
	for id in expected:
		assert_eq(DuelFixture.character(id).light_chain.size(), expected[id], String(id))


func test_guardian_counterguard_answers_a_frontal_hit() -> void:
	var duel: DuelFixture = DuelFixture.versus(&"guardian", &"shadow")
	duel.place(60.0)
	duel.press(0, Intent.Command.SPECIAL)
	duel.step(1)
	duel.press(1, Intent.Command.LIGHT)
	duel.step(8)
	assert_eq(duel.count_events(CombatEvent.Type.RESPONSE), 1)
	assert_eq(duel.fighter(1).state, FighterState.State.STAGGERED)
	assert_eq(duel.fighter(0).move.kind, MoveData.Kind.COUNTER)


func test_counterguard_whiff_leaves_recovery() -> void:
	var duel: DuelFixture = DuelFixture.versus(&"guardian", &"shadow")
	duel.press(0, Intent.Command.SPECIAL)
	duel.step(1)
	duel.step(Ticks.from_seconds(0.35) + 2)
	assert_eq(duel.fighter(0).move_phase, FighterState.Phase.RECOVERY)


func test_mirror_waiting_stance_counts_as_perfect_parry() -> void:
	var duel: DuelFixture = DuelFixture.versus(&"mirror", &"shadow")
	duel.place(60.0)
	duel.press(0, Intent.Command.SPECIAL)
	duel.step(1)
	duel.press(1, Intent.Command.LIGHT)
	duel.step(8)
	assert_eq(duel.count_events(CombatEvent.Type.PERFECT_PARRY), 1)
	assert_true(duel.fighter(1).stagger_counterable)


func test_mirror_parry_windows_are_wider() -> void:
	var duel: DuelFixture = DuelFixture.versus(&"mirror", &"shadow")
	assert_eq(duel.fighter(0).parry_window_ticks, Ticks.from_seconds(0.26))
	assert_gt(duel.fighter(0).perfect_parry_ticks, duel.fighter(1).perfect_parry_ticks)


func test_shadow_impetus_armor_absorbs_one_hit() -> void:
	var duel: DuelFixture = DuelFixture.versus(&"guardian", &"shadow")
	duel.place(60.0)
	duel.press(1, Intent.Command.SPECIAL)
	duel.step(1)
	duel.press(0, Intent.Command.LIGHT)
	duel.step(7)
	assert_eq(duel.count_events(CombatEvent.Type.ARMOR_ABSORBED), 1)
	assert_eq(duel.fighter(1).state, FighterState.State.ATTACKING, "armor keeps the strike going")


func test_bastion_hammer_halves_absorbed_damage() -> void:
	var duel: DuelFixture = DuelFixture.versus(&"guardian", &"bastion")
	duel.place(60.0)
	var health: float = duel.fighter(1).health
	duel.press(1, Intent.Command.SPECIAL)
	duel.step(1)
	duel.press(0, Intent.Command.LIGHT)
	duel.step(7)
	assert_almost(duel.fighter(1).health, health - 5.0)


func test_bastion_walks_in_guard_and_is_not_pushed() -> void:
	var duel: DuelFixture = DuelFixture.versus(&"shadow", &"bastion")
	duel.hold(1, Intent.Command.BLOCK)
	duel.intents[1].move_x = -1
	duel.step(20)
	assert_eq(duel.fighter(1).state, FighterState.State.BLOCKING)
	assert_lt(duel.fighter(1).vx, -1.0, "walks while blocking")
	duel.intents[1].move_x = 0
	duel.step(20)
	duel.place(60.0)
	duel.press(0, Intent.Command.LIGHT)
	duel.step(8)
	assert_eq(duel.count_events(CombatEvent.Type.BLOCK), 1)
	assert_almost(duel.fighter(1).vx, 0.0, 0.001)


func test_wasp_buzz_passes_through_and_swaps_sides() -> void:
	var duel: DuelFixture = DuelFixture.versus(&"wasp", &"guardian")
	duel.place(30.0)
	duel.press(0, Intent.Command.SPECIAL)
	duel.step(30)
	assert_gt(duel.fighter(0).x, duel.fighter(1).x)


func test_wasp_lights_drain_extra_on_block() -> void:
	var duel: DuelFixture = DuelFixture.versus(&"wasp", &"guardian")
	duel.place(60.0)
	duel.hold(1, Intent.Command.BLOCK)
	duel.step(1)
	var vigor: float = duel.fighter(1).vigor
	duel.press(0, Intent.Command.LIGHT)
	duel.step(8)
	var normal: float = duel.sim.block_cost(duel.fighter(1), DuelFixture.character(&"wasp").light_chain[0])
	assert_almost(vigor - duel.fighter(1).vigor, normal + 4.0, 0.3)


func test_lance_sweet_spot_rewards_the_tip() -> void:
	var tip: DuelFixture = DuelFixture.versus(&"lance", &"guardian")
	_light_from(tip, 0, 125.0)
	var health: float = tip.fighter(1).health
	tip.step(10)
	var tip_damage: float = health - tip.fighter(1).health
	var close: DuelFixture = DuelFixture.versus(&"lance", &"guardian")
	_light_from(close, 0, 5.0)
	close.step(10)
	var close_damage: float = health - close.fighter(1).health
	assert_almost(tip_damage, 15.0, 0.01)
	assert_almost(close_damage, 6.0, 0.01)


func test_ember_hits_harder_against_open_opponents() -> void:
	var duel: DuelFixture = DuelFixture.versus(&"ember", &"guardian")
	duel.place(60.0)
	duel.sim.change_state(duel.fighter(1), FighterState.State.STAGGERED)
	duel.fighter(1).stun_ticks = 60
	var health: float = duel.fighter(1).health
	duel.press(0, Intent.Command.LIGHT)
	duel.step(8)
	assert_almost(health - duel.fighter(1).health, 10.0 * duel.fighter(0).blade_multiplier * 1.2, 0.01)


func test_ember_living_ember_responds_with_its_own_strike() -> void:
	var duel: DuelFixture = DuelFixture.versus(&"ember", &"shadow")
	duel.place(60.0)
	duel.press(0, Intent.Command.SPECIAL)
	duel.step(1)
	duel.press(1, Intent.Command.LIGHT)
	duel.step(8)
	assert_eq(duel.count_events(CombatEvent.Type.RESPONSE), 1)
	assert_eq(duel.fighter(0).move.id, &"ember_ability_move")


func test_forge_full_charge_breaks_guard() -> void:
	var duel: DuelFixture = DuelFixture.versus(&"forge", &"guardian")
	duel.place(60.0)
	duel.hold(1, Intent.Command.BLOCK)
	duel.press(0, Intent.Command.SPECIAL)
	duel.step(1)
	duel.hold(0, Intent.Command.SPECIAL)
	duel.step(120)
	assert_eq(duel.count_events(CombatEvent.Type.GUARD_BREAK), 1)
	assert_eq(duel.fighter(1).state, FighterState.State.STUNNED)


func test_forge_charge_raises_damage() -> void:
	var quick: DuelFixture = DuelFixture.versus(&"forge", &"guardian")
	quick.place(60.0)
	var health: float = quick.fighter(1).health
	quick.press(0, Intent.Command.SPECIAL)
	quick.step(1)
	quick.release(0)
	quick.step(40)
	var quick_damage: float = health - quick.fighter(1).health
	var charged: DuelFixture = DuelFixture.versus(&"forge", &"guardian")
	charged.place(60.0)
	charged.press(0, Intent.Command.SPECIAL)
	charged.step(1)
	charged.hold(0, Intent.Command.SPECIAL)
	charged.step(Ticks.from_seconds(0.3) + Ticks.from_seconds(0.35))
	charged.release(0)
	charged.step(30)
	var charged_damage: float = health - charged.fighter(1).health
	assert_almost(charged_damage, quick_damage * 1.35, 0.05)


func test_heron_wall_jump_and_two_aerials() -> void:
	var duel: DuelFixture = DuelFixture.versus(&"heron", &"guardian")
	var limit: float = duel.sim.config.half_width() - duel.sim.config.body_width * 0.5
	duel.fighter(0).x = -limit
	duel.press(0, Intent.Command.JUMP)
	duel.step(6)
	duel.press(0, Intent.Command.JUMP)
	duel.step(1)
	assert_gt(duel.fighter(0).vx, 100.0, "pushes away from the wall")
	assert_eq(duel.fighter(0).last_wall, -1)
	duel.press(0, Intent.Command.LIGHT)
	duel.step(1)
	duel.step_until(func() -> bool: return duel.fighter(0).state == FighterState.State.JUMPING, 40)
	duel.press(0, Intent.Command.HEAVY)
	duel.step(1)
	assert_eq(duel.fighter(0).air_attacks, 2)


func test_reaper_twin_wheel_hits_behind() -> void:
	var duel: DuelFixture = DuelFixture.versus(&"reaper", &"guardian")
	duel.place(20.0)
	duel.fighter(0).facing = -1
	duel.press(0, Intent.Command.SPECIAL)
	duel.step(20)
	assert_eq(duel.count_events(CombatEvent.Type.HIT), 1)


func test_echo_feint_returns_to_guard() -> void:
	var duel: DuelFixture = DuelFixture.versus(&"echo", &"guardian")
	duel.press(0, Intent.Command.HEAVY)
	duel.step(5)
	var vigor: float = duel.fighter(0).vigor
	duel.press(0, Intent.Command.BLOCK)
	duel.step(1)
	assert_eq(duel.fighter(0).state, FighterState.State.BLOCKING)
	assert_eq(duel.count_events(CombatEvent.Type.FEINT), 1)
	assert_almost(vigor - duel.fighter(0).vigor, DuelFixture.CONFIG.feint_vigor, 0.5)


func test_echo_reflex_step_is_invulnerable() -> void:
	var duel: DuelFixture = DuelFixture.versus(&"echo", &"guardian")
	duel.press(0, Intent.Command.SPECIAL)
	duel.step(1)
	assert_eq(duel.fighter(0).dodge_kind, FighterState.DodgeKind.DASH)
	assert_gt(duel.fighter(0).invulnerable_ticks, 0)
	assert_lt(duel.fighter(0).vx, 0.0, "steps back without a direction")


func test_elder_leap_dives_while_falling() -> void:
	var duel: DuelFixture = DuelFixture.versus(&"elder", &"guardian")
	duel.press(0, Intent.Command.SPECIAL)
	duel.step(1)
	assert_true(duel.fighter(0).is_airborne())
	var dived: bool = duel.step_until(func() -> bool: return duel.fighter(0).is_attacking(), 90)
	assert_true(dived)
	assert_lt(duel.fighter(0).vy, 0.0)


func test_awakened_shadow_has_boss_health() -> void:
	var duel: DuelFixture = DuelFixture.versus(&"awakened_shadow", &"guardian")
	assert_almost(duel.fighter(0).max_health, 150.0)


func test_only_the_sovereign_holds_locks_with_the_flow() -> void:
	for id in DuelMode.CAST + [&"sovereign", &"elder", &"foretold", &"awakened_shadow"]:
		var expected: CharacterData.LockStyle = CharacterData.LockStyle.FLOW_HOLD if id == &"sovereign" else CharacterData.LockStyle.BLADE
		assert_eq(DuelFixture.character(id).lock_style, expected, String(id))


func test_every_selectable_fighter_has_a_short_description() -> void:
	var strings: String = FileAccess.get_file_as_string("res://localization/strings.csv")
	var select: GDScript = load("res://screens/select/character_select.gd")
	for id in select.ROSTER + [&"foretold_eclipse"]:
		var key: String = select.description_key(DuelFixture.character(id))
		assert_true(strings.contains("\n" + key + ","), "%s has %s" % [id, key])


func _heavy_exchange(offset: int, command: Intent.Command, gap: float) -> DuelFixture:
	var duel: DuelFixture = DuelFixture.versus(&"sovereign", &"guardian")
	duel.skip_intro()
	duel.place(gap)
	duel.press(0, command)
	if offset == 0:
		duel.press(1, command)
	duel.step()
	for tick in range(1, 60):
		if tick == offset:
			duel.press(1, command)
		duel.step()
	return duel


func test_heavies_meet_with_a_wider_window_than_lights() -> void:
	var late: int = Ticks.from_seconds(DuelFixture.CONFIG.heavy_clash_window) - 1
	assert_gt(_heavy_exchange(late, Intent.Command.HEAVY, 60.0).count_events(CombatEvent.Type.BLADE_LOCK_STARTED), 0, "heavies %d ticks apart still lock" % late)
	assert_gt(_heavy_exchange(late, Intent.Command.HEAVY, 120.0).count_events(CombatEvent.Type.CLASH), 0, "and clash at mid range")
	var light_late: int = Ticks.from_seconds(DuelFixture.CONFIG.clash_window) + 2
	assert_eq(_heavy_exchange(light_late, Intent.Command.LIGHT, 60.0).count_events(CombatEvent.Type.CLASH), 0, "lights keep the short window")
