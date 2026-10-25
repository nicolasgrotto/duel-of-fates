class_name IntroData
extends Resource

const NEVER: float = -1.0

@export var id: StringName
@export var keys: Array[IntroKey] = []
@export var blend_time: float = 0.4
@export var ignite_at: float = 0.6
@export var second_ignite_at: float = NEVER
@export var wears_cloak: bool = false
@export var hood_down_at: float = NEVER
@export var cloak_drop_at: float = NEVER


func second_ignition() -> float:
	return ignite_at if second_ignite_at < 0.0 else second_ignite_at


func last_time() -> float:
	return keys[keys.size() - 1].time if not keys.is_empty() else 0.0
