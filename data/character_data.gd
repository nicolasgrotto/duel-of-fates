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
@export var max_health_override: float = 0.0
@export var block_walk_ratio: float = 0.0
@export var block_push_immune: bool = false
@export var light_block_drain: float = 0.0
@export var perfect_parry_window: float = 0.0
@export var parry_window: float = 0.0
@export var sweet_spot: bool = false
@export var punish_bonus: float = 0.0
@export var knockback_multiplier: float = 1.0
@export var wall_jump: bool = false
@export var dodge_passes_through: bool = false
@export var aerials_per_jump: int = 1
@export var can_feint: bool = false

@export_group("Ability")
@export var ability: AbilityData

@export_group("Flow")
@export var powers: Array[PowerData] = []
@export var fourth_power: PowerData
@export var technique_forward: MoveData
@export var technique_back: MoveData
@export var technique_air: MoveData

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
@export var variant: CharacterData
@export var variant_key: String
