extends TestCase


func _fixture() -> DuelFixture:
	var rules: MatchRules = MatchRules.new()
	rules.fighter_intros = true
	return DuelFixture.create(rules)


func test_skip_from_either_side_preserves_the_title_and_ignores_attacks() -> void:
	for side in 2:
		for command in [Intent.Command.LIGHT, Intent.Command.HEAVY, Intent.Command.SPECIAL, Intent.Command.POWER]:
			var fixture: DuelFixture = _fixture()
			fixture.press(side, command)
			fixture.step()
			assert_eq(fixture.sim.phase_ticks, fixture.sim.intro_title_tick())
			assert_eq(fixture.sim.phase, MatchSimulation.Phase.INTRO)
			for fighter in fixture.sim.fighters:
				assert_eq(fighter.state, FighterState.State.IDLE)
				assert_almost(fighter.vigor, fighter.max_vigor)
				assert_eq(fighter.buffered_action, FighterState.Action.NONE)
			fixture.step(Ticks.from_seconds(fixture.sim.config.match_intro_title))
			assert_eq(fixture.sim.phase, MatchSimulation.Phase.FIGHT)
			assert_eq(fixture.count_events(CombatEvent.Type.FIGHT_STARTED), 1)


func test_confirm_skip_round_trips_through_recording_and_snapshot() -> void:
	var original: DuelFixture = _fixture()
	original.step(17)
	var snapshot: Dictionary = original.sim.capture()
	var recording: IntentRecording = IntentRecording.new()
	original.intents[1].skip_intro = true
	recording.append_tick(original.intents)
	original.sim.step(original.intents[0], original.intents[1])
	var skipped: Dictionary = original.sim.capture()
	var replay: DuelFixture = _fixture()
	replay.sim.restore(snapshot)
	for side in 2:
		var controller: ReplayController = ReplayController.new(recording, side)
		controller.produce(replay.sim, side, replay.intents[side])
	replay.sim.step(replay.intents[0], replay.intents[1])
	assert_eq(replay.sim.capture(), skipped)
	replay.sim.restore(skipped)
	original.release(1)
	replay.release(1)
	original.step(90)
	replay.step(90)
	assert_eq(replay.sim.capture(), original.sim.capture())


func test_repeated_skip_cannot_skip_the_title() -> void:
	var fixture: DuelFixture = _fixture()
	fixture.intents[0].skip_intro = true
	fixture.step()
	var title_tick: int = fixture.sim.phase_ticks
	fixture.step(10)
	assert_eq(fixture.sim.phase_ticks, title_tick + 10)
	assert_eq(fixture.sim.phase, MatchSimulation.Phase.INTRO)


func test_intro_ignores_movement_and_the_attack_on_fight_started() -> void:
	var fixture: DuelFixture = _fixture()
	fixture.intents[0].move_x = 1
	fixture.hold(0, Intent.Command.JUMP)
	fixture.step(Ticks.from_seconds(fixture.sim.config.match_intro) - 1)
	fixture.press(0, Intent.Command.HEAVY)
	fixture.step()
	assert_eq(fixture.sim.phase, MatchSimulation.Phase.FIGHT)
	assert_eq(fixture.fighter(0).state, FighterState.State.IDLE)
	assert_almost(fixture.fighter(0).x, -fixture.sim.config.round_start_distance * 0.5)


func test_second_round_and_disabled_intros_keep_the_normal_duration() -> void:
	var fixture: DuelFixture = _fixture()
	fixture.skip_intro()
	fixture.sim.kill(fixture.fighter(1), fixture.fighter(0), null)
	fixture.step()
	fixture.step(Ticks.from_seconds(fixture.sim.config.ko_duration))
	assert_eq(fixture.sim.round_number, 2)
	assert_eq(fixture.sim.phase_ticks, 0)
	fixture.intents[0].skip_intro = true
	fixture.press(0, Intent.Command.LIGHT)
	fixture.step()
	assert_eq(fixture.sim.phase_ticks, 1)
	fixture.step(Ticks.from_seconds(fixture.sim.config.round_intro) - 1)
	assert_eq(fixture.sim.phase, MatchSimulation.Phase.FIGHT)
	var plain: DuelFixture = DuelFixture.create()
	plain.intents[0].skip_intro = true
	plain.step()
	assert_eq(plain.sim.phase_ticks, 1)
