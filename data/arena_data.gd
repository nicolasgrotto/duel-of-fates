class_name ArenaData
extends Resource

@export var id: StringName
@export var name_key: String
@export var phrase_key: String
@export var scene: PackedScene
@export var ambient: Color = Color(0.55, 0.58, 0.66)
@export var reflective_floor: bool = false
@export var wind: float = 0.0
@export var music: MusicData
@export var ambience: AudioStream
