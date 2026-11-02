class_name SpaceMissionResult
extends RefCounted

var mission_id: StringName
var outcome: SpaceMissionState.Outcome
var ticks: int
var rating: int
var hull: float
var objectives: Array[Dictionary] = []
var point_earned: bool = false
var phase_visits: PackedInt32Array = []
var waves: int = 0


func won() -> bool:
	return outcome == SpaceMissionState.Outcome.COMPLETED
