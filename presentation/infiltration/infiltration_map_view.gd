class_name InfiltrationMapView
extends Node2D

var map: InfiltrationMapData
var config: InfiltrationConfig


func setup(data: InfiltrationMapData, configuration: InfiltrationConfig) -> void:
	map = data
	config = configuration
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	queue_redraw()


func _draw() -> void:
	if map == null:
		return
	for y in map.rows.size():
		for x in map.width():
			var destination: Rect2 = Rect2(Vector2(x, y) * map.tile_size, Vector2.ONE * map.tile_size)
			var source: Rect2 = Rect2(Vector2(map.tile_index(x, y) * config.atlas_tile_pixels, 0), Vector2.ONE * config.atlas_tile_pixels)
			draw_texture_rect_region(map.tiles, destination, source)
