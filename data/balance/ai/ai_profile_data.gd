class_name AiProfileData
extends Resource

@export var id: StringName
@export_range(0.0, 1.0) var aggression: float = 0.5
@export_range(0.0, 1.0) var defense: float = 0.5
@export_range(0.0, 1.0) var heavy_chain_ratio: float = 0.7
@export_range(0.0, 1.0) var heavy_ratio: float = 0.3
@export_range(0.0, 1.0) var shove_bias: float = 0.5
@export_range(0.0, 1.0) var parry_bias: float = 0.5
@export_range(0.0, 1.0) var dodge_bias: float = 0.3
@export_range(0.0, 1.0) var patience: float = 0.3
@export var preferred_gap: float = 70.0
@export var safe_gap: float = 260.0
@export_range(0.0, 1.0) var low_vigor_ratio: float = 0.3
@export_range(0.0, 1.0) var ability_bias: float = 0.5
@export_range(0.0, 1.0) var feint_bias: float = 0.0
@export_range(0.0, 1.0) var power_bias: float = 0.5
@export_range(0.0, 1.0) var technique_bias: float = 0.3
