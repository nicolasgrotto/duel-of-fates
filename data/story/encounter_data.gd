class_name EncounterData
extends Resource

enum Route { COMMON, AURORA, ECLIPSE }

@export var id: StringName
@export var chapter: int = 1
@export var title_key: String
@export var route: Route = Route.COMMON
@export var opponent: StringName
@export var arena: ArenaData
@export var ai_offset: int = 0
@export var boss_ai: bool = false
@export var milestone: bool = false
@export var awards_points: bool = true
@export var power_aurora: StringName
@export var power_eclipse: StringName
@export var unlocks: PackedStringArray = []
@export var before: Array[DialogueLine] = []
@export var after: Array[DialogueLine] = []
