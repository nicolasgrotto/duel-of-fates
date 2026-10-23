class_name ParryChallengeMode
extends DuelMode

const TRAINING: TrainingConfig = preload("res://data/balance/training_config.tres")

var tracker: ParryTracker


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
	setup.banner = TranslationServer.translate("PARRY_CHALLENGE_BANNER").format({"best": SaveService.parry_best})
	return _finish_setup(setup)


func create_objective(dummy: DummyController) -> DuelObjective:
	tracker = ParryTracker.new(TRAINING.parry_challenge_time)
	if dummy != null:
		dummy.set_behavior(DummyController.Behavior.HEAVY)
	return tracker


func finish(_winner: int, _sim: MatchSimulation, _seconds: float) -> void:
	if tracker != null:
		tracker.record = SaveService.record_parry(tracker.points)


func result_options() -> Array[StringName]:
	return [&"retry", &"menu"]


func result_title() -> String:
	return tracker.result_title() if tracker != null else ""


func result_note() -> String:
	return tracker.result_note() if tracker != null else ""
