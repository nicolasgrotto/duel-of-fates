class_name InfiltrationIntent
extends RefCounted

const RUN: int = 1 << 8
const SNEAK: int = 1 << 9
const INTERACT: int = 1 << 10
const POWER_2: int = 1 << 11
const POWER_3: int = 1 << 12
const SWITCH_WEAPON: int = 1 << 13
const ORDER_ALLIES: int = 1 << 14

var movement: Vector2 = Vector2.ZERO
var aim: Vector2 = Vector2.ZERO
var held: int = 0
var pressed: int = 0
var panel: int = -1
var cover_target: int = -1
var purchase: int = -1
var ally_order: int = -1


func clear() -> void:
	movement = Vector2.ZERO
	aim = Vector2.ZERO
	held = 0
	pressed = 0
	panel = -1
	cover_target = -1
	purchase = -1
	ally_order = -1
