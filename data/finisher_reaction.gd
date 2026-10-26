class_name FinisherReaction
extends Resource

const NEVER: float = -1.0

@export var front_arm_at: float = NEVER
@export var back_arm_at: float = NEVER
@export var drops_hilt: bool = false
@export var kneel_at: float = NEVER
@export var head_at: float = NEVER
@export var split_at: float = NEVER
@export var fall_at: float = 0.0
@export var fall_backward: bool = false
@export var turn_at: float = NEVER
@export var push_back: float = 0.0
@export var push_at: float = 0.0
@export var push_time: float = 0.3


func scale_times(tempo: float) -> void:
	front_arm_at = FinisherMotion.scaled(front_arm_at, tempo)
	back_arm_at = FinisherMotion.scaled(back_arm_at, tempo)
	kneel_at = FinisherMotion.scaled(kneel_at, tempo)
	head_at = FinisherMotion.scaled(head_at, tempo)
	split_at = FinisherMotion.scaled(split_at, tempo)
	fall_at *= tempo
	turn_at = FinisherMotion.scaled(turn_at, tempo)
	push_at *= tempo
	push_time *= tempo
