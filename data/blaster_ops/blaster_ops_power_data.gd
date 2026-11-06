class_name BlasterOpsPowerData
extends Resource

enum Effect { CONE, SHIELD, ABSORB, HEAL, PROJECTILE, CHANNEL, STUN, BOOST, AREA }

@export var effect: Effect = Effect.CONE
@export var power: PowerData
@export var cooldown: float = 6.0
@export var degrees: float = 100.0
@export var impulse_seconds: float = 0.16
@export var bolt: BoltData
@export var pulse_seconds: float = 0.1
@export var effect_scale: float = 1.0
@export var effect_radius: float = 96.0
@export var holds_target: bool = false
