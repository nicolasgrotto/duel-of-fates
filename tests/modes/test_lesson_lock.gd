extends TestCase

const TRAINING: TrainingConfig = preload("res://data/balance/training_config.tres")
const TUTORIAL: LessonData = preload("res://data/lessons/tutorial.tres")
const GUIDED: LessonData = preload("res://data/lessons/guided_lock.tres")


func _tick(fixture: DuelFixture, tracker: LessonTracker) -> void:
	tracker.dummy.produce(fixture.sim, 1, fixture.intents[1])
	fixture.step()
	for i in fixture.sim.event_count:
		tracker.on_event(fixture.sim.events[i], fixture.sim)
	tracker.on_tick(fixture.sim)


func _win_lock(fixture: DuelFixture, tracker: LessonTracker, gap: float) -> void:
	fixture.place(gap)
	fixture.press(0, Intent.Command.HEAVY)
	for tick in 140:
		if BladeLockResolver.is_active(fixture.sim) and tick % 5 == 0:
			fixture.press(0, Intent.Command.LIGHT)
		_tick(fixture, tracker)
		if fixture.count_events(CombatEvent.Type.BLADE_LOCK_ENDED) > 0:
			return


func test_real_tutorial_mirror_lock_advances_at_several_gaps() -> void:
	for gap in [20.0, 40.0, 60.0]:
		var fixture: DuelFixture = DuelFixture.create()
		fixture.skip_intro()
		var dummy: DummyController = DummyController.new(TRAINING, 7)
		var tracker: LessonTracker = LessonTracker.new(TUTORIAL, dummy, TRAINING)
		for index in TUTORIAL.steps.size():
			if TUTORIAL.steps[index].text_key == "TUT_LOCK":
				tracker.step_index = index
		tracker._enter_step()
		var previous: int = tracker.step_index
		_win_lock(fixture, tracker, gap)
		assert_eq(fixture.count_events(CombatEvent.Type.BLADE_LOCK_STARTED), 1)
		assert_eq(fixture.count_events(CombatEvent.Type.HIT), 0)
		assert_eq(tracker.step_index, previous + 1)


func test_real_guided_mirror_locks_complete_the_three_lock_goal() -> void:
	var fixture: DuelFixture = DuelFixture.create()
	fixture.skip_intro()
	var dummy: DummyController = DummyController.new(TRAINING, 7)
	var tracker: LessonTracker = LessonTracker.new(GUIDED, dummy, TRAINING)
	for gap in [20.0, 40.0, 60.0]:
		fixture.step_until(func() -> bool: return fixture.sim.lock_cooldown_ticks == 0 and fixture.fighter(0).is_free() and fixture.fighter(1).is_free(), 400)
		fixture.clear_log()
		_win_lock(fixture, tracker, gap)
		assert_eq(fixture.count_events(CombatEvent.Type.BLADE_LOCK_STARTED), 1)
		assert_eq(fixture.count_events(CombatEvent.Type.HIT), 0)
	assert_eq(tracker.step_index, 1)
	assert_eq(tracker.step().goal, LessonStep.Goal.PRESS_WIN)
	fixture.step_until(func() -> bool: return fixture.sim.lock_cooldown_ticks == 0 and fixture.fighter(0).is_free() and fixture.fighter(1).is_free(), 400)
	for tick in 300:
		if not BladeLockResolver.is_active(fixture.sim):
			fixture.place(30.0)
		if fixture.fighter(0).is_free() and fixture.fighter(1).is_free():
			fixture.press(0, Intent.Command.LIGHT)
		elif BladeLockResolver.is_active(fixture.sim) and tick % 5 == 0:
			fixture.press(0, Intent.Command.LIGHT)
		_tick(fixture, tracker)
		if tracker.step_index == 2:
			break
	assert_eq(tracker.step_index, 2)
	fixture.release(0)
	fixture.release(1)
	fixture.step_until(func() -> bool: return fixture.sim.lock_cooldown_ticks == 0 and fixture.fighter(0).is_free() and fixture.fighter(1).is_free(), 400)
	fixture.place(30.0)
	for tick in 120:
		if fixture.fighter(0).is_free() and fixture.fighter(1).is_free():
			fixture.press(0, Intent.Command.HEAVY)
		if BladeLockResolver.can_disengage(fixture.sim):
			fixture.press(0, Intent.Command.HEAVY)
		_tick(fixture, tracker)
		if tracker.is_closing():
			break
	assert_true(tracker.is_closing(), "guided step %d phase %d states %d/%d locks %d disengages %d" % [tracker.step_index, fixture.sim.phase, fixture.fighter(0).state, fixture.fighter(1).state, fixture.count_events(CombatEvent.Type.BLADE_LOCK_STARTED), fixture.count_events(CombatEvent.Type.DISENGAGE)])
