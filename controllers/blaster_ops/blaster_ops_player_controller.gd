class_name BlasterOpsPlayerController
extends RefCounted

const COMMANDS: Dictionary = {
	Intent.Command.LIGHT: &"blaster_ops_fire", Intent.Command.BLOCK: &"blaster_ops_guard",
	Intent.Command.DODGE: &"blaster_ops_dodge", Intent.Command.POWER: &"blaster_ops_power",
	InfiltrationIntent.POWER_2: &"blaster_ops_power_2", InfiltrationIntent.POWER_3: &"blaster_ops_power_3",
	InfiltrationIntent.ORDER_ALLIES: &"blaster_ops_order_allies",
	InfiltrationIntent.SWITCH_WEAPON: &"blaster_ops_switch_weapon",
	Intent.Command.HEAVY: &"blaster_ops_strike", InfiltrationIntent.RUN: &"blaster_ops_run",
	InfiltrationIntent.SNEAK: &"blaster_ops_sneak", InfiltrationIntent.INTERACT: &"blaster_ops_interact",
}
const STANCES: int = InfiltrationIntent.RUN | InfiltrationIntent.SNEAK
const COMMAND_HOLD_TICKS: int = 20
const STICK_DEADZONE: float = 0.25
const MENU_ORDERS: Dictionary = {
	JOY_BUTTON_DPAD_UP: BlasterOpsMissionState.AllyOrder.FOLLOW,
	JOY_BUTTON_DPAD_LEFT: BlasterOpsMissionState.AllyOrder.HOLD,
	JOY_BUTTON_DPAD_RIGHT: BlasterOpsMissionState.AllyOrder.GUARD,
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
var _stance: int = 0
var _queued_purchase: int = -1
var _menu_button_held: bool = false
var _menu_ticks: int = 0
var _menu_used: bool = false
var _menu_choice: int = -1


func handle_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if _handle_command_button(event):
		return
	for command in commands:
		if event.is_action_pressed(commands[command]):
			_pending |= command


func _handle_command_button(event: InputEvent) -> bool:
	var button: InputEventJoypadButton = event as InputEventJoypadButton
	if button == null:
		return false
	if button.is_action(commands[InfiltrationIntent.SWITCH_WEAPON]):
		if button.pressed:
			_menu_button_held = true
			_menu_ticks = 0
			_menu_used = false
		elif _menu_button_held:
			if _menu_ticks < COMMAND_HOLD_TICKS and not _menu_used:
				_pending |= InfiltrationIntent.SWITCH_WEAPON
			_menu_button_held = false
		return true
	if not _menu_button_held:
		return false
	if button.pressed and MENU_ORDERS.has(button.button_index):
		_menu_choice = MENU_ORDERS[button.button_index]
		_menu_used = true
	return MENU_ORDERS.has(button.button_index) or button.button_index == JOY_BUTTON_DPAD_DOWN


func command_menu_open() -> bool:
	return _menu_button_held and _menu_ticks >= COMMAND_HOLD_TICKS


func _menu_stick_movement() -> Vector2:
	var stick: Vector2 = Vector2(Input.get_joy_axis(0, JOY_AXIS_LEFT_X), Input.get_joy_axis(0, JOY_AXIS_LEFT_Y))
	return stick if stick.length() >= STICK_DEADZONE else Vector2.ZERO


func point_at(position: Vector2) -> void:
	_pointer = position
	_pointer_active = true
	_explicit_aim = true


func produce(sim: InfiltrationSimulation, intent: InfiltrationIntent) -> void:
	intent.clear()
	intent.movement = _menu_stick_movement() if _menu_button_held else Input.get_vector(prefix + "left", prefix + "right", prefix + "up", prefix + "down")
	if _menu_button_held:
		_menu_ticks += 1
	intent.ally_order = _menu_choice
	_menu_choice = -1
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
	_menu_button_held = false
	_menu_used = false
	_menu_choice = -1
	_suppressed = _held_commands()
	_last_held = _suppressed


func _held_commands() -> int:
	var held: int = 0
	for command in commands:
		if Input.is_action_pressed(commands[command]):
			held |= command
	if _switch_held_by_button():
		held &= ~InfiltrationIntent.SWITCH_WEAPON
	return held


func _switch_held_by_button() -> bool:
	for event in InputMap.action_get_events(commands[InfiltrationIntent.SWITCH_WEAPON]):
		var button: InputEventJoypadButton = event as InputEventJoypadButton
		if button != null and Input.is_joy_button_pressed(button.device, button.button_index):
			return true
	return _menu_button_held
