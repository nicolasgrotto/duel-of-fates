class_name InfiltrationPanel
extends RefCounted

var disabled: bool = false
var active: bool = false
var activation_ticks: int = 0


func capture() -> Dictionary:
	return {"disabled": disabled, "active": active, "activation_ticks": activation_ticks}


func restore(state: Dictionary) -> void:
	disabled = state.disabled
	active = state.active
	activation_ticks = state.activation_ticks
