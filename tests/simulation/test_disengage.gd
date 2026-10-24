extends TestCase

var duel: DuelFixture


func before_each() -> void:
	duel = DuelFixture.versus(&"guardian", &"shadow")
	duel.place(40.0)
	BladeLockResolver.start(duel.sim, duel.fighter(0), duel.fighter(1))
	duel.step_until(func() -> bool: return duel.fighter(0).freeze_ticks == 0, 20)


func _lock() -> BladeLockConfig:
	return duel.sim.config.blade_lock


func test_heavy_before_half_a_second_does_nothing() -> void:
	duel.press(0, Intent.Command.HEAVY)
	duel.step(1)
	assert_true(BladeLockResolver.is_active(duel.sim))
	assert_eq(duel.count_events(CombatEvent.Type.DISENGAGE), 0)


func test_disengage_ends_the_lock_without_a_winner_and_cuts() -> void:
	duel.step(Ticks.from_seconds(_lock().disengage_after))
	var vigor: float = duel.fighter(0).vigor
	var gap: float = CombatGeometry.gap(duel.sim.config, duel.fighter(0), duel.fighter(1))
	duel.press(0, Intent.Command.HEAVY)
	duel.step(1)
	assert_false(BladeLockResolver.is_active(duel.sim))
	assert_eq(duel.count_events(CombatEvent.Type.DISENGAGE), 1)
	assert_eq(duel.count_events(CombatEvent.Type.BLADE_LOCK_ENDED), 0)
	assert_eq(duel.fighter(0).move.id, &"disengage")
	assert_almost(vigor - duel.fighter(0).vigor, BladeLockConfig.DISENGAGE_MOVE.vigor_cost, 0.01)
	assert_eq(duel.fighter(1).state, FighterState.State.HIT)
	assert_gt(duel.sim.lock_cooldown_ticks, 0)
	duel.step(20)
	assert_eq(duel.count_events(CombatEvent.Type.HIT), 1, "an idle rival takes the cut")
	assert_lt(CombatGeometry.gap(duel.sim.config, duel.fighter(0), duel.fighter(1)), gap + _lock().disengage_separation + 40.0)


func test_rival_can_parry_the_disengage_like_a_light() -> void:
	duel.step(Ticks.from_seconds(_lock().disengage_after))
	duel.press(0, Intent.Command.HEAVY)
	duel.step(1)
	duel.press(1, Intent.Command.BLOCK)
	duel.step(15)
	assert_eq(duel.count_events(CombatEvent.Type.PARRY), 1)
	assert_eq(duel.count_events(CombatEvent.Type.HIT), 0)


func test_disengage_does_not_chain() -> void:
	duel.step(Ticks.from_seconds(_lock().disengage_after))
	duel.press(0, Intent.Command.HEAVY)
	duel.step(10)
	duel.press(0, Intent.Command.LIGHT)
	duel.step(4)
	assert_ne(duel.fighter(0).move.kind if duel.fighter(0).move != null else MoveData.Kind.DISENGAGE, MoveData.Kind.LIGHT)


func test_disengage_needs_vigor() -> void:
	duel.step(Ticks.from_seconds(_lock().disengage_after))
	duel.fighter(0).vigor = 5.0
	duel.press(0, Intent.Command.HEAVY)
	duel.step(1)
	assert_true(BladeLockResolver.is_active(duel.sim))
	assert_eq(duel.count_events(CombatEvent.Type.ACTION_REJECTED), 1)


func test_disengage_also_breaks_a_blade_press() -> void:
	var press: DuelFixture = DuelFixture.versus(&"guardian", &"shadow")
	press.place(30.0)
	BladeLockResolver.start(press.sim, press.fighter(0), press.fighter(1), true)
	press.step(Ticks.from_seconds(_lock().disengage_after) + 6)
	press.press(1, Intent.Command.HEAVY)
	press.step(1)
	assert_eq(press.count_events(CombatEvent.Type.DISENGAGE), 1)
	assert_eq(press.fighter(1).move.id, &"disengage")
