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
