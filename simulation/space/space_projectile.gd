class_name SpaceProjectile
extends RefCounted

var active: bool = false
var source: int = 0
var slot: int = 0
var position: Vector2 = Vector2.ZERO
var previous: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
var travelled: float = 0.0
var age: int = 0
var weapon_index: int = -1
var target: int = -1
var hull: float = 0.0


func capture() -> Dictionary:
	return {"active": active, "source": source, "slot": slot, "position": position, "previous": previous, "velocity": velocity, "travelled": travelled, "age": age, "weapon_index": weapon_index, "target": target, "hull": hull}


func restore(state: Dictionary) -> void:
	for key in state:
		set(key, state[key])
