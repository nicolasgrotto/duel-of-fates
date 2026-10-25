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


func test_rebinding_a_used_button_swaps_it() -> void:
	var buttons: Dictionary = InputBindings.default_buttons()
	var result: Dictionary = InputBindings.rebind_button(buttons, "light_attack", JOY_BUTTON_Y)
	assert_eq(result["light_attack"][0], JOY_BUTTON_Y)
	assert_true(result["heavy_attack"].has(JOY_BUTTON_X), "the heavy attack takes the old light button")


func test_custom_buttons_reach_both_gamepads() -> void:
	var buttons: Dictionary = InputBindings.rebind_button(InputBindings.default_buttons(), "jump", JOY_BUTTON_LEFT_STICK)
	InputBindings.apply_buttons(buttons)
	for slot in InputBindings.PLAYER_COUNT:
		var found: bool = false
		for event in InputMap.action_get_events(InputBindings.player_prefix(slot) + "jump"):
			var button: InputEventJoypadButton = event as InputEventJoypadButton
			if button != null and button.button_index == JOY_BUTTON_LEFT_STICK and button.device == slot:
				found = true
		assert_true(found, "slot %d" % slot)
	assert_eq(InputBindings.button_map()["jump"][0], JOY_BUTTON_LEFT_STICK)
	InputBindings.apply_buttons(InputBindings.default_buttons())


func test_reserved_buttons() -> void:
	assert_true(InputBindings.is_reserved_button(JOY_BUTTON_START))
	assert_false(InputBindings.is_reserved_button(JOY_BUTTON_A))


func test_menu_gamepad_buttons_preserve_keys_and_do_not_duplicate() -> void:
	var keys: Array = _key_codes("ui_accept")
	InputBindings.apply_defaults()
	InputBindings.apply_defaults()
	assert_eq(_key_codes("ui_accept"), keys)
	for action in InputBindings.MENU_NAVIGATION_BUTTONS:
		var count: int = 0
		for event in InputMap.action_get_events(action):
			var button: InputEventJoypadButton = event as InputEventJoypadButton
			if button != null and button.button_index == InputBindings.MENU_NAVIGATION_BUTTONS[action] and button.device == InputBindings.ALL_DEVICES:
				count += 1
		assert_eq(count, 1, action)
		var press: InputEventJoypadButton = InputEventJoypadButton.new()
		press.device = 1
		press.button_index = InputBindings.MENU_NAVIGATION_BUTTONS[action]
		press.pressed = true
		assert_true(press.is_action_pressed(action), action)
