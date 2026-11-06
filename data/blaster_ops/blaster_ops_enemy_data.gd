class_name BlasterOpsEnemyData
extends InfiltrationEnemyData

enum Aura { NONE, SHIELD, REPAIR }

@export var telegraph_seconds: float = 0.2
@export var attack_degrees: float = 100.0
@export var shot_angles: PackedFloat32Array
@export var aura: Aura = Aura.NONE
@export var aura_radius: float = 0.0
@export var aura_value: float = 0.0
@export var blast_radius: float = 0.0
@export var blast_damage: float = 0.0
@export var flee_range: float = 0.0
@export var stride: float = 0.0
@export var supply_value: int = 1
