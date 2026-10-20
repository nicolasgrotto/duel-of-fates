extends Node2D

const BACKDROP_WIDTH: float = 6000.0
const BACKDROP_HEIGHT: float = 2400.0
const WALL_HEIGHT: float = 700.0
const WALL_THICKNESS: float = 40.0
const PILLAR_WIDTH: float = 70.0
const PILLAR_SPACING: float = 520.0
const PILLAR_HEIGHT: float = 1100.0

@export var arena_width: float = 1200.0
@export var floor_depth: float = 260.0
@export var mark_spacing: float = 100.0
@export var sky_top: Color = Color("#05070d")
@export var sky_bottom: Color = Color("#0c111b")
@export var platform_color: Color = Color("#141a24")
@export var platform_edge: Color = Color("#2a3242")
@export var mark_color: Color = Color(0.54, 0.58, 0.67, 0.18)
@export var wall_color: Color = Color("#0e131c")
@export var far_layer_color: Color = Color("#090d15")


func _draw() -> void:
	var half: float = arena_width * 0.5
	var sky: PackedVector2Array = [
		Vector2(-BACKDROP_WIDTH, -BACKDROP_HEIGHT), Vector2(BACKDROP_WIDTH, -BACKDROP_HEIGHT),
		Vector2(BACKDROP_WIDTH, floor_depth), Vector2(-BACKDROP_WIDTH, floor_depth),
	]
	draw_polygon(sky, PackedColorArray([sky_top, sky_top, sky_bottom, sky_bottom]))
	var x: float = -BACKDROP_WIDTH
	while x < BACKDROP_WIDTH:
		draw_rect(Rect2(x, -PILLAR_HEIGHT, PILLAR_WIDTH, PILLAR_HEIGHT), far_layer_color)
		x += PILLAR_SPACING
	draw_rect(Rect2(-half - WALL_THICKNESS, -WALL_HEIGHT, WALL_THICKNESS, WALL_HEIGHT), wall_color)
	draw_rect(Rect2(half, -WALL_HEIGHT, WALL_THICKNESS, WALL_HEIGHT), wall_color)
	draw_rect(Rect2(-half - WALL_THICKNESS, 0.0, arena_width + WALL_THICKNESS * 2.0, floor_depth), platform_color)
	draw_line(Vector2(-half - WALL_THICKNESS, 0.0), Vector2(half + WALL_THICKNESS, 0.0), platform_edge, 3.0)
	var mark: float = 0.0
	while mark <= half:
		var height: float = 14.0 if is_zero_approx(fmod(mark, mark_spacing * 2.0)) else 8.0
		draw_line(Vector2(mark, 2.0), Vector2(mark, 2.0 + height), mark_color, 2.0)
		if mark > 0.0:
			draw_line(Vector2(-mark, 2.0), Vector2(-mark, 2.0 + height), mark_color, 2.0)
		mark += mark_spacing
