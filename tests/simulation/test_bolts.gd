extends TestCase

const SHOT: MoveData = preload("res://data/training/dummy_shot.tres")
const BOLT: BoltData = preload("res://data/bolts/standard_bolt.tres")
const TRAINING: TrainingConfig = preload("res://data/balance/training_config.tres")
const GAP: float = 420.0


func _duel(shot: MoveData = SHOT) -> DuelFixture:
	var shooter: CharacterData = DuelFixture.character(&"guardian").duplicate() as CharacterData
	shooter.technique_forward = shot
	var cast: Array[CharacterData] = [shooter, DuelFixture.SHADOW]
	var duel: DuelFixture = DuelFixture.create(null, null, 7, cast)
	duel.skip_intro()
	duel.place(GAP)
	return duel


func _shoot(duel: DuelFixture) -> void:
	duel.intents[0].move_x = duel.fighter(0).facing
	duel.press(0, Intent.Command.SPECIAL)
	duel.step()
	duel.release(0)


func _bolt(duel: DuelFixture) -> Projectile:
	for projectile in duel.sim.projectiles:
		if projectile.active and projectile.kind == Projectile.Kind.BOLT:
			return projectile
	return null


func _arrival_tick() -> int:
	var dry: DuelFixture = _duel()
	_shoot(dry)
	dry.step_until(func() -> bool: return dry.count_events(CombatEvent.Type.BOLT_HIT) > 0, 120)
	return dry.last_event(CombatEvent.Type.BOLT_HIT)["tick"]


func _guard_with_tap(lead: int) -> DuelFixture:
	var arrival: int = _arrival_tick()
	var duel: DuelFixture = _duel()
	_shoot(duel)
	duel.step_until(func() -> bool: return duel.sim.tick >= arrival - lead - 1, 120)
	duel.press(1, Intent.Command.BLOCK)
	duel.hold(1, Intent.Command.BLOCK)
	duel.step(lead + 2)
	return duel


func test_bolt_flinches_an_idle_fighter_without_knockback() -> void:
	var duel: DuelFixture = _duel()
	var health: float = duel.fighter(1).health
	_shoot(duel)
	assert_true(duel.step_until(func() -> bool: return duel.count_events(CombatEvent.Type.BOLT_HIT) > 0, 120))
	assert_almost(duel.fighter(1).health, health - BOLT.damage)
	assert_eq(duel.fighter(1).state, FighterState.State.HIT)
	assert_true(duel.fighter(1).stun_ticks <= BOLT.flinch_ticks())
	assert_almost(duel.fighter(1).vx, 0.0)
	assert_true(_bolt(duel) == null, "the bolt ends on the hit")


func test_bolt_never_interrupts_an_attack() -> void:
	var arrival: int = _arrival_tick()
	var duel: DuelFixture = _duel()
	var health: float = duel.fighter(1).health
	_shoot(duel)
	duel.step_until(func() -> bool: return duel.sim.tick >= arrival - 6, 120)
	duel.press(1, Intent.Command.HEAVY)
	duel.step()
	duel.release(1)
	var heavy: MoveData = duel.fighter(1).move
	assert_true(heavy != null and duel.fighter(1).is_attacking())
	duel.step_until(func() -> bool: return duel.count_events(CombatEvent.Type.BOLT_HIT) > 0, 30)
	assert_almost(duel.fighter(1).health, health - BOLT.damage)
	assert_true(duel.fighter(1).is_attacking(), "the attack goes on")
	assert_eq(duel.fighter(1).move, heavy)


func test_facing_guard_blocks_with_vigor_and_back_guard_does_not() -> void:
	var duel: DuelFixture = _duel()
	duel.hold(1, Intent.Command.BLOCK)
	duel.step(20)
	var health: float = duel.fighter(1).health
	var vigor: float = duel.fighter(1).vigor
	duel.intents[0].move_x = duel.fighter(0).facing
	duel.press(0, Intent.Command.SPECIAL)
	duel.step()
	duel.intents[0].clear()
	assert_true(duel.step_until(func() -> bool: return duel.count_events(CombatEvent.Type.BOLT_BLOCKED) > 0, 120))
	assert_almost(duel.fighter(1).health, health)
	assert_almost(duel.fighter(1).vigor, vigor - BOLT.guard_vigor, 0.5)
	var behind: DuelFixture = _duel()
	behind.hold(1, Intent.Command.BLOCK)
	behind.step(20)
	var back_health: float = behind.fighter(1).health
	BoltResolver.fire(behind.sim, behind.fighter(0), BOLT)
	var bolt: Projectile = _bolt(behind)
	bolt.x = behind.fighter(1).x + 200.0
	bolt.vx = -BOLT.speed
	assert_true(behind.step_until(func() -> bool: return behind.count_events(CombatEvent.Type.BOLT_HIT) > 0, 60), "a guard does not cover the back")
	assert_almost(behind.fighter(1).health, back_health - BOLT.damage)


func test_parry_sends_the_bolt_back_along_its_line() -> void:
	var duel: DuelFixture = _guard_with_tap(8)
	var event: Dictionary = duel.last_event(CombatEvent.Type.BOLT_REFLECTED)
	assert_false(event.is_empty(), "the parry reflects")
	assert_almost(event["amount"], 0.0)
	var bolt: Projectile = _bolt(duel)
	assert_true(bolt != null)
	assert_eq(bolt.owner, 1)
	assert_lt(bolt.vx, 0.0)
	assert_almost(bolt.vy, 0.0)


func test_perfect_parry_aims_the_bolt_at_the_shooter_and_it_hurts() -> void:
	var duel: DuelFixture = _guard_with_tap(1)
	var event: Dictionary = duel.last_event(CombatEvent.Type.BOLT_REFLECTED)
	assert_false(event.is_empty(), "the perfect parry reflects")
	assert_almost(event["amount"], 1.0)
	var bolt: Projectile = _bolt(duel)
	assert_gt(absf(bolt.vx), BOLT.speed, "a perfect reflection flies faster")
	var shooter_health: float = duel.fighter(0).health
	assert_true(duel.step_until(func() -> bool: return duel.count_events(CombatEvent.Type.BOLT_HIT) > 0, 120))
	assert_eq(duel.last_event(CombatEvent.Type.BOLT_HIT)["target"], 0)
	assert_almost(duel.fighter(0).health, shooter_health - BOLT.damage)


func test_bolts_give_no_flow() -> void:
	var duel: DuelFixture = _duel()
	var calm: DuelFixture = _duel()
	_shoot(duel)
	calm.step()
	duel.step_until(func() -> bool: return duel.count_events(CombatEvent.Type.BOLT_HIT) > 0, 120)
	calm.step(duel.sim.tick - calm.sim.tick)
	for index in 2:
		assert_almost(duel.fighter(index).flow, calm.fighter(index).flow, 0.01)


func test_burst_fires_count_bolts_at_the_interval() -> void:
	var burst: BoltData = BOLT.duplicate() as BoltData
	burst.count = 3
	burst.interval = 0.05
	var shot: MoveData = SHOT.duplicate() as MoveData
	shot.bolt = burst
	shot.recovery = 0.4
	var duel: DuelFixture = _duel(shot)
	duel.place(900.0)
	_shoot(duel)
	duel.step(shot.startup_ticks() + burst.interval_ticks() * 3 + 2)
	var ticks: Array[int] = []
	for entry in duel.events_log:
		if entry["type"] == CombatEvent.Type.PROJECTILE_SPAWNED:
			ticks.append(entry["tick"])
	assert_eq(ticks.size(), 3)
	assert_eq(ticks[1] - ticks[0], burst.interval_ticks())
	assert_eq(ticks[2] - ticks[1], burst.interval_ticks())


func test_snapshot_restore_replays_bolts_exactly() -> void:
	var duel: DuelFixture = _duel()
	_shoot(duel)
	duel.step(SHOT.startup_ticks() + 4)
	var snapshot: Dictionary = duel.sim.capture()
	duel.step(40)
	var result: Dictionary = duel.sim.capture()
	duel.sim.restore(snapshot)
	duel.step(40)
	for key in result:
		assert_eq(duel.sim.capture()[key], result[key], "restored " + str(key))


func test_shooting_dummy_fires_at_its_interval() -> void:
	var duel: DuelFixture = _duel()
	var dummy: DummyController = DummyController.new(TRAINING)
	dummy.set_behavior(DummyController.Behavior.SHOOT)
	var interval: int = Ticks.from_seconds(TRAINING.dummy_shot_interval)
	for tick in interval * 2 + SHOT.startup_ticks() + 2:
		dummy.produce(duel.sim, 0, duel.intents[0])
		duel.step()
	assert_eq(duel.count_events(CombatEvent.Type.PROJECTILE_SPAWNED), 2)


func _evade_before(duel: DuelFixture, arrival: int, lead: int) -> void:
	duel.step_until(func() -> bool: return duel.sim.tick >= arrival - lead - 1, 200)
	duel.press(1, Intent.Command.EVADE)
	duel.step()


func test_precision_evade_slips_a_bolt_and_frees_the_defender() -> void:
	var arrival: int = _arrival_tick()
	var duel: DuelFixture = _duel()
	var health: float = duel.fighter(1).health
	_shoot(duel)
	_evade_before(duel, arrival, 2)
	duel.step(3)
	assert_eq(duel.count_events(CombatEvent.Type.EVADE_SUCCESS), 1)
	assert_eq(duel.fighter(1).evade_streak, 1)
	assert_true(duel.fighter(1).is_free(), "free right after the slip")
	assert_true(_bolt(duel) != null and _bolt(duel).evaded, "the bolt keeps flying past")
	duel.step(60)
	assert_eq(duel.count_events(CombatEvent.Type.BOLT_HIT), 0)
	assert_almost(duel.fighter(1).health, health)


func test_evade_chain_continues_through_a_burst() -> void:
	var burst: BoltData = BOLT.duplicate() as BoltData
	burst.count = 3
	burst.interval = 0.3
	var shot: MoveData = SHOT.duplicate() as MoveData
	shot.bolt = burst
	shot.recovery = 1.0
	var duel: DuelFixture = _duel(shot)
	_shoot(duel)
	for i in burst.count:
		assert_true(duel.step_until(func() -> bool: return _ticks_to_reach(duel) <= 2, 120), "bolt %d approaches" % i)
		duel.press(1, Intent.Command.EVADE)
		duel.step(4)
	assert_eq(duel.count_events(CombatEvent.Type.EVADE_SUCCESS), 3)
	assert_eq(duel.fighter(1).evade_streak, 3)
	assert_eq(duel.count_events(CombatEvent.Type.BOLT_HIT), 0)


func _ticks_to_reach(duel: DuelFixture) -> int:
	var target: FighterState = duel.fighter(1)
	var nearest: int = 999
	for projectile in duel.sim.projectiles:
		if not projectile.active or projectile.kind != Projectile.Kind.BOLT or projectile.evaded:
			continue
		var gap: float = absf(projectile.x - target.x) - DuelFixture.CONFIG.body_width * 0.5 - projectile.size
		nearest = mini(nearest, ceili(gap / (absf(projectile.vx) * Ticks.DELTA)))
	return nearest


func test_late_evade_still_takes_the_bolt() -> void:
	var arrival: int = _arrival_tick()
	var duel: DuelFixture = _duel()
	_shoot(duel)
	_evade_before(duel, arrival, -2)
	duel.step(10)
	assert_eq(duel.count_events(CombatEvent.Type.EVADE_SUCCESS), 0)
	assert_eq(duel.count_events(CombatEvent.Type.BOLT_HIT), 1)


func test_chained_evades_lean_differently_from_the_first() -> void:
	var first: Vector3 = PoseSolver.evade_pose_for(0)
	for streak in range(1, 7):
		assert_true(PoseSolver.evade_pose_for(streak) != first, "chain pose %d differs from the first" % streak)
		assert_true(PoseSolver.evade_pose_for(streak) != PoseSolver.evade_pose_for(streak + 1), "consecutive chain poses alternate")


func test_evade_on_the_contact_tick_succeeds_without_a_visible_dodge_state() -> void:
	var duel: DuelFixture = _duel()
	_shoot(duel)
	assert_true(duel.step_until(func() -> bool: return _ticks_to_reach(duel) <= 1, 120))
	duel.press(1, Intent.Command.EVADE)
	duel.step()
	assert_eq(duel.count_events(CombatEvent.Type.EVADE_SUCCESS), 1, "late but inside the window still slips")
	assert_eq(duel.fighter(1).state, FighterState.State.IDLE, "the dodge state ends in the same tick")
	assert_eq(duel.count_events(CombatEvent.Type.BOLT_HIT), 0)


func test_evade_success_holds_the_dodge_pose_after_the_state_ends() -> void:
	var duel: DuelFixture = _duel()
	var solver: PoseSolver = PoseSolver.new()
	var fighter: FighterState = duel.fighter(1)
	solver.setup(fighter.character, fighter.character.art)
	assert_false(solver.holds_evade(fighter))
	solver.start_evade_hold(2)
	assert_true(solver.holds_evade(fighter), "the slip stays visible while idle")
	assert_eq(solver.evade_hold_streak, 1, "pose of the evade that just succeeded")
	solver.advance(PoseSolver.EVADE_HOLD_TIME + 0.01)
	assert_false(solver.holds_evade(fighter))
