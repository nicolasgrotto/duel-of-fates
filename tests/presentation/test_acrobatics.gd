extends TestCase


func _pose(character: CharacterData, prepare: Callable) -> RigPose:
	var fighter: FighterState = FighterState.new()
	fighter.setup(0, character, DuelFixture.CONFIG)
	fighter.state = FighterState.State.STAGGERED
	var solver: PoseSolver = PoseSolver.new()
	solver.setup(character, character.art)
	prepare.call(solver, fighter)
	var pose: RigPose = RigPose.new()
	solver.solve(fighter, fighter, pose)
	return pose


func test_agile_families_backflip_out_of_long_separations() -> void:
	var wasp: CharacterData = DuelFixture.character(&"wasp")
	var pose: RigPose = _pose(wasp, func(solver: PoseSolver, _fighter: FighterState) -> void:
		solver.start_tumble()
		solver.advance(wasp.family.tumble_time * 0.5))
	assert_lt(pose.spin, -1.0, "mid backflip")


func test_heavy_families_skid_with_a_hand_on_the_floor() -> void:
	var bastion: CharacterData = DuelFixture.character(&"bastion")
	var resting: RigPose = _pose(bastion, func(_solver: PoseSolver, _fighter: FighterState) -> void: pass)
	var skidding: RigPose = _pose(bastion, func(solver: PoseSolver, _fighter: FighterState) -> void: solver.start_tumble())
	assert_eq(skidding.spin, 0.0)
	assert_gt(skidding.pelvis.y, resting.pelvis.y, "the body drops into the skid")
	assert_gt(skidding.off_hand.y, -4.0, "the free hand reaches the floor")


func test_vault_turns_the_body_halfway_over_the_opponent() -> void:
	var guardian: CharacterData = DuelFixture.GUARDIAN
	var solver: PoseSolver = PoseSolver.new()
	solver.setup(guardian, guardian.art)
	solver.vault_progress = 0.0
	solver.advance(guardian.family.vault_time * 0.6)
	assert_true(solver.is_vaulting())
	assert_true(solver.vault_turned())
