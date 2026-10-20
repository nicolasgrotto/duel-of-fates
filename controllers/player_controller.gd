class_name PlayerController
extends FighterController

const COMMAND_ACTIONS: Dictionary = {
	Intent.Command.JUMP: "jump",
	Intent.Command.LIGHT: "light_attack",
	Intent.Command.HEAVY: "heavy_attack",
	Intent.Command.BLOCK: "block",
	Intent.Command.DODGE: "dodge",
	Intent.Command.EVADE: "evade",
	Intent.Command.SPECIAL: "special",
	Intent.Command.POWER: "power",
}

var _actions: Dictionary = {}
var _move_left: StringName
var _move_right: StringName
var _pending_pressed: int = 0
var _last_held: int = 0


func _init(player_slot: int) -> void:
	var prefix: String = InputBindings.player_prefix(player_slot)
	for command in COMMAND_ACTIONS:
		_actions[command] = StringName(prefix + COMMAND_ACTIONS[command])
	_move_left = StringName(prefix + "move_left")
	_move_right = StringName(prefix + "move_right")


func handle_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	for command in _actions:
		if event.is_action_pressed(_actions[command]):
			_pending_pressed |= command


func produce(_sim: MatchSimulation, _fighter_index: int, intent: Intent) -> void:
	var held: int = 0
	for command in _actions:
		if Input.is_action_pressed(_actions[command]):
			held |= command
	intent.move_x = int(Input.is_action_pressed(_move_right)) - int(Input.is_action_pressed(_move_left))
	intent.pressed = _pending_pressed | (held & ~_last_held)
	intent.held = held | _pending_pressed
	_last_held = held
	_pending_pressed = 0
