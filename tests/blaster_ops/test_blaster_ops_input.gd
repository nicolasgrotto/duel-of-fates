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


func test_run_and_sneak_toggle_on_a_tap_and_replace_each_other() -> void:
	BlasterOpsBindings.install()
	var fixture: BlasterOpsFixture = BlasterOpsFixture.create()
	var controller: BlasterOpsPlayerController = BlasterOpsPlayerController.new()
	var intent: InfiltrationIntent = InfiltrationIntent.new()
	Input.action_press(&"blaster_ops_run")
	controller.produce(fixture.sim, intent)
	assert_eq(intent.held & InfiltrationIntent.RUN, InfiltrationIntent.RUN)
	Input.action_release(&"blaster_ops_run")
	controller.produce(fixture.sim, intent)
	assert_eq(intent.held & InfiltrationIntent.RUN, InfiltrationIntent.RUN)
	Input.action_press(&"blaster_ops_sneak")
	controller.produce(fixture.sim, intent)
	Input.action_release(&"blaster_ops_sneak")
	controller.produce(fixture.sim, intent)
	assert_eq(intent.held & BlasterOpsPlayerController.STANCES, InfiltrationIntent.SNEAK)
	Input.action_press(&"blaster_ops_sneak")
	controller.produce(fixture.sim, intent)
	Input.action_release(&"blaster_ops_sneak")
	controller.produce(fixture.sim, intent)
	assert_eq(intent.held & BlasterOpsPlayerController.STANCES, 0)
	BlasterOpsBindings.uninstall()


func test_pause_keeps_the_stance_and_restart_clears_it() -> void:
	BlasterOpsBindings.install()
	var fixture: BlasterOpsFixture = BlasterOpsFixture.create()
	var controller: BlasterOpsPlayerController = BlasterOpsPlayerController.new()
	var intent: InfiltrationIntent = InfiltrationIntent.new()
	Input.action_press(&"blaster_ops_run")
	controller.produce(fixture.sim, intent)
	Input.action_release(&"blaster_ops_run")
	controller.discard_pending()
	controller.produce(fixture.sim, intent)
	assert_eq(intent.held & InfiltrationIntent.RUN, InfiltrationIntent.RUN)
	controller.reset_stance()
	controller.produce(fixture.sim, intent)
	assert_eq(intent.held & InfiltrationIntent.RUN, 0)
	BlasterOpsBindings.uninstall()


func test_no_default_operations_key_uses_ctrl_alt_or_meta() -> void:
	for suffix in BlasterOpsBindings.KEYS:
		for code in BlasterOpsBindings.KEYS[suffix]:
			assert_false(BlasterOpsBindings.is_unsafe_key(code), suffix)


func test_custom_keys_survive_the_layout_migration_without_ctrl_or_conflicts() -> void:
	var saved: Dictionary = {"fire": [], "guard": [KEY_Z], "dodge": [KEY_SPACE], "power": [KEY_T], "run": [KEY_SHIFT], "sneak": [KEY_CTRL, KEY_C], "strike": [KEY_1], "interact": [KEY_E], "left": [KEY_A], "right": [KEY_D], "up": [KEY_W], "down": [KEY_S]}
	var keys: Dictionary = BlasterOpsBindings.migrate_keys(saved)
	assert_eq(keys.guard, [KEY_Z])
	assert_eq(keys.sneak, [KEY_C])
	assert_eq(keys.strike, [KEY_1])
	assert_eq(keys.power, [KEY_T])
	assert_eq(keys.fire, [KEY_V])
	assert_eq(keys.power_2, [KEY_2])
	assert_eq(keys.switch_weapon, [KEY_X])
	assert_true(BlasterOpsBindings.migrate_keys({}).is_empty())


func test_ctrl_only_binding_falls_back_to_the_default_key() -> void:
	var keys: Dictionary = BlasterOpsBindings.migrate_keys({"sneak": [KEY_CTRL]})
	assert_eq(keys.sneak, [KEY_C])


func test_old_settings_file_migrates_keys_and_new_file_keeps_them() -> void:
	var path: String = "user://test_operations_layout.cfg"
	var file: ConfigFile = ConfigFile.new()
	file.set_value("blaster_ops", "keys", {"sneak": [KEY_CTRL, KEY_C], "guard": [KEY_Z]})
	file.set_value("blaster_ops", "operations_layout", 1)
	file.save(path)
	var keys: Dictionary = Settings._load_operations_keys(file)
	assert_eq(keys.sneak, [KEY_C])
	assert_eq(keys.guard, [KEY_Z])
	file.set_value("blaster_ops", "operations_layout", BlasterOpsBindings.LAYOUT_VERSION)
	file.set_value("blaster_ops", "keys", {"guard": [KEY_Z]})
	assert_eq(Settings._load_operations_keys(file), {"guard": [KEY_Z]})
	DirAccess.remove_absolute(path)


func test_window_fit_keeps_the_aspect_and_never_grows() -> void:
	assert_eq(Settings.fitted_window_size(Vector2i(1280, 720), Vector2i(1440, 830)), Vector2i(1280, 720))
	assert_eq(Settings.fitted_window_size(Vector2i(1600, 900), Vector2i(1440, 830)), Vector2i(1440, 810))
	assert_eq(Settings.fitted_window_size(Vector2i(1280, 720), Vector2i(1024, 700)), Vector2i(1024, 576))


func test_heat_bar_levels_and_labels_follow_the_weapon_state() -> void:
	var state: BlasterOpsState = BlasterOpsState.new()
	assert_eq(HeatBar.level_for(0.2, false, 0.7), HeatBar.Level.COOL)
	assert_eq(HeatBar.level_for(0.7, false, 0.7), HeatBar.Level.HOT)
	assert_eq(HeatBar.level_for(0.1, true, 0.7), HeatBar.Level.OVERHEATED)
	assert_eq(HeatBar.label_key(state), "BOPS_HEAT")
	state.heat = 50.0
	state.cooling_ticks = 5
	assert_eq(HeatBar.label_key(state), "BOPS_HEAT")
	state.cooling_ticks = 0
	assert_eq(HeatBar.label_key(state), "BOPS_COOLING")
	state.overheated = true
	assert_eq(HeatBar.label_key(state), "BOPS_OVERHEATED")


func _pad(button: JoyButton, pressed: bool) -> InputEventJoypadButton:
	var event: InputEventJoypadButton = InputEventJoypadButton.new()
	event.device = 0
	event.button_index = button
	event.pressed = pressed
	return event


func test_default_pad_buttons_have_no_conflicts_and_the_dpad_moves() -> void:
	BlasterOpsBindings.install()
	var owners: Dictionary = {}
	for suffix in BlasterOpsBindings.ACTIONS:
		for event in InputMap.action_get_events(BlasterOpsBindings.PREFIX + suffix):
			if event is InputEventJoypadButton:
				assert_false(owners.has(event.button_index), "%s and %s share a button" % [suffix, owners.get(event.button_index, "")])
				owners[event.button_index] = suffix
	assert_eq(owners[JOY_BUTTON_DPAD_UP], "up")
	assert_eq(owners[JOY_BUTTON_DPAD_DOWN], "down")
	assert_eq(owners[JOY_BUTTON_DPAD_LEFT], "left")
	assert_eq(owners[JOY_BUTTON_DPAD_RIGHT], "right")
	assert_eq(owners[JOY_BUTTON_BACK], "switch_weapon")
	BlasterOpsBindings.uninstall()


func test_tapping_back_switches_weapons_and_holding_opens_the_command_menu() -> void:
	BlasterOpsBindings.install()
	var controller: BlasterOpsPlayerController = BlasterOpsPlayerController.new()
	var sim: BlasterOpsSimulation = BlasterOpsSimulation.new(BlasterOpsTraining.CONFIG, BlasterOpsFixture.arena([]), BlasterOpsTraining.PISTOL.duplicate())
	var intent: InfiltrationIntent = InfiltrationIntent.new()
	controller.handle_input(_pad(JOY_BUTTON_BACK, true))
	controller.produce(sim, intent)
	assert_eq(intent.pressed & InfiltrationIntent.SWITCH_WEAPON, 0, "no switch while the button is down")
	controller.handle_input(_pad(JOY_BUTTON_BACK, false))
	controller.produce(sim, intent)
	assert_true((intent.pressed & InfiltrationIntent.SWITCH_WEAPON) != 0, "a tap switches on release")
	controller.handle_input(_pad(JOY_BUTTON_BACK, true))
	for tick in BlasterOpsPlayerController.COMMAND_HOLD_TICKS:
		controller.produce(sim, intent)
	assert_true(controller.command_menu_open())
	controller.handle_input(_pad(JOY_BUTTON_BACK, false))
	controller.produce(sim, intent)
	assert_false(controller.command_menu_open())
	assert_eq(intent.pressed & InfiltrationIntent.SWITCH_WEAPON, 0, "a long hold never switches")
	BlasterOpsBindings.uninstall()


func test_dpad_chooses_an_order_only_while_back_is_held() -> void:
	BlasterOpsBindings.install()
	var controller: BlasterOpsPlayerController = BlasterOpsPlayerController.new()
	var sim: BlasterOpsSimulation = BlasterOpsSimulation.new(BlasterOpsTraining.CONFIG, BlasterOpsFixture.arena([]), BlasterOpsTraining.PISTOL.duplicate())
	var intent: InfiltrationIntent = InfiltrationIntent.new()
	controller.handle_input(_pad(JOY_BUTTON_DPAD_LEFT, true))
	controller.produce(sim, intent)
	assert_eq(intent.ally_order, -1, "the d-pad alone gives no order")
	controller.handle_input(_pad(JOY_BUTTON_DPAD_LEFT, false))
	controller.handle_input(_pad(JOY_BUTTON_BACK, true))
	controller.handle_input(_pad(JOY_BUTTON_DPAD_LEFT, true))
	controller.produce(sim, intent)
	assert_eq(intent.ally_order, BlasterOpsMissionState.AllyOrder.HOLD)
	controller.handle_input(_pad(JOY_BUTTON_DPAD_LEFT, false))
	controller.handle_input(_pad(JOY_BUTTON_BACK, false))
	controller.produce(sim, intent)
	assert_eq(intent.pressed & InfiltrationIntent.SWITCH_WEAPON, 0, "choosing an order does not switch weapons")
	BlasterOpsBindings.uninstall()


func test_pause_while_holding_back_clears_the_menu() -> void:
	BlasterOpsBindings.install()
	var controller: BlasterOpsPlayerController = BlasterOpsPlayerController.new()
	var sim: BlasterOpsSimulation = BlasterOpsSimulation.new(BlasterOpsTraining.CONFIG, BlasterOpsFixture.arena([]), BlasterOpsTraining.PISTOL.duplicate())
	var intent: InfiltrationIntent = InfiltrationIntent.new()
	controller.handle_input(_pad(JOY_BUTTON_BACK, true))
	for tick in BlasterOpsPlayerController.COMMAND_HOLD_TICKS:
		controller.produce(sim, intent)
	controller.discard_pending()
	assert_false(controller.command_menu_open())
	controller.handle_input(_pad(JOY_BUTTON_BACK, false))
	controller.produce(sim, intent)
	assert_eq(intent.pressed & InfiltrationIntent.SWITCH_WEAPON, 0)
	BlasterOpsBindings.uninstall()


func test_every_older_layout_keeps_custom_keys_and_gets_the_new_ones() -> void:
	for layout in [1, 2]:
		var file: ConfigFile = ConfigFile.new()
		file.set_value("blaster_ops", "operations_layout", layout)
		file.set_value("blaster_ops", "keys", {"fire": [KEY_J], "guard": [KEY_K], "strike": [KEY_G]})
		var keys: Dictionary = Settings._load_operations_keys(file)
		assert_true(keys.fire.has(KEY_J), "layout %d" % layout)
		assert_true(keys.guard.has(KEY_K), "layout %d" % layout)
		assert_true(keys.strike.has(KEY_G), "layout %d" % layout)
		assert_false(keys.order_allies.has(KEY_G), "layout %d: a key in use is not taken" % layout)
		for suffix in BlasterOpsBindings.ACTIONS:
			assert_true(keys.has(suffix), "layout %d lists %s" % [layout, suffix])


func test_custom_pad_buttons_survive_and_win_over_defaults() -> void:
	var buttons: Dictionary = {"switch_weapon": [JOY_BUTTON_Y], "order_allies": [JOY_BUTTON_LEFT_STICK]}
	BlasterOpsBindings.install({}, buttons)
	assert_true(BlasterOpsBindings.button_map().switch_weapon.has(JOY_BUTTON_Y))
	assert_true(BlasterOpsBindings.button_map().order_allies.has(JOY_BUTTON_LEFT_STICK))
	assert_false(BlasterOpsBindings.button_map().run.has(JOY_BUTTON_LEFT_STICK), "a taken default stays free")
	assert_true(BlasterOpsBindings.button_map().up.has(JOY_BUTTON_DPAD_UP))
	BlasterOpsBindings.uninstall()
