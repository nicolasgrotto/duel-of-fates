extends TestCase

const POWER: PowerData = preload("res://data/powers/higher_instinct.tres")
const HARD: AiDifficultyData = preload("res://data/balance/ai/difficulty_hard.tres")


func _active() -> DuelFixture:
	var duel: DuelFixture = DuelFixture.versus(&"elder", &"shadow")
	duel.place(70.0)
	duel.give_power(0, &"higher_instinct")
	duel.cast(0)
	duel.step_until(func() -> bool: return duel.fighter(0).is_free(), 60)
	return duel


func _strike(duel: DuelFixture, cut: MoveData.Cut, behind: bool = false, shove: bool = false) -> void:
	var attacker: FighterState = duel.fighter(1)
	attacker.move = attacker.character.light_chain[0].duplicate() as MoveData
	attacker.move.cut = cut
	attacker.move.hits_behind = behind
	if shove:
		attacker.move.kind = MoveData.Kind.SHOVE
	attacker.state = FighterState.State.ATTACKING
	attacker.move_phase = FighterState.Phase.ACTIVE
	attacker.phase_ticks = 0
	attacker.move_hit_done = false
	HitResolver.resolve(duel.sim)


func test_melee_evades_have_distinct_motions_and_do_not_teleport() -> void:
	var motions: Array[int] = []
	for cut in [MoveData.Cut.HORIZONTAL, MoveData.Cut.RISING, MoveData.Cut.THRUST, MoveData.Cut.DESCENDING]:
		var duel: DuelFixture = _active()
		var fighter: FighterState = duel.fighter(0)
		var position: Vector2 = Vector2(fighter.x, fighter.y)
		_strike(duel, cut)
		assert_almost(fighter.health, fighter.max_health)
		assert_eq(Vector2(fighter.x, fighter.y), position)
		assert_gt(fighter.instinct_counter_ticks, 0)
		assert_gt(fighter.instinct_evade_ticks, 0)
		motions.append(fighter.instinct_motion)
	assert_eq(motions, [FighterState.InstinctMotion.LEAN, FighterState.InstinctMotion.STEP_BACK, FighterState.InstinctMotion.TURN, FighterState.InstinctMotion.SLIDE])


func test_area_blade_and_shove_do_not_auto_evade() -> void:
	var area: DuelFixture = _active()
	_strike(area, MoveData.Cut.SPIN, true)
	assert_lt(area.fighter(0).health, area.fighter(0).max_health)
	assert_eq(area.fighter(0).instinct_counter_ticks, 0)
	var shove: DuelFixture = _active()
	_strike(shove, MoveData.Cut.ARC, false, true)
	assert_eq(shove.fighter(0).state, FighterState.State.STAGGERED)
	assert_eq(shove.fighter(0).instinct_counter_ticks, 0)


func test_counter_uses_existing_move_once() -> void:
	var duel: DuelFixture = _active()
	_strike(duel, MoveData.Cut.THRUST)
	duel.press(0, Intent.Command.LIGHT)
	duel.step()
	assert_eq(duel.fighter(0).move, duel.fighter(0).character.counter)
	assert_eq(duel.fighter(0).instinct_counter_ticks, 0)


func test_power_damage_ends_instinct_but_absorbed_damage_does_not() -> void:
	var duel: DuelFixture = _active()
	var fighter: FighterState = duel.fighter(0)
	fighter.sanctuary_ticks = 120
	fighter.sanctuary_hp = 10.0
	duel.sim.apply_damage(fighter, 5.0, true)
	assert_gt(fighter.instinct_ticks, 0)
	duel.sim.apply_damage(fighter, 10.0, true)
	assert_eq(fighter.instinct_ticks, 0)
	assert_eq(fighter.instinct_counter_ticks, 0)
	assert_eq(fighter.instinct_evade_ticks, 0)


func test_projectile_and_grab_bypass_instinct() -> void:
	for id in [&"throw", &"choke", &"fracture"]:
		var duel: DuelFixture = _active()
		duel.set_level(1, 8)
		duel.give_power(1, id)
		duel.cast(1)
		duel.step(100)
		assert_lt(duel.fighter(0).health, duel.fighter(0).max_health, str(id))
		assert_eq(duel.fighter(0).instinct_ticks, 0, str(id))


func test_expiry_and_snapshot_restore() -> void:
	var duel: DuelFixture = _active()
	_strike(duel, MoveData.Cut.RISING)
	var snapshot: Dictionary = duel.sim.capture()
	duel.step(320)
	var result: Dictionary = duel.sim.capture()
	assert_eq(duel.fighter(0).instinct_ticks, 0)
	assert_eq(duel.fighter(0).instinct_counter_ticks, 0)
	duel.sim.restore(snapshot)
	duel.step(320)
	assert_eq(duel.sim.capture(), result)


func test_tier_gate_and_pressure_cast_choice() -> void:
	var duel: DuelFixture = DuelFixture.versus(&"guardian", &"shadow")
	duel.give_power(0, &"higher_instinct")
	duel.set_level(0, 6)
	duel.cast(0)
	assert_eq(duel.count_events(CombatEvent.Type.POWER_REJECTED), 1)
	duel.set_level(0, 7)
	duel.place(90.0)
	duel.press(1, Intent.Command.HEAVY)
	duel.step()
	assert_eq(AiPowers.instinct_slot(duel.sim, duel.fighter(0), duel.fighter(1), 90.0), 0)


func test_ai_waits_instead_of_swinging_for_the_buff_duration() -> void:
	var duel: DuelFixture = _active()
	duel.fighter(1).powers.fill(null)
	var ai: AiController = AiController.new(HARD, duel.fighter(1).character.ai_profile, 19)
	var attacks: int = 0
	for tick in 180:
		ai.produce(duel.sim, 1, duel.intents[1])
		if duel.intents[1].was_pressed(Intent.Command.LIGHT) or duel.intents[1].was_pressed(Intent.Command.HEAVY):
			attacks += 1
		duel.step()
	assert_eq(attacks, 0)



func test_clash_and_lock_still_resolve_before_auto_evade() -> void:
	for heavy in [false, true]:
		var duel: DuelFixture = DuelFixture.versus(&"guardian", &"shadow")
		duel.place(50.0 if heavy else 100.0)
		duel.fighter(0).instinct_power = POWER
		duel.fighter(0).instinct_ticks = 240
		duel.press(0, Intent.Command.HEAVY if heavy else Intent.Command.LIGHT)
		duel.press(1, Intent.Command.HEAVY if heavy else Intent.Command.LIGHT)
		duel.step(25)
		assert_eq(duel.count_events(CombatEvent.Type.BLADE_LOCK_STARTED if heavy else CombatEvent.Type.CLASH), 1)
		assert_eq(duel.count_events(CombatEvent.Type.EVADE_SUCCESS), 0)
