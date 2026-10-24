extends TestCase

var duel: DuelFixture


func before_each() -> void:
	duel = DuelFixture.versus(&"guardian", &"shadow")


func _spin(index: int = 0) -> void:
	duel.intents[index].move_x = duel.fighter(index).facing
	duel.press(index, Intent.Command.DODGE)
	duel.step(1)
	duel.intents[index].move_x = 0


func test_forward_dodge_up_close_spins_through_and_swaps_sides() -> void:
	duel.place(30.0)
	var vigor: float = duel.fighter(0).vigor
	_spin()
	assert_eq(duel.fighter(0).dodge_kind, FighterState.DodgeKind.SPIN)
	assert_almost(vigor - duel.fighter(0).vigor, duel.sim.config.spin_dodge_vigor, 0.01)
	duel.step(Ticks.from_seconds(duel.sim.config.spin_dodge_duration))
	assert_gt(duel.fighter(0).x, duel.fighter(1).x, "the dodger ends on the other side")
	assert_eq(duel.fighter(0).facing, -1, "and lands facing the opponent")
	assert_eq(duel.fighter(0).state, FighterState.State.IDLE)
	duel.step(1)
	assert_eq(duel.fighter(1).facing, 1, "the opponent simply turns around")


func test_far_forward_dodge_stays_a_dash() -> void:
	duel.place(duel.sim.config.spin_dodge_range + 40.0)
	_spin()
	assert_eq(duel.fighter(0).dodge_kind, FighterState.DodgeKind.GROUND)


func test_no_room_behind_the_opponent_falls_back_to_a_forward_dodge() -> void:
	var limit: float = duel.sim.config.half_width() - duel.sim.config.body_width * 0.5
	duel.fighter(1).x = limit
	duel.fighter(0).x = limit - duel.sim.config.body_width - 20.0
	_spin()
	assert_eq(duel.fighter(0).dodge_kind, FighterState.DodgeKind.GROUND)
	assert_eq(duel.fighter(0).dodge_direction, 1)


func test_invulnerable_only_in_the_middle_of_the_spin() -> void:
	var config: CombatConfig = duel.sim.config
	duel.place(30.0)
	_spin()
	assert_false(duel.fighter(0).is_invulnerable(), "the opening frames are exposed")
	duel.step(Ticks.from_seconds(config.spin_dodge_invulnerable_start))
	assert_true(duel.fighter(0).is_invulnerable())
	duel.step(Ticks.from_seconds(config.spin_dodge_invulnerable_end - config.spin_dodge_invulnerable_start))
	assert_false(duel.fighter(0).is_invulnerable(), "the end of the spin is exposed")


func test_recovery_of_the_spin_can_be_punished() -> void:
	var config: CombatConfig = duel.sim.config
	duel.place(30.0)
	_spin()
	duel.step(DodgeState.spin_travel_ticks(config))
	assert_eq(duel.fighter(0).state, FighterState.State.DODGING)
	duel.fighter(1).facing = 1
	duel.press(1, Intent.Command.LIGHT)
	var hit: bool = duel.step_until(func() -> bool: return duel.count_events(CombatEvent.Type.HIT) > 0, 20)
	assert_true(hit)
