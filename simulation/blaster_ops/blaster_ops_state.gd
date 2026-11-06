class_name BlasterOpsState
extends RefCounted

var heat: float = 0.0
var overheated: bool = false
var overheat_ticks: int = 0
var cooling_ticks: int = 0
var fire_ticks: int = 0
var burst_left: int = 0
var burst_ticks: int = 0
var dodge_age: int = -1
var dodge_cooldown: int = 0
var dodge_direction: Vector2 = Vector2.RIGHT
var precision_succeeded: bool = false
var power_cooldown: int = 0
var power_cooldown_2: int = 0
var power_cooldown_3: int = 0
var cast_slot: int = 0
var power_ticks: int = 0
var power_recovery_ticks: int = 0
var power_aim: Vector2 = Vector2.RIGHT
var barrier_ticks: int = 0
var barrier_health: float = 0.0
var absorb_ticks: int = 0
var heal_ticks: int = 0
var heal_rate: float = 0.0
var boost_ticks: int = 0
var channel_ticks: int = 0
var channel_slot: int = 0
var channel_target: int = -1
var area_ticks: int = 0
var area_slot: int = 0
var pulse_ticks: int = 0


func cooldown(slot: int) -> int:
	return power_cooldown if slot == 0 else power_cooldown_2 if slot == 1 else power_cooldown_3


func set_cooldown(slot: int, ticks: int) -> void:
	if slot == 0:
		power_cooldown = ticks
	elif slot == 1:
		power_cooldown_2 = ticks
	else:
		power_cooldown_3 = ticks


func casting(slot: int) -> bool:
	return (power_ticks > 0 and cast_slot == slot) or (channel_ticks > 0 and channel_slot == slot)


func capture() -> Dictionary:
	var state: Dictionary = {}
	for property in get_property_list():
		if (property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0:
			state[property.name] = get(property.name)
	return state


func restore(state: Dictionary) -> void:
	for key in state:
		set(key, state[key])
