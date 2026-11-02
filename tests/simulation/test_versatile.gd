extends TestCase

const VERSATILE: MotionFamily = preload("res://data/families/versatile.tres")
const BARRAGE: MoveData = preload("res://data/techniques/unsettling_barrage.tres")
const CATALOG: PowerCatalog = preload("res://data/powers/catalog.tres")
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


func test_both_versatiles_share_the_family_and_differ_in_their_sidearm() -> void:
	var corsair: CharacterData = DuelFixture.character(&"corsair")
	var lynx: CharacterData = DuelFixture.character(&"lynx")
	assert_eq(corsair.family, VERSATILE)
	assert_eq(lynx.family, VERSATILE)
	assert_eq(corsair.weapon.sidearm, WeaponData.Sidearm.BLASTER)
	assert_eq(lynx.weapon.sidearm, WeaponData.Sidearm.HILT_EMITTER)
	assert_eq(corsair.technique_forward, BARRAGE)
	assert_true(corsair.fourth_power == null and lynx.fourth_power == null, "no versatile ultimate")
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


func test_double_shot_fires_two_bolts_at_its_interval() -> void:
	var duel: DuelFixture = _duel(&"corsair", 700.0)
	var double_shot: MoveData = load("res://data/techniques/double_shot.tres")
	duel.fighter(0).character = duel.fighter(0).character.duplicate() as CharacterData
	duel.fighter(0).character.technique_forward = double_shot
	_special(duel, 1)
	duel.step(double_shot.startup_ticks() + double_shot.bolt.interval_ticks() + 2)
	var ticks: Array[int] = _bolt_ticks(duel)
	assert_eq(ticks.size(), 2)
	assert_eq(ticks[1] - ticks[0], double_shot.bolt.interval_ticks())


func test_barrage_costs_vigor_fires_five_bolts_then_dashes_in() -> void:
	var duel: DuelFixture = _duel(&"corsair", 260.0)
	var vigor: float = duel.fighter(0).vigor
	var flow: float = duel.fighter(0).flow
	_special(duel, 1)
	assert_eq(duel.fighter(0).move, BARRAGE)
	assert_almost(duel.fighter(0).vigor, vigor - BARRAGE.vigor_cost, 1.0)
	assert_true(duel.step_until(func() -> bool: return duel.fighter(0).move == BARRAGE.follow_up, 60), "the dash follows on its own")
	assert_eq(_bolt_ticks(duel).size(), BARRAGE.bolt.count)
	assert_gt(duel.fighter(0).flow + 0.01, flow, "no flow is spent")
	duel.step(40)
	assert_gt(duel.count_events(CombatEvent.Type.HIT) + duel.count_events(CombatEvent.Type.BLOCK), 0, "the dashing cut reaches the rival")


func test_barrage_bolts_do_not_stop_an_active_strike() -> void:
	var duel: DuelFixture = _duel(&"corsair", 300.0)
	duel.press(1, Intent.Command.HEAVY)
	duel.step()
	duel.release(1)
	duel.fighter(1).move_phase = FighterState.Phase.ACTIVE
	BoltResolver.fire(duel.sim, duel.fighter(0), BARRAGE.bolt)
	for projectile in duel.sim.projectiles:
		if projectile.active and projectile.kind == Projectile.Kind.BOLT:
			projectile.x = duel.fighter(1).x - 30.0
	duel.step()
	assert_true(duel.fighter(1).is_attacking())


func test_blaster_techniques_are_offered_only_to_blaster_users() -> void:
	var corsair: CharacterData = DuelFixture.character(&"corsair")
	var guardian: CharacterData = DuelFixture.character(&"guardian")
	assert_true(CATALOG.techniques.has(BARRAGE))
	assert_true(BARRAGE.usable_by(corsair))
	assert_false(BARRAGE.usable_by(guardian))
	assert_false(BARRAGE.usable_by(DuelFixture.character(&"lynx")), "the hilt emitter is not a blaster")
	var chosen: Array[MoveData] = [guardian.technique_forward, guardian.technique_back, guardian.technique_air]
	for step in CATALOG.techniques.size() * 2:
		CATALOG.cycle_technique(chosen, 0, 1, guardian)
		assert_true(chosen[0].usable_by(guardian), String(chosen[0].id))


func test_gallery_hands_blaster_techniques_to_a_wielder() -> void:
	var guardian: CharacterData = DuelFixture.character(&"guardian")
	assert_eq(GalleryPanel.wielder_for(BARRAGE, guardian), &"corsair")
	assert_eq(GalleryPanel.wielder_for(BARRAGE, DuelFixture.character(&"corsair")), &"")
	assert_eq(GalleryPanel.wielder_for(CATALOG.techniques[0], guardian), &"")
