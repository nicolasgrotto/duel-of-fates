extends TestCase

const CONFIG: InfiltrationConfig = preload("res://data/balance/infiltration_config.tres")


func test_every_roster_character_has_a_top_view_sprite_with_the_native_size() -> void:
	for id in CharacterRoster.IDS:
		var sprite: Texture2D = load(InfiltrationLook.SPRITE_PATH % id) as Texture2D
		assert_true(sprite != null, String(id))
		assert_eq(Vector2i(sprite.get_size()), CONFIG.sprite_pixels, String(id))


func test_bake_applies_the_costume_palette_by_slot() -> void:
	var image: Image = Image.create(1, 1, false, Image.FORMAT_RGBA8)
	image.set_pixel(0, 0, Color(0.5, float(CostumeData.Slot.TRIM) / 7.0, 0.0, 1.0))
	var colors: PackedColorArray = PackedColorArray()
	colors.resize(8)
	colors[CostumeData.Slot.TRIM] = Color(0.2, 0.4, 0.6, 1.0)
	var baked: Color = InfiltrationLook.bake(ImageTexture.create_from_image(image), colors).get_image().get_pixel(0, 0)
	assert_almost(baked.r, 0.2, 0.01)
	assert_almost(baked.g, 0.4, 0.01)
	assert_almost(baked.b, 0.6, 0.01)


func test_different_costumes_change_the_baked_sprite() -> void:
	var data: CharacterData = CharacterRoster.character(&"guardian")
	assert_gt(float(data.costumes.size()), 1.0)
	var first: Image = InfiltrationLook.create(data, 0, 0).texture.get_image()
	var second: Image = InfiltrationLook.create(data, 1, 0).texture.get_image()
	assert_ne(first.get_data(), second.get_data())


func test_look_uses_the_chosen_blade_color_and_weapon_kind() -> void:
	var data: CharacterData = CharacterRoster.character(&"wasp")
	var look: InfiltrationLook = InfiltrationLook.create(data, 0, 1)
	assert_eq(look.blade_color, data.blade_colors[1])
	assert_eq(look.kind, WeaponData.Kind.DUAL)
	assert_gt(look.second_blade_ratio, 0.0)


func test_guard_keeps_the_hilt_at_the_hand_on_the_blade_side_and_crosses_the_body() -> void:
	var blade: InfiltrationBlade = InfiltrationBlade.new()
	blade.compose(CONFIG, Vector2.UP, 1.0, 0.0, 0.0)
	var right_side: Vector2 = Vector2.UP.rotated(PI * 0.5)
	assert_gt(blade.hand.dot(right_side), 0.0)
	assert_gt(blade.hand.dot(Vector2.UP), 0.0)
	assert_lt(blade.tip(CONFIG).dot(right_side), 0.0)
	assert_gt(blade.tip(CONFIG).dot(Vector2.UP), 0.0)
	assert_lt(blade.hand.length(), CONFIG.blade_grip + CONFIG.blade_hilt_half)


func test_swing_tip_follows_the_simulated_reach() -> void:
	var blade: InfiltrationBlade = InfiltrationBlade.new()
	for degrees in [-60.0, 0.0, 60.0]:
		blade.compose(CONFIG, Vector2.RIGHT, 0.0, 1.0, degrees)
		assert_almost(blade.tip(CONFIG).length(), CONFIG.swing_reach, 0.01)


func test_saved_look_falls_back_when_unknown_or_locked() -> void:
	var saved: Dictionary = SaveService.infiltration_look
	SaveService.infiltration_look = {"character": "nobody", "costume": 99, "blade": 99}
	var fallback: CharacterData = InfiltrationMode.look_character()
	assert_eq(fallback.id, CharacterRoster.IDS[0])
	assert_eq(InfiltrationMode.look_costume(fallback), 0)
	assert_eq(InfiltrationMode.look_blade(fallback), 0)
	SaveService.infiltration_look = saved


func test_changing_the_look_does_not_touch_the_simulation_hash() -> void:
	var mission: InfiltrationMissionData = InfiltrationMode.MISSIONS[0]
	var sim: InfiltrationSimulation = InfiltrationSimulation.new(CONFIG, mission.map, mission)
	var before: int = sim.state_hash()
	InfiltrationLook.create(CharacterRoster.character(&"shadow"), 0, 0)
	assert_eq(sim.state_hash(), before)


func test_navigation_counts_real_path_through_walls_and_cache_stays_consistent() -> void:
	var map: InfiltrationMapData = InfiltrationMode.MISSIONS[3].map
	var navigation: InfiltrationNavigation = InfiltrationNavigation.new(map)
	var start: Vector2 = map.player_spawn
	var goal: Vector2 = InfiltrationMode.MISSIONS[3].prisoner_spawns[0]
	var tiles: int = navigation.path_tiles(start, goal)
	assert_gt(tiles * map.tile_size, start.distance_to(goal))
	assert_gt(navigation.direction(start, goal, CONFIG.body_radius).length(), 0.9)
	for cell in InfiltrationNavigation.CACHED_GOALS * 2:
		navigation.path_tiles(start, map.player_spawn + Vector2(cell * map.tile_size, 0.0))
	assert_eq(navigation.path_tiles(start, goal), tiles)


func test_mission_previews_exist_at_native_size() -> void:
	for mission in InfiltrationMode.MISSIONS:
		assert_true(mission.preview != null, String(mission.id))
		assert_eq(Vector2i(mission.preview.get_size()), Vector2i(480, 170), String(mission.id))
