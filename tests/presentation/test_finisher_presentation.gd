extends TestCase


func _rig() -> FighterRig:
	var data: CharacterData = DuelFixture.SHADOW
	var rig: FighterRig = FighterRig.new()
	rig.build(data, data.costumes[0])
	return rig


func test_prosthetic_limbs_switch_material_and_clear() -> void:
	var rig: FighterRig = _rig()
	rig.set_prosthetic(MoveData.Limb.ARM, true)
	var metal: int = 0
	for key in rig._sprites:
		if rig._sprites[key].material == rig.prosthetic_material:
			metal += 1
			assert_true(String(key).contains("_front:"), "only the lost side turns metal: %s" % key)
	assert_gt(metal, 0)
	rig.clear_prosthetics()
	for key in rig._sprites:
		assert_true(rig._sprites[key].material == rig.shader_material)
	rig.free()


func test_clip_reaches_both_materials() -> void:
	var rig: FighterRig = _rig()
	rig.set_clip(true, Vector2(1.0, 2.0), Vector2.UP)
	assert_true(rig.shader_material.get_shader_parameter(&"clip_enabled"))
	assert_true(rig.prosthetic_material.get_shader_parameter(&"clip_enabled"))
	assert_eq(rig.prosthetic_material.get_shader_parameter(&"clip_normal"), Vector2.UP)
	rig.free()


func test_finisher_kinds_choose_how_the_body_moves() -> void:
	var player: FinisherPlayer = FinisherPlayer.new()
	player.config = load("res://data/balance/effects_config.tres")
	for kind in [Finisher.Kind.DASH_THROUGH, Finisher.Kind.WAIST, Finisher.Kind.VERTICAL, Finisher.Kind.DIAGONAL, Finisher.Kind.PULL_CUT]:
		player.kind = kind
		assert_true(player.is_split(), "kind %d splits the body" % kind)
		assert_true(player.moves_body())
	player.kind = Finisher.Kind.BLAST
	assert_false(player.is_split())
	assert_true(player.moves_body())
	player.kind = Finisher.Kind.CHARRED
	assert_false(player.moves_body())
	assert_gt(player.fall_delay(), 0.0, "the x-ray plays before the charred body falls")
	player.free()


func test_cleared_finisher_stops_drawing_the_cut() -> void:
	var player: FinisherPlayer = FinisherPlayer.new()
	player.rig = _rig()
	player.kind = Finisher.Kind.WAIST
	player.clear()
	assert_false(player.is_split(), "the queued player no longer draws the freed half")
	player.rig.free()


func test_rig_keeps_every_severed_part() -> void:
	var rig: FighterRig = _rig()
	rig.sever(MoveData.Limb.ARM, true)
	rig.sever(MoveData.Limb.ARM, false)
	rig.sever(MoveData.Limb.HEAD, true)
	assert_true(rig.lost_main_hand())
	for key in rig._sprites:
		var name: String = String(key)
		if name.begins_with("forearm_") or name.begins_with("hand_") or name.begins_with("head:"):
			assert_false(rig._sprites[key].visible, "%s stays hidden after later cuts" % name)
	rig.restore()
	assert_false(rig.lost_main_hand())
	rig.free()


func test_staged_kinds_play_their_motion_and_fall_forward() -> void:
	var player: FinisherPlayer = FinisherPlayer.new()
	player.config = load("res://data/balance/effects_config.tres")
	for kind in Finisher.STAGED:
		var motion: FinisherMotion = FinisherMotion.for_kind(kind)
		assert_true(motion != null and not motion.keys.is_empty(), "kind %d has a motion" % kind)
		player.kind = kind
		player._motion = motion
		assert_eq(player.fall_limb(), MoveData.Limb.HEAD, "kind %d kneels and falls forward" % kind)
		assert_eq(player.fall_delay(), motion.fall_at)
		for key_index in range(1, motion.keys.size()):
			assert_gt(motion.keys[key_index].time, motion.keys[key_index - 1].time, "kind %d keys in order" % kind)
	player.free()


func test_twin_blades_keep_their_stages_apart() -> void:
	var motion: FinisherMotion = FinisherMotion.for_kind(Finisher.Kind.TWIN_BLADES)
	assert_true(motion.drops_hilt)
	assert_lt(motion.front_arm_at, motion.back_arm_at, "two separate cuts")
	assert_lt(motion.back_arm_at, motion.pull_at)
	assert_lt(motion.pull_at, motion.catch_at, "the hilt flies before it is caught")
	assert_lt(motion.catch_at, motion.head_at)
	assert_lt(motion.head_at, motion.kneel_at, "the body stands a moment after the cut")
	assert_lt(motion.head_at, motion.release_at)
	assert_true(motion.streaks_both)


func _motion_pose(id: StringName, kind: Finisher.Kind, at: float) -> RigPose:
	var data: CharacterData = DuelFixture.character(id)
	var fighter: FighterState = FighterState.new()
	fighter.setup(0, data, DuelFixture.CONFIG)
	var solver: PoseSolver = PoseSolver.new()
	solver.setup(data, data.art)
	solver.start_motion(FinisherMotion.for_kind(kind))
	var pose: RigPose = RigPose.new()
	while solver.motion_time >= 0.0 and solver.motion_time < at:
		solver.advance(Ticks.DELTA)
	solver.solve(fighter, fighter, pose)
	return pose


func test_execution_swing_ends_level_at_the_neck() -> void:
	var motion: FinisherMotion = FinisherMotion.for_kind(Finisher.Kind.EXECUTION)
	var pose: RigPose = _motion_pose(&"guardian", Finisher.Kind.EXECUTION, motion.head_at)
	assert_lt(absf(wrapf(pose.blade_angle, -180.0, 180.0)), 25.0, "blade level at the cut")
	assert_gt(ArmGeometry.to_body(pose.grip, pose).x, 20.0, "hand forward at the cut")


func test_scissors_and_twin_blades_close_in_an_x() -> void:
	for case in [[&"wasp", Finisher.Kind.SCISSORS], [&"guardian", Finisher.Kind.TWIN_BLADES]]:
		var motion: FinisherMotion = FinisherMotion.for_kind(case[1])
		var pose: RigPose = _motion_pose(case[0], case[1], motion.head_at)
		assert_gt(wrapf(pose.blade_angle, -180.0, 180.0), 5.0, "%s high blade comes down to the neck" % case[0])
		assert_lt(wrapf(pose.off_blade_angle, -180.0, 180.0), -5.0, "%s low blade comes up to the neck" % case[0])
		assert_eq(pose.hand_spacing, 0.0, "%s hands apart" % case[0])


func test_twin_blades_reach_out_with_an_open_hand_to_pull() -> void:
	var motion: FinisherMotion = FinisherMotion.for_kind(Finisher.Kind.TWIN_BLADES)
	var pose: RigPose = _motion_pose(&"guardian", Finisher.Kind.TWIN_BLADES, (motion.pull_at + motion.catch_at) * 0.5)
	assert_true(pose.open_hand)
	assert_gt(ArmGeometry.to_body(pose.off_hand, pose).x, 15.0, "free hand stretched toward the hilt")


func test_stab_holds_the_blade_level_through_the_chest() -> void:
	var pose: RigPose = _motion_pose(&"mirror", Finisher.Kind.STAB, 0.4)
	assert_lt(absf(wrapf(pose.blade_angle, -180.0, 180.0)), 10.0)
	assert_gt(ArmGeometry.to_body(pose.grip, pose).x, 10.0)


func test_motion_ends_and_hands_back_the_guard() -> void:
	var data: CharacterData = DuelFixture.character(&"guardian")
	var solver: PoseSolver = PoseSolver.new()
	solver.setup(data, data.art)
	var motion: FinisherMotion = FinisherMotion.for_kind(Finisher.Kind.TWIN_BLADES)
	solver.start_motion(motion)
	for tick in Ticks.from_seconds(motion.end_time()) + 2:
		solver.advance(Ticks.DELTA)
	assert_eq(solver.motion_time, -1.0)
	assert_true(solver.motion == null)
