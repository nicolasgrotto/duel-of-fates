extends TestCase

const OPENING_GAP: float = 100.0
const HARD: AiDifficultyData = preload("res://data/balance/ai/difficulty_hard.tres")


func _start_heavy(duel: DuelFixture, gap: float = OPENING_GAP) -> void:
	duel.place(gap)
	duel.press(0, Intent.Command.HEAVY)
	duel.step_until(func() -> bool: return duel.fighter(0).move_phase == FighterState.Phase.RECOVERY)


func _press_heavy_in_recovery(duel: DuelFixture) -> void:
	duel.press(0, Intent.Command.HEAVY)
	duel.step_until(func() -> bool: return duel.fighter(0).move == null or duel.fighter(0).move == duel.fighter(0).character.heavy.heavy_chain, 60)


func test_only_low_damage_fighters_have_a_heavy_sequence() -> void:
	for id in [&"wasp", &"lance"]:
		var data: CharacterData = DuelFixture.character(id)
		assert_true(data.heavy.heavy_chain != null, String(id))
		assert_eq(data.forward_heavy.heavy_chain, data.heavy.heavy_chain, String(id))
	for id in [&"forge", &"shadow", &"guardian"]:
		assert_true(DuelFixture.character(id).heavy.heavy_chain == null, String(id))


func test_second_heavy_is_weaker_cheaper_and_faster() -> void:
	for id in [&"wasp", &"lance"]:
		var first: MoveData = DuelFixture.character(id).heavy
		var second: MoveData = first.heavy_chain
		assert_lt(second.damage, first.damage, String(id))
		assert_lt(second.vigor_cost, first.vigor_cost, String(id))
		assert_lt(second.startup, first.startup * 0.7, "%s second windup is clearly shorter" % id)
		assert_true(second.heavy_chain == null, "%s chains only once" % id)


func test_heavy_chains_after_a_hit() -> void:
	for id in [&"wasp", &"lance"]:
		var duel: DuelFixture = DuelFixture.versus(id, &"guardian")
		_start_heavy(duel)
		assert_true(duel.fighter(0).move_landed, "%s first heavy landed" % id)
		_press_heavy_in_recovery(duel)
		assert_eq(duel.fighter(0).move, duel.fighter(0).character.heavy.heavy_chain, String(id))


func test_heavy_chains_after_a_block() -> void:
	var duel: DuelFixture = DuelFixture.versus(&"wasp", &"guardian")
	duel.hold(1, Intent.Command.BLOCK)
	duel.step(12)
	_start_heavy(duel)
	assert_gt(float(duel.count_events(CombatEvent.Type.BLOCK)), 0.0)
	_press_heavy_in_recovery(duel)
	assert_eq(duel.fighter(0).move.id, &"wasp_heavy_chain")


func test_no_chain_after_a_whiff() -> void:
	var duel: DuelFixture = DuelFixture.versus(&"wasp", &"guardian")
	_start_heavy(duel, 500.0)
	assert_false(duel.fighter(0).move_landed)
	duel.press(0, Intent.Command.HEAVY)
	duel.step(1)
	assert_eq(duel.fighter(0).move.id, &"wasp_heavy")


func test_no_chain_after_a_parry() -> void:
	var duel: DuelFixture = DuelFixture.versus(&"wasp", &"guardian")
	duel.place(OPENING_GAP)
	duel.press(0, Intent.Command.HEAVY)
	var first: MoveData = duel.fighter(0).character.heavy
	duel.step(first.startup_ticks() - 4)
	duel.press(1, Intent.Command.BLOCK)
	duel.step_until(func() -> bool: return duel.fighter(0).move == null or duel.fighter(0).move_phase == FighterState.Phase.RECOVERY)
	assert_false(duel.fighter(0).move_landed, "a parried heavy never opens the sequence")


func test_second_heavy_is_never_guaranteed_after_a_hit() -> void:
	for id in [&"wasp", &"lance"]:
		var duel: DuelFixture = DuelFixture.versus(id, &"guardian")
		_start_heavy(duel)
		duel.press(0, Intent.Command.HEAVY)
		var chain: MoveData = duel.fighter(0).character.heavy.heavy_chain
		var reached: bool = duel.step_until(func() -> bool: return duel.fighter(0).move == chain, 60)
		assert_true(reached, String(id))
		var gap: int = Ticks.from_seconds(duel.sim.config.heavy_chain_gap)
		assert_true(duel.fighter(1).stun_ticks + gap <= chain.startup_ticks(), "%s rival acts %d ticks before the second blade" % [id, gap])


func test_rival_can_block_the_second_heavy_after_recovering() -> void:
	var duel: DuelFixture = DuelFixture.versus(&"wasp", &"guardian")
	_start_heavy(duel)
	duel.press(0, Intent.Command.HEAVY)
	var chain: MoveData = duel.fighter(0).character.heavy.heavy_chain
	duel.step_until(func() -> bool: return duel.fighter(0).move == chain, 60)
	duel.clear_log()
	duel.step_until(func() -> bool: return duel.fighter(1).stun_ticks == 0, 60)
	duel.hold(1, Intent.Command.BLOCK)
	duel.step_until(func() -> bool: return duel.fighter(0).move != chain or duel.fighter(0).move_phase == FighterState.Phase.RECOVERY, 60)
	assert_eq(duel.count_events(CombatEvent.Type.HIT), 0, "guarding in the gap stops the second blade")


func test_second_heavy_reaches_a_rival_who_stands_still() -> void:
	for id in [&"wasp", &"lance"]:
		var duel: DuelFixture = DuelFixture.versus(id, &"guardian")
		_start_heavy(duel)
		duel.clear_log()
		duel.press(0, Intent.Command.HEAVY)
		var chain: MoveData = duel.fighter(0).character.heavy.heavy_chain
		duel.step_until(func() -> bool: return duel.fighter(0).move == chain, 60)
		duel.step_until(func() -> bool: return duel.fighter(0).move != chain or duel.fighter(0).move_phase == FighterState.Phase.RECOVERY, 60)
		assert_eq(duel.count_events(CombatEvent.Type.HIT), 1, "%s second heavy connects" % id)


func test_ai_uses_the_sequence_only_when_the_move_has_one() -> void:
	var controller: AiController = AiController.new(HARD, DuelFixture.character(&"wasp").ai_profile, 3)
	var wanted: bool = false
	for attempt in 20:
		controller._plan_heavy_chain(DuelFixture.character(&"wasp").heavy)
		wanted = wanted or controller._wants_heavy_chain
	assert_true(wanted, "the profile eventually asks for the second heavy")
	controller._plan_heavy_chain(DuelFixture.character(&"forge").heavy)
	assert_false(controller._wants_heavy_chain)
