extends TestCase

var duel: DuelFixture


func before_each() -> void:
	duel = DuelFixture.create()
	duel.skip_intro()


func test_light_hits_after_startup() -> void:
	duel.place(60.0)
	var health: float = duel.fighter(1).health
	duel.press(0, Intent.Command.LIGHT)
	duel.step(1)
	assert_eq(duel.fighter(0).state, FighterState.State.ATTACKING)
	assert_eq(duel.fighter(0).move_phase, FighterState.Phase.STARTUP)
	duel.step(5)
	assert_almost(duel.fighter(1).health, health, 0.001, "no damage during startup")
	duel.step(1)
	assert_almost(duel.fighter(1).health, health - 10.0)
	assert_eq(duel.fighter(1).state, FighterState.State.HIT)
	assert_eq(duel.count_events(CombatEvent.Type.HIT), 1)


func test_attack_costs_vigor() -> void:
	duel.press(0, Intent.Command.LIGHT)
	duel.step(1)
	assert_almost(duel.fighter(0).vigor, duel.fighter(0).max_vigor - 8.0)


func test_attack_without_vigor_is_rejected() -> void:
	duel.fighter(0).vigor = 5.0
	duel.press(0, Intent.Command.HEAVY)
	duel.step(1)
	assert_eq(duel.fighter(0).state, FighterState.State.IDLE)
	assert_eq(duel.count_events(CombatEvent.Type.ACTION_REJECTED), 1)
	assert_eq(duel.fighter(0).buffered_action, FighterState.Action.NONE, "rejected action leaves the buffer")


func test_hit_stop_freezes_both_fighters() -> void:
	duel.place(60.0)
	duel.press(0, Intent.Command.LIGHT)
	duel.step(7)
	var expected: int = Ticks.from_seconds(DuelFixture.CONFIG.hitstop_light)
	assert_eq(duel.fighter(0).freeze_ticks, expected)
	assert_eq(duel.fighter(1).freeze_ticks, expected)
	var x: float = duel.fighter(1).x
	duel.step(1)
	assert_almost(duel.fighter(1).x, x, 0.001, "frozen fighters do not move")


func test_chain_continues_after_connecting() -> void:
	duel.place(60.0)
	duel.press(0, Intent.Command.LIGHT)
	duel.step_until(func() -> bool: return duel.fighter(0).move_phase == FighterState.Phase.RECOVERY)
	duel.press(0, Intent.Command.LIGHT)
	duel.step(1)
	assert_eq(duel.fighter(0).chain_index, 1)
	assert_eq(duel.fighter(0).move.id, &"guardian_light_2")


func test_chain_does_not_continue_after_whiff() -> void:
	duel.place(400.0)
	duel.press(0, Intent.Command.LIGHT)
	duel.step_until(func() -> bool: return duel.fighter(0).move_phase == FighterState.Phase.RECOVERY)
	duel.press(0, Intent.Command.LIGHT)
	duel.step(1)
	assert_eq(duel.fighter(0).move.id, &"guardian_light_1")
	duel.step_until(func() -> bool: return duel.fighter(0).move_phase == FighterState.Phase.STARTUP)
	assert_eq(duel.fighter(0).chain_index, 0, "a whiffed light restarts the sequence")


func test_forward_heavy_needs_forward_direction() -> void:
	duel.intents[0].move_x = 1
	duel.press(0, Intent.Command.HEAVY)
	duel.step(1)
	assert_eq(duel.fighter(0).move.kind, MoveData.Kind.FORWARD_HEAVY)
	assert_eq(duel.fighter(0).state, FighterState.State.HEAVY_ATTACK)


func test_aerial_attack_once_per_jump() -> void:
	duel.press(0, Intent.Command.JUMP)
	duel.step(4)
	duel.press(0, Intent.Command.LIGHT)
	duel.step(1)
	assert_eq(duel.fighter(0).move.kind, MoveData.Kind.AERIAL_LIGHT)
	duel.step_until(func() -> bool: return duel.fighter(0).state == FighterState.State.JUMPING, 60)
	duel.press(0, Intent.Command.LIGHT)
	duel.step(1)
	assert_eq(duel.fighter(0).state, FighterState.State.JUMPING, "second aerial in the same jump is refused")


func test_aerial_hit_does_not_launch_target() -> void:
	duel.place(30.0)
	duel.press(0, Intent.Command.JUMP)
	duel.step(3)
	duel.press(0, Intent.Command.LIGHT)
	var hit: bool = duel.step_until(func() -> bool: return duel.count_events(CombatEvent.Type.HIT) > 0, 30)
	assert_true(hit)
	assert_true(duel.fighter(1).on_ground)
	assert_almost(duel.fighter(1).vy, 0.0)


func test_buffered_attack_comes_out_after_recovery() -> void:
	duel.place(400.0)
	duel.press(0, Intent.Command.HEAVY)
	duel.step(1)
	var total: int = duel.fighter(0).move.total_ticks()
	duel.step(total - 5)
	duel.press(0, Intent.Command.LIGHT)
	duel.step(6)
	assert_eq(duel.fighter(0).state, FighterState.State.ATTACKING)
	assert_eq(duel.fighter(0).move.kind, MoveData.Kind.LIGHT)


func test_shadow_regains_vigor_on_hit() -> void:
	duel.place(60.0)
	duel.fighter(1).facing = -1
	duel.press(1, Intent.Command.LIGHT)
	duel.step(1)
	var after_cost: float = duel.fighter(1).vigor
	duel.step(6)
	assert_eq(duel.count_events(CombatEvent.Type.HIT), 1)
	assert_gt(duel.fighter(1).vigor, after_cost + 5.0)
