class_name SpaceBackdrop
extends Node2D

const PALETTE: UiPalette = preload("res://ui/palette.tres")
const NEBULA: Texture2D = preload("res://assets/space/nebula.png")

var center: Vector2 = Vector2.ZERO
var _config: SpaceConfig
var _arena: SpaceArenaData
var _stars: PackedVector2Array = []


func setup(config: SpaceConfig, arena: SpaceArenaData) -> void:
	_config = config
	_arena = arena
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = config.star_seed
	for index in config.star_count:
		_stars.append(Vector2(random.randf(), random.randf()))


func _draw() -> void:
	if _config == null:
		return
	var extent: Vector2 = get_viewport_rect().size * _config.units_per_pixel
	var origin: Vector2 = center - extent * 0.5
	draw_rect(Rect2(origin - Vector2.ONE * 8.0, extent + Vector2.ONE * 16.0), PALETTE.background)
	var tile_size: Vector2 = NEBULA.get_size() * _config.units_per_pixel * 2.0
	var offset: Vector2 = center * 0.06
	var first: Vector2 = ((origin + offset) / tile_size).floor() * tile_size - offset
	for y in range(ceili(extent.y / tile_size.y) + 1):
		for x in range(ceili(extent.x / tile_size.x) + 1):
			draw_texture_rect(NEBULA, Rect2(_snap(first + Vector2(x, y) * tile_size), tile_size), false)
	for index in _stars.size():
		var layer: int = index % 3
		var point: Vector2 = _snap(_wrapped(_stars[index] * extent - center * (0.1 + layer * 0.17), extent) + origin)
		var color: Color = Color(PALETTE.secondary, 0.22 + layer * 0.15)
		var size: float = _config.units_per_pixel * (2.0 if index % 17 == 0 else 1.0)
		draw_rect(Rect2(point, Vector2.ONE * size), color)
	var step: float = 80.0
	for side in 2:
		for x in range(0, ceili(_arena.size.x / step)):
			draw_line(Vector2(x * step, side * _arena.size.y), Vector2(x * step + step * 0.4, side * _arena.size.y), PALETTE.infiltration_edge, _config.units_per_pixel)
		for y in range(0, ceili(_arena.size.y / step)):
			draw_line(Vector2(side * _arena.size.x, y * step), Vector2(side * _arena.size.x, y * step + step * 0.4), PALETTE.infiltration_edge, _config.units_per_pixel)


func _wrapped(point: Vector2, size: Vector2) -> Vector2:
	return Vector2(fposmod(point.x, size.x), fposmod(point.y, size.y))


func _snap(point: Vector2) -> Vector2:
	return (point / _config.units_per_pixel).round() * _config.units_per_pixel
