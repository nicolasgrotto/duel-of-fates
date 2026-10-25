extends TestCase

const CUT: MoveData = preload("res://data/techniques/projected_cut.tres")
const CATALOG: PowerCatalog = preload("res://data/powers/catalog.tres")


func _duel(character: StringName = &"guardian") -> DuelFixture:
	var hero: CharacterData = DuelFixture.character(character).duplicate() as CharacterData
	hero.technique_forward = CUT
	var cast: Array[CharacterData] = [hero, DuelFixture.SHADOW]
	var duel: DuelFixture = DuelFixture.create(null, null, 7, cast)
	duel.skip_intro()
	duel.place(300.0)
	return duel


func _start(duel: DuelFixture) -> void:
	duel.intents[0].move_x = duel.fighter(0).facing
	duel.press(0, Intent.Command.SPECIAL)
	duel.step()
	duel.release(0)


func test_neutral_wave_spawns_on_active_and_costs_only_vigor() -> void:
	for id in [&"guardian", &"shadow"]:
		var duel: DuelFixture = _duel(id)
		var vigor: float = duel.fighter(0).vigor
		duel.fighter(0).flow = 0.0
		_start(duel)
		assert_almost(duel.fighter(0).vigor, vigor - CUT.vigor_cost)
		assert_eq(duel.count_events(CombatEvent.Type.POWER_STARTED), 0)
		assert_eq(duel.count_events(CombatEvent.Type.PROJECTILE_SPAWNED), 0)
		duel.step_until(func() -> bool: return duel.fighter(0).is_active(), 30)
		assert_eq(duel.count_events(CombatEvent.Type.PROJECTILE_SPAWNED), 1)
		assert_false(duel.fighter(0).blade_out)
		for wave in duel.sim.projectiles:
			if wave.active:
				assert_eq(wave.move, CUT)
				assert_true(wave.power == null)
				assert_almost(wave.damage, CUT.damage * duel.fighter(0).blade_multiplier)


func test_guard_blocks_wave_and_spends_vigor() -> void:
	var duel: DuelFixture = _duel()
	duel.hold(1, Intent.Command.BLOCK)
	duel.step(15)
	var health: float = duel.fighter(1).health
	var vigor: float = duel.fighter(1).vigor
	_start(duel)
	duel.step(70)
	assert_eq(duel.count_events(CombatEvent.Type.BLOCK), 1)
	assert_almost(duel.fighter(1).health, health)
	assert_lt(duel.fighter(1).vigor, vigor)


func test_perfect_parry_returns_wave_to_original_attacker() -> void:
	var duel: DuelFixture = _duel()
	_start(duel)
	assert_true(duel.step_until(func() -> bool:
		for wave in duel.sim.projectiles:
			if wave.active and absf(wave.x - duel.fighter(1).x) < 70.0:
				return true
		return false, 120))
	duel.press(1, Intent.Command.BLOCK)
	duel.step(60)
	assert_eq(duel.count_events(CombatEvent.Type.PROJECTILE_REFLECTED), 1)
	assert_lt(duel.fighter(0).health, duel.fighter(0).max_health)
	assert_almost(duel.fighter(1).health, duel.fighter(1).max_health)


func test_wave_has_range_and_no_apex_repeat() -> void:
	var duel: DuelFixture = _duel()
	duel.place(700.0)
	duel.set_level(0, 10)
	_start(duel)
	duel.step(160)
	assert_eq(duel.count_events(CombatEvent.Type.PROJECTILE_SPAWNED), 1)
	assert_eq(duel.count_events(CombatEvent.Type.HIT), 0)
	for wave in duel.sim.projectiles:
		assert_false(wave.active)


func test_wave_triggers_waist_on_deciding_ko() -> void:
	var duel: DuelFixture = _duel()
	duel.sim.rules.rounds_to_win = 1
	duel.fighter(1).health = 1.0
	_start(duel)
	duel.step(70)
	assert_eq(duel.fighter(1).finisher_kind, Finisher.Kind.WAIST)


func test_arsenal_intercepts_wave() -> void:
	var duel: DuelFixture = _duel()
	duel.fighter(1).arsenal_count = 2
	duel.fighter(1).arsenal_ticks = 300
	_start(duel)
	duel.step(70)
	assert_eq(duel.fighter(1).arsenal_count, 1)
	assert_almost(duel.fighter(1).health, duel.fighter(1).max_health)


func test_catalog_and_old_save_drop_removed_power() -> void:
	assert_true(CATALOG.find(&"flow_cleave") == null)
	assert_true(CATALOG.techniques.has(CUT))
	var saved: Dictionary = StoryCampaign.create("Iria", 0, 0, 0, 0, 1).to_dict()
	saved["learned"] = [&"repulse", &"flow_cleave", &"unknown"]
	saved["equipped"] = [&"flow_cleave", &"repulse", &""]
	var campaign: StoryCampaign = StoryCampaign.from_dict(saved)
	assert_eq(campaign.learned.size(), 1)
	assert_eq(campaign.equipped[0], &"repulse")


func _waves(duel: DuelFixture) -> int:
	return duel.count_events(CombatEvent.Type.PROJECTILE_SPAWNED)


func test_pressing_again_throws_a_second_wave_once() -> void:
	var duel: DuelFixture = _duel()
	duel.place(500.0)
	var vigor: float = duel.fighter(0).vigor
	_start(duel)
	duel.step_until(func() -> bool: return duel.fighter(0).is_active(), 30)
	duel.press(0, Intent.Command.SPECIAL)
	duel.step()
	duel.release(0)
	assert_true(duel.step_until(func() -> bool: return _waves(duel) == 2, 60), "the follow-up throws a second wave")
	assert_eq(duel.fighter(0).move, CUT.follow_up)
	assert_almost(duel.fighter(0).vigor, vigor - CUT.vigor_cost - CUT.follow_up.vigor_cost, 2.0)
	duel.press(0, Intent.Command.SPECIAL)
	duel.step()
	duel.release(0)
	duel.step(40)
	assert_eq(_waves(duel), 2, "only two waves in a row")


func test_without_a_second_press_only_one_wave_leaves() -> void:
	var duel: DuelFixture = _duel()
	duel.place(500.0)
	_start(duel)
	duel.step(60)
	assert_eq(_waves(duel), 1)


func test_wave_grows_with_the_flow_tier() -> void:
	var sizes: Array[float] = []
	for level in [1, 4, 7, 10]:
		var duel: DuelFixture = _duel()
		duel.place(500.0)
		duel.set_level(0, level)
		_start(duel)
		duel.step_until(func() -> bool: return _waves(duel) == 1, 30)
		for wave in duel.sim.projectiles:
			if wave.active and wave.kind == Projectile.Kind.CLEAVE:
				sizes.append(wave.size)
	assert_eq(sizes.size(), 4)
	assert_almost(sizes[0], CUT.projectile_size)
	for i in 3:
		assert_gt(sizes[i + 1], sizes[i], "tier %d wave is larger" % (i + 2))
