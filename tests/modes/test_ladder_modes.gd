extends TestCase


func test_arcade_ladder_rotates_without_the_player() -> void:
	var ladder: Array[CharacterData] = ArcadeMode.ladder(&"guardian", 6)
	assert_eq(ladder.size(), 6)
	assert_eq(ladder[0].id, &"shadow")
	for data in ladder:
		assert_ne(data.id, &"guardian")


func test_arcade_difficulty_climbs_to_the_boss() -> void:
	var mode: ArcadeMode = ArcadeMode.new()
	var expected: Array[StringName] = [&"easy", &"easy", &"normal", &"normal", &"hard", &"hard", &"hard"]
	for fight in expected.size():
		mode.fight = fight
		assert_eq(mode.fight_difficulty(), expected[fight], "fight %d" % fight)
	mode.fight = 6
	assert_true(mode.is_boss_fight())
	assert_eq(mode.character_for_fight().id, &"awakened_shadow")


func test_survival_heals_and_schedules_the_boss() -> void:
	var fixture: DuelFixture = DuelFixture.create()
	fixture.fighter(0).health = fixture.fighter(0).max_health * 0.4
	var mode: SurvivalMode = SurvivalMode.new()
	mode.finish(0, fixture.sim)
	assert_eq(mode.wins, 1)
	assert_almost(mode.health, 0.7, 0.01)
	assert_false(mode.is_boss_fight())
	mode.wins = 5
	assert_true(mode.is_boss_fight())
	assert_eq(mode.fight_difficulty(), &"hard")
	mode.wins = 1
	assert_eq(mode.fight_difficulty(), &"easy")
	mode.wins = 3
	assert_eq(mode.fight_difficulty(), &"normal")


func test_start_health_is_applied_each_round() -> void:
	var rules: MatchRules = MatchRules.new()
	rules.start_health = PackedFloat32Array([0.35, 1.0])
	var fixture: DuelFixture = DuelFixture.create(rules)
	assert_almost(fixture.fighter(0).health_ratio(), 0.35, 0.01)
	assert_almost(fixture.fighter(1).health_ratio(), 1.0, 0.01)


func test_boss_ai_awakens_below_half_health() -> void:
	var fixture: DuelFixture = DuelFixture.versus(&"guardian", &"awakened_shadow")
	var hard: AiDifficultyData = DuelMode.difficulty(&"hard")
	var ai: AiController = AiController.new(hard, fixture.fighter(1).character.ai_profile, 3)
	ai.awakening = DuelMode.BOSS_DIFFICULTY
	var intent: Intent = Intent.new()
	ai.produce(fixture.sim, 1, intent)
	assert_false(ai.awakened)
	fixture.fighter(1).health = fixture.fighter(1).max_health * 0.4
	ai.produce(fixture.sim, 1, intent)
	assert_true(ai.awakened)
	assert_eq(ai.difficulty, DuelMode.BOSS_DIFFICULTY)
