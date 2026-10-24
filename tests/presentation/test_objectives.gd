extends TestCase

const TRAINING: TrainingConfig = preload("res://data/balance/training_config.tres")
const TABLE: String = "res://localization/strings.csv"


func _feed(fixture: DuelFixture, objective: DuelObjective, ticks: int) -> void:
	for tick in ticks:
		fixture.step(1)
		for i in fixture.sim.event_count:
			objective.on_event(fixture.sim.events[i], fixture.sim)
		objective.on_tick(fixture.sim)


func test_lesson_advances_on_light_hits() -> void:
	var lesson: LessonData = LessonData.new()
	var step: LessonStep = LessonStep.new()
	step.goal = LessonStep.Goal.LIGHT_HIT
	step.count = 2
	lesson.steps = [step]
	var fixture: DuelFixture = DuelFixture.create()
	fixture.skip_intro()
	fixture.place(60.0)
	var tracker: LessonTracker = LessonTracker.new(lesson, null, TRAINING)
	fixture.press(0, Intent.Command.LIGHT)
	_feed(fixture, tracker, 30)
	assert_eq(tracker.progress, 1)
	assert_false(tracker.done)
	fixture.place(60.0)
	fixture.press(0, Intent.Command.LIGHT)
	_feed(fixture, tracker, 30)
	assert_true(tracker.done)


func test_parry_points() -> void:
	var tracker: ParryTracker = ParryTracker.new(45.0)
	var fixture: DuelFixture = DuelFixture.create()
	var parry: CombatEvent = CombatEvent.new()
	parry.type = CombatEvent.Type.PARRY
	parry.target = 0
	parry.heavy = true
	tracker.on_event(parry, fixture.sim)
	parry.type = CombatEvent.Type.PERFECT_PARRY
	tracker.on_event(parry, fixture.sim)
	assert_eq(tracker.points, 3)


func test_lesson_and_challenge_texts_exist() -> void:
	var keys: Dictionary = {}
	var file: FileAccess = FileAccess.open(TABLE, FileAccess.READ)
	file.get_csv_line()
	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		if row.size() >= 3 and row[1] != "" and row[2] != "":
			keys[row[0]] = true
	for name in DirAccess.get_files_at("res://data/lessons"):
		if name.ends_with(".tres"):
			var lesson: LessonData = load("res://data/lessons/" + name)
			for key in [lesson.title_key, lesson.done_key]:
				assert_true(keys.has(key), key)
			for step in lesson.steps:
				assert_true(keys.has(step.text_key), step.text_key)
	for name in DirAccess.get_files_at("res://data/challenges"):
		if name.ends_with(".tres"):
			var challenge: ChallengeData = load("res://data/challenges/" + name)
			assert_true(keys.has(challenge.title_key) and keys.has(challenge.description_key), String(challenge.id))
			assert_true(challenge.arena != null, String(challenge.id))


func test_guided_evade_ends_with_spin_dodges() -> void:
	var lesson: LessonData = load("res://data/lessons/guided_evade.tres")
	assert_eq(lesson.steps[lesson.steps.size() - 1].goal, LessonStep.Goal.SPIN_DODGE)
	var single: LessonData = LessonData.new()
	single.steps = [lesson.steps[lesson.steps.size() - 1]]
	var fixture: DuelFixture = DuelFixture.create()
	fixture.skip_intro()
	var tracker: LessonTracker = LessonTracker.new(single, null, TRAINING)
	for attempt in single.steps[0].count:
		fixture.place(30.0)
		fixture.intents[0].move_x = 1
		fixture.press(0, Intent.Command.DODGE)
		_feed(fixture, tracker, 1)
		fixture.intents[0].move_x = 0
		_feed(fixture, tracker, 40)
	assert_true(tracker.done)


func test_chain_step_closes_with_the_last_light_of_a_two_hit_chain() -> void:
	var lesson: LessonData = LessonData.new()
	var step: LessonStep = LessonStep.new()
	step.goal = LessonStep.Goal.CHAIN_HIT
	lesson.steps = [step]
	var fixture: DuelFixture = DuelFixture.create()
	fixture.skip_intro()
	fixture.place(40.0)
	assert_eq(fixture.fighter(0).character.light_chain.size(), 2, "the guardian chain has two lights")
	var tracker: LessonTracker = LessonTracker.new(lesson, null, TRAINING)
	fixture.press(0, Intent.Command.LIGHT)
	for tick in 40:
		if fixture.fighter(0).move_phase == FighterState.Phase.RECOVERY:
			fixture.press(0, Intent.Command.LIGHT)
		_feed(fixture, tracker, 1)
	assert_true(tracker.done)
