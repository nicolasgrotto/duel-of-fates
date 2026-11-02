class_name SpaceIntent
extends RefCounted

enum Command { PRIMARY = 1, SECONDARY = 2, BOOST = 4 }

var thrust: float = 0.0
var turn: float = 0.0
var held: int = 0
var pressed: int = 0
var target: int = -1


func clear() -> void:
	thrust = 0.0
	turn = 0.0
	held = 0
	pressed = 0
	target = -1
