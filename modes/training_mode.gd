class_name TrainingMode
extends DuelMode


func build_setup() -> DuelSetup:
	var setup: DuelSetup = DuelSetup.new()
	setup.characters = [GUARDIAN, SHADOW]
	setup.controllers = [DuelSetup.ControllerKind.PLAYER, DuelSetup.ControllerKind.DUMMY]
	setup.hold_to_lock = [Settings.hold_to_lock[0], false]
	setup.rules = MatchRules.new()
	setup.rules.endless = true
	setup.arena = DEFAULT_ARENA
	setup.match_seed = _new_seed()
	setup.training = true
	return setup


func result_options() -> Array[StringName]:
	return [&"menu"]
