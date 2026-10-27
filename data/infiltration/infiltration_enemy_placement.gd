class_name InfiltrationEnemyPlacement
extends Resource

@export var enemy: InfiltrationEnemyData
@export var position: Vector2
@export var direction: Vector2 = Vector2.LEFT
@export var route: PackedVector2Array = []
@export var reinforcement: bool = false
