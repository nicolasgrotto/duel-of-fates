extends TestCase


func test_mind_twist_waits_for_the_opponent_to_commit_to_a_direction() -> void:
	var duel: DuelFixture = DuelFixture.versus(&"guardian", &"shadow")
	duel.place(150.0)
	duel.give_power(0, &"mind_twist")
	var gap: float = CombatGeometry.gap(duel.sim.config, duel.fighter(0), duel.fighter(1))
	assert_eq(AiPowers.offensive_slot(duel.sim, duel.fighter(0), duel.fighter(1), gap), AiPowers.NO_SLOT, "a still opponent gains nothing from the twist")
	duel.intents[1].move_x = -1
	duel.step(4)
	assert_eq(duel.fighter(1).state, FighterState.State.WALKING)
	assert_eq(AiPowers.offensive_slot(duel.sim, duel.fighter(0), duel.fighter(1), gap), 0)


func test_hard_ai_keeps_meter_for_the_fourth_power() -> void:
	var duel: DuelFixture = DuelFixture.versus(&"foretold", &"shadow")
	duel.place(400.0)
	var me: FighterState = duel.fighter(0)
	var fourth: PowerData = me.powers[FighterState.FOURTH_SLOT]
	assert_true(fourth != null)
	me.flow = fourth.cost_for(me.flow_level) - 1.0
	var gap: float = CombatGeometry.gap(duel.sim.config, me, duel.fighter(1))
	var spent: int = AiPowers.offensive_slot(duel.sim, me, duel.fighter(1), gap)
	assert_ne(spent, AiPowers.NO_SLOT, "without saving it would spend on another power")
	assert_true(AiPowers.spends_fourth_reserve(me, spent))
	assert_eq(AiPowers.offensive_slot(duel.sim, me, duel.fighter(1), gap, true), AiPowers.NO_SLOT, "saving keeps the meter")
	me.flow = 100.0
	assert_eq(AiPowers.offensive_slot(duel.sim, me, duel.fighter(1), gap, true), FighterState.FOURTH_SLOT, "with a full meter the fourth power comes first")
