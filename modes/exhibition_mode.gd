class_name ExhibitionMode
extends DuelMode

const SEQUENCE: ExhibitionData = preload("res://data/exhibition/exhibition.tres")
const SHOWCASE: ExhibitionData = preload("res://data/exhibition/showcase.tres")

var data: ExhibitionData
var index: int = 0


func _init(exhibition: ExhibitionData = SEQUENCE) -> void:
	data = exhibition


func steps() -> Array[StringName]:
	return []


func bout() -> ExhibitionBout:
	return data.bouts[index]


func build_setup() -> DuelSetup:
	var current: ExhibitionBout = bout()
	var setup: DuelSetup = DuelSetup.new()
	setup.characters.assign(current.characters)
	for i in current.characters.size():
		setup.costumes.append(current.characters[i].costumes[current.costumes[i]])
	setup.controllers = [DuelSetup.ControllerKind.CHOREOGRAPHY, DuelSetup.ControllerKind.CHOREOGRAPHY]
	setup.bout = current
	setup.bout_skip_key = "HINT_NEXT_BOUT" if index + 1 < data.bouts.size() else "HINT_SKIP"
	setup.rules = MatchRules.new()
	setup.rules.rounds_to_win = 1
	setup.rules.free_powers = true
	setup.rules.fixed_finishers = true
	setup.rules.fighter_intros = current.fighter_intros
	setup.rules.start_health = current.start_health
	setup.arena = current.arena
	setup.match_seed = current.match_seed
	setup.power_sets = [current.powers_left, current.powers_right]
	setup.flow_levels.assign(current.flow_levels)
	setup.fill_default_looks()
	return setup


func after_match() -> bool:
	index += 1
	if index < data.bouts.size():
		start()
	else:
		SceneRouter.change(&"menu")
	return true


func result_options() -> Array[StringName]:
	return [&"menu"]
