extends TestCase


func _story(path: int) -> StoryCampaign:
	return StoryCampaign.create("Kael", path, 0, 0, 0, 1)


func test_tree_order_and_unique_requirements_follow_existing_data() -> void:
	for path in 2:
		var story: StoryCampaign = _story(path)
		var tree: StoryPowerTree = StoryPowerTree.new(story)
		assert_eq(tree.nodes.size(), story.power_list().size())
		var encounters: Array[EncounterData] = story.route()
		encounters.append(story.secret_encounter())
		for index in tree.nodes.size():
			var node: StoryPowerTree.PowerNode = tree.nodes[index]
			assert_eq(node.power.id, story.power_list()[index])
			var grants: int = 0
			for encounter in encounters:
				if (encounter.power_aurora if path == 0 else encounter.power_eclipse) == node.power.id:
					grants += 1
					assert_eq(node.encounter, encounter)
					assert_eq(node.encounter.chapter, encounter.chapter)
			assert_eq(grants, 0 if index == 0 else 1)
			assert_eq(node.initial, index == 0)
			assert_eq(node.encounter == null, index == 0)


func test_states_track_creation_next_encounter_learning_and_equipment() -> void:
	for path in 2:
		var story: StoryCampaign = _story(path)
		var tree: StoryPowerTree = StoryPowerTree.new(story)
		assert_eq(tree.nodes[0].state, StoryPowerTree.State.EQUIPPED)
		assert_eq(tree.nodes[1].state, StoryPowerTree.State.LOCKED)
		story.complete(story.next_encounter(), 0.5)
		tree.rebuild()
		assert_eq(tree.nodes[1].state, StoryPowerTree.State.NEXT)
		story.complete(story.next_encounter(), 0.5)
		tree.rebuild()
		assert_eq(tree.nodes[1].state, StoryPowerTree.State.LEARNED)
		assert_true(tree.equip(1, 0))
		assert_eq(tree.nodes[0].state, StoryPowerTree.State.LEARNED)
		assert_eq(tree.nodes[1].state, StoryPowerTree.State.EQUIPPED)
		assert_eq(tree.nodes[1].slot, 0)
		while story.next_encounter() != null:
			story.complete(story.next_encounter(), 0.5)
		tree.rebuild()
		for node in tree.nodes:
			assert_true(node.state >= StoryPowerTree.State.LEARNED)


func test_slot_tiers_are_derived_from_milestones() -> void:
	for path in 2:
		var story: StoryCampaign = _story(path)
		var tree: StoryPowerTree = StoryPowerTree.new(story)
		var expected: Array[EncounterData] = []
		for encounter in story.route():
			if encounter.milestone:
				expected.append(encounter)
		assert_eq(tree.milestones, expected)
		assert_eq(tree.milestones[0].chapter, 3)
		assert_eq(tree.milestones[1].chapter, 6)
		for node in tree.nodes:
			var tier: int = 0
			for milestone in expected:
				if node.encounter != null and milestone.chapter <= node.encounter.chapter:
					tier += 1
			assert_eq(node.tier, tier)


func test_flow_gate_reads_campaign_attributes_and_catalog_rules() -> void:
	var story: StoryCampaign = _story(0)
	var power: PowerData = StoryCampaign.load_power(story.power_list()[0])
	var minimum: int = power.min_level
	power.min_level = 6
	story.attributes[&"flow"] = 5
	var tree: StoryPowerTree = StoryPowerTree.new(story)
	assert_false(tree.nodes[0].allowed)
	assert_false(tree.equip(0, 0))
	story.attributes[&"flow"] = 6
	tree.rebuild()
	assert_true(tree.nodes[0].allowed)
	assert_true(tree.equip(0, 0))
	assert_ne(story.style_character().flow, story.attributes[&"flow"])
	power.min_level = minimum
	tree.rebuild()
	story.learned.append(&"lightning")
	assert_false(story.equip_power(&"lightning", 0), "the catalog also rejects the other path")
