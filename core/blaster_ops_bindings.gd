class_name BlasterOpsBindings
extends RefCounted

const PREFIX: String = "blaster_ops_"
const LAYOUT_VERSION: int = 3
const ACTIONS: Array[String] = ["left", "right", "up", "down", "fire", "guard", "dodge", "power", "power_2", "power_3", "switch_weapon", "order_allies", "run", "sneak", "strike", "interact"]
const KEYS: Dictionary = {
	"left": [KEY_A, KEY_LEFT], "right": [KEY_D, KEY_RIGHT], "up": [KEY_W, KEY_UP], "down": [KEY_S, KEY_DOWN],
	"fire": [KEY_V], "guard": [KEY_Q], "dodge": [KEY_SPACE], "power": [KEY_1, KEY_R], "power_2": [KEY_2], "power_3": [KEY_3],
	"switch_weapon": [KEY_X], "order_allies": [KEY_G], "run": [KEY_SHIFT], "sneak": [KEY_C], "strike": [KEY_F], "interact": [KEY_E],
}
const ADDED_IN_LAYOUT_2: Dictionary = {"fire": [KEY_V], "power": [KEY_1]}
const UNSAFE_KEYS: Array[Key] = [KEY_CTRL, KEY_ALT, KEY_META]
const COPIES: Dictionary = {"fire": &"p1_light_attack", "guard": &"p1_block", "dodge": &"p1_dodge", "power": &"p1_power", "sneak": &"p1_special", "strike": &"p1_heavy_attack"}
const BUTTONS: Dictionary = {"run": JOY_BUTTON_LEFT_STICK, "interact": JOY_BUTTON_A, "power_2": JOY_BUTTON_LEFT_SHOULDER, "power_3": JOY_BUTTON_RIGHT_STICK, "switch_weapon": JOY_BUTTON_BACK}
const MOVE_AXES: Dictionary = {"left": [JOY_AXIS_LEFT_X, -1.0], "right": [JOY_AXIS_LEFT_X, 1.0], "up": [JOY_AXIS_LEFT_Y, -1.0], "down": [JOY_AXIS_LEFT_Y, 1.0]}
const AIM_AXES: Dictionary = {"aim_left": [JOY_AXIS_RIGHT_X, -1.0], "aim_right": [JOY_AXIS_RIGHT_X, 1.0], "aim_up": [JOY_AXIS_RIGHT_Y, -1.0], "aim_down": [JOY_AXIS_RIGHT_Y, 1.0]}
const DPAD: Dictionary = {"order_allies": JOY_BUTTON_DPAD_UP}
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
		elif BUTTONS.has(suffix):
			if not _button_taken(buttons, BUTTONS[suffix]):
				_add_button(action, BUTTONS[suffix])
		elif COPIES.has(suffix):
			for event in InputMap.action_get_events(COPIES[suffix]):
				if event is InputEventJoypadButton and not BUTTONS.values().has(event.button_index):
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


static func _button_taken(buttons: Dictionary, code: JoyButton) -> bool:
	for suffix in buttons:
		if buttons[suffix].has(code):
			return true
	return false


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


static func is_unsafe_key(code: Key) -> bool:
	return UNSAFE_KEYS.has(code)


static func migrate_keys(saved: Dictionary) -> Dictionary:
	if saved.is_empty():
		return {}
	var result: Dictionary = {}
	var taken: Array = []
	for suffix in saved:
		var kept: Array = []
		for code in saved[suffix]:
			if not is_unsafe_key(code):
				kept.append(code)
		result[suffix] = kept
		taken.append_array(kept)
	for suffix in ACTIONS:
		var additions: Array = KEYS[suffix] if result.get(suffix, []).is_empty() else ADDED_IN_LAYOUT_2.get(suffix, [])
		var own: Array = result.get(suffix, [])
		for code in additions:
			if not taken.has(code):
				own.append(code)
				taken.append(code)
		result[suffix] = own
	return result


static func uninstall() -> void:
	_users = maxi(_users - 1, 0)
	if _users > 0:
		return
	for suffix in ACTIONS + AIM_AXES.keys():
		if InputMap.has_action(PREFIX + suffix):
			InputMap.erase_action(PREFIX + suffix)
