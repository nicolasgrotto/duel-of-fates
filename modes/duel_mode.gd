class_name DuelMode
extends RefCounted

const CONFIG: CombatConfig = preload("res://data/balance/combat_config.tres")
const GUARDIAN: CharacterData = preload("res://data/characters/guardian/guardian.tres")
const SHADOW: CharacterData = preload("res://data/characters/shadow/shadow.tres")
const DEFAULT_ARENA: ArenaData = preload("res://data/arenas/refinery_platform.tres")
const TRAINING_ARENA: ArenaData = preload("res://data/arenas/training_platform.tres")
const ARENAS: Array[ArenaData] = [DEFAULT_ARENA, TRAINING_ARENA]

var selection: DuelSelection = DuelSelection.new()


func steps() -> Array[StringName]:
	return [&"player", &"opponent", &"arena"]


func build_setup() -> DuelSetup:
	return DuelSetup.new()


func result_options() -> Array[StringName]:
	return [&"rematch", &"menu"]


func start() -> void:
	SceneRouter.change(&"duel", {"mode": self})


func restart() -> void:
	start()


func choose(option: StringName) -> void:
	match option:
		&"rematch":
			restart()
		&"menu":
			SceneRouter.change(&"menu")


func _finish_setup(setup: DuelSetup) -> DuelSetup:
	setup.fill_default_looks()
	selection.apply_to(setup)
	return setup


func _new_seed() -> int:
	return randi()
