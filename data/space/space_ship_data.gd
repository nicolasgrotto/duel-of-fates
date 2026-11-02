class_name SpaceShipData
extends Resource

enum Archetype { DRONE, FIGHTER, INTERCEPTOR, GUNSHIP, LAUNCHER, TURRET, CAPITAL, BOSS, SECTION }

@export var id: StringName
@export var name_key: String
@export var description_key: String
@export var hull: float = 100.0
@export var shield: float = 40.0
@export var shield_delay: float = 2.0
@export var shield_regeneration: float = 12.0
@export var acceleration: float = 600.0
@export var reverse_ratio: float = 0.55
@export var drag: float = 100.0
@export var speed: float = 360.0
@export var rotation_degrees: float = 210.0
@export var radius: float = 26.0
@export var immobile: bool = false
@export var can_boost: bool = true
@export var primary: SpaceWeaponData
@export var secondary: SpaceWeaponData
@export var sprite: Texture2D
@export var archetype: Archetype = Archetype.DRONE
@export var preferred_range: float = 360.0
@export var contact_ratio: float = 1.0
@export var boost_cooldown_ratio: float = 1.0
