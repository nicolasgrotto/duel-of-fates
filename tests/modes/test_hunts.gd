extends TestCase

const CONFIG: CombatConfig = preload("res://data/balance/combat_config.tres")


func _runner(hunt_index: int = 0) -> TickRunner:
	var mode: HuntMode = HuntMode.new(HuntMode.HUNTS[hunt_index])
	var setup: DuelSetup = mode.build_setup()
	setup.rules.round_intro = false
	var sim: MatchSimulation = MatchSimulation.new(CONFIG, setup.rules, setup.characters, 91)
	sim.start_match()
	var runner: TickRunner = TickRunner.new()
	runner.start(sim, [ChoreographyController.new(ExhibitionBout.new(), 0), ChoreographyController.new(ExhibitionBout.new(), 1)])
	runner.objective = mode.tracker
	runner.step_once()
	return runner


func test_three_complete_hunts_use_independent_arena_profiles_and_rewards() -> void:
	var arenas: Dictionary = {}
	for hunt in HuntMode.HUNTS:
		assert_eq(hunt.phases.size(), 3)
		assert_true(hunt.condition != null)
		assert_false(hunt.before.is_empty())
		assert_false(hunt.after.is_empty())
		assert_false(hunt.unlocks.is_empty())
		assert_false(arenas.has(hunt.arena.id))
		arenas[hunt.arena.id] = true
		var previous: float = 2.0
		for phase in hunt.phases:
			assert_lt(phase.health_threshold, previous)
			previous = phase.health_threshold
			assert_true(phase.profile != null)
			assert_eq(phase.powers.size(), 3)
			for power in phase.powers:
				assert_true(phase.flow_level >= power.min_level)


func test_thresholds_are_inclusive_once_and_do_not_reverse_on_heal() -> void:
	var runner: TickRunner = _runner()
	var tracker: HuntTracker = runner.objective as HuntTracker
	var announcements: PackedStringArray = []
	tracker.announced.connect(func(key: String) -> void: announcements.append(key))
	var boss: FighterState = runner.sim.fighters[1]
	assert_eq(tracker.phase_index, 0)
	boss.health = boss.max_health * 0.65 + 0.01
	runner.step_once()
	assert_eq(tracker.phase_index, 0)
	boss.health = boss.max_health * 0.65
	runner.step_once()
	assert_eq(tracker.phase_index, 1)
	boss.health = boss.max_health
	runner.step_once()
	assert_eq(tracker.phase_index, 1)
	boss.health = boss.max_health * 0.30
	runner.step_once()
	assert_eq(tracker.phase_index, 2)
	for tick in 10:
		runner.step_once()
	assert_eq(announcements.size(), 2)
	assert_eq(boss.powers[0].kind, PowerData.Kind.HIGHER_INSTINCT)
	assert_eq(boss.flow_level, 8)
	runner.free()


func test_skipped_thresholds_advance_in_order_without_reviving() -> void:
	var runner: TickRunner = _runner()
	var tracker: HuntTracker = runner.objective as HuntTracker
	var phases: Array[String] = []
	tracker.announced.connect(func(key: String) -> void: phases.append(key))
	runner.sim.fighters[1].health = runner.sim.fighters[1].max_health * 0.2
	runner.step_once()
	assert_eq(phases, [tracker.hunt.phases[1].title_key, tracker.hunt.phases[2].title_key])
	assert_almost(runner.sim.fighters[1].health_ratio(), 0.2)
	runner.sim.kill(runner.sim.fighters[1], runner.sim.fighters[0], null)
	runner.step_once()
	assert_false(runner.sim.fighters[1].is_alive())
	assert_eq(phases, [tracker.hunt.phases[1].title_key, tracker.hunt.phases[2].title_key])
	runner.free()


func test_phase_waits_for_an_active_power_to_resolve() -> void:
	var runner: TickRunner = _runner(2)
	var tracker: HuntTracker = runner.objective as HuntTracker
	var boss: FighterState = runner.sim.fighters[1]
	boss.health = boss.max_health * 0.65
	runner.step_once()
	assert_eq(tracker.phase_index, 1)
	var bout: ExhibitionBout = ExhibitionBout.new()
	var cue: ExhibitionCue = ExhibitionCue.new()
	cue.fighter = 1
	cue.command = Intent.Command.POWER
	bout.cues.append(cue)
	runner.controllers[1] = ChoreographyController.new(bout, 1)
	runner.step_once()
	for tick in 45:
		runner.step_once()
	assert_gt(boss.singularity_ticks, 0)
	boss.health = boss.max_health * 0.30
	runner.step_once()
	assert_eq(tracker.phase_index, 1)
	for tick in 350:
		runner.step_once()
	assert_eq(tracker.phase_index, 2)
	runner.free()


func test_perfect_parry_condition_accepts_only_player_defending_heavies() -> void:
	var runner: TickRunner = _runner()
	var tracker: HuntTracker = runner.objective as HuntTracker
	var event: CombatEvent = CombatEvent.new()
	event.type = CombatEvent.Type.PERFECT_PARRY
	event.source = 0
	event.target = 1
	event.heavy = true
	tracker.on_event(event, runner.sim)
	assert_eq(tracker.perfect_parries, 0)
	event.source = 1
	event.target = 0
	event.heavy = false
	tracker.on_event(event, runner.sim)
	assert_eq(tracker.perfect_parries, 0)
	event.heavy = true
	for i in 2:
		tracker.on_event(event, runner.sim)
	assert_false(tracker.condition_met())
	tracker.on_event(event, runner.sim)
	assert_true(tracker.condition_met())
	runner.free()


func test_scripted_heavy_parry_counts_real_combat_events() -> void:
	var runner: TickRunner = _runner()
	var tracker: HuntTracker = runner.objective as HuntTracker
	runner.sim.fighters[0].x = -60.0
	runner.sim.fighters[1].x = 60.0
	var bout: ExhibitionBout = ExhibitionBout.new()
	var heavy: ExhibitionCue = ExhibitionCue.new()
	heavy.fighter = 1
	heavy.command = Intent.Command.HEAVY
	var guard: ExhibitionCue = ExhibitionCue.new()
	guard.fighter = 0
	guard.command = Intent.Command.BLOCK
	guard.at = runner.sim.fighters[1].character.heavy.startup_ticks() - 2
	guard.hold = 8
	bout.cues = [heavy, guard]
	runner.controllers = [ChoreographyController.new(bout, 0), ChoreographyController.new(bout, 1)]
	for tick in 75:
		runner.step_once()
	assert_eq(tracker.perfect_parries, 1)
	assert_false(tracker.condition_met())
	runner.free()


func test_timer_has_exact_boundary_and_excludes_intro_ko() -> void:
	var runner: TickRunner = _runner(1)
	var tracker: HuntTracker = runner.objective as HuntTracker
	tracker.fight_ticks = Ticks.from_seconds(tracker.hunt.condition.seconds)
	assert_true(tracker.condition_met())
	runner.step_once()
	assert_false(tracker.condition_met())
	var elapsed: int = tracker.fight_ticks
	runner.sim.phase = MatchSimulation.Phase.INTRO
	tracker.on_tick(runner.sim)
	runner.sim.phase = MatchSimulation.Phase.KO
	tracker.on_tick(runner.sim)
	assert_eq(tracker.fight_ticks, elapsed)
	runner.free()


func test_the_lethal_tick_counts_toward_the_deadline() -> void:
	for extra_tick in [0, 1]:
		var runner: TickRunner = _runner(1)
		var tracker: HuntTracker = runner.objective as HuntTracker
		tracker.fight_ticks = Ticks.from_seconds(tracker.hunt.condition.seconds) - 1 + extra_tick
		runner.sim.kill(runner.sim.fighters[1], runner.sim.fighters[0], null)
		runner.step_once()
		assert_eq(runner.sim.phase, MatchSimulation.Phase.KO)
		assert_eq(tracker.condition_met(), extra_tick == 0)
		var final_ticks: int = tracker.fight_ticks
		for tick in 20:
			runner.step_once()
		assert_eq(tracker.fight_ticks, final_ticks)
		runner.free()


func test_scripted_singularity_must_launch_and_finish_while_both_live() -> void:
	var runner: TickRunner = _runner(2)
	var tracker: HuntTracker = runner.objective as HuntTracker
	var boss: FighterState = runner.sim.fighters[1]
	boss.health = boss.max_health * 0.65
	runner.step_once()
	var bout: ExhibitionBout = ExhibitionBout.new()
	var cast: ExhibitionCue = ExhibitionCue.new()
	cast.fighter = 1
	cast.command = Intent.Command.POWER
	bout.cues = [cast]
	runner.controllers = [ChoreographyController.new(bout, 0), ChoreographyController.new(bout, 1)]
	assert_false(tracker.condition_met())
	for tick in 160:
		runner.step_once()
	assert_false(tracker.condition_met())
	for tick in 220:
		runner.step_once()
	assert_true(runner.sim.fighters[0].is_alive())
	assert_true(tracker.condition_met())
	runner.free()


func test_killing_the_caster_during_the_field_does_not_count_as_survival() -> void:
	var runner: TickRunner = _runner(2)
	var tracker: HuntTracker = runner.objective as HuntTracker
	var boss: FighterState = runner.sim.fighters[1]
	boss.health = boss.max_health * 0.65
	runner.step_once()
	var power: PowerData = boss.powers[0]
	var event: CombatEvent = runner.sim.emit(CombatEvent.Type.POWER_ACTIVE, 1, 0)
	event.power = power
	tracker.on_event(event, runner.sim)
	runner.sim.kill(boss, runner.sim.fighters[0], null)
	for tick in 300:
		runner.step_once()
	assert_false(tracker.condition_met())
	runner.free()


func test_ai_opens_phases_with_normal_intents_and_does_not_mutate_state() -> void:
	for index in 3:
		var runner: TickRunner = _runner(index)
		var tracker: HuntTracker = runner.objective as HuntTracker
		var boss: FighterState = runner.sim.fighters[1]
		boss.health = boss.max_health * 0.30
		runner.step_once()
		var ai: HuntController = HuntController.new(tracker, 22)
		var before: Dictionary = runner.sim.capture()
		var intent: Intent = Intent.new()
		ai.produce(runner.sim, 1, intent)
		assert_eq(runner.sim.capture(), before)
		assert_eq(intent.pressed, Intent.Command.POWER)
		runner.controllers[1] = ai
		for tick in 70:
			runner.step_once()
		assert_true(tracker.opening_activated, String(tracker.hunt.id))
		runner.free()


func test_replay_repeats_phases_and_power_state_without_touching_the_live_tracker() -> void:
	var runner: TickRunner = _runner(2)
	var original: HuntTracker = runner.objective as HuntTracker
	runner.sim.fighters[1].health = runner.sim.fighters[1].max_health * 0.28
	var snapshot: Dictionary = runner.sim.capture()
	var clone: MatchSimulation = MatchSimulation.new(CONFIG, runner.sim.rules, [runner.sim.fighters[0].character, runner.sim.fighters[1].character], 91)
	clone.restore(snapshot)
	var replay: HuntTracker = HuntTracker.new(original.hunt)
	var neutral: Intent = Intent.new()
	for tick in 180:
		runner.step_once()
		clone.step(neutral, neutral)
		TickRunner.advance_objective(clone, replay)
	assert_eq(runner.sim.capture(), clone.capture())
	assert_eq(original.phase_index, replay.phase_index)
	assert_eq(original.phase_index, 2)
	var count: int = original.fight_ticks
	TickRunner.advance_objective(clone, replay)
	assert_eq(original.fight_ticks, count)
	runner.free()


func test_hunt_setup_keeps_shared_characters_unchanged() -> void:
	var source: CharacterData = DuelMode.GUARDIAN
	var original_flow: int = source.flow
	var original_powers: Array[PowerData] = source.powers.duplicate()
	var mode: HuntMode = HuntMode.new(HuntMode.HUNTS[0])
	var setup: DuelSetup = mode.build_setup()
	assert_eq(setup.characters[0].flow, 7)
	assert_ne(setup.characters[0], source)
	assert_eq(source.flow, original_flow)
	assert_eq(source.powers, original_powers)
	assert_eq(setup.rules.rounds_to_win, 1)
	assert_true(setup.rules.powers)


func _scripted_victory(index: int, meets_condition: bool) -> Dictionary:
	var runner: TickRunner = _runner(index)
	var tracker: HuntTracker = runner.objective as HuntTracker
	runner.sim.fighters[0].x = -60.0
	runner.sim.fighters[1].x = 60.0
	var bout: ExhibitionBout = ExhibitionBout.new()
	if index == 0:
		var guard_delay: int = runner.sim.fighters[1].character.heavy.startup_ticks() - 2
		for at in [0, 110, 220]:
			_add_cue(bout, 1, at, Intent.Command.HEAVY)
			if meets_condition or at < 220:
				_add_cue(bout, 0, at + guard_delay, Intent.Command.BLOCK, 8)
		for at in range(360, 1920, 120):
			_add_cue(bout, 0, at, Intent.Command.HEAVY, 1, 1)
	elif index == 1:
		if not meets_condition:
			tracker.hunt = tracker.hunt.duplicate() as HuntData
			tracker.hunt.condition = tracker.hunt.condition.duplicate() as HuntCondition
			tracker.hunt.condition.seconds = 1.0
		for at in range(0, 1920, 120):
			_add_cue(bout, 0, at, Intent.Command.HEAVY, 1, 1)
	else:
		for at in [0, 120, 240]:
			_add_cue(bout, 0, at, Intent.Command.HEAVY, 1, 1)
		_add_cue(bout, 1, 400, Intent.Command.POWER)
		for at in range(960 if meets_condition else 360, 1920, 120):
			_add_cue(bout, 0, at, Intent.Command.HEAVY, 1, 1)
	runner.controllers = [ChoreographyController.new(bout, 0), ChoreographyController.new(bout, 1)]
	for tick in 2200:
		runner.step_once()
		if runner.sim.phase == MatchSimulation.Phase.OVER:
			break
	var result: Dictionary = {"winner": runner.sim.match_winner, "met": tracker.condition_met(), "phase": tracker.phase_index}
	runner.free()
	return result


func _add_cue(bout: ExhibitionBout, fighter: int, at: int, command: int, hold: int = 1, move: int = 0) -> void:
	var cue: ExhibitionCue = ExhibitionCue.new()
	cue.fighter = fighter
	cue.at = at
	cue.command = command
	cue.hold = hold
	cue.move = move
	bout.cues.append(cue)


func test_scripted_duels_win_with_each_condition_satisfied_or_missed() -> void:
	for index in 3:
		for success in [true, false]:
			var result: Dictionary = _scripted_victory(index, success)
			assert_eq(result["winner"], 0, "hunt %d success %s" % [index, success])
			assert_eq(result["met"], success, "hunt %d condition" % index)
