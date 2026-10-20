class_name CharacterData
extends Resource

enum GuardStyle { HIGH, LOW }

@export var id: StringName
@export var name_key: String

@export_group("Attributes")
@export_range(1, 10) var health: int = 4
@export_range(1, 10) var vigor: int = 4
@export_range(1, 10) var blade: int = 4
@export_range(1, 10) var defense: int = 4
@export_range(1, 10) var agility: int = 4
@export_range(1, 10) var flow: int = 4

@export_group("Moves")
@export var light_chain: Array[MoveData] = []
@export var heavy: MoveData
@export var forward_heavy: MoveData
@export var counter: MoveData
@export var shove: MoveData
@export var aerial_light: MoveData
@export var aerial_heavy: MoveData

@export_group("Traits")
@export var guard_break_stun: float = 1.3
@export var block_cost_multiplier: float = 1.0
@export var vigor_on_hit: float = 0.0
@export var double_jump_ratio: float = 0.7
@export var air_dash_vigor: float = 18.0

@export_group("AI")
@export var ai_profile: AiProfileData

@export_group("Look")
@export var blade_color: Color = Color("#7fe4ff")
@export var cloak_color: Color = Color("#6b5a48")
@export var body_color: Color = Color("#2e2925")
@export var skin_color: Color = Color("#7a5f4e")
@export var hair_color: Color = Color("#3b2a20")
@export var hilt_color: Color = Color("#9aa3ad")
@export var hood_up: bool = false
@export var cloak_to_floor: bool = false
@export var guard_style: GuardStyle = GuardStyle.HIGH
