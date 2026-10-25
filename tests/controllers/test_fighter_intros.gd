extends TestCase


func test_confirm_is_recorded_as_intro_skip_for_each_player_slot() -> void:
	InputBindings.apply_defaults()
	var fixture: DuelFixture = DuelFixture.create()
	var accept: InputEventAction = InputEventAction.new()
	accept.action = &"ui_accept"
	accept.pressed = true
	for side in 2:
		var player: PlayerController = PlayerController.new(side)
		var intent: Intent = Intent.new()
		player.handle_input(accept)
		player.produce(fixture.sim, side, intent)
		assert_true(intent.skip_intro)
		var copy: Intent = Intent.new()
		copy.unpack(intent.pack())
		assert_true(copy.skip_intro)
		player.produce(fixture.sim, side, intent)
		assert_false(intent.skip_intro)
		player.handle_input(accept)
		fixture.sim.phase = MatchSimulation.Phase.FIGHT
		player.produce(fixture.sim, side, intent)
		assert_false(intent.skip_intro)
		fixture.sim.phase = MatchSimulation.Phase.INTRO
