extends TestCase


func _duel(first: StringName, second: StringName, rounds: int = 1, finishers: bool = true, fixed: bool = true) -> DuelFixture:
	var rules: MatchRules = MatchRules.new()
	rules.rounds_to_win = rounds
	rules.finishers = finishers
	rules.fixed_finishers = fixed
	var cast: Array[CharacterData] = [DuelFixture.character(first), DuelFixture.character(second)]
	var duel: DuelFixture = DuelFixture.create(rules, null, 7, cast)
	duel.skip_intro()
	return duel


func _technique(duel: DuelFixture, direction: int) -> void:
	duel.intents[0].move_x = direction * duel.fighter(0).facing
	duel.press(0, Intent.Command.SPECIAL)
	duel.step(1)
	duel.intents[0].move_x = 0


func _death(duel: DuelFixture, ticks: int) -> Dictionary:
	duel.step_until(func() -> bool: return duel.count_events(CombatEvent.Type.DEATH) > 0, ticks)
	return {"finisher": duel.fighter(1).finisher_kind, "limb": duel.fighter(1).finisher_limb}


func test_dash_slash_finishes_through_the_opponent_on_the_deciding_ko() -> void:
	var duel: DuelFixture = _duel(&"guardian", &"shadow")
	duel.place(200.0)
	duel.fighter(1).health = 1.0
	_technique(duel, 1)
	var result: Dictionary = _death(duel, 60)
	assert_eq(result["finisher"], Finisher.Kind.DASH_THROUGH)
	assert_eq(result["limb"], MoveData.Limb.NONE, "the cinematic replaces the limb cut")
	assert_gt(duel.fighter(0).x, duel.fighter(1).x, "the cutter stops behind the opponent")
	assert_true(duel.sim.cinematic_ko)


func test_earlier_rounds_keep_the_limb_cut() -> void:
	var duel: DuelFixture = _duel(&"guardian", &"shadow", 2)
	duel.place(200.0)
	duel.fighter(1).health = 1.0
	_technique(duel, 1)
	var result: Dictionary = _death(duel, 60)
	assert_eq(result["finisher"], Finisher.Kind.NONE)
	assert_ne(result["limb"], MoveData.Limb.NONE)
	assert_false(duel.sim.cinematic_ko)


func test_finishers_option_off_means_no_cinematic() -> void:
	var duel: DuelFixture = _duel(&"guardian", &"shadow", 1, false)
	duel.place(200.0)
	duel.fighter(1).health = 1.0
	_technique(duel, 1)
	assert_eq(_death(duel, 60)["finisher"], Finisher.Kind.NONE)


func test_lightning_chars_only_when_its_pulse_kills() -> void:
	var duel: DuelFixture = _duel(&"shadow", &"guardian")
	duel.place(200.0)
	duel.give_power(0, &"lightning")
	duel.fighter(1).health = 1.0
	duel.hold(0, Intent.Command.POWER)
	duel.cast(0)
	duel.hold(0, Intent.Command.POWER)
	assert_eq(_death(duel, 90)["finisher"], Finisher.Kind.CHARRED)


func test_pull_executes_a_weakened_opponent() -> void:
	var duel: DuelFixture = _duel(&"shadow", &"guardian")
	duel.place(200.0)
	var pull: PowerData = duel.give_power(0, &"pull")
	duel.fighter(1).health = pull.execute_below - 1.0
	duel.cast(0)
	assert_eq(_death(duel, 60)["finisher"], Finisher.Kind.PULL_CUT)


func test_pull_does_not_execute_a_healthy_opponent() -> void:
	var duel: DuelFixture = _duel(&"shadow", &"guardian")
	duel.place(200.0)
	var pull: PowerData = duel.give_power(0, &"pull")
	duel.fighter(1).health = pull.execute_below + 20.0
	duel.cast(0)
	duel.step(60)
	assert_eq(duel.count_events(CombatEvent.Type.DEATH), 0)


func test_choke_and_blade_throw_finishers() -> void:
	var choke: DuelFixture = _duel(&"shadow", &"guardian")
	choke.place(120.0)
	choke.give_power(0, &"choke")
	choke.fighter(1).health = 0.5
	choke.hold(0, Intent.Command.POWER)
	choke.cast(0)
	choke.hold(0, Intent.Command.POWER)
	assert_eq(_death(choke, 120)["finisher"], Finisher.Kind.CHOKED)
	var thrown: DuelFixture = _duel(&"guardian", &"shadow")
	thrown.place(250.0)
	thrown.fighter(1).health = 1.0
	_technique(thrown, -1)
	assert_eq(_death(thrown, 120)["finisher"], Finisher.Kind.DIAGONAL)


func test_cinematic_ko_lasts_longer() -> void:
	var duel: DuelFixture = _duel(&"guardian", &"shadow")
	duel.place(200.0)
	duel.fighter(1).health = 1.0
	_technique(duel, 1)
	_death(duel, 60)
	var config: CombatConfig = duel.sim.config
	duel.step(Ticks.from_seconds(config.ko_duration) + 2)
	assert_eq(duel.sim.phase, MatchSimulation.Phase.KO, "the cinematic gets extra time")
	duel.step(Ticks.from_seconds(config.consequences.cinematic_ko_time) + 2)
	assert_ne(duel.sim.phase, MatchSimulation.Phase.KO)


func test_thrown_blade_returns_to_the_thrower_after_the_deciding_ko() -> void:
	var duel: DuelFixture = _duel(&"guardian", &"shadow")
	duel.place(250.0)
	duel.fighter(1).health = 1.0
	_technique(duel, -1)
	_death(duel, 120)
	var returned: bool = duel.step_until(func() -> bool: return not duel.fighter(0).blade_out, 900)
	assert_true(returned, "the blade comes back to the thrower")
	for projectile in duel.sim.projectiles:
		assert_false(projectile.active and projectile.kind == Projectile.Kind.BLADE)


func _heavy(duel: DuelFixture, forward: bool) -> Dictionary:
	duel.place(70.0)
	duel.fighter(1).health = 1.0
	duel.intents[0].move_x = duel.fighter(0).facing if forward else 0
	duel.press(0, Intent.Command.HEAVY)
	duel.step(1)
	duel.intents[0].move_x = 0
	return _death(duel, 120)


func test_deciding_heavy_takes_the_blade_or_executes() -> void:
	var result: Dictionary = _heavy(_duel(&"guardian", &"shadow"), false)
	assert_eq(result["finisher"], Finisher.Kind.TWIN_BLADES)
	assert_eq(result["limb"], MoveData.Limb.NONE)
	assert_eq(_heavy(_duel(&"guardian", &"shadow"), true)["finisher"], Finisher.Kind.EXECUTION)
	for victim in [&"wasp", &"reaper", &"lance"]:
		assert_eq(_heavy(_duel(&"guardian", victim), false)["finisher"], Finisher.Kind.EXECUTION, "no single blade to take from %s" % victim)


func test_colossus_and_reaper_have_their_own_heavy_finisher() -> void:
	for id in [&"bastion", &"forge"]:
		assert_eq(_heavy(_duel(id, &"shadow"), false)["finisher"], Finisher.Kind.OVERHEAD, String(id))
	assert_eq(_heavy(_duel(&"reaper", &"shadow"), false)["finisher"], Finisher.Kind.DOUBLE_ROTATION)


func test_twin_blades_holds_the_knockout_longer() -> void:
	var duel: DuelFixture = _duel(&"guardian", &"shadow")
	_heavy(duel, false)
	assert_true(duel.sim.long_cinematic)
	var config: CombatConfig = duel.sim.config
	assert_eq(duel.sim.cinematic_seconds(), config.consequences.long_cinematic_ko_time)
	duel.step(Ticks.from_seconds(config.ko_duration + config.consequences.cinematic_ko_time) + 2)
	assert_eq(duel.sim.phase, MatchSimulation.Phase.KO, "still playing")
	duel.step(Ticks.from_seconds(config.consequences.long_cinematic_ko_time - config.consequences.cinematic_ko_time) + 2)
	assert_ne(duel.sim.phase, MatchSimulation.Phase.KO)


func test_wasp_closes_the_scissors() -> void:
	assert_eq(_heavy(_duel(&"wasp", &"shadow"), false)["finisher"], Finisher.Kind.SCISSORS)
	assert_eq(_heavy(_duel(&"wasp", &"shadow"), true)["finisher"], Finisher.Kind.SCISSORS)


func test_fencer_forward_heavy_stabs() -> void:
	for id in [&"mirror", &"lance", &"sovereign"]:
		assert_eq(_heavy(_duel(id, &"shadow"), true)["finisher"], Finisher.Kind.STAB, String(id))
		assert_eq(_heavy(_duel(id, &"shadow"), false)["finisher"], Finisher.Kind.TWIN_BLADES, String(id))


func test_heavy_before_the_deciding_round_cuts_a_limb() -> void:
	var result: Dictionary = _heavy(_duel(&"guardian", &"shadow", 2), false)
	assert_eq(result["finisher"], Finisher.Kind.NONE)
	assert_eq(result["limb"], DuelFixture.character(&"guardian").heavy.finisher_limb)


func test_every_heavy_has_a_cinematic_finisher() -> void:
	for id in DuelMode.CAST:
		var data: CharacterData = DuelFixture.character(id)
		assert_ne(data.heavy.cinematic_finisher, Finisher.Kind.NONE, String(id))
		assert_ne(data.forward_heavy.cinematic_finisher, Finisher.Kind.NONE, String(id))


func test_stab_stops_the_lunge_in_front_of_the_victim() -> void:
	var duel: DuelFixture = _duel(&"mirror", &"shadow")
	_heavy(duel, true)
	var gap: float = absf(duel.fighter(0).x - duel.fighter(1).x)
	duel.step(60)
	assert_almost(absf(duel.fighter(0).x - duel.fighter(1).x), gap, 0.5, "the cutter does not slide through the body")
	assert_true(gap >= duel.sim.config.body_width + duel.sim.config.consequences.execution_clearance - 0.01)


func test_heron_whirls_behind_the_opponent() -> void:
	var duel: DuelFixture = _duel(&"heron", &"shadow")
	var result: Dictionary = _heavy(duel, true)
	assert_eq(result["finisher"], Finisher.Kind.WHIRL)
	var killer: FighterState = duel.fighter(0)
	var victim: FighterState = duel.fighter(1)
	assert_gt(killer.x, victim.x, "the heron ends behind the opponent")
	assert_eq(killer.facing, -1, "facing back toward the falling body")
	var gap: float = killer.x - victim.x
	duel.step(60)
	assert_almost(duel.fighter(0).x - duel.fighter(1).x, gap, 0.5)


func test_each_family_offers_four_exclusive_finishers_that_fit_the_knockout() -> void:
	var seen: Dictionary = {}
	var config: CombatConfig = DuelFixture.CONFIG
	for id in DuelMode.CAST + [&"awakened_shadow", &"sovereign", &"elder", &"foretold", &"foretold_eclipse", &"holster"]:
		var data: CharacterData = DuelFixture.character(id)
		assert_eq(data.family.finisher_pool.size(), 4, String(id))
		for value in data.family.finisher_pool:
			var kind: Finisher.Kind = value as Finisher.Kind
			assert_true(Finisher.is_staged(kind), String(id))
			seen[kind] = String(data.family.resource_path)
			var motion: FinisherMotion = FinisherMotion.for_kind(kind, data.finisher_style)
			assert_true(motion != null, "%s %d" % [id, value])
			var extra: float = config.consequences.long_cinematic_ko_time if Finisher.is_long(kind) else config.consequences.cinematic_ko_time
			var done: float = maxf(motion.end_time(), motion.reaction.fall_at + FighterView.KNEEL_TIME + FighterView.FALL_DURATION)
			assert_lt(done, config.ko_duration + extra, "%s %d fits the knockout" % [id, value])
	assert_eq(seen.size(), 36)


func test_family_finishers_never_restore_a_limb_through_a_split() -> void:
	for kind in Finisher.STAGED:
		var motion: FinisherMotion = FinisherMotion.for_kind(kind)
		var reaction: FinisherReaction = motion.reaction
		if reaction.split_at < 0.0 or kind == Finisher.Kind.OVERHEAD:
			continue
		assert_lt(reaction.front_arm_at, 0.0, str(kind))
		assert_lt(reaction.back_arm_at, 0.0, str(kind))
		assert_lt(reaction.front_leg_at, 0.0, str(kind))
		assert_lt(reaction.back_leg_at, 0.0, str(kind))
		assert_lt(reaction.head_at, 0.0, str(kind))


func test_every_new_finisher_has_a_name_in_both_languages() -> void:
	var saved: String = TranslationServer.get_locale()
	for locale in ["pt_BR", "en"]:
		TranslationServer.set_locale(locale)
		for kind in Finisher.STAGED:
			if kind < Finisher.Kind.GUARDIAN_DISARM:
				continue
			var key: String = "FINISHER_%s" % Finisher.Kind.keys()[kind]
			assert_ne(TranslationServer.translate(key), key)
	TranslationServer.set_locale(saved)


func test_deciding_heavy_draws_from_the_family_pool_with_variety() -> void:
	var drawn: Dictionary = {}
	for tick_offset in 24:
		var duel: DuelFixture = _duel(&"guardian", &"shadow", 1, true, false)
		duel.step(tick_offset)
		var result: Dictionary = _heavy(duel, false)
		var family: PackedInt32Array = DuelFixture.character(&"guardian").family.finisher_pool
		assert_true(result["finisher"] == Finisher.Kind.TWIN_BLADES or family.has(int(result["finisher"])), str(result["finisher"]))
		drawn[result["finisher"]] = true
	assert_gt(float(drawn.size()), 2.0, "the draw varies")


func test_same_seed_and_tick_draw_the_same_finisher() -> void:
	var first: Dictionary = _heavy(_duel(&"wasp", &"shadow", 1, true, false), false)
	var second: Dictionary = _heavy(_duel(&"wasp", &"shadow", 1, true, false), false)
	assert_eq(first["finisher"], second["finisher"])


func test_powers_techniques_and_earlier_rounds_stay_fixed() -> void:
	var earlier: Dictionary = _heavy(_duel(&"guardian", &"shadow", 2, true, false), false)
	assert_eq(earlier["finisher"], Finisher.Kind.NONE)
	var duel: DuelFixture = _duel(&"guardian", &"shadow", 1, true, false)
	var dash: MoveData = load("res://data/techniques/dash_slash.tres")
	assert_eq(Consequences.family_finisher(duel.sim, duel.fighter(0), duel.fighter(1), dash, dash.cinematic_finisher), dash.cinematic_finisher)
	assert_eq(Consequences.family_finisher(duel.sim, duel.fighter(0), duel.fighter(1), null, Finisher.Kind.BLAST), Finisher.Kind.BLAST)


func test_twin_blades_is_never_drawn_against_a_non_single_blade() -> void:
	for tick_offset in 16:
		var duel: DuelFixture = _duel(&"guardian", &"wasp", 1, true, false)
		duel.step(tick_offset)
		assert_ne(_heavy(duel, false)["finisher"], Finisher.Kind.TWIN_BLADES)

