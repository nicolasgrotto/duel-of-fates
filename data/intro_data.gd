class_name IntroData
extends PoseTrack

const NEVER: float = -1.0

@export var id: StringName
@export var ignite_at: float = 0.6
@export var second_ignite_at: float = NEVER
@export var wears_cloak: bool = false
@export var hood_down_at: float = NEVER
@export var cloak_drop_at: float = NEVER


func second_ignition() -> float:
	return ignite_at if second_ignite_at < 0.0 else second_ignite_at
