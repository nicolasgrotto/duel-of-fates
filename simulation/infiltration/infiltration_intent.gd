class_name InfiltrationIntent
extends RefCounted

const RUN: int = 1 << 8
const SNEAK: int = 1 << 9
const INTERACT: int = 1 << 10
const POWER_2: int = 1 << 11
const POWER_3: int = 1 << 12
const SWITCH_WEAPON: int = 1 << 13

var movement: Vector2 = Vector2.ZERO
var aim: Vector2 = Vector2.ZERO
var held: int = 0
var pressed: int = 0
var panel: int = -1


func clear() -> void:
	movement = Vector2.ZERO
	aim = Vector2.ZERO
	held = 0
	pressed = 0
	panel = -1
