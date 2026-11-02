class_name FinisherEffects
extends Resource

@export var streaks: PackedFloat32Array
@export var streaks_both: bool = false
@export var hole: bool = false
@export var hole_at: float = 0.0
@export var extra_holes: PackedFloat32Array
@export var shots: PackedFloat32Array


func scale_times(tempo: float) -> void:
	for i in streaks.size():
		streaks[i] *= tempo
	for i in shots.size():
		shots[i] *= tempo
	hole_at *= tempo
	for i in extra_holes.size():
		extra_holes[i] *= tempo
