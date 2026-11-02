extends TestCase

const RIGHT_HAND_KEYS: Array[Key] = [KEY_U, KEY_I, KEY_O, KEY_P, KEY_H, KEY_J, KEY_K, KEY_L, KEY_N, KEY_M]


func test_keyboard_layout_stays_near_movement_keys_and_never_changes_duel_actions() -> void:
	InputBindings.apply_defaults()
	var keys: Dictionary = InputBindings.rebind(InputBindings.preset_keys(&"default"), "light_attack", KEY_Z)
	InputBindings.apply_keyboard(keys)
	var before: PackedStringArray = []
	for event in InputMap.action_get_events(&"p1_light_attack"):
		before.append(event.as_text())
	InfiltrationBindings.install()
	assert_eq(_keys(&"infiltration_attack"), PackedInt32Array([KEY_SPACE]))
	assert_eq(_keys(&"infiltration_guard"), PackedInt32Array([KEY_Q]))
	assert_eq(_keys(&"infiltration_sneak"), PackedInt32Array([KEY_C]))
	assert_eq(_keys(&"infiltration_takedown"), PackedInt32Array([KEY_F]))
	assert_eq(_keys(&"infiltration_interact"), PackedInt32Array([KEY_E]))
	assert_eq(_keys(&"infiltration_up"), PackedInt32Array([KEY_W, KEY_UP]))
	assert_true(InputMap.has_action(&"infiltration_aim_up"))
	var mouse_found: bool = false
	for event in InputMap.action_get_events(&"infiltration_attack"):
		if event is InputEventMouseButton:
			mouse_found = true
	assert_true(mouse_found)
	InfiltrationBindings.uninstall()
	assert_false(InputMap.has_action(&"infiltration_up"))
	var after: PackedStringArray = []
	for event in InputMap.action_get_events(&"p1_light_attack"):
		after.append(event.as_text())
	assert_eq(after, before)
	InputBindings.apply_keyboard(InputBindings.preset_keys(&"default"))


func test_no_keyboard_action_sits_on_the_mouse_hand_side() -> void:
	InputBindings.apply_defaults()
	InfiltrationBindings.install()
	for action in InfiltrationBindings.KEYS:
		for code in _keys(action):
			assert_false(code in RIGHT_HAND_KEYS, String(action))
	InfiltrationBindings.uninstall()


func test_gamepad_buttons_still_follow_the_duel() -> void:
	InputBindings.apply_defaults()
	InfiltrationBindings.install()
	assert_eq(_buttons(&"infiltration_attack"), _buttons(&"p1_light_attack"))
	assert_eq(_buttons(&"infiltration_guard"), _buttons(&"p1_block"))
	InfiltrationBindings.uninstall()


func _buttons(action: StringName) -> PackedInt32Array:
	var codes: PackedInt32Array = []
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton:
			codes.append(event.button_index)
	return codes


func _keys(action: StringName) -> PackedInt32Array:
	var codes: PackedInt32Array = []
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			codes.append(event.physical_keycode)
	return codes


func test_bindings_survive_overlapping_screen_transitions_without_duplicates() -> void:
	InputBindings.apply_defaults()
	InfiltrationBindings.install()
	var count: int = InputMap.action_get_events(&"infiltration_attack").size()
	InfiltrationBindings.install()
	assert_eq(InputMap.action_get_events(&"infiltration_attack").size(), count)
	InfiltrationBindings.uninstall()
	assert_true(InputMap.has_action(&"infiltration_attack"))
	InfiltrationBindings.uninstall()
	assert_false(InputMap.has_action(&"infiltration_attack"))


func test_stealth_actions_only_produce_intent_bits() -> void:
	InputBindings.apply_defaults()
	InfiltrationBindings.install()
	var sim: InfiltrationSimulation = InfiltrationSimulation.new(load("res://data/balance/infiltration_config.tres"), load("res://data/infiltration/patrol_map.tres"))
	var before: Dictionary = sim.capture()
	var controller: InfiltrationPlayerController = InfiltrationPlayerController.new()
	var intent: InfiltrationIntent = InfiltrationIntent.new()
	Input.action_press(&"infiltration_takedown")
	Input.action_press(&"infiltration_interact")
	controller.produce(sim, intent)
	assert_eq(intent.pressed, Intent.Command.HEAVY | Intent.Command.POWER)
	assert_eq(sim.capture(), before)
	Input.action_release(&"infiltration_takedown")
	Input.action_release(&"infiltration_interact")
	InfiltrationBindings.uninstall()
	assert_false(InputMap.has_action(&"infiltration_takedown"))
	assert_false(InputMap.has_action(&"infiltration_interact"))


func test_controller_produces_independent_movement_aim_and_commands_without_mutating_simulation() -> void:
	InputBindings.apply_defaults()
	InfiltrationBindings.install()
	var sim: InfiltrationSimulation = InfiltrationSimulation.new(load("res://data/balance/infiltration_config.tres"), load("res://data/infiltration/training_map.tres"))
	var controller: InfiltrationPlayerController = InfiltrationPlayerController.new()
	var intent: InfiltrationIntent = InfiltrationIntent.new()
	var snapshot: Dictionary = sim.capture()
	Input.action_press(&"infiltration_right")
	Input.action_press(&"infiltration_down")
	Input.action_press(&"infiltration_run")
	controller.point_at(sim.player.position + Vector2.LEFT * 300.0)
	controller.produce(sim, intent)
	assert_almost(intent.movement.length(), 1.0)
	assert_eq(intent.aim, Vector2.LEFT)
	assert_eq(intent.pressed, Intent.Command.DODGE)
	assert_eq(sim.capture(), snapshot)
	Input.action_press(&"infiltration_aim_up")
	controller.produce(sim, intent)
	assert_eq(intent.aim, Vector2.UP)
	assert_eq(intent.pressed, 0)
	assert_eq(sim.capture(), snapshot)
	for action in [&"infiltration_right", &"infiltration_down", &"infiltration_run", &"infiltration_aim_up"]:
		Input.action_release(action)
	InfiltrationBindings.uninstall()
