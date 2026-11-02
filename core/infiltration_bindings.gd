class_name InfiltrationBindings
extends RefCounted

const COPIES: Dictionary = {
	&"infiltration_left": &"p1_move_left",
	&"infiltration_right": &"p1_move_right",
	&"infiltration_up": &"p1_jump",
	&"infiltration_down": &"p1_evade",
	&"infiltration_run": &"p1_dodge",
	&"infiltration_sneak": &"p1_special",
	&"infiltration_attack": &"p1_light_attack",
	&"infiltration_guard": &"p1_block",
	&"infiltration_takedown": &"p1_heavy_attack",
	&"infiltration_interact": &"p1_power",
}
const KEYS: Dictionary = {
	&"infiltration_left": [KEY_A, KEY_LEFT],
	&"infiltration_right": [KEY_D, KEY_RIGHT],
	&"infiltration_up": [KEY_W, KEY_UP],
	&"infiltration_down": [KEY_S, KEY_DOWN],
	&"infiltration_run": [KEY_SHIFT],
	&"infiltration_sneak": [KEY_CTRL, KEY_C],
	&"infiltration_attack": [KEY_SPACE],
	&"infiltration_guard": [KEY_Q],
	&"infiltration_takedown": [KEY_F],
	&"infiltration_interact": [KEY_E],
}
const AIM_AXES: Dictionary = {
	&"infiltration_aim_left": [JOY_AXIS_RIGHT_X, -1.0],
	&"infiltration_aim_right": [JOY_AXIS_RIGHT_X, 1.0],
	&"infiltration_aim_up": [JOY_AXIS_RIGHT_Y, -1.0],
	&"infiltration_aim_down": [JOY_AXIS_RIGHT_Y, 1.0],
}
const DEADZONE: float = 0.25
static var _users: int = 0


static func install() -> void:
	_users += 1
	if _users > 1:
		return
	for action in COPIES:
		InputMap.add_action(action, DEADZONE)
		var vertical: bool = action == &"infiltration_up" or action == &"infiltration_down"
		for keycode in KEYS[action]:
			var key: InputEventKey = InputEventKey.new()
			key.physical_keycode = keycode
			InputMap.action_add_event(action, key)
		for event in InputMap.action_get_events(COPIES[action]):
			if not vertical and not event is InputEventKey:
				InputMap.action_add_event(action, event.duplicate())
		if vertical:
			var direction: float = -1.0 if action == &"infiltration_up" else 1.0
			_add_axis(action, JOY_AXIS_LEFT_Y, direction)
			var button: InputEventJoypadButton = InputEventJoypadButton.new()
			button.device = 0
			button.button_index = JOY_BUTTON_DPAD_UP if direction < 0.0 else JOY_BUTTON_DPAD_DOWN
			InputMap.action_add_event(action, button)
	for action in AIM_AXES:
		InputMap.add_action(action, DEADZONE)
		_add_axis(action, AIM_AXES[action][0], AIM_AXES[action][1])
	for action in [&"infiltration_attack", &"infiltration_guard"]:
		var mouse: InputEventMouseButton = InputEventMouseButton.new()
		mouse.button_index = MOUSE_BUTTON_LEFT if action == &"infiltration_attack" else MOUSE_BUTTON_RIGHT
		InputMap.action_add_event(action, mouse)


static func _add_axis(action: StringName, axis: JoyAxis, direction: float) -> void:
	var event: InputEventJoypadMotion = InputEventJoypadMotion.new()
	event.device = 0
	event.axis = axis
	event.axis_value = direction
	InputMap.action_add_event(action, event)


static func uninstall() -> void:
	_users = maxi(_users - 1, 0)
	if _users > 0:
		return
	for action in COPIES:
		if InputMap.has_action(action):
			InputMap.erase_action(action)
	for action in AIM_AXES:
		if InputMap.has_action(action):
			InputMap.erase_action(action)
