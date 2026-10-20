extends TestCase

var duel: DuelFixture
var heavy_startup: int


func before_each() -> void:
	duel = DuelFixture.create()
	duel.skip_intro()
	duel.place(80.0)
	heavy_startup = DuelFixture.SHADOW.heavy.startup_ticks()


func _shadow_heavy_with_guard_tap(tap_before_active: int) -> void:
	duel.press(1, Intent.Command.HEAVY)
	duel.step(1)
	duel.step(heavy_startup - 1 - tap_before_active)
	duel.press(0, Intent.Command.BLOCK)
	duel.step(1)
	duel.step_until(func() -> bool: return duel.fighter(1).move_hit_done or not duel.fighter(1).is_attacking(), 30)


func test_held_guard_blocks_and_costs_vigor() -> void:
	duel.hold(0, Intent.Command.BLOCK)
	duel.step(1)
	assert_eq(duel.fighter(0).state, FighterState.State.BLOCKING)
	var health: float = duel.fighter(0).health
	duel.press(1, Intent.Command.HEAVY)
	duel.step(heavy_startup + 2)
	assert_eq(duel.count_events(CombatEvent.Type.BLOCK), 1)
	assert_almost(duel.fighter(0).health, health, 0.001, "no chip damage")
	var expected_cost: float = 30.0 * 0.8 / duel.fighter(0).defense_multiplier
	assert_almost(duel.fighter(0).vigor, duel.fighter(0).max_vigor - expected_cost, 0.5)


func test_guard_breaks_without_vigor() -> void:
	duel.hold(0, Intent.Command.BLOCK)
	duel.step(1)
	duel.fighter(0).vigor = 5.0
	duel.fighter(0).regen_delay_ticks = 600
	duel.press(1, Intent.Command.HEAVY)
	duel.step(heavy_startup + 2)
	assert_eq(duel.count_events(CombatEvent.Type.GUARD_BREAK), 1)
	assert_eq(duel.fighter(0).state, FighterState.State.STUNNED)
	assert_almost(duel.fighter(0).vigor, 0.0)


func test_guard_only_defends_from_the_front() -> void:
	duel.hold(0, Intent.Command.BLOCK)
	duel.step(1)
	duel.fighter(0).facing = -1
	duel.fighter(0).stun_ticks = 600
	duel.press(1, Intent.Command.HEAVY)
	duel.step(heavy_startup + 2)
	assert_eq(duel.count_events(CombatEvent.Type.HIT), 1)


func test_perfect_parry_staggers_heavy_attacker() -> void:
	_shadow_heavy_with_guard_tap(2)
	assert_eq(duel.count_events(CombatEvent.Type.PERFECT_PARRY), 1)
	assert_eq(duel.fighter(1).state, FighterState.State.STAGGERED)
	assert_true(duel.fighter(1).stagger_counterable)
	assert_almost(duel.fighter(0).vigor, duel.fighter(0).max_vigor, 0.01)
	var expected_loss: float = 24.0 + duel.sim.block_cost(duel.fighter(0), DuelFixture.SHADOW.heavy) * 2.0
	assert_almost(duel.fighter(1).vigor, duel.fighter(1).max_vigor - expected_loss, 0.5)


func test_counterattack_after_perfect_parry() -> void:
	_shadow_heavy_with_guard_tap(2)
	duel.release(0)
	duel.step_until(func() -> bool: return duel.fighter(0).freeze_ticks == 0 and duel.fighter(0).is_free(), 30)
	duel.press(0, Intent.Command.LIGHT)
	duel.step(1)
	assert_eq(duel.fighter(0).move.kind, MoveData.Kind.COUNTER)
	var health: float = duel.fighter(1).health
	duel.step(10)
	assert_almost(duel.fighter(1).health, health - 16.0)


func test_parry_sends_heavy_to_recovery() -> void:
	_shadow_heavy_with_guard_tap(8)
	assert_eq(duel.count_events(CombatEvent.Type.PARRY), 1)
	assert_eq(duel.fighter(1).move_phase, FighterState.Phase.RECOVERY)
	assert_almost(duel.fighter(0).vigor, duel.fighter(0).max_vigor, 0.01, "parry costs nothing")


func test_late_tap_is_just_a_guard() -> void:
	duel.press(0, Intent.Command.BLOCK)
	duel.step(1)
	duel.hold(0, Intent.Command.BLOCK)
	duel.press(1, Intent.Command.HEAVY)
	duel.step(heavy_startup + 2)
	assert_eq(duel.count_events(CombatEvent.Type.BLOCK), 1)
	assert_eq(duel.count_events(CombatEvent.Type.PARRY), 0)


func test_failed_parry_locks_new_windows() -> void:
	duel.press(0, Intent.Command.BLOCK)
	duel.step(1)
	duel.step(Ticks.from_seconds(DuelFixture.CONFIG.parry_window) + 1)
	assert_gt(duel.fighter(0).parry_lockout_ticks, 0)
	duel.press(0, Intent.Command.BLOCK)
	duel.step(1)
	assert_eq(duel.fighter(0).parry_ticks, FighterState.NO_PARRY)


func test_perfect_timing_against_light_counts_as_parry() -> void:
	duel.place(60.0)
	duel.press(1, Intent.Command.LIGHT)
	duel.step(4)
	duel.press(0, Intent.Command.BLOCK)
	duel.step(4)
	assert_eq(duel.count_events(CombatEvent.Type.PARRY), 1)
	assert_eq(duel.count_events(CombatEvent.Type.PERFECT_PARRY), 0)


func test_shove_goes_through_guard() -> void:
	duel.place(20.0)
	duel.hold(0, Intent.Command.BLOCK)
	duel.hold(1, Intent.Command.BLOCK)
	duel.step(1)
	duel.press(1, Intent.Command.LIGHT)
	duel.step(DuelFixture.SHADOW.shove.startup_ticks() + 2)
	assert_eq(duel.count_events(CombatEvent.Type.SHOVE), 1)
	assert_eq(duel.fighter(0).state, FighterState.State.STAGGERED)
	assert_almost(duel.fighter(0).vigor, duel.fighter(0).max_vigor - 20.0, 0.5)


func test_precision_evade_consumes_attack() -> void:
	duel.press(1, Intent.Command.HEAVY)
	duel.step(1)
	duel.step(heavy_startup - 3)
	duel.press(0, Intent.Command.EVADE)
	duel.step(4)
	assert_eq(duel.count_events(CombatEvent.Type.EVADE_SUCCESS), 1)
	assert_true(duel.fighter(0).is_free(), "free to punish right away")
	assert_eq(duel.fighter(0).evade_streak, 1)
	assert_almost(duel.fighter(0).vigor, duel.fighter(0).max_vigor, 0.01, "evade is free")


func test_dodge_is_invulnerable_at_start() -> void:
	duel.press(0, Intent.Command.DODGE)
	duel.step(1)
	assert_eq(duel.fighter(0).state, FighterState.State.DODGING)
	assert_gt(duel.fighter(0).invulnerable_ticks, 0)
	assert_lt(duel.fighter(0).vx, 0.0, "no direction dodges backward")
	assert_almost(duel.fighter(0).vigor, duel.fighter(0).max_vigor - DuelFixture.CONFIG.dodge_vigor)


func test_air_dash_once_per_jump() -> void:
	duel.press(0, Intent.Command.JUMP)
	duel.step(3)
	duel.press(0, Intent.Command.DODGE)
	duel.step(1)
	assert_true(duel.fighter(0).is_air_dashing())
	assert_gt(duel.fighter(0).vx, 0.0, "no direction dashes forward")
	duel.step_until(func() -> bool: return duel.fighter(0).state == FighterState.State.JUMPING, 30)
	duel.press(0, Intent.Command.DODGE)
	duel.step(1)
	assert_false(duel.fighter(0).is_air_dashing())
