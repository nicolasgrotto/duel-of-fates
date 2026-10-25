extends TestCase


func test_every_power_has_its_own_consistent_icon() -> void:
	var kinds: Dictionary = {}
	var pixels: Dictionary = {}
	for file in DirAccess.get_files_at("res://data/powers"):
		if not file.ends_with(".tres"):
			continue
		var power: PowerData = load("res://data/powers/" + file) as PowerData
		if power == null:
			continue
		assert_true(power.icon != null, String(power.id))
		if power.icon == null:
			continue
		assert_eq(power.icon.resource_path, "res://assets/ui/powers/%s.png" % power.id)
		assert_eq(power.icon.get_size(), Vector2(24.0, 24.0))
		var signature: int = hash(power.icon.get_image().get_data())
		assert_false(pixels.has(signature), "%s has a unique silhouette" % power.id)
		pixels[signature] = power.id
		kinds[power.kind] = true
	assert_eq(kinds.size(), PowerData.Kind.size() - 1)


func test_blade_icons_match_resources_and_cover_every_style_and_ability_kind() -> void:
	var catalog: PowerCatalog = load("res://data/powers/catalog.tres")
	for technique in catalog.techniques:
		assert_true(technique.icon != null, String(technique.id))
		assert_eq(technique.icon.get_size(), Vector2(24.0, 24.0))
	for style in StoryCampaign.CAMPAIGN.styles.size():
		var story: StoryCampaign = StoryCampaign.create("Iria", 0, style, 0, 0, 1)
		assert_true(story.style_character().ability.icon != null)
	var kinds: Array[String] = ["strike", "stance", "dash", "charge", "leap"]
	for kind in kinds:
		assert_true(ResourceLoader.exists("res://assets/ui/blade/ability_%s.png" % kind))
