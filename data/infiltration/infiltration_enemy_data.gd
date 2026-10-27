class_name InfiltrationEnemyData
extends InfiltrationTargetData

enum Archetype { PATROL, SENTRY, HEAVY }

@export var archetype: Archetype = Archetype.PATROL
@export var speed: float = 110.0
@export var alarm_speed_ratio: float = 1.5
@export var vision_range: float = 400.0
@export var vision_degrees: float = 80.0
@export var rotation_degrees: float = 35.0
@export var preferred_range: float = 250.0
@export var sprite: int = 0
