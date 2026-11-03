class_name InfiltrationPlayerController
extends BlasterOpsPlayerController


func _init() -> void:
	prefix = "infiltration_"
	commands = {}
	for command in COMMANDS:
		var suffix: String = String(COMMANDS[command]).trim_prefix(BlasterOpsBindings.PREFIX)
		if suffix == "fire":
			suffix = "attack"
		elif suffix == "strike":
			suffix = "takedown"
		commands[command] = StringName(prefix + suffix)
