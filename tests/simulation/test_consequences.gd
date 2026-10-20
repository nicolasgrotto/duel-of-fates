extends TestCase

var duel: DuelFixture


func before_each() -> void:
	duel = DuelFixture.create()
	duel.skip_intro()


func test_spending_to_five_percent_exhausts() -> void:
	duel.fighter(0).vigor = 12.0
	duel.press(0, Intent.Command.LIGHT)
	duel.step(1)
	assert_true(duel.fighter(0).exhausted)
	assert_eq(duel.count_events(CombatEvent.Type.EXHAUSTION), 1)


func test_exhaustion_ends_with_thirty_percent_and_one_second() -> void:
	duel.fighter(0).vigor = 12.0
	duel.press(0, Intent.Command.LIGHT)
	duel.step(1)
	var recovered: bool = duel.step_until(func() -> bool: return not duel.fighter(0).exhausted, 300)
	assert_true(recovered)
	assert_true(duel.fighter(0).vigor >= duel.fighter(0).max_vigor * 0.3 - 0.01)
	assert_eq(duel.count_events(CombatEvent.Type.EXHAUSTION_RECOVERED), 1)


func test_exhausted_fighter_takes_extra_damage() -> void:
	duel.place(60.0)
	duel.fighter(1).exhausted = true
	var health: float = duel.fighter(1).health
	duel.press(0, Intent.Command.LIGHT)
	duel.step(8)
	assert_almost(duel.fighter(1).health, health - 11.0)


func test_heavy_wounds_arm_of_exhausted_target() -> void:
	duel.place(60.0)
	duel.fighter(1).exhausted = true
	duel.press(0, Intent.Command.HEAVY)
	duel.step(30)
	assert_eq(duel.fighter(1).wound, FighterState.Wound.ARM)
	assert_eq(duel.count_events(CombatEvent.Type.WOUND), 1)


func test_forward_heavy_wounds_leg_once_per_round() -> void:
	duel.place(60.0)
	duel.fighter(1).exhausted = true
	duel.intents[0].move_x = 1
	duel.press(0, Intent.Command.HEAVY)
	duel.step(1)
	duel.intents[0].move_x = 0
	duel.step(30)
	assert_eq(duel.fighter(1).wound, FighterState.Wound.LEG)
	assert_true(duel.fighter(1).wounded_this_round)


func test_no_wound_without_exhaustion() -> void:
	duel.place(60.0)
	duel.press(0, Intent.Command.HEAVY)
	duel.step(30)
	assert_eq(duel.fighter(1).wound, FighterState.Wound.NONE)


func test_wounded_arm_makes_blocking_costlier() -> void:
	var move: MoveData = DuelFixture.SHADOW.heavy
	var normal: float = duel.sim.block_cost(duel.fighter(0), move)
	duel.fighter(0).wound = FighterState.Wound.ARM
	assert_almost(duel.sim.block_cost(duel.fighter(0), move), normal * 1.25)


func test_wounded_leg_removes_double_jump() -> void:
	duel.fighter(0).wound = FighterState.Wound.LEG
	duel.press(0, Intent.Command.JUMP)
	duel.step(8)
	duel.press(0, Intent.Command.JUMP)
	duel.step(1)
	assert_eq(duel.fighter(0).jumps_used, 1)


func test_lethal_blade_hit_severs_limb() -> void:
	duel.place(60.0)
	duel.fighter(1).health = 5.0
	duel.press(0, Intent.Command.LIGHT)
	duel.step(8)
	assert_eq(duel.fighter(1).state, FighterState.State.DEAD)
	var death: Dictionary = duel.last_event(CombatEvent.Type.DEATH)
	assert_eq(death.get("limb"), MoveData.Limb.ARM)


func test_deciding_knockout_can_take_the_head() -> void:
	var config: CombatConfig = DuelFixture.config_copy()
	config.consequences.head_finisher_chance = 1.0
	var rules: MatchRules = MatchRules.new()
	rules.rounds_to_win = 1
	duel = DuelFixture.create(rules, config)
	duel.skip_intro()
	duel.place(60.0)
	duel.fighter(1).health = 5.0
	duel.press(0, Intent.Command.LIGHT)
	duel.step(8)
	assert_eq(duel.last_event(CombatEvent.Type.DEATH).get("limb"), MoveData.Limb.HEAD)


func test_shove_knockout_has_no_finisher() -> void:
	var move: MoveData = DuelFixture.GUARDIAN.shove
	assert_eq(Consequences.finisher_limb(duel.sim, move, true), MoveData.Limb.NONE)
	assert_eq(Consequences.finisher_limb(duel.sim, DuelFixture.GUARDIAN.aerial_light, true), MoveData.Limb.NONE)
