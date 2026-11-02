extends TestCase

const BOLT: BoltData = preload("res://data/bolts/standard_bolt.tres")
const DASH_SLASH: MoveData = preload("res://data/techniques/dash_slash.tres")


func _duel(gap: float = 300.0) -> DuelFixture:
	var duel: DuelFixture = DuelFixture.create()
	duel.skip_intro()
	duel.place(gap)
	return duel


func _shot(fighter: FighterState) -> Projectile:
	var projectile: Projectile = Projectile.new()
	projectile.bolt = BOLT
	projectile.damage = BOLT.damage
	projectile.x = fighter.x + fighter.facing * 10.0
	return projectile


func _hit(duel: DuelFixture, target: int) -> void:
	BoltResolver.resolve(duel.sim, _shot(duel.fighter(target)), duel.fighter(1 - target), duel.fighter(target))


func _start(duel: DuelFixture, move: MoveData) -> void:
	assert_true(ActionStarter.start_attack(duel.sim, duel.fighter(1), move))


func test_bolt_cancels_a_dash_slash_in_startup() -> void:
	var duel: DuelFixture = _duel()
	_start(duel, DASH_SLASH)
	duel.step(3)
	assert_eq(duel.fighter(1).move_phase, FighterState.Phase.STARTUP)
	_hit(duel, 1)
	assert_true(duel.fighter(1).move == null)
	assert_eq(duel.fighter(1).state, FighterState.State.HIT)
	assert_almost(duel.fighter(1).vx, 0.0)
	assert_eq(duel.fighter(1).stun_ticks, BOLT.flinch_ticks())


func test_bolt_does_not_stop_an_active_strike() -> void:
	var duel: DuelFixture = _duel()
	_start(duel, DASH_SLASH)
	duel.fighter(1).move_phase = FighterState.Phase.ACTIVE
	_hit(duel, 1)
	assert_eq(duel.fighter(1).move, DASH_SLASH)
	assert_eq(duel.fighter(1).move_phase, FighterState.Phase.ACTIVE)


func test_armored_startup_keeps_going() -> void:
	var duel: DuelFixture = _duel()
	var armored: MoveData = DASH_SLASH.duplicate() as MoveData
	armored.armor_hits = 1
	_start(duel, armored)
	duel.step(2)
	_hit(duel, 1)
	assert_eq(duel.fighter(1).move, armored)


func test_flinch_grants_immunity_so_bursts_cannot_lock() -> void:
	var duel: DuelFixture = _duel()
	var fighter: FighterState = duel.fighter(1)
	_hit(duel, 1)
	assert_eq(fighter.state, FighterState.State.HIT)
	var stun: int = fighter.stun_ticks
	var health: float = fighter.health
	_hit(duel, 1)
	assert_almost(fighter.health, health - BOLT.damage)
	assert_eq(fighter.stun_ticks, stun)
	duel.step(BOLT.flinch_ticks() + 1)
	assert_true(fighter.is_free())
	_start(duel, DASH_SLASH)
	duel.step(2)
	_hit(duel, 1)
	assert_eq(fighter.move, DASH_SLASH, "still immune right after the flinch")
	duel.fighter(1).clear_move()
	duel.sim.change_state(fighter, FighterState.State.IDLE)
	duel.step(Ticks.from_seconds(duel.sim.config.bolt_flinch_immunity) + 1)
	_hit(duel, 1)
	assert_eq(fighter.state, FighterState.State.HIT)


func test_flinch_never_shortens_a_recovery() -> void:
	var duel: DuelFixture = _duel()
	var fighter: FighterState = duel.fighter(1)
	_start(duel, DASH_SLASH)
	fighter.move_phase = FighterState.Phase.RECOVERY
	fighter.phase_ticks = 0
	var remaining: int = fighter.move_recovery_ticks()
	assert_gt(float(remaining), float(BOLT.flinch_ticks()))
	_hit(duel, 1)
	assert_eq(fighter.state, FighterState.State.HIT)
	assert_eq(fighter.stun_ticks, remaining)


func test_airborne_fighter_only_takes_damage() -> void:
	var duel: DuelFixture = _duel()
	var fighter: FighterState = duel.fighter(1)
	fighter.on_ground = false
	var state: FighterState.State = fighter.state
	_hit(duel, 1)
	assert_eq(fighter.state, state)


func test_immunity_is_part_of_the_snapshot_and_resets_each_round() -> void:
	var duel: DuelFixture = _duel()
	var fighter: FighterState = duel.fighter(1)
	_hit(duel, 1)
	var immunity: int = fighter.bolt_immunity_ticks
	assert_gt(float(immunity), 0.0)
	var saved: Dictionary = duel.sim.capture()
	duel.step(10)
	duel.sim.restore(saved)
	assert_eq(duel.fighter(1).bolt_immunity_ticks, immunity)
	fighter.reset_for_round(fighter.x, fighter.facing)
	assert_eq(fighter.bolt_immunity_ticks, 0)
