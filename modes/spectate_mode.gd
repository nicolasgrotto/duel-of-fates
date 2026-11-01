class_name SpectateMode
extends DuelMode


func steps() -> Array[StringName]:
	return [&"fighter_one", &"fighter_two", &"arena"]


func build_setup() -> DuelSetup:
	var setup: DuelSetup = DuelSetup.new()
	setup.characters = [GUARDIAN, SHADOW]
	setup.controllers = [DuelSetup.ControllerKind.AI, DuelSetup.ControllerKind.AI]
	setup.difficulty = Settings.difficulty_data()
	setup.rules = MatchRules.new()
	setup.rules.fighter_intros = Settings.fighter_intros
	setup.rules.powers = Settings.powers
	setup.arena = DEFAULT_ARENA
	setup.match_seed = _new_seed()
	return _finish_setup(setup)


func result_title() -> String:
	return String(TranslationServer.translate("RESULT_SPECTATE"))
