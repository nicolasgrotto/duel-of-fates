extends TestCase


func test_rebinding_a_used_key_swaps_it() -> void:
	var keys: Dictionary = InputBindings.preset_keys(&"default")
	var result: Dictionary = InputBindings.rebind(keys, "light_attack", KEY_K)
	assert_eq(result["light_attack"][0], KEY_K)
	assert_true(result["heavy_attack"].has(KEY_J), "the heavy attack takes the old light key")
	assert_false(result["heavy_attack"].has(KEY_K))


func test_rebinding_keeps_secondary_keys() -> void:
	var keys: Dictionary = InputBindings.preset_keys(&"default")
	var result: Dictionary = InputBindings.rebind(keys, "jump", KEY_Q)
	assert_eq(result["jump"][0], KEY_Q)
	assert_true(result["jump"].has(KEY_UP))
	assert_true(result["jump"].has(KEY_SPACE))


func test_reserved_keys() -> void:
	assert_true(InputBindings.is_reserved(KEY_ESCAPE))
	assert_true(InputBindings.is_reserved(KEY_F3))
	assert_false(InputBindings.is_reserved(KEY_Q))


func test_presets_cover_every_combat_action() -> void:
	for preset in [&"default", &"arrows"]:
		var keys: Dictionary = InputBindings.preset_keys(preset)
		for action in InputBindings.COMBAT_KEYS:
			assert_false(keys.get(action, []).is_empty(), "%s %s" % [preset, action])


func _key_codes(action: String) -> Array:
	var codes: Array = []
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			codes.append((event as InputEventKey).physical_keycode)
	return codes


func test_two_player_keyboard_splits_and_restores() -> void:
	InputBindings.apply_defaults()
	InputBindings.apply_two_player_keyboard()
	assert_eq(_key_codes("p1_light_attack"), [KEY_F])
	assert_eq(_key_codes("p2_light_attack"), [KEY_J])
	InputBindings.apply_keyboard(InputBindings.preset_keys(&"default"))
	assert_eq(_key_codes("p1_light_attack"), [KEY_J])
	assert_true(_key_codes("p2_light_attack").is_empty())
