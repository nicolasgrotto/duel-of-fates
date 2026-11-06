class_name BlasterOpsStageData
extends Resource

enum Objective { CLEAR, DESTROY, HOLD, REACH, INTERACT, ESCORT, BOSS }

@export var objective: Objective = Objective.CLEAR
@export var title_key: String
@export var first_wave: int = -1
@export var last_wave: int = -1
@export var wave_gap_seconds: float = 0.0
@export var targets: PackedInt32Array
@export var terminals: PackedInt32Array
@export var opens_covers: PackedInt32Array
@export var hold_seconds: float = 0.0
@export var zone: Vector2
@export var zone_radius: float = 0.0
@export var prep_seconds: float = 4.0
@export var supply_reward: int = 2
@export var repair_on_complete: float = 20.0
@export var requires_clear: bool = false
