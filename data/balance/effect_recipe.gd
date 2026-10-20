class_name EffectRecipe
extends Resource

@export var sparks_min: int = 6
@export var sparks_max: int = 10
@export var spark_speed: float = 520.0
@export var spread_degrees: float = 70.0
@export var lift_degrees: float = 25.0
@export var shake: float = 0.0
@export var shake_duration: float = 0.0
@export_range(0.0, 0.35) var flash: float = 0.0
@export_range(0.0, 0.06) var punch_in: float = 0.0
@export var ring_radius: float = 0.0
@export var hit_flash: bool = false
