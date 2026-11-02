extends TestCase

const TRAINING: TrainingConfig = preload("res://data/balance/training_config.tres")
const TUTORIAL: LessonData = preload("res://data/lessons/tutorial.tres")
const STANCE_LEAD_TICKS: int = 8


func _tick(fixture: DuelFixture, tracker: LessonTracker) -> void:
	tracker.dummy.produce(fixture.sim, 1, fixture.intents[1])
	fixture.step()
	for i in fixture.sim.event_count:
		tracker.on_event(fixture.sim.events[i], fixture.sim)
	tracker.on_tick(fixture.sim)


func _tracker_at(key: String) -> LessonTracker:
	var tracker: LessonTracker = LessonTracker.new(TUTORIAL, DummyController.new(TRAINING, 7), TRAINING)
	for index in TUTORIAL.steps.size():
		if TUTORIAL.steps[index].text_key == key:
			tracker.step_index = index
	tracker._enter_step()
	return tracker


func test_finishing_the_last_step_holds_the_lesson_before_ending() -> void:
	var fixture: DuelFixture = DuelFixture.create()
	fixture.skip_intro()
	var tracker: LessonTracker = _tracker_at("TUT_ABILITY_ANSWER")
	tracker.progress = tracker.step().count - 1
	tracker._advance()
	assert_false(tracker.done)
	assert_true(tracker.is_closing())
	assert_eq(tracker.instruction(), tracker.result_title())
	for tick in Ticks.from_seconds(TRAINING.lesson_close_seconds) - 1:
		tracker.on_tick(fixture.sim)
	assert_false(tracker.done)
	tracker.on_tick(fixture.sim)
	assert_true(tracker.done)


func test_tutorial_ends_with_an_ability_explanation_and_a_practice_step() -> void:
	var last: LessonStep = TUTORIAL.steps[-1]
	var before: LessonStep = TUTORIAL.steps[-2]
	assert_eq(before.goal, LessonStep.Goal.ABILITY)
	assert_eq(last.goal, LessonStep.Goal.ABILITY_ANSWER)
	assert_eq(last.dummy, DummyController.Behavior.ATTACK)
	assert_gt(float(last.count), 1.0)
	for locale in ["pt_BR", "en"]:
		var saved: String = TranslationServer.get_locale()
		TranslationServer.set_locale(locale)
		assert_ne(TranslationServer.translate(last.text_key), last.text_key)
		TranslationServer.set_locale(saved)


func _tick_scripted(fixture: DuelFixture, tracker: LessonTracker) -> void:
	fixture.step()
	for i in fixture.sim.event_count:
		tracker.on_event(fixture.sim.events[i], fixture.sim)
	tracker.on_tick(fixture.sim)


func test_real_counterguard_answer_counts_for_the_practice_step() -> void:
	var fixture: DuelFixture = DuelFixture.create()
	fixture.skip_intro()
	var tracker: LessonTracker = _tracker_at("TUT_ABILITY_ANSWER")
	tracker.dummy.set_behavior(DummyController.Behavior.STAND)
	fixture.place(60.0)
	fixture.press(1, Intent.Command.HEAVY)
	_tick_scripted(fixture, tracker)
	var startup: int = fixture.fighter(1).move.startup_ticks()
	for tick in maxi(startup - STANCE_LEAD_TICKS, 0):
		_tick_scripted(fixture, tracker)
	fixture.press(0, Intent.Command.SPECIAL)
	for tick in 60:
		_tick_scripted(fixture, tracker)
	assert_eq(tracker.progress, 1, "responses %d" % fixture.count_events(CombatEvent.Type.RESPONSE))


func test_plain_parry_without_the_ability_does_not_count() -> void:
	var fixture: DuelFixture = DuelFixture.create()
	fixture.skip_intro()
	var tracker: LessonTracker = _tracker_at("TUT_ABILITY_ANSWER")
	var event: CombatEvent = CombatEvent.new()
	event.type = CombatEvent.Type.PERFECT_PARRY
	event.source = 1
	event.target = 0
	tracker.on_event(event, fixture.sim)
	assert_eq(tracker.progress, 0)
