class_name BlasterOpsPlayerController
extends RefCounted

const COMMANDS: Dictionary = {
	Intent.Command.LIGHT: &"blaster_ops_fire", Intent.Command.BLOCK: &"blaster_ops_guard",
	Intent.Command.DODGE: &"blaster_ops_dodge", Intent.Command.POWER: &"blaster_ops_power",
	Intent.Command.HEAVY: &"blaster_ops_strike", InfiltrationIntent.RUN: &"blaster_ops_run",
	InfiltrationIntent.SNEAK: &"blaster_ops_sneak", InfiltrationIntent.INTERACT: &"blaster_ops_interact",
}

var prefix: String = BlasterOpsBindings.PREFIX
var commands: Dictionary = COMMANDS
var _pending: int = 0
var _last_held: int = 0
var _suppressed: int = 0
var _pointer: Vector2 = Vector2.ZERO
var _pointer_active: bool = false
var _aim: Vector2 = Vector2.RIGHT
var _explicit_aim: bool = false


func handle_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	for command in commands:
		if event.is_action_pressed(commands[command]):
			_pending |= command


func point_at(position: Vector2) -> void:
	_pointer = position
	_pointer_active = true
	_explicit_aim = true


func produce(sim: InfiltrationSimulation, intent: InfiltrationIntent) -> void:
	intent.clear()
	intent.movement = Input.get_vector(prefix + "left", prefix + "right", prefix + "up", prefix + "down")
	var aim: Vector2 = Input.get_vector(prefix + "aim_left", prefix + "aim_right", prefix + "aim_up", prefix + "aim_down")
	if aim.length_squared() > 0.0:
		_aim = aim.normalized()
		_pointer_active = false
		_explicit_aim = true
	elif _pointer_active and _pointer.distance_squared_to(sim.player.position) > 0.0:
		_aim = (_pointer - sim.player.position).normalized()
	elif not _explicit_aim and intent.movement.length_squared() > 0.0:
		_aim = intent.movement.normalized()
	intent.aim = _aim
	var raw: int = _held_commands()
	_suppressed &= raw
	intent.held = raw & ~_suppressed
	intent.pressed = (_pending | (intent.held & ~_last_held)) & ~_suppressed
	intent.held |= intent.pressed
	_last_held = intent.held
	_pending = 0


func discard_pending() -> void:
	_pending = 0
	_suppressed = _held_commands()
	_last_held = _suppressed


func _held_commands() -> int:
	var held: int = 0
	for command in commands:
		if Input.is_action_pressed(commands[command]):
			held |= command
	return held
