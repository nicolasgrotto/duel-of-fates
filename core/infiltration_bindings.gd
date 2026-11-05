class_name InfiltrationBindings
extends RefCounted

const ALIASES: Dictionary = {"left": "left", "right": "right", "up": "up", "down": "down", "attack": "fire", "guard": "guard", "run": "run", "sneak": "sneak", "takedown": "strike", "interact": "interact", "dodge": "dodge", "power": "power", "power_2": "power_2", "power_3": "power_3", "switch_weapon": "switch_weapon", "aim_left": "aim_left", "aim_right": "aim_right", "aim_up": "aim_up", "aim_down": "aim_down"}
const KEYS: Dictionary = {
	&"infiltration_left": BlasterOpsBindings.KEYS.left, &"infiltration_right": BlasterOpsBindings.KEYS.right,
	&"infiltration_up": BlasterOpsBindings.KEYS.up, &"infiltration_down": BlasterOpsBindings.KEYS.down,
	&"infiltration_attack": BlasterOpsBindings.KEYS.fire, &"infiltration_guard": BlasterOpsBindings.KEYS.guard,
	&"infiltration_run": BlasterOpsBindings.KEYS.run, &"infiltration_sneak": BlasterOpsBindings.KEYS.sneak,
	&"infiltration_takedown": BlasterOpsBindings.KEYS.strike, &"infiltration_interact": BlasterOpsBindings.KEYS.interact,
	&"infiltration_dodge": BlasterOpsBindings.KEYS.dodge, &"infiltration_power": BlasterOpsBindings.KEYS.power, &"infiltration_power_2": BlasterOpsBindings.KEYS.power_2,
	&"infiltration_power_3": BlasterOpsBindings.KEYS.power_3, &"infiltration_switch_weapon": BlasterOpsBindings.KEYS.switch_weapon,
}
static var _users: int = 0


static func install(keys: Dictionary = {}, buttons: Dictionary = {}) -> void:
	_users += 1
	BlasterOpsBindings.install(keys, buttons)
	refresh()


static func refresh() -> void:
	if _users == 0:
		return
	for suffix in ALIASES:
		var action: StringName = StringName("infiltration_" + suffix)
		if not InputMap.has_action(action):
			InputMap.add_action(action, BlasterOpsBindings.DEADZONE)
		InputMap.action_erase_events(action)
		for event in InputMap.action_get_events(BlasterOpsBindings.PREFIX + ALIASES[suffix]):
			InputMap.action_add_event(action, event.duplicate())


static func uninstall() -> void:
	if _users == 0:
		return
	_users -= 1
	BlasterOpsBindings.uninstall()
	if _users > 0:
		return
	for suffix in ALIASES:
		var action: StringName = StringName("infiltration_" + suffix)
		if InputMap.has_action(action):
			InputMap.erase_action(action)
