class_name VersusMode
extends DuelMode


func build_setup() -> DuelSetup:
	var setup: DuelSetup = DuelSetup.new()
	setup.characters = [GUARDIAN, SHADOW]
	setup.controllers = [DuelSetup.ControllerKind.PLAYER, DuelSetup.ControllerKind.AI]
	setup.hold_to_lock = [Settings.hold_to_lock[0], false]
	setup.difficulty = Settings.difficulty_data()
	setup.rules = MatchRules.new()
	setup.rules.fighter_intros = Settings.fighter_intros
	setup.rules.powers = Settings.powers
	setup.arena = DEFAULT_ARENA
	setup.match_seed = _new_seed()
	return _finish_setup(setup)
