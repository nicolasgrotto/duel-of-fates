extends TestCase


func _campaign(path: int = 0) -> StoryCampaign:
	return StoryCampaign.create("Iria", path, 3, 3, 0, 1)


func test_holster_creation_has_fourth_style_and_the_expected_initial_kit() -> void:
	assert_eq(StoryCampaign.CAMPAIGN.styles.size(), 4)
	assert_eq(StoryCampaign.CAMPAIGN.style_keys.size(), 4)
	for path in 2:
		var story: StoryCampaign = _campaign(path)
		assert_true(story.uses_blaster_style())
		var hero: CharacterData = story.protagonist()
		assert_eq(hero.family, DuelFixture.GUARDIAN.family)
		assert_eq(hero.weapon.sidearm, WeaponData.Sidearm.HOLSTER)
		assert_eq(hero.weapon.blaster.id, &"holster_pistol")
		assert_eq(hero.technique_forward.id, &"double_draw")
		assert_true(hero.technique_back == null and hero.technique_air == null and hero.ability == null)
		assert_false(DuelFixture.character(&"holster").selectable)
		assert_eq(hero.eclipse_eyes, path == 1)
	for style in 3:
		assert_false(StoryCampaign.create("Iria", 0, style, 0, 0, 1).uses_blaster_style())


func test_holster_story_round_trip_keeps_equipment_and_legacy_defaults() -> void:
	var story: StoryCampaign = _campaign()
	story.blaster_id = &"back_rifle"
	var restored: StoryCampaign = StoryCampaign.from_dict(story.to_dict())
	assert_eq(restored.style, 3)
	assert_eq(restored.blaster_id, &"back_rifle")
	assert_eq(restored.protagonist().weapon.blaster.id, &"back_rifle")
	var old: Dictionary = story.to_dict()
	old.erase("blaster_id")
	assert_eq(StoryCampaign.from_dict(old).blaster_id, &"holster_pistol")
	old["blaster_id"] = "missing_weapon"
	assert_eq(StoryCampaign.from_dict(old).blaster_id, &"holster_pistol")
	assert_eq(DuelFixture.character(&"holster").weapon.blaster.id, &"holster_pistol")


func test_holster_blade_tree_buys_moves_and_restores_projected_cut_slots() -> void:
	var story: StoryCampaign = _campaign()
	story.skill_points = 10
	var tree: StoryPowerTree = StoryPowerTree.new(story, true)
	assert_eq(tree.nodes[0].technique.id, &"double_draw")
	assert_eq(tree.nodes[1].technique.id, &"retreat_draw")
	assert_eq(tree.nodes[2].technique.id, &"plunge")
	assert_eq(tree.nodes[3].ability.move.id, &"covering_fire")
	for index in range(1, tree.nodes.size()):
		assert_true(tree.buy(index))
	assert_eq(story.skill_points, 0)
	assert_true(story.protagonist().ability != null)
	for slot in 3:
		assert_true(tree.equip(4, slot))
		var restored: StoryCampaign = StoryCampaign.from_dict(story.to_dict())
		assert_eq(restored.projected_cut_slot, slot)
		assert_true(tree.equip(slot, slot))
	assert_eq(story.protagonist().technique_back.id, &"retreat_draw")
	assert_eq(story.protagonist().technique_air.id, &"plunge")


func test_holster_save_service_keeps_the_selected_blaster() -> void:
	var previous_path: String = SaveService.path
	var previous_campaign: Dictionary = SaveService.campaign.duplicate(true)
	SaveService.path = "user://task15_test_progress.cfg"
	var story: StoryCampaign = _campaign(1)
	story.blaster_id = &"back_rifle"
	story.save()
	SaveService.campaign = {}
	SaveService.load_progress()
	assert_eq(StoryCampaign.current().blaster_id, &"back_rifle")
	assert_eq(StoryCampaign.current().style, 3)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveService.path))
	SaveService.path = previous_path
	SaveService.campaign = previous_campaign


func test_holster_damage_discount_does_not_change_parry_or_technique_family() -> void:
	var holster: FighterState = FighterState.new()
	var technique: FighterState = FighterState.new()
	holster.setup(0, _campaign().protagonist(), DuelFixture.CONFIG)
	technique.setup(0, StoryCampaign.create("Iria", 0, 0, 3, 0, 1).protagonist(), DuelFixture.CONFIG)
	assert_almost(holster.blade_multiplier, technique.blade_multiplier * 0.9)
	assert_eq(holster.perfect_parry_ticks, technique.perfect_parry_ticks)
	assert_eq(holster.character.family, technique.character.family)
