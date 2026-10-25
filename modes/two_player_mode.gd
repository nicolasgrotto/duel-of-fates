class_name TwoPlayerMode
extends DuelMode


func steps() -> Array[StringName]:
	return [&"player_one", &"player_two", &"arena"]


func build_setup() -> DuelSetup:
	var setup: DuelSetup = DuelSetup.new()
	setup.characters = [GUARDIAN, SHADOW]
	setup.controllers = [DuelSetup.ControllerKind.PLAYER, DuelSetup.ControllerKind.PLAYER]
	setup.player_slots = [0, 1]
	setup.hold_to_lock = [Settings.hold_to_lock[0], Settings.hold_to_lock[1]]
	setup.difficulty = Settings.difficulty_data()
	setup.rules = MatchRules.new()
	setup.rules.fighter_intros = Settings.fighter_intros
	setup.rules.powers = Settings.powers
	setup.arena = DEFAULT_ARENA
	setup.match_seed = _new_seed()
	setup.two_players = true
	return _finish_setup(setup)
