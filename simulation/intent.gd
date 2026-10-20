class_name Intent
extends RefCounted

enum Command { JUMP = 1, LIGHT = 2, HEAVY = 4, BLOCK = 8, DODGE = 16, EVADE = 32, SPECIAL = 64, POWER = 128 }

const COMMAND_BITS: int = 8
const COMMAND_MASK: int = 0xFF

var move_x: int = 0
var held: int = 0
var pressed: int = 0


func clear() -> void:
	move_x = 0
	held = 0
	pressed = 0


func is_held(command: Command) -> bool:
	return (held & command) != 0


func was_pressed(command: Command) -> bool:
	return (pressed & command) != 0


func press(command: Command) -> void:
	pressed |= command
	held |= command


func hold(command: Command) -> void:
	held |= command


func copy_from(other: Intent) -> void:
	move_x = other.move_x
	held = other.held
	pressed = other.pressed


func pack() -> int:
	return (move_x + 1) | (held << 2) | (pressed << (2 + COMMAND_BITS))


func unpack(value: int) -> void:
	move_x = (value & 3) - 1
	held = (value >> 2) & COMMAND_MASK
	pressed = (value >> (2 + COMMAND_BITS)) & COMMAND_MASK


func pack_relative(facing: int) -> int:
	var absolute_move: int = move_x
	move_x *= facing
	var packed: int = pack()
	move_x = absolute_move
	return packed


func unpack_relative(value: int, facing: int) -> void:
	unpack(value)
	move_x *= facing
