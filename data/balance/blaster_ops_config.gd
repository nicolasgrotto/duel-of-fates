class_name BlasterOpsConfig
extends InfiltrationConfig

@export_group("Heat")
@export var heat_capacity: float = 100.0
@export var cooling_rate: float = 30.0
@export var cooling_delay: float = 0.25
@export var overheat_seconds: float = 1.0
@export var resume_heat: float = 40.0

@export_group("Dodge")
@export var dodge_seconds: float = 0.26
@export var dodge_speed: float = 720.0
@export var dodge_cooldown: float = 0.9
@export var invulnerable_from: int = 3
@export var invulnerable_until: int = 12
@export var precision_until: int = 9
@export var melee_parry_stun: float = 0.4

@export_group("Powers")
@export var absorb_refund_seconds: float = 1.0
@export var storm_reach: float = 640.0

@export_group("Infiltration policy")
@export var stealth_power_cooldown_multiplier: float = 3.0
@export var dodge_noise: float = 220.0
@export var power_noise: float = 300.0

@export_group("Limits")
@export var max_active_enemies: int = 24
@export var max_allies: int = 6

@export_group("Incursion missions")
@export var barrier_capacity: int = 2
@export var deploy_distance: float = 96.0
@export var deploy_health: float = 60.0
@export var ally_fire_interval: float = 1.2
@export var ally_fire_range: float = 480.0
@export var protected_speed: float = 90.0
@export var protected_follow_range: float = 320.0
@export var ally_bolt: BoltData = preload("res://data/bolts/standard_bolt.tres")

@export_group("Operations presentation")
@export var dodge_echo_offset: float = 22.0
@export var precision_flash_seconds: float = 0.24
@export var power_effect_seconds: float = 0.3
@export var warning_db: float = -8.0
@export var blast_capacity: int = 8
@export var blast_seconds: float = 0.35
@export var heat_hot_ratio: float = 0.7
@export var heat_pulse_speed: float = 6.0
