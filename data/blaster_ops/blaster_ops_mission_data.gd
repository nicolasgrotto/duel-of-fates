class_name BlasterOpsMissionData
extends InfiltrationMissionData

enum Kind { ARENA, ASSAULT, DEFENSE, HOLD_OUT, ESCORT, RIVAL, BOSS }

@export var kind: Kind = Kind.ARENA
@export var waves: Array[BlasterOpsWaveData] = []
@export var stages: Array[BlasterOpsStageData] = []
@export var defense_targets: PackedInt32Array
@export var protected_index: int = -1
@export var protected_health: float = 180.0
@export var hold_seconds: float = 0.0
@export var phase_target: int = -1
@export var phases: Array[BlasterOpsPhaseData] = []
@export var intermission_seconds: float = 6.0
@export var supply_terminals: PackedVector2Array
@export var starting_supplies: int = 0
@export var supply_per_wave: int = 2
@export var enemy_damage_scale: float = 1.0
@export var barrier_charges: int = 0
@export var heavy_barrier_charges: int = 0
@export var barrier_prep_only: bool = false
@export var ally_roles: Array[BlasterOpsAllyData] = []
@export var reserve_start: int = -1
@export var damage_bonus: float = 25.0
@export var accuracy_bonus: float = 0.5


func ally_role(index: int) -> BlasterOpsAllyData:
	return ally_roles[index] if index >= 0 and index < ally_roles.size() else null


func is_reserve(index: int) -> bool:
	return reserve_start >= 0 and index >= reserve_start


func objective_count() -> int:
	return stages.size() if not stages.is_empty() else 2
