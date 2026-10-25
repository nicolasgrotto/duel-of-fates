class_name TrainingConfig
extends Resource

@export var dummy_attack_interval: float = 1.0
@export var dummy_heavy_every: int = 3
@export var max_recording: float = 10.0
@export var heavy_interval_min: float = 1.2
@export var heavy_interval_max: float = 2.6
@export var parry_challenge_time: float = 45.0
@export var evade_punish_window: float = 1.0
@export var walk_distance: float = 160.0
@export var dummy_shot: MoveData
@export var dummy_shot_interval: float = 1.2

@export_group("Power gallery")
@export var gallery_pause: float = 1.0
@export var gallery_max_time: float = 10.0
@export var gallery_target_level: int = 5
@export var gallery_finisher_health: float = 1.0
@export_range(0.1, 1.0) var gallery_reach_ratio: float = 0.7
