extends TestCase

var duel: DuelFixture


func before_each() -> void:
	duel = DuelFixture.create()
	duel.skip_intro()


func _start_blade_lock() -> void:
	duel.place(50.0)
	duel.press(0, Intent.Command.HEAVY)
	duel.press(1, Intent.Command.HEAVY)
	duel.step_until(func() -> bool: return BladeLockResolver.is_active(duel.sim), 40)


func test_light_clash_cancels_both_hits() -> void:
	duel.place(100.0)
	var health_a: float = duel.fighter(0).health
	var health_b: float = duel.fighter(1).health
	duel.press(0, Intent.Command.LIGHT)
	duel.press(1, Intent.Command.LIGHT)
	duel.step(12)
	assert_eq(duel.count_events(CombatEvent.Type.CLASH), 1)
	assert_false(duel.last_event(CombatEvent.Type.CLASH)["heavy"])
	assert_almost(duel.fighter(0).health, health_a)
	assert_almost(duel.fighter(1).health, health_b)
	assert_true(duel.fighter(0).move_connected, "the sequence may continue")


func test_heavy_clash_cancels_and_recoils() -> void:
	duel.place(100.0)
	duel.press(0, Intent.Command.HEAVY)
	duel.step(1)
	duel.step(DuelFixture.GUARDIAN.heavy.startup_ticks() - DuelFixture.SHADOW.light_chain[0].startup_ticks() - 1)
	duel.press(1, Intent.Command.LIGHT)
	duel.step_until(func() -> bool: return duel.count_events(CombatEvent.Type.CLASH) > 0, 20)
	assert_true(duel.last_event(CombatEvent.Type.CLASH)["heavy"])
	assert_eq(duel.fighter(0).state, FighterState.State.HIT)
	assert_eq(duel.fighter(1).state, FighterState.State.HIT)
	assert_almost(duel.fighter(0).health, duel.fighter(0).max_health)


func test_heavy_against_heavy_starts_blade_lock() -> void:
	_start_blade_lock()
	assert_true(BladeLockResolver.is_active(duel.sim))
	assert_eq(duel.count_events(CombatEvent.Type.BLADE_LOCK_STARTED), 1)
	assert_almost(duel.fighter(1).x - duel.fighter(0).x, DuelFixture.CONFIG.blade_lock.center_distance)


func test_blade_lock_won_by_pressure() -> void:
	_start_blade_lock()
	var loser_health: float = duel.fighter(1).health
	var loser_vigor: float = duel.fighter(1).vigor
	for i in 60:
		if i % 5 == 0:
			duel.press(0, Intent.Command.LIGHT)
		duel.step(1)
		if not BladeLockResolver.is_active(duel.sim):
			break
	var ended: Dictionary = duel.last_event(CombatEvent.Type.BLADE_LOCK_ENDED)
	assert_eq(ended.get("source"), 0)
	assert_almost(duel.fighter(1).health, loser_health - 8.0)
	assert_almost(duel.fighter(1).vigor, loser_vigor - 35.0, 0.5)
	assert_eq(duel.fighter(1).state, FighterState.State.STAGGERED)
	assert_eq(duel.fighter(0).state, FighterState.State.ATTACKING)


func test_blade_lock_presses_are_rate_limited() -> void:
	_start_blade_lock()
	duel.step_until(func() -> bool: return duel.fighter(0).freeze_ticks == 0, 20)
	for i in 12:
		duel.press(0, Intent.Command.LIGHT)
		duel.step(1)
	assert_eq(duel.fighter(0).lock_presses, 3, "15 presses per second at most")


func test_blade_lock_tie_only_separates() -> void:
	_start_blade_lock()
	duel.step_until(func() -> bool: return not BladeLockResolver.is_active(duel.sim), 300)
	var ended: Dictionary = duel.last_event(CombatEvent.Type.BLADE_LOCK_ENDED)
	assert_eq(ended.get("source"), CombatEvent.NO_FIGHTER)
	assert_almost(duel.fighter(1).health, duel.fighter(1).max_health)
	duel.step(30)
	assert_gt(duel.fighter(1).x - duel.fighter(0).x, 300.0)


func test_hold_to_lock_counts_slower_presses() -> void:
	duel.fighter(1).hold_to_lock = true
	_start_blade_lock()
	duel.step_until(func() -> bool: return duel.fighter(1).freeze_ticks == 0, 20)
	duel.hold(1, Intent.Command.LIGHT)
	duel.step(45)
	assert_eq(duel.fighter(1).lock_presses, 4)


func test_blade_lock_has_cooldown() -> void:
	_start_blade_lock()
	duel.step_until(func() -> bool: return not BladeLockResolver.is_active(duel.sim), 300)
	assert_gt(duel.sim.lock_cooldown_ticks, 0)


func test_staggered_heavies_lock_within_the_clash_window() -> void:
	var window: int = Ticks.from_seconds(DuelFixture.CONFIG.clash_window)
	for delay in range(1, window + 1):
		for side in 2:
			var fixture: DuelFixture = DuelFixture.create()
			fixture.skip_intro()
			fixture.place(40.0)
			fixture.press(side, Intent.Command.HEAVY)
			fixture.step(delay)
			fixture.press(1 - side, Intent.Command.HEAVY)
			assert_true(fixture.step_until(func() -> bool: return BladeLockResolver.is_active(fixture.sim), 35), "delay %d side %d" % [delay, side])
			assert_eq(fixture.count_events(CombatEvent.Type.BLADE_LOCK_STARTED), 1)
			assert_eq(fixture.count_events(CombatEvent.Type.HIT), 0)
			for fighter in fixture.sim.fighters:
				assert_almost(fighter.health, fighter.max_health)
			fixture.step(20)
			assert_eq(fixture.count_events(CombatEvent.Type.BLADE_LOCK_STARTED), 1)


func test_faster_heavy_hits_just_outside_the_clash_window() -> void:
	duel.place(20.0)
	duel.press(0, Intent.Command.HEAVY)
	duel.step(Ticks.from_seconds(duel.sim.config.clash_window) + 1)
	duel.press(1, Intent.Command.HEAVY)
	duel.step(50)
	assert_eq(duel.count_events(CombatEvent.Type.BLADE_LOCK_STARTED), 0)
	assert_eq(duel.count_events(CombatEvent.Type.CLASH), 0)
	assert_eq(duel.count_events(CombatEvent.Type.HIT), 1)
	assert_eq(duel.last_event(CombatEvent.Type.HIT)["source"], 0)


func test_staggered_lights_cancel_without_delayed_active_hits() -> void:
	for delay in range(1, Ticks.from_seconds(DuelFixture.CONFIG.clash_window) + 1):
		var fixture: DuelFixture = DuelFixture.create()
		fixture.skip_intro()
		fixture.place(40.0)
		fixture.press(0, Intent.Command.LIGHT)
		fixture.step(delay)
		fixture.press(1, Intent.Command.LIGHT)
		assert_true(fixture.step_until(func() -> bool: return fixture.count_events(CombatEvent.Type.CLASH) > 0, 20))
		for fighter in fixture.sim.fighters:
			assert_true(fighter.move_hit_done and fighter.move_connected)
			assert_eq(fighter.move_phase, FighterState.Phase.RECOVERY)
		fixture.step(40)
		assert_eq(fixture.count_events(CombatEvent.Type.CLASH), 1)
		assert_eq(fixture.count_events(CombatEvent.Type.HIT), 0)


func test_active_heavy_catches_a_light_in_late_startup() -> void:
	duel.place(40.0)
	duel.press(0, Intent.Command.HEAVY)
	duel.step(DuelFixture.GUARDIAN.heavy.startup_ticks() - DuelFixture.SHADOW.light_chain[0].startup_ticks() + 2)
	duel.press(1, Intent.Command.LIGHT)
	duel.step(30)
	assert_eq(duel.count_events(CombatEvent.Type.CLASH), 1)
	assert_true(duel.last_event(CombatEvent.Type.CLASH)["heavy"])
	assert_eq(duel.count_events(CombatEvent.Type.HIT), 0)


func test_two_late_startups_do_not_clash() -> void:
	duel.place(20.0)
	duel.press(0, Intent.Command.HEAVY)
	duel.press(1, Intent.Command.HEAVY)
	duel.step(DuelFixture.GUARDIAN.heavy.startup_ticks() - 1)
	assert_eq(duel.fighter(0).move_phase, FighterState.Phase.STARTUP)
	assert_eq(duel.fighter(1).move_phase, FighterState.Phase.STARTUP)
	assert_eq(duel.count_events(CombatEvent.Type.CLASH), 0)
	assert_eq(duel.count_events(CombatEvent.Type.BLADE_LOCK_STARTED), 0)


func test_late_startup_technique_clash_cancels_both_moves() -> void:
	duel.place(40.0)
	var move: MoveData = load("res://data/techniques/rising_cut.tres")
	ActionStarter.start_attack(duel.sim, duel.fighter(0), move)
	duel.step(2)
	ActionStarter.start_attack(duel.sim, duel.fighter(1), move)
	assert_true(duel.step_until(func() -> bool: return duel.count_events(CombatEvent.Type.TECHNIQUE_CLASH) > 0, 35))
	for fighter in duel.sim.fighters:
		assert_eq(fighter.state, FighterState.State.STAGGERED)
		assert_true(fighter.move == null)
	duel.step(60)
	assert_eq(duel.count_events(CombatEvent.Type.HIT), 0)
	assert_eq(duel.count_events(CombatEvent.Type.TECHNIQUE_CLASH), 1)
