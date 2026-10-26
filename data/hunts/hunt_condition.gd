class_name HuntCondition
extends Resource

enum Goal { PERFECT_PARRIES, TIME_LIMIT, SURVIVE_SINGULARITY }

@export var goal: Goal = Goal.PERFECT_PARRIES
@export var description_key: String
@export var count: int = 3
@export var seconds: float = 90.0
