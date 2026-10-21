class_name CharacterData
extends Resource

enum Path { AURORA, ECLIPSE }

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

@export_group("Identity")
@export var path: Path = Path.AURORA
@export var style_key: String
@export var trait_key: String
@export var ability_key: String
@export var secret: bool = false
@export var selectable: bool = true

@export_group("Look")
@export var art: FighterArt
@export var family: MotionFamily
@export var weapon: WeaponData
@export var costumes: Array[CostumeData] = []
@export var blade_colors: PackedColorArray = PackedColorArray([Color("#7fe4ff")])
@export var blade_color_keys: PackedStringArray = []
@export var guard_angle: float = -55.0
@export var guard_grip: Vector2 = Vector2(14.0, -24.0)
@export var eclipse_eyes: bool = false
