class_name PoseTrack
extends Resource

@export var keys: Array[PoseKey] = []
@export var blend_time: float = 0.4
@export var lead_in: bool = false


func last_time() -> float:
	return keys[keys.size() - 1].time if not keys.is_empty() else 0.0


func end_time() -> float:
	return last_time() + blend_time
