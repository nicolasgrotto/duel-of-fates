extends TestCase


func _campaign(path: int, difficulty: int) -> StoryCampaign:
	return StoryCampaign.create("Kael", path, 0, 0, 0, difficulty)


func test_points_reach_the_documented_totals() -> void:
	var expected: Array[int] = [42, 36, 30]
	for difficulty in 3:
		var campaign: StoryCampaign = _campaign(0, difficulty)
		var total: int = campaign.attribute_total() + campaign.free_points
		for encounter in campaign.route():
			if encounter.chapter < 8:
				total += campaign.points_for(encounter)
		assert_eq(total, expected[difficulty], "difficulty %d" % difficulty)


func test_routes_follow_the_flow_path() -> void:
	var aurora: StoryCampaign = _campaign(0, 1)
	var eclipse: StoryCampaign = _campaign(1, 1)
	assert_eq(aurora.route().size(), 8)
	assert_eq(aurora.route()[7].opponent, &"sovereign")
	assert_eq(eclipse.route()[7].opponent, &"elder")
	assert_eq(aurora.learned, [&"repulse"] as Array[StringName])
	assert_eq(eclipse.learned, [&"lightning"] as Array[StringName])


func test_route_order_text_and_dialogue_exist() -> void:
	for path in 2:
		for encounter in _campaign(path, 1).route():
			assert_true(encounter.before.size() > 0 and encounter.after.size() > 0, String(encounter.id))
			assert_true(encounter.arena != null, String(encounter.id))


func test_attributes_cap_at_seven() -> void:
	var campaign: StoryCampaign = _campaign(0, 0)
	campaign.free_points = 10
	for i in 6:
		campaign.raise(&"blade")
	assert_eq(campaign.attributes[&"blade"], 7)
	assert_eq(campaign.free_points, 6)


func test_round_trip_and_protagonist() -> void:
	var campaign: StoryCampaign = _campaign(1, 2)
	campaign.attributes[&"flow"] = 6
	var copy: StoryCampaign = StoryCampaign.from_dict(campaign.to_dict())
	assert_eq(copy.path, 1)
	assert_eq(copy.attributes[&"flow"], 6)
	var data: CharacterData = copy.protagonist()
	assert_eq(data.flow, 6)
	assert_eq(data.name_key, "Kael")
	assert_eq(data.powers[0].id, &"lightning")
	assert_true(data.powers[1] == null)


func test_appearance_shows_the_chosen_hair_beard_and_colors() -> void:
	var campaign: StoryCampaign = StoryCampaign.create("Kael", 0, 0, 3, 0, 1)
	campaign.set_appearance({&"hair": 2, &"beard": 2, &"hair_color": 5, &"skin": 3})
	var hero: CharacterData = campaign.protagonist()
	var costume: CostumeData = hero.costumes[0]
	var parts: PackedStringArray = costume.parts_for(hero.art)
	assert_true(parts.has("hair_mid_wavy"))
	assert_true(parts.has("beard_full"))
	assert_true(parts.has("plate"), "the light plate outfit shows the plate")
	assert_false(parts.has("hair"), "the base hair gives way to the chosen one")
	assert_eq(costume.color(CostumeData.Slot.HAIR), StoryCampaign.CAMPAIGN.hair_colors[5])
	assert_eq(costume.color(CostumeData.Slot.SKIN), StoryCampaign.CAMPAIGN.skin_tones[3])
	assert_false(hero.eclipse_eyes, "aurora protagonists keep their own eyes")


func test_old_saves_get_a_default_appearance() -> void:
	var campaign: StoryCampaign = StoryCampaign.from_dict({"name": "Iria", "path": 1, "style": 1, "look": 0})
	assert_eq(campaign.hair, StoryCampaign.CAMPAIGN.default_hair)
	assert_eq(campaign.beard, 0)
	assert_true(campaign.protagonist().eclipse_eyes)
	var round_trip: StoryCampaign = StoryCampaign.from_dict(campaign.to_dict())
	assert_eq(round_trip.skin, campaign.skin)


func test_tree_equipping_preserves_full_unique_slots_and_save_format() -> void:
	for path in 2:
		var campaign: StoryCampaign = _campaign(path, 1)
		for encounter in campaign.route():
			campaign.complete(encounter, 0.5)
		var original_keys: Array = campaign.to_dict().keys()
		var tree: StoryPowerTree = StoryPowerTree.new(campaign)
		assert_false(tree.equip(0, campaign.slots_open))
		assert_false(campaign.equip_power(&"", 0))
		assert_false(campaign.equip_power(&"unknown", 0))
		for index in tree.nodes.size():
			for slot in campaign.slots_open:
				var other: int = campaign.equipped.find(tree.nodes[index].power.id)
				var changed: bool = tree.equip(index, slot)
				assert_eq(changed, tree.nodes[index].allowed and (other < 0 or other == slot))
				var seen: Dictionary = {}
				for open_slot in campaign.slots_open:
					var id: StringName = campaign.equipped[open_slot]
					assert_ne(id, &"")
					assert_false(seen.has(id))
					seen[id] = true
		assert_eq(campaign.to_dict().keys(), original_keys)
		assert_eq(StoryCampaign.from_dict(campaign.to_dict()).equipped, campaign.equipped)
