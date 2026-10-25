extends TestCase

const SECRET_CAST: Array[StringName] = [&"awakened_shadow", &"sovereign", &"elder", &"foretold", &"foretold_eclipse"]
const EFFECTS: EffectsConfig = preload("res://data/balance/effects_config.tres")


func test_every_character_has_ordered_intro_data_that_settles_before_the_title() -> void:
	var cast: Array[StringName] = DuelMode.CAST.duplicate()
	cast.append_array(SECRET_CAST)
	for id in cast:
		var data: CharacterData = DuelFixture.character(id)
		var intro: IntroData = data.intro
		assert_true(intro != null, String(id))
		assert_gt(intro.keys.size(), 1, String(id))
		assert_almost(intro.keys[0].time, 0.0)
		var previous: float = -1.0
		for key in intro.keys:
			assert_gt(key.time, previous, String(id))
			previous = key.time
		var title: float = DuelFixture.CONFIG.match_intro - DuelFixture.CONFIG.match_intro_title
		assert_true(intro.last_time() <= DuelFixture.CONFIG.match_intro, String(id))
		assert_true(intro.last_time() + intro.blend_time <= title + 0.001, String(id))
		assert_gt(intro.blend_time, 0.0, String(id))
		assert_true(intro.ignite_at >= 0.0 and intro.second_ignition() + EFFECTS.ignition <= title, String(id))


func test_story_protagonist_inherits_the_intro_of_each_style() -> void:
	for style in 3:
		var campaign: StoryCampaign = StoryCampaign.create("Iria", 0, style, 0, 0, 1)
		assert_true(campaign.protagonist().intro != null)
