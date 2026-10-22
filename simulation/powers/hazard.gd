class_name Hazard
extends RefCounted

enum Kind { ROCK_DROP, BOLT, FRACTURE }

var active: bool = false
var kind: Kind = Kind.ROCK_DROP
var owner: int = 0
var x: float = 0.0
var half_width: float = 30.0
var delay_ticks: int = 0
var total_delay: int = 0
var group: int = 0
var damage: float = 0.0
var flow_level: int = 4
var power: PowerData


func capture() -> Dictionary:
	return {
		"active": active, "kind": kind, "owner": owner, "x": x, "half_width": half_width, "delay_ticks": delay_ticks,
		"total_delay": total_delay, "group": group, "damage": damage, "flow_level": flow_level, "power": power,
	}


func restore(snapshot: Dictionary) -> void:
	for key in snapshot:
		set(key, snapshot[key])
