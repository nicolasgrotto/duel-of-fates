extends TestCase


func _blocking_pose(attacker_move: MoveData) -> RigPose:
	var data: CharacterData = DuelFixture.GUARDIAN
	var defender: FighterState = FighterState.new()
	defender.setup(0, data, DuelFixture.CONFIG)
	defender.state = FighterState.State.BLOCKING
	var attacker: FighterState = FighterState.new()
	attacker.setup(1, DuelFixture.SHADOW, DuelFixture.CONFIG)
	attacker.state = FighterState.State.HEAVY_ATTACK if attacker_move.is_heavy() else FighterState.State.ATTACKING
	attacker.move = attacker_move
	attacker.move_phase = FighterState.Phase.STARTUP
	var solver: PoseSolver = PoseSolver.new()
	solver.setup(data, data.art)
	var pose: RigPose = RigPose.new()
	solver.solve(defender, attacker, pose)
	return pose


func test_guard_rises_against_cuts_from_above() -> void:
	var high: RigPose = _blocking_pose(DuelFixture.SHADOW.light_chain[0])
	var low: RigPose = _blocking_pose(DuelFixture.SHADOW.light_chain[1])
	assert_lt(high.grip.y, low.grip.y, "a descending cut is met higher than a rising one")


func test_thrusts_are_met_with_a_slanted_blade() -> void:
	var pose: RigPose = _blocking_pose(DuelFixture.SHADOW.light_chain[2])
	assert_almost(pose.blade_angle, DuelFixture.GUARDIAN.family.block_line_angles.z, 0.01)


func test_threat_line_reads_untyped_moves_by_their_arc() -> void:
	var counter: MoveData = load("res://data/characters/common/counter.tres")
	assert_eq(PoseSolver.threat_line(counter), MoveData.Cut.HORIZONTAL)
	var thrust: MoveData = load("res://data/techniques/thrust.tres")
	assert_eq(PoseSolver.threat_line(thrust), MoveData.Cut.THRUST)
