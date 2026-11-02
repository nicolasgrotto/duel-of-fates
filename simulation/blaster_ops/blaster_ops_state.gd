class_name BlasterOpsState
extends RefCounted

var heat: float = 0.0
var overheated: bool = false
var overheat_ticks: int = 0
var cooling_ticks: int = 0
var fire_ticks: int = 0
var dodge_age: int = -1
var dodge_cooldown: int = 0
var dodge_direction: Vector2 = Vector2.RIGHT
var precision_succeeded: bool = false
var power_cooldown: int = 0
var power_ticks: int = 0
var power_recovery_ticks: int = 0
var power_aim: Vector2 = Vector2.RIGHT
var barrier_ticks: int = 0
var barrier_health: float = 0.0


func capture() -> Dictionary:
	var state: Dictionary = {}
	for property in get_property_list():
		if (property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0:
			state[property.name] = get(property.name)
	return state


func restore(state: Dictionary) -> void:
	for key in state:
		set(key, state[key])
