class_name InfiltrationEnemyData
extends InfiltrationTargetData

enum Archetype { PATROL, SENTRY, HEAVY, MARKSMAN, DRONE, SHIELD, WALKER }

@export var archetype: Archetype = Archetype.PATROL
@export var speed: float = 110.0
@export var alarm_speed_ratio: float = 1.5
@export var vision_range: float = 400.0
@export var vision_degrees: float = 80.0
@export var rotation_degrees: float = 35.0
@export var preferred_range: float = 250.0
@export var sprite: int = 0
@export var texture: Texture2D
@export var body_radius: float = 0.0
@export var turn_degrees: float = 0.0
@export var can_raise_alarm: bool = true
@export var prefers_prisoners: bool = false
@export var aim_line: bool = false
@export var takedown_immune: bool = false
@export var front_damage_ratio: float = 1.0
@export var front_degrees: float = 120.0
@export var melee_damage: float = 0.0
@export var melee_guard_vigor: float = 0.0
@export var melee_range: float = 0.0
@export var melee_interval: float = 0.0
@export var melee_flinch: float = 0.0
