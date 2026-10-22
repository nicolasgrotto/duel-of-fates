class_name InputBindings

const PLAYER_COUNT: int = 2
const AXIS_DEADZONE: float = 0.5

const COMBAT_KEYS: Dictionary = {
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"jump": [KEY_W, KEY_UP, KEY_SPACE],
	"light_attack": [KEY_J],
	"heavy_attack": [KEY_K],
	"block": [KEY_L],
	"dodge": [KEY_SHIFT],
	"evade": [KEY_S, KEY_DOWN],
	"special": [KEY_I],
	"power": [KEY_U],
	"pause": [KEY_ESCAPE, KEY_P],
}

const COMBAT_BUTTONS: Dictionary = {
	"move_left": [JOY_BUTTON_DPAD_LEFT],
	"move_right": [JOY_BUTTON_DPAD_RIGHT],
	"jump": [JOY_BUTTON_A],
	"light_attack": [JOY_BUTTON_X],
	"heavy_attack": [JOY_BUTTON_Y],
	"block": [JOY_BUTTON_LEFT_SHOULDER],
	"dodge": [JOY_BUTTON_B],
	"evade": [JOY_BUTTON_DPAD_DOWN],
	"special": [JOY_BUTTON_RIGHT_SHOULDER],
	"pause": [JOY_BUTTON_START],
}

const COMBAT_AXES: Dictionary = {
	"move_left": [[JOY_AXIS_LEFT_X, -1.0]],
	"move_right": [[JOY_AXIS_LEFT_X, 1.0]],
	"evade": [[JOY_AXIS_LEFT_Y, 1.0]],
	"block": [[JOY_AXIS_TRIGGER_LEFT, 1.0]],
	"power": [[JOY_AXIS_TRIGGER_RIGHT, 1.0]],
}

const MENU_KEYS: Dictionary = {
	"menu_costume": [KEY_C],
	"menu_variant": [KEY_V],
	"menu_powers": [KEY_P],
}

const MENU_BUTTONS: Dictionary = {
	"menu_costume": [JOY_BUTTON_Y],
	"menu_variant": [JOY_BUTTON_X],
	"menu_powers": [JOY_BUTTON_LEFT_SHOULDER],
}

const ALL_DEVICES: int = -1

const TOOL_KEYS: Dictionary = {
	"debug_overlay": [KEY_F3],
	"training_dummy_behavior": [KEY_F5],
	"training_record": [KEY_F6],
	"training_playback": [KEY_F7],
}


static func player_prefix(player_slot: int) -> String:
	return "p%d_" % (player_slot + 1)


static func apply_defaults() -> void:
	for slot in PLAYER_COUNT:
		var prefix: String = player_prefix(slot)
		for action in COMBAT_KEYS:
			_reset_action(prefix + action)
			if slot == 0:
				for keycode in COMBAT_KEYS[action]:
					_add_key(prefix + action, keycode)
			for button in COMBAT_BUTTONS.get(action, []):
				_add_button(prefix + action, button, slot)
			for axis in COMBAT_AXES.get(action, []):
				_add_axis(prefix + action, axis[0], axis[1], slot)
	for action in MENU_KEYS:
		_reset_action(action)
		for keycode in MENU_KEYS[action]:
			_add_key(action, keycode)
		for button in MENU_BUTTONS.get(action, []):
			_add_button(action, button, ALL_DEVICES)
	for action in TOOL_KEYS:
		_reset_action(action)
		for keycode in TOOL_KEYS[action]:
			_add_key(action, keycode)


static func _reset_action(action: String) -> void:
	if InputMap.has_action(action):
		InputMap.action_erase_events(action)
	else:
		InputMap.add_action(action, AXIS_DEADZONE)


static func _add_key(action: String, keycode: Key) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action, event)


static func _add_button(action: String, button: JoyButton, device: int) -> void:
	var event: InputEventJoypadButton = InputEventJoypadButton.new()
	event.button_index = button
	event.device = device
	InputMap.action_add_event(action, event)


static func _add_axis(action: String, axis: JoyAxis, direction: float, device: int) -> void:
	var event: InputEventJoypadMotion = InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = direction
	event.device = device
	InputMap.action_add_event(action, event)
