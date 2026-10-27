class_name InfiltrationIntent
extends RefCounted

var movement: Vector2 = Vector2.ZERO
var aim: Vector2 = Vector2.ZERO
var held: int = 0
var pressed: int = 0


func clear() -> void:
	movement = Vector2.ZERO
	aim = Vector2.ZERO
	held = 0
	pressed = 0
