class_name AiDifficultyData
extends Resource

@export var id: StringName
@export var name_key: String

@export_group("Reaction")
@export var reaction_time: float = 0.3
@export var reaction_floor: float = 0.15
@export_range(0.0, 1.0) var reaction_jitter: float = 0.4

@export_group("Defense")
@export_range(0.0, 1.0) var defend_chance: float = 0.5
@export_range(0.0, 1.0) var parry_chance: float = 0.3
@export_range(0.0, 1.0) var perfect_parry_chance: float = 0.05
@export_range(0.0, 1.0) var spin_dodge_chance: float = 0.2
@export var spin_dodge_corner: float = 140.0
@export_range(0.0, 1.0) var spin_dodge_open_ratio: float = 0.3

@export_group("Offense")
@export_range(0.0, 1.0) var shove_chance: float = 0.3
@export var attack_warning: float = 0.08
@export var smart_punish: bool = false
@export_range(0.0, 1.0) var whiff_bait_chance: float = 0.0

@export_group("Mistakes and memory")
@export_range(0.0, 1.0) var error_chance: float = 0.15
@export_range(0.0, 1.0) var habit_weight: float = 0.0
@export var habit_window: float = 8.0

@export_group("Flow")
@export_range(0.0, 1.0) var power_chance: float = 0.35
@export_range(0.0, 1.0) var power_defense_chance: float = 0.4

@export_group("Blade lock")
@export var lock_reaction: float = 0.45
@export var lock_presses_per_second: float = 9.0
@export_range(0.0, 1.0) var disengage_chance: float = 0.1
@export var awaken_below: float = 0.5
