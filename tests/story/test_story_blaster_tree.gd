extends TestCase

const CAMPAIGN: CampaignData = preload("res://data/story/campaign.tres")
const STYLE_TECHNIQUE: int = 0
const STYLE_HOLSTER: int = 3
const DRAW: int = 0
const RETREAT: int = 1
const COVER: int = 2


func _story(style: int = STYLE_TECHNIQUE) -> StoryCampaign:
	return StoryCampaign.create("Iria", 0, style, 0, 0, 1)


func _armed(style: int = STYLE_TECHNIQUE) -> StoryCampaign:
	var story: StoryCampaign = _story(style)
	story.skill_points = 20
	story.credits = 1000
	var pistol: BlasterData = CAMPAIGN.blasters[0]
	if not story.owns_blaster(pistol):
		story.buy_blaster(pistol)
	story.equip_blaster(pistol)
	return story


func _tree(story: StoryCampaign) -> StoryPowerTree:
	return StoryPowerTree.new(story, false, true)


func test_no_style_has_a_blaster_technique_in_the_blade_tree() -> void:
	for style in CAMPAIGN.styles.size():
		var tree: StoryPowerTree = StoryPowerTree.new(_story(style), true)
		for node in tree.nodes:
			assert_false(node.technique != null and node.technique.draws_sidearm, "%d %s" % [style, node.name_key])
			assert_false(node.technique != null and node.technique.required_sidearm != WeaponData.Sidearm.NONE, "%d %s" % [style, node.name_key])
			assert_false(node.ability != null and node.ability.id == &"covering_fire", "%d ability" % style)


func test_blaster_tree_stays_shut_without_a_weapon_and_spends_nothing() -> void:
	var story: StoryCampaign = _story()
	story.skill_points = 20
	var tree: StoryPowerTree = _tree(story)
	assert_eq(tree.nodes.size(), 3)
	for index in tree.nodes.size():
		assert_eq(tree.nodes[index].state, StoryPowerTree.State.NEEDS_BLASTER)
	assert_false(tree.buy(RETREAT))
	assert_false(tree.equip(DRAW, -1))
	assert_eq(story.skill_points, 20)


func test_skills_follow_parents_and_cost_points() -> void:
	var story: StoryCampaign = _armed()
	var tree: StoryPowerTree = _tree(story)
	assert_false(tree.buy(COVER))
	assert_true(tree.buy(RETREAT))
	assert_true(tree.buy(COVER))
	assert_eq(story.skill_points, 15)
	var hero: CharacterData = story.protagonist()
	assert_eq(hero.technique_forward.id, &"double_draw")
	assert_eq(hero.technique_back.id, &"retreat_draw")
	assert_eq(hero.ability.id, &"covering_fire")
	assert_eq(hero.ability_key, "ABILITY_COVERING_FIRE")


func test_turning_a_skill_off_or_putting_the_weapon_away_gives_the_slot_back() -> void:
	var story: StoryCampaign = _armed()
	var blade: StoryPowerTree = StoryPowerTree.new(story, true)
	assert_true(blade.buy(1))
	var saber: MoveData = story.style_character().technique_back
	var tree: StoryPowerTree = _tree(story)
	assert_true(tree.buy(RETREAT))
	assert_eq(story.protagonist().technique_back.id, &"retreat_draw")
	blade.rebuild()
	assert_eq(blade.nodes[1].slot, -1)
	assert_true(tree.equip(RETREAT, -1))
	assert_eq(story.protagonist().technique_back, saber)
	assert_true(tree.equip(RETREAT, -1))
	story.unequip_blaster()
	assert_eq(story.protagonist().technique_back, saber)
	assert_true(story.protagonist().weapon.blaster == null)


func test_a_saber_choice_in_the_blade_tree_releases_the_draw_in_that_slot() -> void:
	var story: StoryCampaign = _armed()
	var blade: StoryPowerTree = StoryPowerTree.new(story, true)
	assert_true(blade.equip(0, 0))
	assert_eq(story.protagonist().technique_forward, story.style_character().technique_forward)
	var tree: StoryPowerTree = _tree(story)
	assert_true(tree.equip(DRAW, -1))
	assert_eq(story.protagonist().technique_forward.id, &"double_draw")


func test_the_style_ability_and_covering_fire_share_one_place() -> void:
	var story: StoryCampaign = _armed()
	story.skill_points = 30
	var blade: StoryPowerTree = StoryPowerTree.new(story, true)
	for index in 3:
		assert_true(blade.buy(index + 1))
	var own: AbilityData = story.style_character().ability
	var tree: StoryPowerTree = _tree(story)
	assert_true(tree.buy(RETREAT))
	assert_true(tree.buy(COVER))
	assert_eq(story.protagonist().ability.id, &"covering_fire")
	blade.rebuild()
	assert_eq(blade.nodes[3].state, StoryPowerTree.State.LEARNED)
	assert_true(blade.equip(3, -1))
	assert_eq(story.protagonist().ability, own)
	blade.rebuild()
	assert_eq(blade.nodes[3].state, StoryPowerTree.State.EQUIPPED)


func test_projected_cut_and_draw_never_share_a_slot() -> void:
	var story: StoryCampaign = _armed()
	var blade: StoryPowerTree = StoryPowerTree.new(story, true)
	for index in range(1, blade.nodes.size()):
		assert_true(blade.buy(index))
	assert_true(blade.equip(4, 0))
	assert_eq(story.protagonist().technique_forward, CAMPAIGN.blade_tree[4].technique)
	assert_false(story.draw_in_slot(0))
	var tree: StoryPowerTree = _tree(story)
	assert_true(tree.equip(DRAW, -1))
	assert_eq(story.projected_cut_slot, -1)
	assert_eq(story.protagonist().technique_forward.id, &"double_draw")


func test_skills_and_weapon_survive_a_save() -> void:
	var story: StoryCampaign = _armed()
	var tree: StoryPowerTree = _tree(story)
	assert_true(tree.buy(RETREAT))
	assert_true(tree.equip(DRAW, -1))
	var loaded: StoryCampaign = StoryCampaign.from_dict(story.to_dict())
	assert_true(loaded.blaster_equipped())
	assert_true(loaded.blaster_bought.has(CAMPAIGN.blaster_tree[RETREAT].node_id()))
	assert_false(loaded.blaster_active.has(CAMPAIGN.blaster_tree[DRAW].node_id()))
	assert_eq(loaded.protagonist().technique_back.id, &"retreat_draw")


func test_old_holster_saves_keep_what_they_had_bought_at_no_cost() -> void:
	var story: StoryCampaign = _story(STYLE_HOLSTER)
	story.skill_points = 7
	var saved: Dictionary = story.to_dict()
	saved.erase("blaster_carried")
	saved.erase("blaster_bought")
	saved.erase("blaster_active")
	saved.erase("owned_blasters")
	saved["blade_bought"] = ["style_forward", "style_back"]
	var loaded: StoryCampaign = StoryCampaign.from_dict(saved)
	assert_eq(loaded.skill_points, 7)
	assert_true(loaded.owns_blaster(CAMPAIGN.blasters[0]))
	var hero: CharacterData = loaded.protagonist()
	assert_eq(hero.technique_forward.id, &"double_draw")
	assert_eq(hero.technique_back.id, &"retreat_draw")
	assert_true(hero.ability == null)


func test_earlier_arsenal_saves_keep_their_carried_weapon_and_slot() -> void:
	var story: StoryCampaign = _story()
	var saved: Dictionary = story.to_dict()
	saved.erase("blaster_carried")
	saved.erase("blaster_bought")
	saved.erase("blaster_active")
	saved["blaster_slot"] = 1
	var loaded: StoryCampaign = StoryCampaign.from_dict(saved)
	assert_true(loaded.blaster_equipped())
	assert_true(loaded.owns_blaster(loaded.blaster_data()))
	assert_eq(loaded.protagonist().technique_back.id, &"retreat_draw")
