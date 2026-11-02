extends TestCase

const PISTOL: BlasterData = preload("res://data/blasters/holster_pistol.tres")
const RIFLE: BlasterData = preload("res://data/blasters/back_rifle.tres")
const DOUBLE: MoveData = preload("res://data/techniques/double_draw.tres")
const RETREAT: MoveData = preload("res://data/techniques/retreat_draw.tres")
const COVER: MoveData = preload("res://data/techniques/covering_fire.tres")


func _duel(blaster: BlasterData = PISTOL) -> DuelFixture:
	var story: StoryCampaign = StoryCampaign.create("Iria", 0, 3, 0, 0, 1)
	story.skill_points = 10
	for node in StoryCampaign.CAMPAIGN.blade_tree:
		story.buy(node)
	var hero: CharacterData = story.protagonist()
	hero.weapon.blaster = blaster
	var cast: Array[CharacterData] = [hero, DuelFixture.SHADOW]
	var duel: DuelFixture = DuelFixture.create(null, null, 7, cast)
	duel.skip_intro()
	duel.place(600.0)
	return duel


func _start(duel: DuelFixture, move: MoveData = DOUBLE) -> void:
	assert_eq(ActionStarter.start_attack(duel.sim, duel.fighter(0), move), ActionStarter.Result.STARTED)
	duel.clear_log()


func _first_bolt(duel: DuelFixture) -> Projectile:
	for projectile in duel.sim.projectiles:
		if projectile.active and projectile.kind == Projectile.Kind.BOLT:
			return projectile
	return null


func _first_shot(duel: DuelFixture) -> void:
	assert_true(duel.step_until(func() -> bool: return duel.count_events(CombatEvent.Type.PROJECTILE_SPAWNED) > 0, 90))


func test_holster_draw_and_return_have_exact_tick_boundaries() -> void:
	for blaster in [PISTOL, RIFLE]:
		var duel: DuelFixture = _duel(blaster)
		_start(duel)
		var fighter: FighterState = duel.fighter(0)
		var startup: int = DOUBLE.startup_ticks() + blaster.draw_ticks()
		for tick in range(1, startup + 1):
			duel.step()
			assert_eq(fighter.sidearm_out, tick >= blaster.draw_ticks())
			assert_eq(duel.count_events(CombatEvent.Type.PROJECTILE_SPAWNED), 1 if tick == startup else 0)
		assert_eq(fighter.move_phase, FighterState.Phase.ACTIVE)
		duel.step(DOUBLE.active_ticks())
		assert_eq(fighter.move_phase, FighterState.Phase.RECOVERY)
		duel.step(DOUBLE.recovery_ticks() - 1)
		assert_true(fighter.sidearm_out)
		duel.step()
		assert_false(fighter.sidearm_out)
		duel.step(blaster.holster_ticks() - 1)
		assert_true(fighter.is_attacking())
		duel.step()
		assert_true(fighter.is_free())
		assert_false(fighter.sidearm_out)


func test_holster_moves_fire_the_configured_count_and_interval() -> void:
	for blaster in [PISTOL, RIFLE]:
		for move in [RETREAT, DOUBLE, COVER]:
			var duel: DuelFixture = _duel(blaster)
			_start(duel, move)
			var expected_tick: int = duel.sim.tick + move.startup_ticks() + blaster.draw_ticks()
			duel.step(move.total_ticks() + blaster.draw_ticks() + blaster.holster_ticks())
			var shots: int = 0
			for event in duel.events_log:
				if event["type"] == CombatEvent.Type.PROJECTILE_SPAWNED:
					assert_eq(event["tick"], expected_tick + shots * Ticks.from_seconds(move.shot_interval))
					shots += 1
			assert_eq(shots, move.shot_count)


func test_holster_equipment_changes_projectiles_without_mutating_shared_data() -> void:
	for blaster in [PISTOL, RIFLE]:
		var duel: DuelFixture = _duel(blaster)
		_start(duel)
		_first_shot(duel)
		var bolt: Projectile = _first_bolt(duel)
		assert_eq(bolt.bolt, blaster.bolt)
		assert_almost(bolt.damage, blaster.bolt.damage)
		assert_almost(bolt.vx, blaster.bolt.speed)
		assert_almost(bolt.max_distance, blaster.bolt.max_range)
	assert_eq(DuelFixture.character(&"holster").weapon.blaster, PISTOL)
	assert_true(RIFLE.draw_ticks() > PISTOL.draw_ticks())
	assert_true(RIFLE.bolt.damage > PISTOL.bolt.damage)


func test_holster_guard_cancels_the_second_shot_and_charges_one_hand_cost() -> void:
	var duel: DuelFixture = _duel()
	_start(duel)
	_first_shot(duel)
	duel.press(0, Intent.Command.BLOCK)
	duel.hold(0, Intent.Command.BLOCK)
	duel.step()
	var fighter: FighterState = duel.fighter(0)
	assert_eq(fighter.state, FighterState.State.BLOCKING)
	assert_false(fighter.sidearm_out)
	assert_eq(fighter.sidearm_guard_ticks, PISTOL.holster_ticks())
	var move: MoveData = DuelFixture.SHADOW.light_chain[0]
	var normal: float = move.block_vigor_cost * fighter.character.block_cost_multiplier / fighter.defense_multiplier
	assert_almost(duel.sim.block_cost(fighter, move), normal * 1.25)
	duel.step(PISTOL.holster_ticks())
	assert_almost(duel.sim.block_cost(fighter, move), normal)
	duel.step(30)
	assert_eq(duel.count_events(CombatEvent.Type.PROJECTILE_SPAWNED), 1)


func test_holster_guard_penalty_applies_to_bolts_without_changing_parry() -> void:
	var duel: DuelFixture = _duel()
	_start(duel)
	_first_shot(duel)
	duel.press(0, Intent.Command.BLOCK)
	duel.hold(0, Intent.Command.BLOCK)
	duel.step()
	var fighter: FighterState = duel.fighter(0)
	var incoming: Projectile = Projectile.new()
	incoming.bolt = PISTOL.bolt
	incoming.x = fighter.x + 20.0
	incoming.vx = -PISTOL.bolt.speed
	var vigor: float = fighter.vigor
	BoltResolver.resolve(duel.sim, incoming, duel.fighter(1), fighter)
	assert_almost(fighter.vigor, vigor)
	assert_eq(incoming.owner, fighter.index)
	fighter.parry_ticks = FighterState.NO_PARRY
	incoming.hit_done = false
	BoltResolver.resolve(duel.sim, incoming, duel.fighter(1), fighter)
	assert_almost(fighter.vigor, vigor - PISTOL.bolt.guard_vigor * 1.25)


func test_holster_precision_evade_cancels_remaining_covering_fire() -> void:
	var duel: DuelFixture = _duel()
	_start(duel, COVER)
	_first_shot(duel)
	duel.press(0, Intent.Command.EVADE)
	duel.step()
	assert_eq(duel.fighter(0).state, FighterState.State.DODGING)
	assert_false(duel.fighter(0).sidearm_out)
	assert_eq(duel.fighter(0).bolts_left, 0)
	duel.release(0)
	duel.step(60)
	assert_eq(duel.count_events(CombatEvent.Type.PROJECTILE_SPAWNED), 1)


func test_holster_cannot_cancel_before_the_first_shot() -> void:
	var duel: DuelFixture = _duel()
	_start(duel)
	duel.press(0, Intent.Command.BLOCK)
	duel.hold(0, Intent.Command.BLOCK)
	duel.step()
	assert_true(duel.fighter(0).is_attacking())
	assert_eq(duel.count_events(CombatEvent.Type.PROJECTILE_SPAWNED), 0)


func test_holster_interruption_clears_armed_state_and_pending_burst() -> void:
	for state in [FighterState.State.IDLE, FighterState.State.BLOCKING, FighterState.State.DODGING, FighterState.State.BLADE_LOCK, FighterState.State.DEAD, FighterState.State.HIT]:
		var duel: DuelFixture = _duel()
		_start(duel, COVER)
		_first_shot(duel)
		assert_true(duel.fighter(0).sidearm_out)
		duel.sim.change_state(duel.fighter(0), state)
		assert_false(duel.fighter(0).sidearm_out)
		assert_eq(duel.fighter(0).bolts_left, 0)
		assert_true(duel.fighter(0).move == null)


func test_holster_round_end_stows_the_winner_and_stops_the_burst() -> void:
	var duel: DuelFixture = _duel()
	_start(duel, COVER)
	_first_shot(duel)
	duel.fighter(1).health = 1.0
	duel.step_until(func() -> bool: return duel.sim.phase == MatchSimulation.Phase.KO, 90)
	assert_eq(duel.sim.phase, MatchSimulation.Phase.KO)
	assert_false(duel.fighter(0).sidearm_out)
	assert_true(duel.fighter(0).move == null)
	assert_eq(duel.fighter(0).bolts_left, 0)


func test_holster_retreat_moves_back_and_air_technique_stays_blade_only() -> void:
	var duel: DuelFixture = _duel()
	var start_x: float = duel.fighter(0).x
	_start(duel, RETREAT)
	_first_shot(duel)
	assert_lt(duel.fighter(0).x, start_x - 60.0)
	var fighter: FighterState = duel.fighter(0)
	duel.sim.change_state(fighter, FighterState.State.JUMPING)
	fighter.on_ground = false
	fighter.y = 200.0
	assert_eq(ActionStarter.start_attack(duel.sim, fighter, COVER), ActionStarter.Result.NOT_POSSIBLE)
	assert_false(fighter.character.technique_air.draws_sidearm)


func test_holster_bolt_evade_and_parry_use_the_shared_resolution() -> void:
	for action in [Intent.Command.BLOCK, Intent.Command.EVADE]:
		var dry: DuelFixture = _duel()
		_start(dry, RETREAT)
		assert_true(dry.step_until(func() -> bool: return dry.count_events(CombatEvent.Type.BOLT_HIT) > 0, 180))
		var arrival: int = dry.last_event(CombatEvent.Type.BOLT_HIT)["tick"]
		var duel: DuelFixture = _duel()
		_start(duel, RETREAT)
		duel.step(arrival - duel.sim.tick - 2)
		duel.press(1, action)
		duel.hold(1, action)
		duel.step(4)
		var event_type: CombatEvent.Type = CombatEvent.Type.BOLT_REFLECTED if action == Intent.Command.BLOCK else CombatEvent.Type.EVADE_SUCCESS
		assert_eq(duel.count_events(event_type), 1)
		assert_almost(duel.fighter(1).health, duel.fighter(1).max_health)


func test_holster_bolt_stops_the_draw_but_not_the_active_burst() -> void:
	var duel: DuelFixture = _duel()
	var fighter: FighterState = duel.fighter(0)
	_start(duel)
	fighter.move_phase = FighterState.Phase.ACTIVE
	var projectile: Projectile = Projectile.new()
	projectile.bolt = RIFLE.bolt
	projectile.damage = RIFLE.bolt.damage
	projectile.x = fighter.x + 10.0
	BoltResolver.resolve(duel.sim, projectile, duel.fighter(1), fighter)
	assert_eq(fighter.move, DOUBLE)
	fighter.clear_move()
	duel.sim.change_state(fighter, FighterState.State.IDLE)
	_start(duel)
	fighter.move_phase = FighterState.Phase.STARTUP
	BoltResolver.resolve(duel.sim, projectile, duel.fighter(1), fighter)
	assert_true(fighter.move == null)
	assert_eq(fighter.state, FighterState.State.HIT)


func test_holster_snapshot_replays_draw_burst_and_guard_return() -> void:
	var duel: DuelFixture = _duel(RIFLE)
	_start(duel, COVER)
	duel.step(12)
	var snapshot: Dictionary = duel.sim.capture()
	duel.step(85)
	var expected: Dictionary = duel.sim.capture()
	duel.sim.restore(snapshot)
	duel.step(85)
	assert_eq(duel.sim.capture(), expected)
	_start(duel)
	_first_shot(duel)
	duel.press(0, Intent.Command.BLOCK)
	duel.hold(0, Intent.Command.BLOCK)
	duel.step()
	snapshot = duel.sim.capture()
	duel.step(10)
	expected = duel.sim.capture()
	duel.sim.restore(snapshot)
	duel.step(10)
	assert_eq(duel.sim.capture(), expected)
