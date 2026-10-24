extends TestCase

var duel: DuelFixture


func before_each() -> void:
	duel = DuelFixture.versus(&"shadow", &"shadow")


func _trade_lights(ticks: int) -> void:
	for tick in ticks:
		if BladeLockResolver.is_active(duel.sim):
			return
		if duel.fighter(0).is_free() and duel.fighter(1).is_free():
			duel.place(30.0)
			duel.press(0, Intent.Command.LIGHT)
			duel.press(1, Intent.Command.LIGHT)
		duel.step(1)


func _parry_lights(ticks: int) -> void:
	for tick in ticks:
		if BladeLockResolver.is_active(duel.sim):
			return
		var attacker: FighterState = duel.fighter(1)
		if attacker.is_free() or (attacker.move != null and attacker.move_phase == FighterState.Phase.RECOVERY):
			duel.press(1, Intent.Command.LIGHT)
		if attacker.move != null and attacker.move_phase == FighterState.Phase.STARTUP and attacker.phase_ticks == 1:
			duel.press(0, Intent.Command.BLOCK)
		duel.step(1)


func test_three_light_clashes_open_a_blade_press() -> void:
	duel.place(30.0)
	_trade_lights(120)
	assert_eq(duel.count_events(CombatEvent.Type.BLADE_PRESS_STARTED), 1)
	assert_eq(duel.count_events(CombatEvent.Type.CLASH), 3)
	assert_true(duel.fighter(0).lock_press)
	assert_eq(duel.fighter(0).lock_presses, 0, "a press from clashes starts even")


func test_parrying_the_third_light_gives_one_press_of_advantage() -> void:
	duel.place(30.0)
	_parry_lights(200)
	assert_eq(duel.count_events(CombatEvent.Type.BLADE_PRESS_STARTED), 1)
	assert_eq(duel.fighter(0).lock_presses - duel.fighter(1).lock_presses, duel.sim.config.blade_lock.press_parry_advantage)


func test_press_is_short_and_won_by_three() -> void:
	var lock: BladeLockConfig = duel.sim.config.blade_lock
	duel.place(30.0)
	_trade_lights(120)
	assert_true(BladeLockResolver.is_active(duel.sim))
	duel.step_until(func() -> bool: return duel.fighter(0).freeze_ticks == 0, 20)
	var health: float = duel.fighter(1).health
	for press in lock.press_presses_to_win:
		duel.press(0, Intent.Command.LIGHT)
		duel.step(lock.press_interval_ticks())
	duel.step(2)
	assert_eq(duel.count_events(CombatEvent.Type.BLADE_PRESS_ENDED), 1)
	assert_eq(duel.last_event(CombatEvent.Type.BLADE_PRESS_ENDED)["source"], 0)
	assert_almost(health - duel.fighter(1).health, lock.press_loser_damage, 0.01)
	assert_eq(duel.fighter(1).state, FighterState.State.STAGGERED)
	assert_gt(duel.sim.lock_cooldown_ticks, 0, "the press shares the lock cooldown")


func test_press_times_out_into_a_plain_separation() -> void:
	duel.place(30.0)
	_trade_lights(120)
	duel.step(Ticks.from_seconds(duel.sim.config.blade_lock.press_max_duration) + 20)
	assert_eq(duel.count_events(CombatEvent.Type.BLADE_PRESS_ENDED), 1)
	assert_eq(duel.last_event(CombatEvent.Type.BLADE_PRESS_ENDED)["source"], CombatEvent.NO_FIGHTER)
	assert_eq(duel.fighter(1).health, duel.fighter(1).max_health)


func test_a_hit_resets_the_contact_count() -> void:
	duel.place(30.0)
	duel.sim.contact_streak = 2
	duel.sim.contact_idle_ticks = 0
	duel.press(0, Intent.Command.LIGHT)
	duel.step(10)
	assert_eq(duel.count_events(CombatEvent.Type.HIT), 1)
	assert_eq(duel.sim.contact_streak, 0)


func test_contacts_expire_after_the_window() -> void:
	duel.sim.contact_streak = 2
	duel.sim.contact_idle_ticks = 0
	duel.step(Ticks.from_seconds(duel.sim.config.blade_lock.press_contact_window) + 2)
	assert_eq(duel.sim.contact_streak, 0)
