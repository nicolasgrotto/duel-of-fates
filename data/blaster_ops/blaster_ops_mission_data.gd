class_name BlasterOpsMissionData
extends InfiltrationMissionData

enum Kind { ARENA, ASSAULT, DEFENSE, HOLD_OUT, ESCORT, RIVAL, BOSS }

@export var kind: Kind = Kind.ARENA
@export var waves: Array[BlasterOpsWaveData] = []
@export var defense_targets: PackedInt32Array
@export var protected_index: int = -1
@export var protected_health: float = 180.0
@export var hold_seconds: float = 0.0
@export var phase_target: int = -1
@export var phases: Array[BlasterOpsPhaseData] = []
@export var intermission_seconds: float = 6.0
@export var damage_bonus: float = 25.0
@export var accuracy_bonus: float = 0.5


func objective_count() -> int:
	return 2
