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
