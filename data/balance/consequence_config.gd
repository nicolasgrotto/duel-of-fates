class_name ConsequenceConfig
extends Resource

const DEFAULT_CUT_HEIGHTS: PackedFloat32Array = [100.0, 132.0, 66.0, 104.0, 96.0, 100.0, 100.0]

@export_group("Exhaustion")
@export var exhaustion_enter_ratio: float = 0.05
@export var exhaustion_exit_ratio: float = 0.30
@export var exhaustion_min_duration: float = 1.0
@export var exhausted_damage_multiplier: float = 1.1

@export_group("Wounds")
@export var wounded_arm_block_multiplier: float = 1.25
@export var wounded_leg_dodge_multiplier: float = 1.2

@export_group("Finishers")
@export var cut_heights: PackedFloat32Array = DEFAULT_CUT_HEIGHTS
@export var head_line: float = 118.0
@export var leg_line: float = 50.0
@export var head_on_deciding_heavy: bool = true
@export var cinematic_ko_time: float = 1.6
@export var long_cinematic_ko_time: float = 3.4
@export var long_replay_tail: float = 2.4
@export var dash_through_clearance: float = 24.0
@export var execution_clearance: float = 16.0
@export var finisher_backstep: float = 70.0
