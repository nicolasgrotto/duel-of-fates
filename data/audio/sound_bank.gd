class_name SoundBank
extends Resource

@export var sounds: Dictionary = {}


func stream(id: StringName) -> AudioStream:
	return sounds.get(id)
