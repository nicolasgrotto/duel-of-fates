extends TestCase


func _duel(first: StringName, second: StringName, rounds: int = 1, finishers: bool = true) -> DuelFixture:
	var rules: MatchRules = MatchRules.new()
	rules.rounds_to_win = rounds
	rules.finishers = finishers
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
