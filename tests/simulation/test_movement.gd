extends TestCase

var duel: DuelFixture


func before_each() -> void:
	duel = DuelFixture.create()
	duel.skip_intro()


func test_round_starts_with_configured_distance() -> void:
	var fresh: DuelFixture = DuelFixture.create()
	assert_almost(fresh.fighter(1).x - fresh.fighter(0).x, DuelFixture.CONFIG.round_start_distance)
	assert_eq(fresh.fighter(0).facing, 1)
	assert_eq(fresh.fighter(1).facing, -1)


func test_controls_are_locked_during_intro() -> void:
	var fresh: DuelFixture = DuelFixture.create()
	var start_x: float = fresh.fighter(0).x
	fresh.intents[0].move_x = 1
	fresh.step(10)
	assert_eq(fresh.sim.phase, MatchSimulation.Phase.INTRO)
	assert_almost(fresh.fighter(0).x, start_x)


func test_walk_accelerates_to_walk_speed() -> void:
	duel.intents[0].move_x = 1
	duel.step(1)
	assert_lt(duel.fighter(0).vx, duel.fighter(0).walk_speed, "acceleration takes time")
	duel.step(20)
	assert_almost(duel.fighter(0).vx, duel.fighter(0).walk_speed)
	assert_eq(duel.fighter(0).state, FighterState.State.WALKING)


func test_walking_backward_is_slower() -> void:
	duel.intents[0].move_x = -1
	duel.step(30)
	var expected: float = -duel.fighter(0).walk_speed * DuelFixture.CONFIG.back_walk_ratio
	assert_almost(duel.fighter(0).vx, expected)


func test_jump_lands_back_on_ground() -> void:
	duel.press(0, Intent.Command.JUMP)
	duel.step(1)
	assert_eq(duel.fighter(0).state, FighterState.State.JUMPING)
	assert_false(duel.fighter(0).on_ground)
	var landed: bool = duel.step_until(func() -> bool: return duel.fighter(0).on_ground, 120)
	assert_true(landed)
	assert_eq(duel.fighter(0).state, FighterState.State.IDLE)
	assert_eq(duel.count_events(CombatEvent.Type.LAND), 1)


func test_double_jump_once_per_jump() -> void:
	duel.press(0, Intent.Command.JUMP)
	duel.step(10)
	var before: float = duel.fighter(0).vy
	duel.press(0, Intent.Command.JUMP)
	duel.step(1)
	assert_gt(duel.fighter(0).vy, before)
	assert_eq(duel.fighter(0).jumps_used, 2)
	duel.press(0, Intent.Command.JUMP)
	duel.step(1)
	assert_eq(duel.fighter(0).jumps_used, 2, "third jump is not allowed")


func test_bodies_do_not_overlap() -> void:
	duel.place(0.0)
	duel.intents[0].move_x = 1
	duel.step(60)
	var gap: float = duel.fighter(1).x - duel.fighter(0).x
	assert_true(gap >= DuelFixture.CONFIG.body_width - 0.01, "gap %f" % gap)


func test_walls_hold_fighters_inside_arena() -> void:
	duel.intents[0].move_x = -1
	duel.step(400)
	var limit: float = DuelFixture.CONFIG.half_width() - DuelFixture.CONFIG.body_width * 0.5
	assert_almost(duel.fighter(0).x, -limit)


func test_fighters_turn_to_face_each_other_on_ground() -> void:
	duel.fighter(0).x = 200.0
	duel.fighter(1).x = -200.0
	duel.step(1)
	assert_eq(duel.fighter(0).facing, -1)
	assert_eq(duel.fighter(1).facing, 1)
