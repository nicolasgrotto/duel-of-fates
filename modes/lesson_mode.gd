class_name LessonMode
extends DuelMode

const TRAINING: TrainingConfig = preload("res://data/balance/training_config.tres")
const TUTORIAL_ID: StringName = &"tutorial"

var lesson: LessonData
var tracker: LessonTracker


func _init(lesson_data: LessonData) -> void:
	lesson = lesson_data


func steps() -> Array[StringName]:
	return []


func build_setup() -> DuelSetup:
	var setup: DuelSetup = DuelSetup.new()
	setup.characters = [GUARDIAN, SHADOW]
	setup.controllers = [DuelSetup.ControllerKind.PLAYER, DuelSetup.ControllerKind.DUMMY]
	setup.hold_to_lock = [Settings.hold_to_lock[0], false]
	setup.rules = MatchRules.new()
	setup.rules.endless = true
	setup.rules.powers = false
	setup.arena = TRAINING_ARENA
	setup.match_seed = _new_seed()
	setup.training = true
	setup.objective = true
	return _finish_setup(setup)


func create_objective(dummy: DummyController) -> DuelObjective:
	tracker = LessonTracker.new(lesson, dummy, TRAINING)
	return tracker


func result_options() -> Array[StringName]:
	return [&"parry_challenge", &"menu"] if lesson.id == TUTORIAL_ID else [&"retry", &"menu"]


func result_title() -> String:
	return tracker.result_title() if tracker != null else ""


func choose(option: StringName) -> void:
	if option == &"parry_challenge":
		ParryChallengeMode.new().start()
		return
	super.choose(option)
