class_name ControlHints

const SEPARATOR: String = "  ·  "
const WEB_FEATURE: String = "web"


static func key_label(action: StringName) -> String:
	if not InputMap.has_action(action):
		return ""
	for event in InputMap.action_get_events(action):
		var key: InputEventKey = event as InputEventKey
		if key == null:
			continue
		var code: Key = key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
		if not OS.has_feature(WEB_FEATURE):
			code = DisplayServer.keyboard_get_keycode_from_physical(code)
		return OS.get_keycode_string(code)
	return ""


static func hint(action: StringName, text_key: String) -> String:
	return "%s  %s" % [key_label(action), TranslationServer.translate(text_key)]


static func line(hints: PackedStringArray) -> String:
	return SEPARATOR.join(hints)
