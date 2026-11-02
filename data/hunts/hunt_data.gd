class_name HuntData
extends Resource

@export var id: StringName
@export var title_key: String
@export var opponent: StringName
@export var arena: ArenaData
@export var difficulty: AiDifficultyData
@export var player: CharacterData
@export var player_flow: int = 7
@export var player_powers: Array[PowerData] = []
@export var phases: Array[HuntPhase] = []
@export var condition: HuntCondition
@export var before: Array[DialogueLine] = []
@export var after: Array[DialogueLine] = []
@export var unlocks: PackedStringArray
@export var reward_key: String


func dialogue_encounter() -> EncounterData:
	var encounter: EncounterData = EncounterData.new()
	encounter.id = id
	encounter.title_key = title_key
	encounter.opponent = opponent
	encounter.arena = arena
	encounter.before = before
	encounter.after = after
	return encounter
