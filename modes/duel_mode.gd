class_name DuelMode
extends RefCounted

const CONFIG: CombatConfig = preload("res://data/balance/combat_config.tres")
const GUARDIAN: CharacterData = preload("res://data/characters/guardian/guardian.tres")
const SHADOW: CharacterData = preload("res://data/characters/shadow/shadow.tres")
const DEFAULT_ARENA: ArenaData = preload("res://data/arenas/training_platform.tres")


func build_setup() -> DuelSetup:
	return DuelSetup.new()


func result_options() -> Array[StringName]:
	return [&"rematch", &"menu"]


func restart() -> void:
	SceneRouter.change(&"duel", {"mode": self})


func choose(option: StringName) -> void:
	match option:
		&"rematch":
			restart()
		&"menu":
			SceneRouter.change(&"menu")


func _new_seed() -> int:
	return randi()
