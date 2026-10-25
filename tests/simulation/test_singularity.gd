extends TestCase

const POWER: PowerData = preload("res://data/powers/singularity.tres")
const HARD: AiDifficultyData = preload("res://data/balance/ai/difficulty_hard.tres")


func _duel(active: bool = true) -> DuelFixture:
	var duel: DuelFixture = DuelFixture.versus(&"sovereign", &"guardian")
	duel.place(440.0)
	duel.set_level(0, 7)
	duel.set_level(1, 7)
	duel.give_power(0, &"singularity")
	if active:
		duel.cast(0)
		duel.step_until(func() -> bool: return duel.fighter(0).singularity_ticks > 0, 60)
	return duel


func _mark(duel: DuelFixture) -> Hazard:
	duel.step_until(func() -> bool:
		for hazard in duel.sim.hazards:
			if hazard.active and hazard.kind == Hazard.Kind.EXTRACTION:
				return true
		return false, 60)
	for hazard in duel.sim.hazards:
		if hazard.active and hazard.kind == Hazard.Kind.EXTRACTION:
			return hazard
	return null


func _mass(duel: DuelFixture) -> Projectile:
	var target: FighterState = duel.fighter(1)
	var projectile: Projectile = duel.sim.spawn_projectile(Projectile.Kind.SINGULARITY, duel.fighter(0), POWER)
	projectile.x = target.x - POWER.projectile_size
	projectile.y = target.y + POWER.target_height
	projectile.vx = POWER.speed
	projectile.vy = 0.0
	projectile.damage = POWER.damage
	projectile.size = POWER.projectile_size
	projectile.max_distance = POWER.throw_range
	projectile.delay_ticks = Ticks.from_seconds(POWER.throw_range / POWER.speed)
	return projectile


func test_warning_precedes_extraction_and_marked_fighter_is_lifted() -> void:
	var duel: DuelFixture = _duel()
	var mark: Hazard = _mark(duel)
	assert_true(mark != null)
	assert_eq(mark.delay_ticks, Ticks.from_seconds(POWER.warning))
	assert_eq(mark.total_delay, mark.delay_ticks)
	var health: float = duel.fighter(1).health
	var group: int = mark.group
	duel.step(mark.delay_ticks - 1)
	assert_true(mark.active)
	assert_almost(duel.fighter(1).health, health)
	duel.step()
	assert_true(not mark.active or mark.group != group)
	assert_lt(duel.fighter(1).health, health)
	assert_false(duel.fighter(1).on_ground)
	assert_eq(duel.fighter(1).state, FighterState.State.HELD)
	assert_gt(duel.fighter(1).vy, 0.0)


func test_running_leaves_marks_and_preserves_safe_ground() -> void:
	var duel: DuelFixture = _duel()
	_mark(duel)
	duel.intents[1].move_x = 1
	duel.step(Ticks.from_seconds(POWER.warning))
	assert_almost(duel.fighter(1).health, duel.fighter(1).max_health)
	assert_true(duel.fighter(1).on_ground)
	var marks: Array[float] = []
	for hazard in duel.sim.hazards:
		if hazard.kind == Hazard.Kind.EXTRACTION and hazard.total_delay > 0:
			marks.append(hazard.x)
	assert_true(absf(marks[0] - marks[1]) >= POWER.mark_half_width * 2.0 + POWER.safe_width)


func test_airborne_attraction_is_stronger_and_dodge_breaks_pull() -> void:
	var ground: DuelFixture = _duel()
	var air: DuelFixture = _duel()
	var from_x: float = ground.fighter(1).x
	air.press(1, Intent.Command.JUMP)
	ground.step(20)
	air.step(20)
	assert_gt(from_x - air.fighter(1).x, from_x - ground.fighter(1).x)
	assert_gt(air.fighter(1).y, 0.0)
	var field: GDScript = load("res://simulation/powers/singularity_field.gd")
	air.fighter(1).invulnerable_ticks = 10
	air.fighter(1).vx = 123.0
	air.fighter(1).vy = 234.0
	field.pull(air.sim, air.fighter(1))
	assert_almost(air.fighter(1).vx, 123.0)
	assert_almost(air.fighter(1).vy, 234.0)


func test_final_mass_ignores_guard_barrier_absorption_and_arsenal() -> void:
	for defense in [&"guard", &"barrier", &"absorption", &"arsenal", &"instinct"]:
		var duel: DuelFixture = _duel(false)
		var target: FighterState = duel.fighter(1)
		if defense == &"guard":
			duel.hold(1, Intent.Command.BLOCK)
			duel.step(15)
		elif defense in [&"barrier", &"absorption"]:
			duel.give_power(1, defense)
			duel.cast(1)
			duel.step(20)
		elif defense == &"arsenal":
			target.arsenal_count = 3
			target.arsenal_ticks = 100
		else:
			target.instinct_ticks = 200
			target.instinct_power = load("res://data/powers/higher_instinct.tres")
		_mass(duel)
		duel.step()
		assert_lt(target.health, target.max_health, str(defense))
		if defense == &"arsenal":
			assert_eq(target.arsenal_count, 3)
		if defense == &"instinct":
			assert_eq(target.instinct_ticks, 0)


func test_sanctuary_absorbs_mass_damage() -> void:
	var duel: DuelFixture = _duel(false)
	var target: FighterState = duel.fighter(1)
	target.sanctuary_hp = POWER.damage + 10.0
	target.sanctuary_ticks = 100
	_mass(duel)
	duel.step()
	assert_almost(target.health, target.max_health)
	assert_almost(target.sanctuary_hp, 10.0)
	assert_eq(target.state, FighterState.State.STAGGERED)


func test_final_mass_misses_invulnerable_dodge_and_target_outside_path() -> void:
	var dodge: DuelFixture = _duel(false)
	dodge.press(1, Intent.Command.DODGE)
	dodge.step()
	_mass(dodge)
	dodge.step()
	assert_almost(dodge.fighter(1).health, dodge.fighter(1).max_health)
	var outside: DuelFixture = _duel(false)
	var projectile: Projectile = _mass(outside)
	outside.fighter(1).y = projectile.y + projectile.size * 2.0
	outside.fighter(1).on_ground = false
	outside.step()
	assert_almost(outside.fighter(1).health, outside.fighter(1).max_health)


func test_formation_locks_aim_and_final_projectile_does_not_home() -> void:
	var duel: DuelFixture = _duel()
	duel.step_until(func() -> bool: return duel.fighter(0).singularity_phase == FighterState.SingularityPhase.FORMATION, 240)
	var aim: Vector2 = duel.fighter(0).singularity_aim
	duel.fighter(1).x = duel.sim.config.half_width() - 100.0
	duel.step_until(func() -> bool: return duel.fighter(0).singularity_ticks == 0, 60)
	assert_eq(duel.fighter(0).singularity_aim, aim)
	var found: bool = false
	for projectile in duel.sim.projectiles:
		if projectile.active and projectile.kind == Projectile.Kind.SINGULARITY:
			var expected: Vector2 = (aim - duel.fighter(0).singularity_center).normalized() * POWER.speed
			assert_eq(Vector2(projectile.vx, projectile.vy), expected)
			found = true
	assert_true(found)
	var health: float = duel.fighter(1).health
	duel.step(120)
	assert_almost(duel.fighter(1).health, health)
	for projectile in duel.sim.projectiles:
		assert_false(projectile.active)


func test_creation_is_interruptible_and_locked_below_flow_seven() -> void:
	var low: DuelFixture = _duel(false)
	low.set_level(0, 6)
	low.cast(0)
	assert_eq(low.count_events(CombatEvent.Type.POWER_REJECTED), 1)
	var interrupted: DuelFixture = _duel(false)
	interrupted.place(60.0)
	interrupted.cast(0)
	interrupted.press(1, Intent.Command.LIGHT)
	interrupted.step(60)
	assert_eq(interrupted.fighter(0).singularity_ticks, 0)
	assert_eq(interrupted.count_events(CombatEvent.Type.HAZARD_MARKED), 0)


func test_caster_moves_but_cannot_attack_or_recast_during_field() -> void:
	var duel: DuelFixture = _duel()
	duel.step(15)
	var from_x: float = duel.fighter(0).x
	duel.intents[0].move_x = -1
	duel.press(0, Intent.Command.LIGHT)
	duel.step(10)
	assert_lt(duel.fighter(0).x, from_x)
	assert_false(duel.fighter(0).is_attacking())
	duel.press(0, Intent.Command.POWER)
	duel.step()
	assert_eq(duel.count_events(CombatEvent.Type.POWER_STARTED), 1)


func test_snapshot_restores_marks_forces_and_diagonal_throw() -> void:
	var duel: DuelFixture = _duel()
	_mark(duel)
	var snapshot: Dictionary = duel.sim.capture()
	duel.step(320)
	var result: Dictionary = duel.sim.capture()
	duel.sim.restore(snapshot)
	duel.step(320)
	for key in result:
		assert_eq(duel.sim.capture()[key], result[key], "restored " + str(key))
	var fresh: DuelFixture = _duel()
	_mark(fresh)
	for key in snapshot:
		if key == "fighters":
			for index in 2:
				for field in snapshot[key][index]:
					assert_eq(fresh.sim.capture()[key][index][field], snapshot[key][index][field], "fresh " + str(index) + " " + str(field))
		else:
			assert_eq(fresh.sim.capture()[key], snapshot[key], "fresh " + str(key))


func test_only_final_mass_uses_blast_finisher_and_death_cancels_field() -> void:
	var final: DuelFixture = _duel(false)
	final.sim.rules.rounds_to_win = 1
	final.fighter(1).health = 1.0
	_mass(final)
	final.step()
	assert_eq(final.fighter(1).finisher_kind, Finisher.Kind.BLAST)
	var extraction: DuelFixture = _duel()
	extraction.sim.rules.rounds_to_win = 1
	extraction.fighter(1).health = 1.0
	_mark(extraction)
	extraction.step(Ticks.from_seconds(POWER.warning))
	assert_eq(extraction.fighter(1).finisher_kind, Finisher.Kind.NONE)
	var cancel: DuelFixture = _duel()
	_mark(cancel)
	cancel.sim.kill(cancel.fighter(0), cancel.fighter(1), null)
	cancel.step()
	assert_eq(cancel.fighter(0).singularity_ticks, 0)
	for hazard in cancel.sim.hazards:
		assert_false(hazard.active)


func test_ai_casts_at_midrange_and_stays_on_safe_ground() -> void:
	var duel: DuelFixture = _duel(false)
	assert_eq(AiPowers.offensive_slot(duel.sim, duel.fighter(0), duel.fighter(1), 440.0), 0)
	duel.fighter(1).on_ground = false
	assert_eq(AiPowers.offensive_slot(duel.sim, duel.fighter(0), duel.fighter(1), 440.0), AiPowers.NO_SLOT)
	duel = _duel()
	var ai: AiController = AiController.new(HARD, duel.fighter(1).character.ai_profile, 8)
	var jumps: int = 0
	var guards: int = 0
	for tick in 290:
		ai.produce(duel.sim, 1, duel.intents[1])
		if duel.intents[1].was_pressed(Intent.Command.JUMP):
			jumps += 1
		if duel.intents[1].is_held(Intent.Command.BLOCK):
			guards += 1
		duel.step()
		if duel.fighter(0).singularity_ticks == 0 and duel.count_events(CombatEvent.Type.PROJECTILE_ENDED) > 0:
			break
	assert_eq(jumps, 0)
	assert_eq(guards, 0)
	assert_almost(duel.fighter(1).health, duel.fighter(1).max_health)


func test_hard_ai_saves_meter_and_prioritizes_singularity_in_any_slot() -> void:
	var duel: DuelFixture = _duel(false)
	duel.fighter(0).powers[0] = load("res://data/powers/lightning.tres")
	duel.give_power(0, &"singularity", 2)
	duel.fighter(0).flow = POWER.cost - 2.0
	assert_true(AiPowers.spends_singularity_reserve(duel.fighter(0), 0))
	assert_eq(AiPowers.offensive_slot(duel.sim, duel.fighter(0), duel.fighter(1), 250.0, true), AiPowers.NO_SLOT)
	duel.fighter(0).flow = 100.0
	assert_eq(AiPowers.offensive_slot(duel.sim, duel.fighter(0), duel.fighter(1), 250.0, true), 2)


func test_diagonal_projectile_snapshot_and_pool_reuse_preserve_velocity() -> void:
	var original: DuelFixture = _duel(false)
	var projectile: Projectile = _mass(original)
	projectile.x -= POWER.projectile_size * 4.0
	projectile.vy = -POWER.speed * 0.2
	var snapshot: Dictionary = original.sim.capture()
	original.step(3)
	var replay: DuelFixture = _duel(false)
	replay.sim.restore(snapshot)
	replay.step(3)
	assert_eq(replay.sim.capture(), original.sim.capture())
	projectile.active = false
	var reused: Projectile = original.sim.spawn_projectile(Projectile.Kind.ROCK, original.fighter(0), load("res://data/powers/throw.tres"))
	assert_true(reused == projectile)
	assert_almost(reused.vy, 0.0)


func _wave_marks(level: int) -> Array[float]:
	var duel: DuelFixture = DuelFixture.versus(&"sovereign", &"guardian")
	duel.place(440.0)
	duel.set_level(0, level)
	duel.set_level(1, 7)
	duel.give_power(0, &"singularity")
	duel.cast(0)
	duel.step_until(func() -> bool: return duel.fighter(0).singularity_ticks > 0, 60)
	_mark(duel)
	var marks: Array[float] = []
	for hazard in duel.sim.hazards:
		if hazard.active and hazard.kind == Hazard.Kind.EXTRACTION:
			marks.append(hazard.x)
	return marks


func test_apex_tier_pulls_three_areas_with_safe_ground_between() -> void:
	assert_eq(_wave_marks(7).size(), 2, "tier III extracts two areas")
	var marks: Array[float] = _wave_marks(10)
	assert_eq(marks.size(), 3, "tier IV extracts three areas")
	marks.sort()
	for i in marks.size() - 1:
		assert_true(marks[i + 1] - marks[i] >= POWER.mark_half_width * 2.0 + POWER.safe_width - 0.01, "marks keep a safe lane")
