extends TestCase


func _story(path: int) -> StoryCampaign:
	return StoryCampaign.create("Kael", path, 0, 0, 0, 1)


func test_tree_order_costs_and_parents_match_the_story() -> void:
	var ids: Array[Array] = [
		[&"repulse", &"pull", &"barrier", &"throw", &"focus", &"heal", &"absorption", &"mind_twist", &"supreme_push", &"sanctuary", &"mass_telekinesis"],
		[&"pull", &"repulse", &"drain", &"choke", &"freeze", &"lightning", &"mind_twist", &"wrath", &"fracture", &"arsenal", &"storm"],
	]
	for path in 2:
		var story: StoryCampaign = _story(path)
		var tree: StoryPowerTree = StoryPowerTree.new(story)
		var costs: Array[int] = [0, 1, 1, 2, 2, 2, 2, 2 if path == 0 else 3, 3, 3, 4]
		assert_eq(story.power_list(), ids[path])
		assert_eq(tree.nodes.size(), 11)
		for index in tree.nodes.size():
			var node: StoryPowerTree.PowerNode = tree.nodes[index]
			assert_eq(node.power.id, ids[path][index])
			assert_eq(node.definition.cost, costs[index])
			assert_eq(node.definition.parent, -1 if index == 0 else (5 if index == 8 else index - 1))
			assert_eq(node.definition.branch, 0 if index < 8 else 1)
		assert_eq(tree.nodes[0].state, StoryPowerTree.State.EQUIPPED)
		assert_eq(tree.nodes[1].state, StoryPowerTree.State.EXPENSIVE)
		assert_eq(tree.nodes[2].state, StoryPowerTree.State.LOCKED)


func test_buying_checks_points_parent_path_and_duplicate_ownership() -> void:
	var story: StoryCampaign = _story(0)
	var tree: StoryPowerTree = StoryPowerTree.new(story)
	assert_false(tree.buy(1))
	story.skill_points = 3
	tree.rebuild()
	assert_eq(tree.nodes[1].state, StoryPowerTree.State.AFFORDABLE)
	assert_false(tree.buy(2))
	assert_false(story.buy(StoryCampaign.CAMPAIGN.eclipse_tree[1]))
	assert_true(tree.buy(1))
	assert_eq(story.skill_points, 2)
	assert_false(tree.buy(1))
	assert_true(tree.buy(2))
	assert_eq(story.skill_points, 1)
	assert_false(tree.buy(3))
	assert_false(tree.buy(-1))
	assert_false(tree.buy(100))


func test_supreme_branch_can_be_bought_below_tier_but_not_equipped() -> void:
	for path in 2:
		var story: StoryCampaign = _story(path)
		story.skill_points = 100
		var tree: StoryPowerTree = StoryPowerTree.new(story)
		for index in range(1, 6):
			assert_true(tree.buy(index))
		assert_true(tree.buy(8), "supremes open after node six without buying seven and eight")
		assert_eq(tree.nodes[8].state, StoryPowerTree.State.TIER_BLOCKED)
		assert_false(tree.equip(8, 0))
		var power: PowerData = tree.nodes[8].power
		story.attributes[&"flow"] = power.min_level
		tree.rebuild()
		assert_true(tree.equip(8, 0))
		assert_true(tree.buy(9))
		assert_true(tree.buy(10))
		assert_false(tree.equip(10, 0))
		story.attributes[&"flow"] = tree.nodes[10].power.min_level
		tree.rebuild()
		assert_true(tree.equip(10, 0))


func test_encounters_no_longer_teach_powers_and_milestones_still_open_slots() -> void:
	for path in 2:
		var story: StoryCampaign = _story(path)
		var tree: StoryPowerTree = StoryPowerTree.new(story)
		assert_eq(tree.milestones[0].chapter, 3)
		assert_eq(tree.milestones[1].chapter, 6)
		for encounter in story.route():
			story.complete(encounter, 0.5)
		assert_eq(story.learned.size(), 1)
		assert_eq(story.slots_open, 3)
		story.skill_points = 3
		assert_true(story.buy(story.power_tree()[1]))
		assert_true(story.buy(story.power_tree()[2]))
		assert_ne(story.equipped[1], &"")
		assert_ne(story.equipped[2], &"")


func test_flow_gate_uses_catalog_and_rejects_the_other_path() -> void:
	var story: StoryCampaign = _story(0)
	story.learned.append(&"lightning")
	assert_false(story.equip_power(&"lightning", 0))
	assert_false(story.equip_power(&"unknown", 0))
