class_name TrainingMode
extends DuelMode


func steps() -> Array[StringName]:
	return [&"player", &"dummy"]


func build_setup() -> DuelSetup:
	var setup: DuelSetup = DuelSetup.new()
	setup.characters = [GUARDIAN, SHADOW]
	setup.controllers = [DuelSetup.ControllerKind.PLAYER, DuelSetup.ControllerKind.DUMMY]
	setup.hold_to_lock = [Settings.hold_to_lock[0], false]
	setup.rules = MatchRules.new()
	setup.rules.powers = Settings.powers
	setup.rules.endless = true
	setup.arena = TRAINING_ARENA
	setup.match_seed = _new_seed()
	setup.training = true
	_finish_setup(setup)
	setup.characters[1] = setup.characters[1].duplicate() as CharacterData
	return setup


func result_options() -> Array[StringName]:
	return [&"menu"]
