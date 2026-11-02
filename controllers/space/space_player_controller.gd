class_name SpacePlayerController
extends RefCounted

const COMMANDS: Dictionary = {
	SpaceIntent.Command.PRIMARY: &"space_fire",
	SpaceIntent.Command.SECONDARY: &"space_secondary",
	SpaceIntent.Command.BOOST: &"space_boost",
}

var _pending: int = 0
var _last_held: int = 0
var _suppressed: int = 0


func handle_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	for command in COMMANDS:
		if event.is_action_pressed(COMMANDS[command]):
			_pending |= command
		elif event.is_action_released(COMMANDS[command]):
			_suppressed &= ~int(command)


func produce(intent: SpaceIntent) -> void:
	intent.clear()
	intent.turn = Input.get_axis(&"space_left", &"space_right")
	intent.thrust = Input.get_action_strength(&"space_thrust") - Input.get_action_strength(&"space_reverse")
	var held: int = _held_commands()
	_suppressed &= held
	intent.held = held & ~_suppressed
	intent.pressed = _pending | (intent.held & ~_last_held)
	intent.held |= _pending
	_last_held = intent.held
	_pending = 0


func discard_pending() -> void:
	_pending = 0
	_last_held = _held_commands()
	_suppressed = _last_held


func _held_commands() -> int:
	var held: int = 0
	for command in COMMANDS:
		if Input.is_action_pressed(COMMANDS[command]):
			held |= command
	return held
