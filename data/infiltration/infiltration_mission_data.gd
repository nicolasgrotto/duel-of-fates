class_name InfiltrationMissionData
extends Resource

@export var id: StringName
@export var title_key: String
@export var briefing_key: String
@export var map: InfiltrationMapData
@export var disable_alarms: bool = false
@export var panels_unlock_prisoners: bool = false
@export var terminals: PackedVector2Array
@export var prisoner_spawns: PackedVector2Array
@export var extraction: Vector2
@export var extraction_radius: float = 96.0
@export var bonus_seconds: float = 90.0
@export var preview: Texture2D


func objective_count() -> int:
	return (map.panels.size() if disable_alarms else 0) + terminals.size() + prisoner_spawns.size()
