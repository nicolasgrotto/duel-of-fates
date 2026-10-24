extends TestCase

const ROOT: String = "res://data/characters"


func _characters() -> Array[CharacterData]:
	var characters: Array[CharacterData] = []
	for id in DirAccess.get_directories_at(ROOT):
		var path: String = "%s/%s/%s.tres" % [ROOT, id, id]
		if ResourceLoader.exists(path):
			var data: CharacterData = load(path)
			if data.art != null:
				characters.append(data)
	return characters


func _check_reach(data: CharacterData, pose: RigPose, context: String) -> void:
	var length: float = data.art.dim("upper_arm") + data.art.dim("forearm")
	var radius: float = length * lerpf(data.family.arm_reach, data.family.arm_extension, pose.arm_extension)
	for front in [true, false]:
		var hand: Vector2 = pose.grip if front else pose.off_hand
		var shoulder: Vector2 = ArmGeometry.shoulder(pose, data.art, front)
		assert_true(shoulder.distance_to(hand) <= radius + 0.01, "%s %s arm %s" % [data.id, context, front])
	if pose.hand_spacing > 0.0:
		var geometry: WeaponPose = WeaponPose.new()
		geometry.compute(data.weapon, pose)
		var nearest: Vector2 = Geometry2D.get_closest_point_to_segment(pose.off_hand, geometry.hilt_from, geometry.hilt_to)
		assert_true(nearest.distance_to(pose.off_hand) < 0.01, "%s %s back hand on hilt" % [data.id, context])


func test_all_moves_keep_both_hands_within_reach_through_every_phase() -> void:
	for data in _characters():
		var fighter: FighterState = FighterState.new()
		fighter.setup(0, data, DuelFixture.CONFIG)
		var solver: PoseSolver = PoseSolver.new()
		solver.setup(data, data.art)
		var pose: RigPose = RigPose.new()
		var blended: RigPose = RigPose.new()
		solver.solve(fighter, fighter, blended)
		var moves: Array[MoveData] = data.light_chain.duplicate()
		moves.append_array([data.heavy, data.forward_heavy, data.counter, data.shove, data.aerial_light, data.aerial_heavy, data.technique_forward, data.technique_back, data.technique_air, BladeLockConfig.DISENGAGE_MOVE])
		if data.ability != null:
			moves.append(data.ability.move)
		for move in moves:
			if move == null:
				continue
			fighter.move = move
			fighter.chain_index = maxi(data.light_chain.find(move), 0)
			fighter.state = FighterState.State.HEAVY_ATTACK if move.is_heavy() else FighterState.State.ATTACKING
			fighter.on_ground = not move.is_aerial()
			for phase in [FighterState.Phase.STARTUP, FighterState.Phase.ACTIVE, FighterState.Phase.RECOVERY]:
				fighter.move_phase = phase
				var duration: int = move.startup_ticks() if phase == FighterState.Phase.STARTUP else move.active_ticks() if phase == FighterState.Phase.ACTIVE else move.recovery_ticks()
				for tick in duration:
					fighter.phase_ticks = tick
					solver.advance(Ticks.DELTA)
					solver.solve(fighter, fighter, pose)
					var context: String = "%s phase %d tick %d" % [move.id, phase, tick]
					_check_reach(data, pose, context)
					blended.blend_toward(pose, 0.35)
					ArmGeometry.constrain(blended, data)
					_check_reach(data, blended, "blended " + context)


func test_states_and_powers_keep_hands_reachable() -> void:
	for data in _characters():
		var fighter: FighterState = FighterState.new()
		fighter.setup(0, data, DuelFixture.CONFIG)
		var solver: PoseSolver = PoseSolver.new()
		solver.setup(data, data.art)
		var pose: RigPose = RigPose.new()
		for state in FighterState.State.values():
			fighter.state = state
			for tick in 24:
				fighter.state_ticks = tick
				solver.advance(Ticks.DELTA)
				solver.solve(fighter, fighter, pose)
				_check_reach(data, pose, "state %d tick %d" % [state, tick])
		for file in DirAccess.get_files_at("res://data/powers"):
			if not file.ends_with(".tres"):
				continue
			var power: PowerData = load("res://data/powers/" + file) as PowerData
			if power == null:
				continue
			fighter.power = power
			fighter.state = FighterState.State.CASTING
			for phase in [FighterState.Phase.STARTUP, FighterState.Phase.ACTIVE, FighterState.Phase.RECOVERY]:
				fighter.power_phase = phase
				for tick in 24:
					fighter.power_ticks = tick
					solver.solve(fighter, fighter, pose)
					_check_reach(data, pose, "power %s phase %d tick %d" % [power.id, phase, tick])


func test_compact_guard_elbows_stay_low_and_hands_touch_rendered_hilts() -> void:
	for data in _characters():
		var fighter: FighterState = FighterState.new()
		fighter.setup(0, data, DuelFixture.CONFIG)
		var solver: PoseSolver = PoseSolver.new()
		solver.setup(data, data.art)
		var pose: RigPose = RigPose.new()
		var rig: FighterRig = FighterRig.new()
		rig.build(data, data.costumes[0])
		for tick in 30:
			solver.advance(Ticks.DELTA)
			solver.solve(fighter, fighter, pose)
			rig.apply(pose, 1, 0.0)
			for front in [true, false]:
				var elbow: Vector2 = rig.front_elbow if front else rig.back_elbow
				var shoulder: Vector2 = ArmGeometry.shoulder(pose, data.art, front)
				if data.guard_angle > -100.0:
					assert_true((elbow - shoulder).rotated(-pose.torso_angle).y > 0.0, "%s compact guard elbow %s" % [data.id, front])
				var side: String = "front" if front else "back"
				var hand: Vector2 = pose.grip if front else pose.off_hand
				assert_true((rig._bones["hand_" + side] as Bone2D).position.distance_to(hand) < 0.01, "%s visible hand %s" % [data.id, front])
		rig.free()


func test_body_coordinates_follow_the_torso_without_moving_shoulders() -> void:
	var data: CharacterData = DuelFixture.GUARDIAN.duplicate()
	data.family = data.family.duplicate()
	var fighter: FighterState = FighterState.new()
	fighter.setup(0, data, DuelFixture.CONFIG)
	var solver: PoseSolver = PoseSolver.new()
	solver.setup(data, data.art)
	var pose: RigPose = RigPose.new()
	for lean in [-24.0, 0.0, 32.0]:
		data.family.lean = lean
		solver.solve(fighter, fighter, pose)
		assert_true(ArmGeometry.to_body(pose.grip, pose).distance_to(data.guard_grip) < 0.01, "hand follows body frame")


func test_shared_grip_survives_large_blended_blade_rotations() -> void:
	var data: CharacterData = DuelFixture.GUARDIAN
	var pose: RigPose = RigPose.new()
	pose.hand_spacing = data.family.back_hand_spacing
	pose.grip = Vector2(80.0, -180.0)
	for angle in range(-180, 181, 6):
		pose.blade_angle = angle
		ArmGeometry.constrain(pose, data)
		_check_reach(data, pose, "rotating hilt %d" % angle)
