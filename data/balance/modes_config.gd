class_name ModesConfig
extends Resource

@export_group("Arcade")
@export var arcade_opponents: int = 6
@export var arcade_easy_fights: int = 2
@export var arcade_normal_fights: int = 2

@export_group("Survival")
@export var survival_heal_ratio: float = 0.3
@export var survival_easy_wins: int = 2
@export var survival_normal_wins: int = 5
@export var survival_boss_every: int = 5

@export_group("Boss")
@export var boss_letterbox: float = 1.5
@export var boss_message_seconds: float = 1.5
@export_range(0.0, 1.0) var boss_music_floor: float = 0.7
