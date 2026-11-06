class_name BlasterOpsPlayerController
extends RefCounted

const COMMANDS: Dictionary = {
	Intent.Command.LIGHT: &"blaster_ops_fire", Intent.Command.BLOCK: &"blaster_ops_guard",
	Intent.Command.DODGE: &"blaster_ops_dodge", Intent.Command.POWER: &"blaster_ops_power",
	InfiltrationIntent.POWER_2: &"blaster_ops_power_2", InfiltrationIntent.POWER_3: &"blaster_ops_power_3",
	InfiltrationIntent.SWITCH_WEAPON: &"blaster_ops_switch_weapon",
	Intent.Command.HEAVY: &"blaster_ops_strike", InfiltrationIntent.RUN: &"blaster_ops_run",
	InfiltrationIntent.SNEAK: &"blaster_ops_sneak", InfiltrationIntent.INTERACT: &"blaster_ops_interact",
}
const STANCES: int = InfiltrationIntent.RUN | InfiltrationIntent.SNEAK

var prefix: String = BlasterOpsBindings.PREFIX
var commands: Dictionary = COMMANDS
var _pending: int = 0
var _last_held: int = 0
var _suppressed: int = 0
var _pointer: Vector2 = Vector2.ZERO
var _pointer_active: bool = false
var _aim: Vector2 = Vector2.RIGHT
var _explicit_aim: bool = false
var _stance: int = 0
var _queued_purchase: int = -1


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
	var active: int = raw & ~_suppressed
	intent.pressed = (_pending | (active & ~_last_held)) & ~_suppressed
	_last_held = active | intent.pressed
	_toggle_stance(intent.pressed)
	intent.held = (_last_held & ~STANCES) | _stance
	intent.purchase = _queued_purchase
	_queued_purchase = -1
	_pending = 0


func queue_purchase(offer: int) -> void:
	_queued_purchase = offer


func stance() -> int:
	return _stance


func reset_stance() -> void:
	_stance = 0


func _toggle_stance(pressed: int) -> void:
	for bit in [InfiltrationIntent.RUN, InfiltrationIntent.SNEAK]:
		if (pressed & bit) != 0:
			_stance = 0 if _stance == bit else bit


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
