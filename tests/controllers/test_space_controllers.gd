extends TestCase


func test_space_aliases_preserve_other_actions_and_copy_remapped_player_controls() -> void:
	InputBindings.apply_defaults()
	var before: Array[InputEvent] = InputMap.action_get_events(&"p1_light_attack")
	InputMap.action_erase_events(&"p1_light_attack")
	var remapped: InputEventKey = InputEventKey.new()
	remapped.physical_keycode = KEY_Q
	InputMap.action_add_event(&"p1_light_attack", remapped)
	SpaceBindings.install()
	SpaceBindings.install()
	assert_eq(InputMap.action_get_events(&"space_fire").size(), 1)
	assert_eq((InputMap.action_get_events(&"space_fire")[0] as InputEventKey).physical_keycode, KEY_Q)
	assert_true(InputMap.has_action(&"p1_light_attack"))
	var vertical_axis: bool = false
	for event in InputMap.action_get_events(&"space_thrust"):
		if event is InputEventJoypadMotion:
			vertical_axis = event.axis == JOY_AXIS_LEFT_Y and event.axis_value == -1.0
	assert_true(vertical_axis)
	SpaceBindings.uninstall()
	assert_true(InputMap.has_action(&"space_fire"))
	SpaceBindings.uninstall()
	assert_false(InputMap.has_action(&"space_fire"))
	assert_eq((InputMap.action_get_events(&"p1_light_attack")[0] as InputEventKey).physical_keycode, KEY_Q)
	InputMap.action_erase_events(&"p1_light_attack")
	for event in before:
		InputMap.action_add_event(&"p1_light_attack", event)


func test_player_produces_axes_and_commands_without_mutating_simulation() -> void:
	InputBindings.apply_defaults()
	SpaceBindings.install()
	var sim: SpaceSimulation = SpaceFixture.make_sim()
	var saved: int = sim.state_hash()
	var controller: SpacePlayerController = SpacePlayerController.new()
	var intent: SpaceIntent = SpaceIntent.new()
	Input.action_press(&"space_thrust")
	Input.action_press(&"space_right")
	Input.action_press(&"space_fire")
	Input.action_press(&"space_boost")
	controller.produce(intent)
	assert_almost(intent.thrust, 1.0)
	assert_almost(intent.turn, 1.0)
	assert_eq(intent.pressed, SpaceIntent.Command.PRIMARY | SpaceIntent.Command.BOOST)
	assert_eq(sim.state_hash(), saved)
	controller.produce(intent)
	assert_eq(intent.pressed, 0)
	for action in [&"space_thrust", &"space_right", &"space_fire", &"space_boost"]:
		Input.action_release(action)
	SpaceBindings.uninstall()


func test_pause_discards_pending_and_suppresses_held_fire_until_release() -> void:
	InputBindings.apply_defaults()
	SpaceBindings.install()
	var controller: SpacePlayerController = SpacePlayerController.new()
	var intent: SpaceIntent = SpaceIntent.new()
	Input.action_press(&"space_fire")
	Input.action_press(&"space_boost")
	controller.discard_pending()
	controller.produce(intent)
	assert_eq(intent.held, 0)
	assert_eq(intent.pressed, 0)
	Input.action_release(&"space_fire")
	Input.action_release(&"space_boost")
	controller.produce(intent)
	Input.action_press(&"space_fire")
	controller.produce(intent)
	assert_eq(intent.pressed, SpaceIntent.Command.PRIMARY)
	Input.action_release(&"space_fire")
	SpaceBindings.uninstall()


func test_quick_press_release_is_buffered_once_for_fixed_tick() -> void:
	InputBindings.apply_defaults()
	SpaceBindings.install()
	var controller: SpacePlayerController = SpacePlayerController.new()
	var event: InputEventAction = InputEventAction.new()
	event.action = &"space_boost"
	event.pressed = true
	controller.handle_input(event)
	event.pressed = false
	controller.handle_input(event)
	var intent: SpaceIntent = SpaceIntent.new()
	controller.produce(intent)
	assert_eq(intent.pressed, SpaceIntent.Command.BOOST)
	controller.produce(intent)
	assert_eq(intent.pressed, 0)
	SpaceBindings.uninstall()


func test_drone_only_produces_intents_and_telegraphs_before_shooting() -> void:
	var sim: SpaceSimulation = SpaceFixture.make_sim()
	sim.ships[1].data.primary = SpaceWeaponData.new()
	sim.ships[1].data.primary.windup = 0.45
	sim.ships[1].angle = PI
	var controller: SpaceDroneController = SpaceDroneController.new(sim.ships.size())
	var player: SpaceIntent = SpaceIntent.new()
	var saved: int = sim.state_hash()
	var intents: Array[SpaceIntent] = controller.produce_all(sim, player)
	assert_eq(sim.state_hash(), saved)
	assert_eq(intents[1].held, SpaceIntent.Command.PRIMARY)
	sim.step(intents)
	assert_eq(sim.ships[1].charges[0], 1)
	for tick in 27:
		sim.step(controller.produce_all(sim, player))
	var shots: int = 0
	for projectile in sim.projectiles:
		shots += int(projectile.active and projectile.source == 1)
	assert_eq(shots, 1)


func test_drone_does_not_shoot_at_dead_out_of_range_or_misaligned_target() -> void:
	var sim: SpaceSimulation = SpaceFixture.make_sim()
	sim.ships[1].data.primary = SpaceWeaponData.new()
	var controller: SpaceDroneController = SpaceDroneController.new(sim.ships.size())
	var player: SpaceIntent = SpaceIntent.new()
	assert_eq(controller.produce_all(sim, player)[1].held, 0)
	sim.ships[1].angle = PI
	sim.ships[1].data.primary.max_range = 50.0
	assert_eq(controller.produce_all(sim, player)[1].held, 0)
	sim.ships[1].data.primary.max_range = 1400.0
	sim.ships[0].hull = 0.0
	assert_eq(controller.produce_all(sim, player)[1].held, 0)
