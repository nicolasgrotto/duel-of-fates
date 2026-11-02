class_name SpaceBindings
extends RefCounted

const COPIES: Dictionary = {
	&"space_left": &"p1_move_left",
	&"space_right": &"p1_move_right",
	&"space_thrust": &"p1_jump",
	&"space_reverse": &"p1_evade",
	&"space_fire": &"p1_light_attack",
	&"space_secondary": &"p1_heavy_attack",
	&"space_boost": &"p1_dodge",
}
const DEADZONE: float = 0.25
static var _users: int = 0


static func install() -> void:
	_users += 1
	if _users > 1:
		return
	for action in COPIES:
		InputMap.add_action(action, DEADZONE)
		var vertical: bool = action == &"space_thrust" or action == &"space_reverse"
		for event in InputMap.action_get_events(COPIES[action]):
			if not vertical or event is InputEventKey:
				InputMap.action_add_event(action, event.duplicate())
		if vertical:
			var axis: InputEventJoypadMotion = InputEventJoypadMotion.new()
			axis.device = 0
			axis.axis = JOY_AXIS_LEFT_Y
			axis.axis_value = -1.0 if action == &"space_thrust" else 1.0
			InputMap.action_add_event(action, axis)
			var button: InputEventJoypadButton = InputEventJoypadButton.new()
			button.device = 0
			button.button_index = JOY_BUTTON_DPAD_UP if action == &"space_thrust" else JOY_BUTTON_DPAD_DOWN
			InputMap.action_add_event(action, button)


static func uninstall() -> void:
	_users = maxi(_users - 1, 0)
	if _users > 0:
		return
	for action in COPIES:
		if InputMap.has_action(action):
			InputMap.erase_action(action)
