extends TestCase

const VERSATILE: MotionFamily = preload("res://data/families/versatile.tres")
const BARRAGE: PowerData = preload("res://data/powers/unsettling_barrage.tres")
const SEQUENCE: PowerData = preload("res://data/powers/cut_and_fire.tres")
const HARD: AiDifficultyData = preload("res://data/balance/ai/difficulty_hard.tres")


func _duel(first: StringName, gap: float = 300.0) -> DuelFixture:
	var duel: DuelFixture = DuelFixture.versus(first, &"guardian")
	duel.skip_intro()
	duel.place(gap)
	return duel


func _bolt_ticks(duel: DuelFixture, source: int = 0) -> Array[int]:
	var ticks: Array[int] = []
	for entry in duel.events_log:
		if entry["type"] == CombatEvent.Type.PROJECTILE_SPAWNED and entry["source"] == source and int(entry["amount"]) == Projectile.Kind.BOLT:
			ticks.append(entry["tick"])
	return ticks


func _special(duel: DuelFixture, direction: int) -> void:
	duel.intents[0].move_x = direction * duel.fighter(0).facing
	duel.press(0, Intent.Command.SPECIAL)
	duel.step()
	duel.release(0)
	duel.step_until(func() -> bool: return duel.fighter(0).is_attacking(), Ticks.from_seconds(duel.sim.config.flow.chord_window) + 3)


func _fourth(duel: DuelFixture) -> void:
	duel.press(0, Intent.Command.POWER)
	duel.press(0, Intent.Command.SPECIAL)
	duel.step()
	duel.release(0)


func test_both_versatiles_share_the_family_and_differ_in_their_sidearm() -> void:
	var corsair: CharacterData = DuelFixture.character(&"corsair")
	var lynx: CharacterData = DuelFixture.character(&"lynx")
	assert_eq(corsair.family, VERSATILE)
	assert_eq(lynx.family, VERSATILE)
	assert_eq(corsair.weapon.sidearm, WeaponData.Sidearm.BLASTER)
	assert_eq(lynx.weapon.sidearm, WeaponData.Sidearm.HILT_EMITTER)
	assert_eq(corsair.fourth_power, BARRAGE)
	assert_eq(lynx.fourth_power, SEQUENCE)
	assert_true(DuelMode.CAST.has(&"corsair") and DuelMode.CAST.has(&"lynx"))


func test_corsair_second_light_cuts_and_fires_on_its_first_active_tick() -> void:
	var duel: DuelFixture = _duel(&"corsair", 60.0)
	var second: MoveData = duel.fighter(0).character.light_chain[1]
	assert_true(second.bolt != null and second.reach > 0.0, "the step cuts and shoots")
	ActionStarter.start_attack(duel.sim, duel.fighter(0), second, 1)
	var started: int = duel.sim.tick
	duel.step(second.startup_ticks() + 2)
	var ticks: Array[int] = _bolt_ticks(duel)
	assert_eq(ticks.size(), 1)
	assert_eq(ticks[0] - started, second.startup_ticks())


func test_double_shot_fires_two_bolts_at_its_interval() -> void:
	var duel: DuelFixture = _duel(&"corsair", 700.0)
	var double_shot: MoveData = duel.fighter(0).character.technique_forward
	_special(duel, 1)
	duel.step(double_shot.startup_ticks() + double_shot.bolt.interval_ticks() + 2)
	var ticks: Array[int] = _bolt_ticks(duel)
	assert_eq(ticks.size(), 2)
	assert_eq(ticks[1] - ticks[0], double_shot.bolt.interval_ticks())


func test_retreating_shot_moves_back_while_the_bolt_flies_forward() -> void:
	var duel: DuelFixture = _duel(&"corsair", 120.0)
	var start_x: float = duel.fighter(0).x
	_special(duel, -1)
	assert_eq(duel.fighter(0).move, duel.fighter(0).character.technique_back)
	duel.step(duel.fighter(0).character.technique_back.startup_ticks() + 8)
	assert_lt(duel.fighter(0).x, start_x - 20.0, "the corsair retreats")
	assert_eq(_bolt_ticks(duel).size(), 1)
	var flying: bool = false
	for projectile in duel.sim.projectiles:
		if projectile.active and projectile.kind == Projectile.Kind.BOLT:
			flying = projectile.vx > 0.0
	assert_true(flying or duel.count_events(CombatEvent.Type.BOLT_HIT) + duel.count_events(CombatEvent.Type.BOLT_BLOCKED) > 0, "the bolt goes toward the rival")


func test_snap_shot_leaves_the_guard_directly() -> void:
	var duel: DuelFixture = _duel(&"lynx", 500.0)
	duel.hold(0, Intent.Command.BLOCK)
	duel.step(10)
	assert_eq(duel.fighter(0).state, FighterState.State.BLOCKING)
	duel.intents[0].move_x = duel.fighter(0).facing
	duel.press(0, Intent.Command.SPECIAL)
	duel.hold(0, Intent.Command.BLOCK)
	var waited: bool = duel.step_until(func() -> bool: return duel.fighter(0).is_attacking(), Ticks.from_seconds(duel.sim.config.flow.chord_window) + 3)
	assert_true(waited, "the snap shot starts from the guard")
	assert_eq(duel.fighter(0).move.id, &"snap_shot")


func test_non_guard_techniques_do_not_leave_the_guard() -> void:
	var duel: DuelFixture = _duel(&"corsair", 500.0)
	duel.hold(0, Intent.Command.BLOCK)
	duel.step(10)
	duel.intents[0].move_x = duel.fighter(0).facing
	duel.press(0, Intent.Command.SPECIAL)
	duel.hold(0, Intent.Command.BLOCK)
	duel.step(Ticks.from_seconds(duel.sim.config.flow.chord_window) + 3)
	assert_false(duel.fighter(0).is_attacking())


func test_corsair_barrage_is_tier_gated() -> void:
	var duel: DuelFixture = _duel(&"corsair")
	duel.set_level(0, BARRAGE.min_level - 1)
	duel.fighter(0).flow = 100.0
	_fourth(duel)
	duel.step(3)
	assert_gt(duel.count_events(CombatEvent.Type.POWER_REJECTED), 0)
	assert_false(duel.fighter(0).is_casting())


func test_corsair_barrage_fires_five_unsettling_bolts_then_dashes_in() -> void:
	var duel: DuelFixture = _duel(&"corsair", 260.0)
	duel.set_level(0, BARRAGE.min_level)
	duel.fighter(0).flow = 100.0
	_fourth(duel)
	assert_true(duel.step_until(func() -> bool: return duel.fighter(0).move == BARRAGE.sequence, 40), "the barrage starts")
	assert_true(duel.step_until(func() -> bool: return duel.fighter(0).move == BARRAGE.sequence.follow_up, 60), "the dash follows on its own")
	assert_eq(_bolt_ticks(duel).size(), BARRAGE.sequence.bolt.count)
	assert_gt(duel.count_events(CombatEvent.Type.BOLT_HIT), 0)
	duel.step(40)
	assert_gt(duel.count_events(CombatEvent.Type.HIT), 0, "the dashing cut lands on the unsettled rival")


func test_unsettling_bolt_staggers_even_an_attacker() -> void:
	var duel: DuelFixture = _duel(&"corsair", 300.0)
	var barrage_bolt: BoltData = BARRAGE.sequence.bolt
	duel.press(1, Intent.Command.HEAVY)
	duel.step()
	duel.release(1)
	assert_true(duel.fighter(1).is_attacking())
	BoltResolver.fire(duel.sim, duel.fighter(0), barrage_bolt)
	for projectile in duel.sim.projectiles:
		if projectile.active and projectile.kind == Projectile.Kind.BOLT:
			projectile.x = duel.fighter(1).x - 30.0
	duel.step()
	assert_eq(duel.fighter(1).state, FighterState.State.STAGGERED)


func test_lynx_sequence_alternates_cuts_and_point_blank_shots() -> void:
	var duel: DuelFixture = _duel(&"lynx", 40.0)
	duel.set_level(0, SEQUENCE.min_level)
	duel.fighter(0).flow = 100.0
	_fourth(duel)
	var order: Array[StringName] = []
	for tick in 200:
		var current: MoveData = duel.fighter(0).move
		if current != null and (order.is_empty() or order[-1] != current.id):
			order.append(current.id)
		duel.step()
	assert_eq(order, [&"sequence_cut_1", &"sequence_shot_1", &"sequence_cut_2", &"sequence_shot_2", &"sequence_finish"] as Array[StringName])
	assert_eq(_bolt_ticks(duel).size(), 2)


func _shots_in_ai_duel(id: StringName) -> int:
	var rules: MatchRules = MatchRules.new()
	rules.endless = true
	var cast: Array[CharacterData] = [DuelFixture.character(id), DuelFixture.character(&"guardian")]
	var duel: DuelFixture = DuelFixture.create(rules, null, 11, cast)
	duel.skip_intro()
	var ais: Array[AiController] = [AiController.new(HARD, cast[0].ai_profile, 3), AiController.new(HARD, cast[1].ai_profile, 4)]
	for tick in Ticks.from_seconds(40.0):
		for index in 2:
			ais[index].produce(duel.sim, index, duel.intents[index])
		duel.step()
	return _bolt_ticks(duel).size()


func test_blade_gunner_shoots_clearly_less_than_the_armed_duelist() -> void:
	var corsair: int = _shots_in_ai_duel(&"corsair")
	var lynx: int = _shots_in_ai_duel(&"lynx")
	assert_gt(float(corsair), 0.0, "the corsair shoots")
	assert_gt(float(corsair), float(lynx) * 2.0, "corsair %d vs lynx %d" % [corsair, lynx])
