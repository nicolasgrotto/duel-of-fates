class_name ExhibitionMode
extends DuelMode

const EXHIBITION: ExhibitionData = preload("res://data/exhibition/exhibition.tres")

var index: int = 0


func steps() -> Array[StringName]:
	return []


func bout() -> ExhibitionBout:
	return EXHIBITION.bouts[index]


func build_setup() -> DuelSetup:
	var current: ExhibitionBout = bout()
	var setup: DuelSetup = DuelSetup.new()
	setup.characters.assign(current.characters)
	for i in current.characters.size():
		setup.costumes.append(current.characters[i].costumes[current.costumes[i]])
	setup.controllers = [DuelSetup.ControllerKind.CHOREOGRAPHY, DuelSetup.ControllerKind.CHOREOGRAPHY]
	setup.bout = current
	setup.rules = MatchRules.new()
	setup.rules.rounds_to_win = 1
	setup.rules.free_powers = true
	setup.rules.fighter_intros = current.fighter_intros
	setup.rules.start_health = current.start_health
	setup.arena = current.arena
	setup.match_seed = current.match_seed
	setup.power_sets = [current.powers_left, current.powers_right]
	setup.fill_default_looks()
	return setup


func after_match() -> bool:
	index += 1
	if index < EXHIBITION.bouts.size():
		start()
	else:
		SceneRouter.change(&"menu")
	return true


func result_options() -> Array[StringName]:
	return [&"menu"]
