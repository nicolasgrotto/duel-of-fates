class_name InfiltrationBolt
extends RefCounted

var active: bool = false
var position: Vector2 = Vector2.ZERO
var previous: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
var travelled: float = 0.0
var owner: int = 0
var shooter: int = 0
var origin: Vector2 = Vector2.ZERO
var data: BoltData


func capture() -> Dictionary:
	return {"active": active, "position": position, "previous": previous, "velocity": velocity, "travelled": travelled, "owner": owner, "shooter": shooter, "origin": origin}


func restore(state: Dictionary, sources: Array[InfiltrationTargetData]) -> void:
	for key in state:
		set(key, state[key])
	data = sources[shooter].bolt if active else null
