extends TestCase


func _texts(action: StringName) -> PackedStringArray:
	var texts: PackedStringArray = []
	for event in InputMap.action_get_events(action):
		texts.append(event.as_text())
	return texts


func test_bindings_support_mouse_and_sticks_without_changing_duel_actions() -> void:
	InputBindings.apply_defaults()
	var before: PackedStringArray = _texts(&"p1_light_attack")
	BlasterOpsBindings.install()
	assert_true(InputMap.has_action(&"blaster_ops_aim_up"))
	assert_true(InputMap.has_action(&"blaster_ops_up"))
	var mouse: int = 0
	for event in InputMap.action_get_events(&"blaster_ops_fire"):
		if event is InputEventMouseButton:
			mouse += 1
	assert_eq(mouse, 1)
	assert_eq(_texts(&"p1_light_attack"), before)
	BlasterOpsBindings.uninstall()
	assert_false(InputMap.has_action(&"blaster_ops_fire"))
	assert_eq(_texts(&"p1_light_attack"), before)


func test_binding_lifetimes_are_refcounted_and_apply_never_duplicates_events() -> void:
	BlasterOpsBindings.install()
	var before: PackedStringArray = _texts(&"blaster_ops_fire")
	BlasterOpsBindings.install()
	BlasterOpsBindings.apply({}, {})
	assert_eq(_texts(&"blaster_ops_fire"), before)
	BlasterOpsBindings.uninstall()
	assert_true(InputMap.has_action(&"blaster_ops_fire"))
	BlasterOpsBindings.uninstall()
	assert_false(InputMap.has_action(&"blaster_ops_fire"))


func test_remapped_actions_keep_mouse_trigger_axes_and_independent_aim() -> void:
	BlasterOpsBindings.install()
	var keys: Dictionary = InputBindings.rebind(BlasterOpsBindings.keyboard_map(), "fire", KEY_Z)
	var buttons: Dictionary = InputBindings.rebind_button(BlasterOpsBindings.button_map(), "fire", JOY_BUTTON_A)
	BlasterOpsBindings.apply(keys, buttons)
	assert_eq((InputMap.action_get_events(&"blaster_ops_fire")[0] as InputEventKey).physical_keycode, KEY_Z)
	var trigger: bool = false
	for event in InputMap.action_get_events(&"blaster_ops_power"):
		if event is InputEventJoypadMotion:
			trigger = true
	assert_true(trigger)
	assert_true(InputMap.has_action(&"blaster_ops_aim_right"))
	BlasterOpsBindings.uninstall()


func test_player_controller_only_produces_intent_and_can_move_against_aim() -> void:
	BlasterOpsBindings.install()
	var fixture: BlasterOpsFixture = BlasterOpsFixture.create()
	var controller: BlasterOpsPlayerController = BlasterOpsPlayerController.new()
	var intent: InfiltrationIntent = InfiltrationIntent.new()
	var snapshot: Dictionary = fixture.sim.capture()
	controller.point_at(fixture.sim.player.position + Vector2(-100, 0))
	Input.action_press(&"blaster_ops_right")
	Input.action_press(&"blaster_ops_fire")
	controller.produce(fixture.sim, intent)
	assert_eq(intent.movement, Vector2.RIGHT)
	assert_eq(intent.aim, Vector2.LEFT)
	assert_true((intent.held & Intent.Command.LIGHT) != 0)
	assert_eq(fixture.sim.capture(), snapshot)
	Input.action_release(&"blaster_ops_right")
	Input.action_release(&"blaster_ops_fire")
	BlasterOpsBindings.uninstall()


func test_right_stick_aim_stays_after_release_and_pause_discards_held_fire() -> void:
	BlasterOpsBindings.install()
	var fixture: BlasterOpsFixture = BlasterOpsFixture.create()
	var controller: BlasterOpsPlayerController = BlasterOpsPlayerController.new()
	var intent: InfiltrationIntent = InfiltrationIntent.new()
	Input.action_press(&"blaster_ops_aim_up")
	controller.produce(fixture.sim, intent)
	assert_eq(intent.aim, Vector2.UP)
	Input.action_release(&"blaster_ops_aim_up")
	Input.action_press(&"blaster_ops_right")
	controller.produce(fixture.sim, intent)
	assert_eq(intent.aim, Vector2.UP)
	Input.action_press(&"blaster_ops_fire")
	controller.discard_pending()
	controller.produce(fixture.sim, intent)
	assert_eq(intent.held & Intent.Command.LIGHT, 0)
	Input.action_release(&"blaster_ops_fire")
	controller.produce(fixture.sim, intent)
	Input.action_press(&"blaster_ops_fire")
	controller.produce(fixture.sim, intent)
	assert_eq(intent.pressed & Intent.Command.LIGHT, Intent.Command.LIGHT)
	Input.action_release(&"blaster_ops_fire")
	Input.action_release(&"blaster_ops_right")
	BlasterOpsBindings.uninstall()


func test_settings_round_trip_the_mode_bindings_without_changing_duel_maps() -> void:
	var previous_keys: Dictionary = Settings.blaster_ops_keys.duplicate(true)
	var previous_buttons: Dictionary = Settings.blaster_ops_buttons.duplicate(true)
	var duel_keys: Dictionary = Settings.custom_keys.duplicate(true)
	Settings.blaster_ops_keys = {"fire": [KEY_Z]}
	Settings.blaster_ops_buttons = {"fire": [JOY_BUTTON_A]}
	Settings.save_settings("user://task16_test_settings.cfg")
	Settings.blaster_ops_keys = {}
	Settings.blaster_ops_buttons = {}
	Settings.load_settings("user://task16_test_settings.cfg")
	assert_eq(Settings.blaster_ops_keys, {"fire": [KEY_Z]})
	assert_eq(Settings.blaster_ops_buttons, {"fire": [JOY_BUTTON_A]})
	assert_eq(Settings.custom_keys, duel_keys)
	Settings.blaster_ops_keys = previous_keys
	Settings.blaster_ops_buttons = previous_buttons
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://task16_test_settings.cfg"))
