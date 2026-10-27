class_name InfiltrationMapData
extends Resource

@export var id: StringName
@export var title_key: String
@export var tile_size: float = 64.0
@export var rows: PackedStringArray = []
@export var player_spawn: Vector2
@export var player_direction: Vector2 = Vector2.RIGHT
@export var targets: Array[InfiltrationTargetData] = []
@export var enemies: Array[InfiltrationEnemyPlacement] = []
@export var panels: Array[InfiltrationPanelData] = []
@export var enemy_sprites: Texture2D
@export var tiles: Texture2D
@export var sprites: Texture2D


func width() -> int:
	return rows[0].length() if not rows.is_empty() else 0


func world_size() -> Vector2:
	return Vector2(width(), rows.size()) * tile_size


func is_solid(x: int, y: int) -> bool:
	var tile: int = tile_index(x, y)
	return tile == 1 or tile == 2


func tile_index(x: int, y: int) -> int:
	if y < 0 or y >= rows.size() or x < 0 or x >= width():
		return 1
	match rows[y].unicode_at(x):
		35:
			return 1
		67:
			return 2
		61:
			return 3
	return 0
