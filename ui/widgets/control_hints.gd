class_name ControlHints

const SEPARATOR: String = "  ·  "
const WEB_FEATURE: String = "web"


static func key_label(action: StringName) -> String:
	var keys: PackedStringArray = key_names(action)
	return keys[0] if not keys.is_empty() else ""


static func key_names(action: StringName) -> PackedStringArray:
	var names: PackedStringArray = []
	if not InputMap.has_action(action):
		return names
	for event in InputMap.action_get_events(action):
		var key: InputEventKey = event as InputEventKey
		if key == null:
			continue
		names.append(key_name(key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode))
	return names


static func button_names(action: StringName) -> PackedStringArray:
	var names: PackedStringArray = []
	if not InputMap.has_action(action):
		return names
	for event in InputMap.action_get_events(action):
		var button: InputEventJoypadButton = event as InputEventJoypadButton
		if button != null:
			names.append(button_name(button.button_index))
		var motion: InputEventJoypadMotion = event as InputEventJoypadMotion
		if motion != null:
			names.append(TranslationServer.translate("PAD_AXIS_%d" % motion.axis))
	return names


static func button_name(button: JoyButton) -> String:
	return TranslationServer.translate("PAD_%d" % button)


static func key_name(physical: Key) -> String:
	var code: Key = physical
	if not OS.has_feature(WEB_FEATURE):
		code = DisplayServer.keyboard_get_keycode_from_physical(code)
	return OS.get_keycode_string(code)


static func hint(action: StringName, text_key: String) -> String:
	return "%s  %s" % [key_label(action), TranslationServer.translate(text_key)]


static func line(hints: PackedStringArray) -> String:
	return SEPARATOR.join(hints)


static func blaster_ops_hint(suffix: String) -> String:
	var action: StringName = StringName(BlasterOpsBindings.PREFIX + suffix)
	var names: PackedStringArray = key_names(action)
	for event in InputMap.action_get_events(action):
		if event is InputEventMouseButton:
			names.append(TranslationServer.translate("BOPS_MOUSE_LEFT" if event.button_index == MOUSE_BUTTON_LEFT else "BOPS_MOUSE_RIGHT"))
	var buttons: PackedStringArray = button_names(action)
	if not buttons.is_empty():
		names.append(buttons[0])
	return "%s  %s" % [" / ".join(names), TranslationServer.translate("BOPS_ACTION_" + suffix.to_upper())]
