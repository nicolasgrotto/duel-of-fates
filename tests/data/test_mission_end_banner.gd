extends TestCase


func test_banner_shows_outcome_text_and_closes_once() -> void:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	var banner: MissionEndBanner = MissionEndBanner.new()
	tree.root.add_child(banner)
	var calls: Array[int] = [0]
	banner.closed.connect(func() -> void: calls[0] += 1)
	banner.present(true, "detail")
	assert_eq(banner.title_text(), TranslationServer.translate("MISSION_END_SUCCESS").to_upper())
	banner.close()
	banner.close()
	assert_eq(calls[0], 1)
	banner.free()


func test_banner_failure_uses_its_own_title() -> void:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	var banner: MissionEndBanner = MissionEndBanner.new()
	tree.root.add_child(banner)
	banner.present(false, "detail")
	assert_eq(banner.title_text(), TranslationServer.translate("MISSION_END_FAILURE").to_upper())
	banner.free()
