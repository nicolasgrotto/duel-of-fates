class_name BoltData
extends Resource

@export var id: StringName
@export var speed: float = 900.0
@export var max_range: float = 1100.0
@export var damage: float = 4.0
@export var size: float = 6.0
@export var flinch: float = 0.25
@export var guard_vigor: float = 4.0
@export var muzzle_height: float = 100.0
@export var muzzle_forward: float = 30.0
@export var count: int = 1
@export var interval: float = 0.1
@export var perfect_reflect_speed: float = 1.25
@export var pitch: float = 1.0


func flinch_ticks() -> int:
	return Ticks.from_seconds(flinch)


func interval_ticks() -> int:
	return maxi(Ticks.from_seconds(interval), 1)
