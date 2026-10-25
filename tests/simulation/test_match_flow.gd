extends TestCase

var duel: DuelFixture


func before_each() -> void:
	duel = DuelFixture.create()


func _knock_out(attacker: int) -> void:
	duel.skip_intro()
	var defender: int = 1 - attacker
	duel.place(60.0)
	duel.fighter(attacker).facing = 1 if attacker == 0 else -1
	duel.fighter(defender).health = 1.0
	duel.press(attacker, Intent.Command.LIGHT)
	duel.step(8)


func test_knockout_ends_round() -> void:
	_knock_out(0)
	assert_eq(duel.sim.phase, MatchSimulation.Phase.KO)
	assert_eq(duel.sim.round_winner, 0)
	assert_eq(duel.fighter(0).round_wins, 1)
	assert_eq(duel.count_events(CombatEvent.Type.ROUND_ENDED), 1)


func test_next_round_resets_fighters() -> void:
	_knock_out(0)
	duel.step_until(func() -> bool: return duel.sim.phase == MatchSimulation.Phase.INTRO, 400)
	assert_eq(duel.sim.round_number, 2)
	assert_almost(duel.fighter(1).health, duel.fighter(1).max_health)
	assert_eq(duel.fighter(1).state, FighterState.State.IDLE)


func test_best_of_three_ends_match() -> void:
	_knock_out(0)
	duel.step_until(func() -> bool: return duel.sim.phase == MatchSimulation.Phase.INTRO, 400)
	_knock_out(0)
	duel.step_until(func() -> bool: return duel.sim.phase == MatchSimulation.Phase.OVER, 400)
	assert_eq(duel.sim.match_winner, 0)
	assert_eq(duel.count_events(CombatEvent.Type.MATCH_ENDED), 1)


func test_endless_rules_never_kill() -> void:
	var rules: MatchRules = MatchRules.new()
	rules.endless = true
	duel = DuelFixture.create(rules)
	_knock_out(0)
	assert_true(duel.fighter(1).is_alive())
	assert_eq(duel.sim.phase, MatchSimulation.Phase.FIGHT)
	duel.step(120)
	assert_almost(duel.fighter(1).health, duel.fighter(1).max_health)


func test_vigor_regenerates_after_delay() -> void:
	duel.skip_intro()
	duel.fighter(0).vigor = 50.0
	duel.fighter(0).regen_delay_ticks = Ticks.from_seconds(DuelFixture.CONFIG.vigor_regen_delay)
	duel.step(30)
	assert_almost(duel.fighter(0).vigor, 50.0, 0.001, "no regen during the delay")
	duel.step(60)
	assert_gt(duel.fighter(0).vigor, 70.0)


func _intro_ticks(rules: MatchRules) -> int:
	var fixture: DuelFixture = DuelFixture.create(rules)
	var ticks: int = 0
	while fixture.sim.phase == MatchSimulation.Phase.INTRO:
		fixture.step()
		ticks += 1
	return ticks


func test_fighter_intros_lengthen_only_the_first_round_intro() -> void:
	var config: CombatConfig = duel.sim.config
	var plain: MatchRules = MatchRules.new()
	var with_intros: MatchRules = MatchRules.new()
	with_intros.fighter_intros = true
	assert_eq(_intro_ticks(plain), Ticks.from_seconds(config.round_intro))
	assert_eq(_intro_ticks(with_intros), Ticks.from_seconds(config.match_intro))
	var fixture: DuelFixture = DuelFixture.create(with_intros)
	fixture.skip_intro()
	fixture.sim.round_number = 2
	assert_almost(fixture.sim.intro_seconds(), config.round_intro, 0.001, "later rounds keep the short intro")
