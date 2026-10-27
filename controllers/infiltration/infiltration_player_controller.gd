class_name InfiltrationPlayerController
extends RefCounted

const COMMANDS: Dictionary = {
	Intent.Command.LIGHT: &"infiltration_attack",
	Intent.Command.BLOCK: &"infiltration_guard",
	Intent.Command.DODGE: &"infiltration_run",
	Intent.Command.SPECIAL: &"infiltration_sneak",
	Intent.Command.HEAVY: &"infiltration_takedown",
	Intent.Command.POWER: &"infiltration_interact",
}

var _pending: int = 0
var _last_held: int = 0
var _pointer: Vector2 = Vector2.ZERO
var _pointer_active: bool = false
var _aim: Vector2 = Vector2.RIGHT


func handle_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	for command in COMMANDS:
		if event.is_action_pressed(COMMANDS[command]):
			_pending |= command


func point_at(position: Vector2) -> void:
	_pointer = position
	_pointer_active = true


func produce(sim: InfiltrationSimulation, intent: InfiltrationIntent) -> void:
	intent.clear()
	intent.movement = Input.get_vector(&"infiltration_left", &"infiltration_right", &"infiltration_up", &"infiltration_down")
	var aim: Vector2 = Input.get_vector(&"infiltration_aim_left", &"infiltration_aim_right", &"infiltration_aim_up", &"infiltration_aim_down")
	if aim.length_squared() > 0.0:
		_aim = aim.normalized()
		_pointer_active = false
	elif _pointer_active:
		var to_pointer: Vector2 = _pointer - sim.player.position
		if to_pointer.length_squared() > 0.0:
			_aim = to_pointer.normalized()
	elif intent.movement.length_squared() > 0.0:
		_aim = intent.movement.normalized()
	intent.aim = _aim
	intent.held = _held_commands()
	intent.pressed = _pending | (intent.held & ~_last_held)
	intent.held |= _pending
	_last_held = intent.held
	_pending = 0


func discard_pending() -> void:
	_pending = 0
	_last_held = _held_commands()


func _held_commands() -> int:
	var held: int = 0
	for command in COMMANDS:
		if Input.is_action_pressed(COMMANDS[command]):
			held |= command
	return held
