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


func test_execution_kinds_kneel_and_fall_forward() -> void:
	var player: FinisherPlayer = FinisherPlayer.new()
	var effects: EffectsConfig = load("res://data/balance/effects_config.tres")
	player.config = effects
	for kind in [Finisher.Kind.EXECUTION, Finisher.Kind.SCISSORS, Finisher.Kind.STAB]:
		player.kind = kind
		assert_false(player.moves_body(), "kind %d keeps the body in place" % kind)
		assert_eq(player.fall_limb(), MoveData.Limb.HEAD, "kind %d kneels and falls forward" % kind)
	player.kind = Finisher.Kind.EXECUTION
	assert_eq(player.fall_delay(), effects.execution_cut, "the body falls once the head is off")
	player.kind = Finisher.Kind.STAB
	assert_eq(player.fall_delay(), effects.stab_hold + effects.stab_withdraw, "the body falls once the blade is out")
	player.free()


func _execution_pose(id: StringName, kind: Finisher.Kind, at: float) -> RigPose:
	var data: CharacterData = DuelFixture.character(id)
	var fighter: FighterState = FighterState.new()
	fighter.setup(0, data, DuelFixture.CONFIG)
	var solver: PoseSolver = PoseSolver.new()
	solver.setup(data, data.art)
	var effects: EffectsConfig = load("res://data/balance/effects_config.tres")
	solver.start_execution(kind, 62.0, effects)
	var pose: RigPose = RigPose.new()
	while solver.execution_time >= 0.0 and solver.execution_time < at:
		solver.advance(Ticks.DELTA)
	solver.solve(fighter, fighter, pose)
	return pose


func test_execution_swing_ends_level_at_the_neck() -> void:
	var effects: EffectsConfig = load("res://data/balance/effects_config.tres")
	var pose: RigPose = _execution_pose(&"guardian", Finisher.Kind.EXECUTION, effects.execution_cut)
	assert_lt(absf(rad_to_deg(pose.torso_angle) + pose.blade_angle - PoseSolver.EXECUTION_STRIKE_ANGLE), 25.0, "blade level at the cut")
	assert_gt(ArmGeometry.to_body(pose.grip, pose).x, 20.0, "hand forward at the cut")


func test_scissors_close_both_blades_in_an_x() -> void:
	var effects: EffectsConfig = load("res://data/balance/effects_config.tres")
	var pose: RigPose = _execution_pose(&"wasp", Finisher.Kind.SCISSORS, effects.execution_cut)
	assert_gt(wrapf(pose.blade_angle, -180.0, 180.0), 5.0, "the high blade comes down to the neck")
	assert_lt(wrapf(pose.off_blade_angle, -180.0, 180.0), -5.0, "the low blade comes up to the neck")


func test_stab_holds_the_blade_level_through_the_chest() -> void:
	var effects: EffectsConfig = load("res://data/balance/effects_config.tres")
	var pose: RigPose = _execution_pose(&"mirror", Finisher.Kind.STAB, effects.stab_hold * 0.5)
	assert_lt(absf(pose.blade_angle), 10.0)
	assert_gt(ArmGeometry.to_body(pose.grip, pose).x, PoseSolver.STAB_MIN_GRIP - 1.0)
