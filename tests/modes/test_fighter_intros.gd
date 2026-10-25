extends TestCase


func test_duel_modes_copy_the_saved_intro_option() -> void:
	var saved: bool = Settings.fighter_intros
	var campaign: StoryCampaign = StoryCampaign.create("Iria", 0, 0, 0, 0, 1)
	var modes: Array[DuelMode] = [VersusMode.new(), ArcadeMode.new(), SurvivalMode.new(), TwoPlayerMode.new(), StoryMode.new(campaign, campaign.route()[0])]
	for enabled in [false, true]:
		Settings.fighter_intros = enabled
		for mode in modes:
			assert_eq(mode.build_setup().rules.fighter_intros, enabled, mode.get_script().resource_path)
	Settings.fighter_intros = saved


func test_learning_and_demonstration_modes_never_enable_fighter_intros() -> void:
	var saved: bool = Settings.fighter_intros
	Settings.fighter_intros = true
	var modes: Array[DuelMode] = [TrainingMode.new(), GalleryMode.new(), ParryChallengeMode.new()]
	for path in DirAccess.get_files_at("res://data/lessons"):
		if path.ends_with(".tres"):
			modes.append(LessonMode.new(load("res://data/lessons/" + path)))
	for path in DirAccess.get_files_at("res://data/challenges"):
		if path.ends_with(".tres"):
			modes.append(ChallengeMode.new(load("res://data/challenges/" + path)))
	assert_gt(modes.size(), 6)
	for mode in modes:
		assert_false(mode.build_setup().rules.fighter_intros, mode.get_script().resource_path)
	Settings.fighter_intros = saved
