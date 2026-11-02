class_name SpaceFormationData
extends Resource

@export var ship: SpaceShipData
@export var origin: Vector2
@export var angle: float = PI
@export var team: int = 1
@export var target: int = 0
@export var offsets: Array[Vector2] = [Vector2.ZERO]


func append_to(arena: SpaceArenaData, wave: int) -> void:
	var leader: int = arena.ships.size()
	for offset in offsets:
		var placement: SpaceShipPlacement = SpaceShipPlacement.new()
		placement.ship = ship
		placement.position = origin + offset.rotated(angle)
		placement.angle = angle
		placement.team = team
		placement.target = target
		placement.wave = wave
		placement.formation = leader
		placement.formation_offset = offset
		arena.ships.append(placement)
