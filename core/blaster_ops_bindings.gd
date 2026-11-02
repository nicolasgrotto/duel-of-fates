class_name BlasterOpsBindings
extends RefCounted

const PREFIX: String = "blaster_ops_"
const ACTIONS: Array[String] = ["left", "right", "up", "down", "fire", "guard", "dodge", "power"]
const KEYS: Dictionary = {
	"left": [KEY_A, KEY_LEFT], "right": [KEY_D, KEY_RIGHT], "up": [KEY_W, KEY_UP], "down": [KEY_S, KEY_DOWN],
	"fire": [KEY_SPACE], "guard": [KEY_Q], "dodge": [KEY_SHIFT], "power": [KEY_E],
}
const COPIES: Dictionary = {"fire": &"p1_light_attack", "guard": &"p1_block", "dodge": &"p1_dodge", "power": &"p1_power"}
const MOVE_AXES: Dictionary = {"left": [JOY_AXIS_LEFT_X, -1.0], "right": [JOY_AXIS_LEFT_X, 1.0], "up": [JOY_AXIS_LEFT_Y, -1.0], "down": [JOY_AXIS_LEFT_Y, 1.0]}
const AIM_AXES: Dictionary = {"aim_left": [JOY_AXIS_RIGHT_X, -1.0], "aim_right": [JOY_AXIS_RIGHT_X, 1.0], "aim_up": [JOY_AXIS_RIGHT_Y, -1.0], "aim_down": [JOY_AXIS_RIGHT_Y, 1.0]}
const DPAD: Dictionary = {"left": JOY_BUTTON_DPAD_LEFT, "right": JOY_BUTTON_DPAD_RIGHT, "up": JOY_BUTTON_DPAD_UP, "down": JOY_BUTTON_DPAD_DOWN}
const DEADZONE: float = 0.25
static var _users: int = 0


static func install(keys: Dictionary = {}, buttons: Dictionary = {}) -> void:
	_users += 1
	if _users == 1:
		apply(keys, buttons)


static func apply(keys: Dictionary, buttons: Dictionary) -> void:
	for suffix in ACTIONS:
		var action: StringName = StringName(PREFIX + suffix)
		if not InputMap.has_action(action):
			InputMap.add_action(action, DEADZONE)
		InputMap.action_erase_events(action)
		for code in keys.get(suffix, KEYS[suffix]):
			var event: InputEventKey = InputEventKey.new()
			event.physical_keycode = code
			InputMap.action_add_event(action, event)
		if COPIES.has(suffix):
			for event in InputMap.action_get_events(COPIES[suffix]):
				if event is InputEventJoypadMotion:
					InputMap.action_add_event(action, event.duplicate())
		if buttons.has(suffix):
			for code in buttons[suffix]:
				_add_button(action, code)
		elif DPAD.has(suffix):
			_add_button(action, DPAD[suffix])
		else:
			for event in InputMap.action_get_events(COPIES[suffix]):
				if event is InputEventJoypadButton:
					InputMap.action_add_event(action, event.duplicate())
		if MOVE_AXES.has(suffix):
			_add_axis(action, MOVE_AXES[suffix])
		if suffix in ["fire", "guard"]:
			var mouse: InputEventMouseButton = InputEventMouseButton.new()
			mouse.button_index = MOUSE_BUTTON_LEFT if suffix == "fire" else MOUSE_BUTTON_RIGHT
			InputMap.action_add_event(action, mouse)
	for suffix in AIM_AXES:
		var action: StringName = StringName(PREFIX + suffix)
		if not InputMap.has_action(action):
			InputMap.add_action(action, DEADZONE)
		InputMap.action_erase_events(action)
		_add_axis(action, AIM_AXES[suffix])


static func _add_button(action: StringName, code: JoyButton) -> void:
	var button: InputEventJoypadButton = InputEventJoypadButton.new()
	button.device = 0
	button.button_index = code
	InputMap.action_add_event(action, button)


static func _add_axis(action: StringName, axis: Array) -> void:
	var event: InputEventJoypadMotion = InputEventJoypadMotion.new()
	event.device = 0
	event.axis = axis[0]
	event.axis_value = axis[1]
	InputMap.action_add_event(action, event)


static func keyboard_map() -> Dictionary:
	var keys: Dictionary = {}
	for suffix in ACTIONS:
		var codes: Array = []
		for event in InputMap.action_get_events(PREFIX + suffix):
			if event is InputEventKey:
				codes.append(event.physical_keycode)
		keys[suffix] = codes
	return keys


static func button_map() -> Dictionary:
	var buttons: Dictionary = {}
	for suffix in ACTIONS:
		var codes: Array = []
		for event in InputMap.action_get_events(PREFIX + suffix):
			if event is InputEventJoypadButton:
				codes.append(event.button_index)
		buttons[suffix] = codes
	return buttons


static func uninstall() -> void:
	_users = maxi(_users - 1, 0)
	if _users > 0:
		return
	for suffix in ACTIONS + AIM_AXES.keys():
		if InputMap.has_action(PREFIX + suffix):
			InputMap.erase_action(PREFIX + suffix)
