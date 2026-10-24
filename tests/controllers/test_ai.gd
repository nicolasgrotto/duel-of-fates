extends TestCase

const EASY: AiDifficultyData = preload("res://data/balance/ai/difficulty_easy.tres")
const NORMAL: AiDifficultyData = preload("res://data/balance/ai/difficulty_normal.tres")
const HARD: AiDifficultyData = preload("res://data/balance/ai/difficulty_hard.tres")


func _parries_against_heavies(difficulty: AiDifficultyData, trials: int, count_responses: bool = false) -> int:
	var parries: int = 0
	for trial in trials:
		var duel: DuelFixture = DuelFixture.create(null, null, trial)
		duel.skip_intro()
		duel.place(80.0)
		var ai: AiController = AiController.new(difficulty, DuelFixture.GUARDIAN.ai_profile, trial)
		duel.press(1, Intent.Command.HEAVY)
		for tick in 40:
			ai.produce(duel.sim, 0, duel.intents[0])
			duel.step(1)
		parries += duel.count_events(CombatEvent.Type.PARRY) + duel.count_events(CombatEvent.Type.PERFECT_PARRY)
		if count_responses:
			parries += duel.count_events(CombatEvent.Type.RESPONSE)
	return parries


func test_hard_ai_answers_heavies_with_timing() -> void:
	assert_gt(_parries_against_heavies(HARD, 40, true), 3.0)


func test_easy_ai_never_parries() -> void:
	assert_eq(_parries_against_heavies(EASY, 40), 0)


func test_ai_is_reproducible_with_same_seed() -> void:
	var characters: Array[CharacterData] = [DuelFixture.GUARDIAN, DuelFixture.SHADOW]
	var difficulties: Array[AiDifficultyData] = [NORMAL, NORMAL]
	var first: HeadlessDuel = HeadlessDuel.new(DuelFixture.CONFIG, characters, difficulties, 42)
	var second: HeadlessDuel = HeadlessDuel.new(DuelFixture.CONFIG, characters, difficulties, 42)
	first.run()
	second.run()
	assert_eq(first.sim.capture(), second.sim.capture())


func test_ai_duel_reaches_a_winner() -> void:
	var characters: Array[CharacterData] = [DuelFixture.GUARDIAN, DuelFixture.SHADOW]
	var difficulties: Array[AiDifficultyData] = [HARD, HARD]
	var duel: HeadlessDuel = HeadlessDuel.new(DuelFixture.CONFIG, characters, difficulties, 3)
	var winner: int = duel.run()
	assert_ne(winner, MatchSimulation.NO_WINNER)
	assert_gt(duel.count(CombatEvent.Type.HIT), 4.0)


func test_ai_presses_during_blade_lock() -> void:
	var duel: DuelFixture = DuelFixture.create()
	duel.skip_intro()
	duel.place(50.0)
	duel.press(0, Intent.Command.HEAVY)
	duel.press(1, Intent.Command.HEAVY)
	duel.step_until(func() -> bool: return BladeLockResolver.is_active(duel.sim), 40)
	var ai: AiController = AiController.new(NORMAL, DuelFixture.SHADOW.ai_profile, 1)
	for tick in 120:
		ai.produce(duel.sim, 1, duel.intents[1])
		duel.step(1)
		if not BladeLockResolver.is_active(duel.sim):
			break
	assert_eq(duel.last_event(CombatEvent.Type.BLADE_LOCK_ENDED).get("source"), 1)


func test_habit_memory_tracks_heavy_use() -> void:
	var memory: AiHabitMemory = AiHabitMemory.new(8.0)
	var opponent: FighterState = FighterState.new()
	for i in 5:
		opponent.state = FighterState.State.HEAVY_ATTACK
		memory.observe(opponent)
		opponent.state = FighterState.State.IDLE
		memory.observe(opponent)
	assert_gt(memory.heavy_share(), 0.7)
	assert_lt(memory.light_share(), 0.01)


func test_ai_casts_powers_in_a_duel() -> void:
	var characters: Array[CharacterData] = [DuelFixture.GUARDIAN, DuelFixture.SHADOW]
	var difficulties: Array[AiDifficultyData] = [HARD, HARD]
	var duel: HeadlessDuel = HeadlessDuel.new(DuelFixture.CONFIG, characters, difficulties, 5)
	duel.run()
	assert_gt(duel.count(CombatEvent.Type.POWER_STARTED), 2.0)


func test_ai_jumps_over_a_fracture() -> void:
	var jumps: int = 0
	for trial in 20:
		var duel: DuelFixture = DuelFixture.create(null, null, trial)
		duel.skip_intro()
		duel.place(260.0)
		duel.give_power(1, &"fracture")
		duel.set_level(1, 8)
		var ai: AiController = AiController.new(HARD, DuelFixture.GUARDIAN.ai_profile, trial)
		duel.cast(1)
		for tick in 50:
			ai.produce(duel.sim, 0, duel.intents[0])
			duel.step(1)
			if duel.fighter(0).is_airborne():
				jumps += 1
				break
	assert_gt(jumps, 5.0)


func _spin_dodges_when_cornered(difficulty: AiDifficultyData, trials: int) -> int:
	var profile: AiProfileData = DuelFixture.GUARDIAN.ai_profile.duplicate()
	profile.ability_bias = 0.0
	profile.defense = 1.0
	var spins: int = 0
	for trial in trials:
		var duel: DuelFixture = DuelFixture.create(null, null, trial)
		duel.skip_intro()
		var limit: float = duel.sim.config.half_width() - duel.sim.config.body_width * 0.5
		duel.fighter(0).x = -limit
		duel.fighter(1).x = -limit + duel.sim.config.body_width + 30.0
		var ai: AiController = AiController.new(difficulty, profile, trial)
		duel.press(1, Intent.Command.HEAVY)
		duel.step(1)
		for tick in 40:
			ai.produce(duel.sim, 0, duel.intents[0])
			duel.step(1)
			if duel.fighter(0).dodge_kind == FighterState.DodgeKind.SPIN:
				spins += 1
				break
	return spins


func test_cornered_ai_spins_out_under_a_heavy() -> void:
	var eager: AiDifficultyData = HARD.duplicate()
	eager.defend_chance = 1.0
	eager.parry_chance = 0.0
	eager.spin_dodge_chance = 1.0
	assert_gt(_spin_dodges_when_cornered(eager, 10), 5.0)
	assert_eq(_spin_dodges_when_cornered(EASY, 20), 0)


func test_ai_pushes_through_a_blade_press() -> void:
	var duel: DuelFixture = DuelFixture.create(null, null, 3)
	duel.skip_intro()
	duel.place(30.0)
	BladeLockResolver.start(duel.sim, duel.fighter(0), duel.fighter(1), true)
	var ai: AiController = AiController.new(HARD, DuelFixture.GUARDIAN.ai_profile, 3)
	for tick in Ticks.from_seconds(DuelFixture.CONFIG.blade_lock.press_max_duration) + 30:
		ai.produce(duel.sim, 0, duel.intents[0])
		duel.step(1)
	assert_eq(duel.count_events(CombatEvent.Type.BLADE_PRESS_ENDED), 1)
	assert_eq(duel.last_event(CombatEvent.Type.BLADE_PRESS_ENDED)["source"], 0)


func _disengages_while_losing(difficulty: AiDifficultyData, trials: int) -> int:
	var total: int = 0
	for trial in trials:
		var duel: DuelFixture = DuelFixture.create(null, null, trial)
		duel.skip_intro()
		duel.place(40.0)
		BladeLockResolver.start(duel.sim, duel.fighter(0), duel.fighter(1))
		var ai: AiController = AiController.new(difficulty, DuelFixture.GUARDIAN.ai_profile, trial)
		for tick in Ticks.from_seconds(DuelFixture.CONFIG.blade_lock.max_duration):
			if not BladeLockResolver.is_active(duel.sim):
				break
			ai.produce(duel.sim, 0, duel.intents[0])
			duel.intents[0].pressed &= ~Intent.Command.LIGHT
			if tick % 9 == 0:
				duel.press(1, Intent.Command.LIGHT)
			duel.step(1)
		total += duel.count_events(CombatEvent.Type.DISENGAGE)
	return total


func test_hard_ai_disengages_when_losing_the_count() -> void:
	var eager: AiDifficultyData = HARD.duplicate()
	eager.disengage_chance = 1.0
	assert_gt(_disengages_while_losing(eager, 5), 3.0)
	assert_lt(_disengages_while_losing(EASY, 10), 2.0)
