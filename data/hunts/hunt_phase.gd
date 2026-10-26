class_name HuntPhase
extends Resource

@export var title_key: String
@export_range(0.0, 1.0) var health_threshold: float = 1.0
@export var profile: AiProfileData
@export var powers: Array[PowerData] = []
@export var flow_level: int = 7
@export var starting_flow: float = 100.0
@export_range(-1, 2) var opening_slot: int = -1
