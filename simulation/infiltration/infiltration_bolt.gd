class_name InfiltrationBolt
extends RefCounted

var active: bool = false
var position: Vector2 = Vector2.ZERO
var previous: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
var travelled: float = 0.0
var owner: int = 0
var shooter: int = 0
var data: BoltData


func capture() -> Dictionary:
	return {"active": active, "position": position, "previous": previous, "velocity": velocity, "travelled": travelled, "owner": owner, "shooter": shooter}


func restore(state: Dictionary, map: InfiltrationMapData) -> void:
	for key in state:
		set(key, state[key])
	data = map.targets[shooter].bolt if active else null
