class_name ChallengeData
extends Resource

@export var id: StringName
@export var title_key: String
@export var description_key: String
@export var player: StringName
@export var opponent: StringName
@export var arena: ArenaData
@export var difficulty: StringName = &"normal"
@export var powers: bool = true
@export var start_health: float = 1.0
