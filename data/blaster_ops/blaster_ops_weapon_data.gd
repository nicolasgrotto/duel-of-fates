class_name BlasterOpsWeaponData
extends Resource

enum TrainingClass { SHORT, MEDIUM, LONG }

@export var blaster: BlasterData
@export var training_class: TrainingClass = TrainingClass.SHORT
@export var two_handed: bool = false
@export var damage_scale: float = 2.5
@export var fire_interval: float = 0.16
@export var heat_per_shot: float = 20.0
