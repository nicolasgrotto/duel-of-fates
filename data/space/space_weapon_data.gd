class_name SpaceWeaponData
extends Resource

enum Kind { BOLT, MISSILE }

@export var id: StringName
@export var damage: float = 10.0
@export var speed: float = 1000.0
@export var max_range: float = 1400.0
@export var radius: float = 3.0
@export var interval: float = 0.18
@export var windup: float = 0.0
@export var muzzle: float = 44.0
@export var muzzle_side: float = 0.0
@export var kind: Kind = Kind.BOLT
@export var projectile_hull: float = 0.0
@export var turn_degrees: float = 0.0
@export var count: int = 1
@export var spread_degrees: float = 0.0
@export var press_only: bool = false
