class_name BlasterOpsMapView
extends InfiltrationMapView

var operations: BlasterOpsSimulation
var _revision: int = -1
var _health_hash: int = 0


func attach(sim: BlasterOpsSimulation) -> void:
	operations = sim
	setup(sim.map, sim.config)


func _process(_delta: float) -> void:
	var current: int = 0
	for cover in operations.arena.covers:
		current = current * 31 + int(cover.health)
	if _revision != operations.cover_revision or current != _health_hash:
		_revision = operations.cover_revision
		_health_hash = current
		queue_redraw()


func _draw() -> void:
	super._draw()
	if operations == null:
		return
	for cover in operations.arena.covers:
		var position: Vector2 = Vector2(cover.data.cell) * map.tile_size
		var source: Rect2 = Rect2(Vector2(cover.damage_stage() * config.atlas_tile_pixels, 0), Vector2.ONE * config.atlas_tile_pixels)
		draw_texture_rect_region(operations.arena.source.cover_atlas, Rect2(position, Vector2.ONE * map.tile_size), source)
