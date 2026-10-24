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
