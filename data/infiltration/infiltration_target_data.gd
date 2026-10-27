class_name InfiltrationTargetData
extends Resource

enum Kind { DUMMY, EMITTER }

@export var id: StringName
@export var kind: Kind = Kind.DUMMY
@export var position: Vector2
@export var direction: Vector2 = Vector2.LEFT
@export var health: float = 30.0
@export var bolt: BoltData
@export var initial_delay: float = 1.0
@export var fire_interval: float = 1.5
@export var respawn_seconds: float = 3.0
