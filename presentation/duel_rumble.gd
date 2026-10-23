class_name DuelRumble
extends Node

var devices: PackedInt32Array = PackedInt32Array([-1, -1])


func setup(controllers: Array[DuelSetup.ControllerKind], player_slots: Array[int]) -> void:
	for i in devices.size():
		devices[i] = player_slots[i] if i < controllers.size() and controllers[i] == DuelSetup.ControllerKind.PLAYER else -1


func on_rumbled(weak: float, strong: float, duration: float, source: int, target: int) -> void:
	if not Settings.vibration:
		return
	for index in [source, target]:
		if index >= 0 and index < devices.size() and devices[index] >= 0:
			Input.start_joy_vibration(devices[index], weak, strong, duration)


func _exit_tree() -> void:
	for device in devices:
		if device >= 0:
			Input.stop_joy_vibration(device)
