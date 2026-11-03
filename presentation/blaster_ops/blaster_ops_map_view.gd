class_name BlasterOpsMapView
extends InfiltrationMapView

const PALETTE: UiPalette = preload("res://ui/palette.tres")

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
		if cover.data.cell.x < 0:
			continue
		var position: Vector2 = Vector2(cover.data.cell) * map.tile_size
		if operations.mission is BlasterOpsMissionState and operations.arena.covers.find(cover) >= operations.arena.covers.size() - operations.operations.barrier_capacity and (operations.mission as BlasterOpsMissionState).definition.kind == BlasterOpsMissionData.Kind.DEFENSE:
			if cover.health > 0.0:
				var color: Color = PALETTE.accent
				draw_rect(Rect2(position + Vector2.ONE * 4.0, Vector2.ONE * (map.tile_size - 8.0)), PALETTE.background)
				draw_rect(Rect2(position + Vector2.ONE * 4.0, Vector2.ONE * (map.tile_size - 8.0)), color, false, config.units_per_pixel)
				draw_line(position + Vector2(12, 24), position + Vector2(12 + 40 * cover.health / operations.operations.deploy_health, 24), color, 4.0)
			continue
		var source: Rect2 = Rect2(Vector2(cover.damage_stage() * config.atlas_tile_pixels, 0), Vector2.ONE * config.atlas_tile_pixels)
		draw_texture_rect_region((operations.arena.source as BlasterOpsArenaData).cover_atlas, Rect2(position, Vector2.ONE * map.tile_size), source)
