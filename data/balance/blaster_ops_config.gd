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

@export_group("Operations presentation")
@export var dodge_echo_offset: float = 22.0
@export var precision_flash_seconds: float = 0.24
@export var power_effect_seconds: float = 0.3
@export var warning_db: float = -8.0
