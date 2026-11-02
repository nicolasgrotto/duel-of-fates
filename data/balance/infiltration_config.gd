class_name InfiltrationConfig
extends Resource

@export_group("Movement")
@export var walk_speed: float = 240.0
@export var run_speed: float = 360.0
@export var sneak_speed: float = 120.0
@export var acceleration: float = 2200.0
@export var deceleration: float = 2800.0
@export var body_radius: float = 18.0
@export var guard_speed_ratio: float = 0.6
@export var step_distance: float = 72.0

@export_group("Combat")
@export var health: float = 100.0
@export var vigor: float = 100.0
@export var vigor_regeneration: float = 25.0
@export var regeneration_delay: float = 0.6
@export var swing_startup: float = 0.1
@export var swing_active: float = 0.1
@export var swing_recovery: float = 0.2
@export var swing_reach: float = 88.0
@export var swing_degrees: float = 120.0
@export var swing_damage: float = 10.0
@export var swing_vigor: float = 8.0
@export var guard_degrees: float = 140.0
@export var duel_config: CombatConfig
@export var projectile_capacity: int = 32
@export var event_capacity: int = 128

@export_group("Stealth and alarms")
@export var vision_gain: float = 1.0
@export var suspicion_decay: float = 0.2
@export var suspicious_threshold: float = 0.25
@export var noise_suspicion: float = 0.45
@export var sneak_visibility: float = 0.6
@export var alert_memory: float = 5.0
@export var walk_noise: float = 40.0
@export var run_noise: float = 220.0
@export var sneak_noise: float = 16.0
@export var combat_noise: float = 300.0
@export var reflected_wall_noise: float = 240.0
@export var takedown_range: float = 72.0
@export var takedown_rear_degrees: float = 100.0
@export var interaction_range: float = 80.0
@export var panel_activation_range: float = 56.0
@export var panel_activation_seconds: float = 0.75
@export var reinforcement_delay: float = 2.0
@export var waypoint_radius: float = 10.0
@export var alarm_db: float = -18.0
@export var music_db: float = -14.0
@export var silent_db: float = -60.0

@export_group("Missions")
@export var prisoner_health: float = 60.0
@export var escort_speed: float = 215.0
@export var escort_follow_distance: float = 56.0

@export_group("Presentation")
@export var camera_zoom: float = 2.0
@export var units_per_pixel: float = 2.0
@export var atlas_tile_pixels: int = 32
@export var sprite_pixels: Vector2i = Vector2i(24, 28)
@export var blade_length: float = 68.0
@export var blade_grip: float = 20.0
@export var blade_width: float = 4.0
@export var blade_hilt_half: float = 6.0
@export var blade_hand_size: float = 6.0
@export var blade_hand_forward: float = 12.0
@export var blade_hand_side: float = 14.0
@export var blade_rest_degrees: float = -8.0
@export var guard_hand_forward: float = 18.0
@export var guard_hand_side: float = 12.0
@export var guard_blade_degrees: float = -68.0
@export var guard_blend_seconds: float = 0.08
@export var bolt_length: float = 22.0
@export var spark_capacity: int = 24
@export var spark_seconds: float = 0.22
@export var hum_db: float = -20.0
@export var effects_db: float = -6.0
@export var footstep_db: float = -16.0


func startup_ticks() -> int:
	return Ticks.from_seconds(swing_startup)


func active_ticks() -> int:
	return Ticks.from_seconds(swing_active)


func swing_ticks() -> int:
	return Ticks.from_seconds(swing_startup + swing_active + swing_recovery)
