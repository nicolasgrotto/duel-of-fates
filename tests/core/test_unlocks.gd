extends TestCase


func test_character_challenges_read_the_duel_stats() -> void:
	var guardian: CharacterData = DuelFixture.GUARDIAN
	assert_eq(guardian.challenge_stat, &"perfect_parries")
	assert_false(Unlocks.challenge_met(guardian, {&"perfect_parries": 2}))
	assert_true(Unlocks.challenge_met(guardian, {&"perfect_parries": 3}))
	assert_eq(Unlocks.color_requirement(guardian, Unlocks.ARCADE_COLOR), "REQUIREMENT_ARCADE")
	assert_eq(Unlocks.color_requirement(guardian, Unlocks.CHALLENGE_COLOR), guardian.challenge_key)


func test_every_cast_member_has_a_color_challenge() -> void:
	for id in DuelMode.CAST:
		var data: CharacterData = DuelMode.character(id)
		assert_true(data.challenge_stat != &"" and data.challenge_target > 0, String(id))
		assert_true(data.challenge_stat in StatsTracker.STAT_KEYS or data.challenge_stat in StatsTracker.EXTRA_KEYS, String(id))
