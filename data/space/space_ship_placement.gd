class_name SpaceShipPlacement
extends Resource

enum Role { NONE, ROOT, GENERATOR, ENGINE, TURRET, WEAKPOINT }

@export var ship: SpaceShipData
@export var position: Vector2
@export var angle: float = 0.0
@export var team: int = 0
@export var respawn_seconds: float = 0.0
@export var wave: int = 0
@export var parent: int = -1
@export var role: Role = Role.NONE
@export var formation: int = -1
@export var formation_offset: Vector2 = Vector2.ZERO
@export var target: int = -1
@export var required: bool = true
