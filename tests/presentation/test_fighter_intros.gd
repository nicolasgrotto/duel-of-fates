extends TestCase

const EFFECTS: EffectsConfig = preload("res://data/balance/effects_config.tres")


func test_intro_hands_move_continuously_through_every_tick() -> void:
	var cast: Array[StringName] = DuelMode.CAST.duplicate()
	cast.append_array([&"awakened_shadow", &"sovereign", &"elder", &"foretold", &"foretold_eclipse"])
	for id in cast:
		var fixture: DuelFixture = DuelFixture.versus(id, &"guardian")
		var data: CharacterData = fixture.fighter(0).character
		var solver: PoseSolver = PoseSolver.new()
		solver.setup(data, data.art)
		solver.intro = data.intro
		var pose: RigPose = RigPose.new()
		var last_grip: Vector2 = Vector2.ZERO
		var last_hand: Vector2 = Vector2.ZERO
		for tick in Ticks.from_seconds(fixture.sim.config.match_intro) + 1:
			solver.time = Ticks.to_seconds(tick)
			solver.intro_time = solver.time
			solver.solve(fixture.fighter(0), fixture.fighter(1), pose)
			assert_true(pose.grip.is_finite() and pose.off_hand.is_finite(), String(id))
			if tick > 0:
				assert_lt(pose.grip.distance_to(last_grip), 16.0, "%s grip tick %d" % [id, tick])
				assert_lt(pose.off_hand.distance_to(last_hand), 16.0, "%s off hand tick %d" % [id, tick])
			last_grip = pose.grip
			last_hand = pose.off_hand


func test_intro_settles_exactly_into_each_characters_guard() -> void:
	var cast: Array[StringName] = DuelMode.CAST.duplicate()
	cast.append_array([&"awakened_shadow", &"sovereign", &"elder", &"foretold", &"foretold_eclipse"])
	for id in cast:
		var fixture: DuelFixture = DuelFixture.versus(id, &"guardian")
		var character: CharacterData = fixture.fighter(0).character
		var solver: PoseSolver = PoseSolver.new()
		solver.setup(character, character.art)
		solver.time = 3.0
		var guard: RigPose = RigPose.new()
		solver.solve(fixture.fighter(0), fixture.fighter(1), guard)
		solver.intro = character.intro
		solver.intro_time = character.intro.last_time() + character.intro.blend_time
		var pose: RigPose = RigPose.new()
		solver.solve(fixture.fighter(0), fixture.fighter(1), pose)
		assert_almost(pose.grip.distance_to(guard.grip), 0.0, 0.001, String(id))
		assert_almost(pose.off_hand.distance_to(guard.off_hand), 0.0, 0.001, String(id))
		assert_almost(pose.pelvis.distance_to(guard.pelvis), 0.0, 0.001, String(id))
		assert_almost(pose.blade_angle, guard.blade_angle, 0.001, String(id))
		assert_almost(pose.off_blade_angle, guard.off_blade_angle, 0.001, String(id))
		assert_almost(pose.torso_angle, guard.torso_angle, 0.001, String(id))
		assert_almost(pose.head_angle, guard.head_angle, 0.001, String(id))


func _view(costume_index: int = 0) -> FighterView:
	var rules: MatchRules = MatchRules.new()
	rules.fighter_intros = true
	var fixture: DuelFixture = DuelFixture.create(rules, null, 7, [DuelFixture.character(&"reaper"), DuelFixture.GUARDIAN])
	var view: FighterView = FighterView.new()
	view.fighter = fixture.fighter(0)
	view.opponent = fixture.fighter(1)
	view.runner = TickRunner.new()
	view.runner.sim = fixture.sim
	view.effects = EFFECTS
	view.rig = FighterRig.new()
	view.add_child(view.rig)
	view.rig.build(view.fighter.character, view.fighter.character.costumes[costume_index])
	return view


func _free_view(view: FighterView) -> void:
	view.runner.free()
	view.free()


func test_temporary_hood_and_cloak_are_removed_after_the_intro_or_skip() -> void:
	for skip in [false, true]:
		var view: FighterView = _view()
		view._update_intro()
		assert_true(view.rig._intro_hood != null and view.rig._intro_hood.visible)
		assert_true(view.rig._intro_cloak != null and view.rig._intro_cloak.visible)
		view.runner.sim.phase_ticks = view.runner.sim.intro_title_tick() if skip else Ticks.from_seconds(view.runner.sim.config.match_intro)
		view.runner.sim.phase = MatchSimulation.Phase.INTRO if skip else MatchSimulation.Phase.FIGHT
		view._update_intro()
		assert_true(view.rig._intro_hood == null)
		assert_true(view.rig._intro_cloak == null)
		_free_view(view)


func test_intro_preserves_hood_and_cape_that_belong_to_the_costume() -> void:
	for index in range(1, 3):
		var view: FighterView = _view(index)
		var parts: PackedStringArray = view.rig.visible_parts.duplicate()
		var cloth_count: int = view.rig._cloths.size()
		view._update_intro()
		view.runner.sim.phase_ticks = view.runner.sim.intro_title_tick()
		view._update_intro()
		assert_eq(view.rig.visible_parts, parts)
		assert_eq(view.rig._cloths.size(), cloth_count)
		for cloth in view.rig._cloths:
			assert_false(cloth.released)
		_free_view(view)


func test_reaper_ignites_one_tip_before_the_other_and_lowers_hood_in_steps() -> void:
	var view: FighterView = _view()
	view._update_intro()
	for cloth in view.rig._cloths:
		cloth.simulate(Vector2.ZERO, 0.0, 1, Ticks.DELTA)
	var intro: IntroData = view.fighter.character.intro
	view.runner.sim.phase_ticks = Ticks.from_seconds(intro.hood_down_at + EFFECTS.hood_lower_time * 0.5)
	view._update_intro()
	assert_true(view.rig._intro_hood.visible)
	assert_gt((view.rig._intro_hood.offset + view.rig.art.pivot("hood")).length(), 0.0)
	view.runner.sim.phase_ticks = Ticks.from_seconds(intro.ignite_at + EFFECTS.ignition * 0.5)
	view._update_intro()
	assert_gt(view._ignition, 0.0)
	assert_almost(view._second_ignition, 0.0)
	assert_false(view.rig._intro_hood.visible)
	view.runner.sim.phase_ticks = Ticks.from_seconds(intro.second_ignition() + EFFECTS.ignition)
	view._update_intro()
	assert_almost(view._ignition, 1.0)
	assert_almost(view._second_ignition, 1.0)
	assert_true(view.rig._intro_cloak.released)
	_free_view(view)
