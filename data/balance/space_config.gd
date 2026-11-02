class_name SpaceConfig
extends Resource

@export_group("Simulation")
@export var projectile_capacity: int = 96
@export var event_capacity: int = 128
@export var boost_seconds: float = 0.30
@export var boost_speed: float = 720.0
@export var boost_cooldown: float = 1.50
@export var boost_invulnerable_start: float = 0.05
@export var boost_invulnerable_end: float = 0.20
@export var drone_aim_degrees: float = 6.0

@export_group("Presentation")
@export var camera_zoom: float = 1.8
@export var units_per_pixel: float = 2.0
@export var star_seed: int = 1313
@export var star_count: int = 140
@export var effect_capacity: int = 40
@export var trail_capacity: int = 64
@export var trail_seconds: float = 0.22
@export var trail_interval: float = 0.035
@export var shield_hit_seconds: float = 0.18
@export var hull_hit_seconds: float = 0.16
@export var explosion_seconds: float = 0.45
@export var bolt_length: float = 22.0
@export var engine_length: float = 20.0
@export var engine_db: float = -23.0
@export var effects_db: float = -9.0
@export var audio_voices: int = 12
@export var refusal_seconds: float = 1.6


func boost_ticks() -> int:
	return Ticks.from_seconds(boost_seconds)
