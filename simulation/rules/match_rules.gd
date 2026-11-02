class_name MatchRules
extends Resource

const DEFAULT_START_HEALTH: PackedFloat32Array = [1.0, 1.0]

@export var rounds_to_win: int = 2
@export var exhaustion: bool = true
@export var wounds: bool = true
@export var blade_lock: bool = true
@export var finishers: bool = true
@export var fighter_intros: bool = false
@export var round_intro: bool = true
@export var endless: bool = false
@export var endless_finishers: bool = false
@export var fixed_finishers: bool = false
@export var powers: bool = true
@export var focus_evade: bool = true
@export var free_powers: bool = false
@export var start_health: PackedFloat32Array = DEFAULT_START_HEALTH
