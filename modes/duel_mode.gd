class_name DuelMode
extends RefCounted

const CONFIG: CombatConfig = preload("res://data/balance/combat_config.tres")
const GUARDIAN: CharacterData = preload("res://data/characters/guardian/guardian.tres")
const SHADOW: CharacterData = preload("res://data/characters/shadow/shadow.tres")
const DEFAULT_ARENA: ArenaData = preload("res://data/arenas/refinery_platform.tres")
const TRAINING_ARENA: ArenaData = preload("res://data/arenas/training_platform.tres")
const ARENAS: Array[ArenaData] = [
	DEFAULT_ARENA,
	preload("res://data/arenas/flooded_sanctuary.tres"),
	preload("res://data/arenas/crystal_mine.tres"),
	preload("res://data/arenas/neon_rooftop.tres"),
	preload("res://data/arenas/orbital_ring.tres"),
	preload("res://data/arenas/luminous_forest.tres"),
	preload("res://data/arenas/glass_salt_flats.tres"),
	preload("res://data/arenas/skyborne_deck.tres"),
	preload("res://data/arenas/snowbound_peak.tres"),
	preload("res://data/arenas/eclipse_citadel.tres"),
	TRAINING_ARENA,
]
const ROTATION_SIZE: int = 10
const MODES: ModesConfig = preload("res://data/balance/modes_config.tres")
const BOSS_PATH: String = "res://data/characters/awakened_shadow/awakened_shadow.tres"
const BOSS_DIFFICULTY: AiDifficultyData = preload("res://data/balance/ai/difficulty_boss.tres")
const CHARACTER_PATH: String = "res://data/characters/%s/%s.tres"
const DIFFICULTY_PATH: String = "res://data/balance/ai/difficulty_%s.tres"
const CAST: Array[StringName] = [&"guardian", &"shadow", &"bastion", &"wasp", &"mirror", &"lance", &"ember", &"forge", &"heron", &"reaper", &"echo"]

var selection: DuelSelection = DuelSelection.new()


func steps() -> Array[StringName]:
	return [&"player", &"opponent", &"arena"]


func build_setup() -> DuelSetup:
	return DuelSetup.new()


func result_options() -> Array[StringName]:
	return [&"rematch", &"menu"]


func finish(_winner: int, _sim: MatchSimulation, _seconds: float) -> void:
	pass


func create_objective(_dummy: DummyController) -> DuelObjective:
	return null


func result_title() -> String:
	return ""


func result_note() -> String:
	return ""


static func difficulty(id: StringName) -> AiDifficultyData:
	return load(DIFFICULTY_PATH % id) as AiDifficultyData


static func character(id: StringName) -> CharacterData:
	return load(CHARACTER_PATH % [id, id]) as CharacterData


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
		&"next", &"retry":
			start()


func _finish_setup(setup: DuelSetup) -> DuelSetup:
	setup.fill_default_looks()
	selection.apply_to(setup)
	return setup


func _new_seed() -> int:
	return randi()
