extends TestCase

const MAX_BOTH_SPREAD: float = 40.0


func _character(id: StringName) -> CharacterData:
	return DuelFixture.character(id)


func _fighter(data: CharacterData, move: MoveData, phase: FighterState.Phase, tick: int) -> FighterState:
	var fighter: FighterState = FighterState.new()
	fighter.setup(0, data, DuelFixture.CONFIG)
	fighter.state = FighterState.State.HEAVY_ATTACK if move.is_heavy() else FighterState.State.ATTACKING
	fighter.move = move
	fighter.move_phase = phase
	fighter.phase_ticks = tick
	fighter.chain_index = maxi(data.light_chain.find(move), 0)
	return fighter


func _pose(data: CharacterData, fighter: FighterState) -> RigPose:
	var solver: PoseSolver = PoseSolver.new()
	solver.setup(data, data.art)
	var pose: RigPose = RigPose.new()
	solver.solve(fighter, fighter, pose)
	return pose


func _spread(first: float, second: float) -> float:
	return absf(wrapf(first - second, -180.0, 180.0))


func test_wasp_chain_names_a_hand_for_every_step() -> void:
	var chain: Array[MoveData] = _character(&"wasp").light_chain
	var hands: Array[MoveData.BladeHand] = [MoveData.BladeHand.MAIN, MoveData.BladeHand.OFF, MoveData.BladeHand.MAIN, MoveData.BladeHand.OFF, MoveData.BladeHand.CROSS]
	for index in chain.size():
		assert_eq(chain[index].blade_hand, hands[index], String(chain[index].id))
	assert_eq(chain[4].cut, MoveData.Cut.SCISSOR)


func test_off_strike_moves_the_off_blade_and_rests_the_main() -> void:
	var data: CharacterData = _character(&"wasp")
	var move: MoveData = data.light_chain[1]
	var pose: RigPose = _pose(data, _fighter(data, move, FighterState.Phase.ACTIVE, 3))
	assert_true(pose.off_trail, "the off blade draws the arc")
	assert_false(pose.trail, "the main blade waits")


func test_wasp_heavy_swings_both_blades_together() -> void:
	var data: CharacterData = _character(&"wasp")
	for move in [data.heavy, data.forward_heavy]:
		assert_eq(move.blade_hand, MoveData.BladeHand.BOTH, String(move.id))
		for tick in move.active_ticks():
			var pose: RigPose = _pose(data, _fighter(data, move, FighterState.Phase.ACTIVE, tick))
			assert_lt(_spread(pose.blade_angle, pose.off_blade_angle), MAX_BOTH_SPREAD, "%s tick %d" % [move.id, tick])
			assert_true(pose.trail and pose.off_trail, "%s draws two trails" % move.id)


func test_scissor_closes_the_blades_from_opposite_sides() -> void:
	var data: CharacterData = _character(&"wasp")
	var move: MoveData = data.light_chain[4]
	var opened: RigPose = _pose(data, _fighter(data, move, FighterState.Phase.ACTIVE, 0))
	var closed: RigPose = _pose(data, _fighter(data, move, FighterState.Phase.ACTIVE, move.active_ticks() - 1))
	assert_gt(_spread(opened.blade_angle, opened.off_blade_angle), _spread(closed.blade_angle, closed.off_blade_angle), "the blades close")
	assert_lt(closed.grip.y, closed.off_hand.y, "the main comes from above and the off blade from below")


func test_single_blade_cast_ignores_the_hand_rules() -> void:
	var data: CharacterData = _character(&"echo")
	assert_eq(data.weapon.kind, WeaponData.Kind.SINGLE)
	for move in [data.heavy, data.forward_heavy]:
		var pose: RigPose = _pose(data, _fighter(data, move, FighterState.Phase.ACTIVE, 2))
		assert_false(pose.off_trail, "%s has no second blade to trail" % move.id)


func _guard_run(id: StringName, attacker_id: StringName, move_of: Callable, line_only: bool = false) -> PoseSolver:
	var data: CharacterData = _character(id)
	var attacker_data: CharacterData = _character(attacker_id)
	var defender: FighterState = FighterState.new()
	defender.setup(0, data, DuelFixture.CONFIG)
	defender.state = FighterState.State.BLOCKING
	var attacker: FighterState = _fighter(attacker_data, move_of.call(attacker_data), FighterState.Phase.STARTUP, 2)
	attacker.index = 1
	attacker.x = 80.0
	attacker.facing = -1
	var solver: PoseSolver = PoseSolver.new()
	solver.setup(data, data.art)
	var pose: RigPose = RigPose.new()
	solver.solve(defender, attacker, pose)
	solver.guard.observe_segment(Vector2(60.0, -70.0), Vector2(20.0, -40.0))
	for frame in 12:
		solver.advance(Ticks.DELTA)
		solver.solve(defender, attacker, pose)
	assert_true(solver.guard.active or line_only)
	return solver


func test_two_blades_cross_against_heavies() -> void:
	for id in [&"wasp", &"ember"]:
		var solver: PoseSolver = _guard_run(id, &"guardian", func(data: CharacterData) -> MoveData: return data.heavy)
		assert_eq(solver.guard_hand, PoseSolver.GuardHand.BOTH, String(id))


func test_wasp_guards_low_lines_with_the_rear_blade() -> void:
	var solver: PoseSolver = _guard_run(&"wasp", &"guardian", func(data: CharacterData) -> MoveData: return data.light_chain[1])
	assert_eq(solver.block_line, MoveData.Cut.RISING)
	assert_eq(solver.guard_hand, PoseSolver.GuardHand.OFF)


func test_wasp_alternates_blades_through_a_chain() -> void:
	var data: CharacterData = _character(&"wasp")
	var rival: CharacterData = _character(&"guardian")
	var solver: PoseSolver = PoseSolver.new()
	solver.setup(data, data.art)
	solver.block_line = MoveData.Cut.DESCENDING
	solver._choose_guard_hand(rival.light_chain[0])
	assert_eq(solver.guard_hand, PoseSolver.GuardHand.MAIN)
	solver.guard.configure(data.family)
	solver.guard_recoiled(false, false)
	solver._choose_guard_hand(data.light_chain[0])
	assert_eq(solver.guard_hand, PoseSolver.GuardHand.OFF)


func test_guard_hand_resets_when_the_guard_drops() -> void:
	var solver: PoseSolver = _guard_run(&"wasp", &"guardian", func(data: CharacterData) -> MoveData: return data.heavy)
	var data: CharacterData = _character(&"wasp")
	var idle: FighterState = FighterState.new()
	idle.setup(0, data, DuelFixture.CONFIG)
	idle.state = FighterState.State.IDLE
	var pose: RigPose = RigPose.new()
	solver.solve(idle, idle, pose)
	assert_eq(solver.guard_hand, PoseSolver.GuardHand.MAIN)
