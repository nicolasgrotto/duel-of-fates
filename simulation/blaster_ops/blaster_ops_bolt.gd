class_name BlasterOpsBolt
extends InfiltrationBolt

var damage: float = 0.0
var evaded: bool = false
var reflected: bool = false


func capture() -> Dictionary:
	var state: Dictionary = super.capture()
	state["data"] = data
	state["damage"] = damage
	state["evaded"] = evaded
	state["reflected"] = reflected
	return state


func restore(state: Dictionary, _sources: Array[InfiltrationTargetData]) -> void:
	for key in state:
		set(key, state[key])
