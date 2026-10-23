class_name ConsequenceConfig
extends Resource

@export_group("Exhaustion")
@export var exhaustion_enter_ratio: float = 0.05
@export var exhaustion_exit_ratio: float = 0.30
@export var exhaustion_min_duration: float = 1.0
@export var exhausted_damage_multiplier: float = 1.1

@export_group("Wounds")
@export var wounded_arm_block_multiplier: float = 1.25
@export var wounded_leg_dodge_multiplier: float = 1.2

@export_group("Finishers")
@export var head_finisher_chance: float = 0.3
@export var head_on_deciding_heavy: bool = true
