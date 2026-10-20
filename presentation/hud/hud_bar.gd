class_name HudBar
extends Control

const OUTLINE_WIDTH: float = 1.0

var ratio: float = 1.0
var ghost_ratio: float = 1.0
var fill_color: Color = Color.WHITE
var ghost_color: Color = Color(1.0, 1.0, 1.0, 0.3)
var back_color: Color = Color(1.0, 1.0, 1.0, 0.1)
var anchored_right: bool = false
var outlined: bool = false


func _draw() -> void:
	var bar: Rect2 = Rect2(Vector2.ZERO, size)
	draw_rect(bar, back_color)
	if ghost_ratio > ratio:
		draw_rect(_portion(ghost_ratio), ghost_color)
	draw_rect(_portion(ratio), fill_color)
	if outlined:
		draw_rect(bar, fill_color, false, OUTLINE_WIDTH)


func _portion(value: float) -> Rect2:
	var width: float = size.x * clampf(value, 0.0, 1.0)
	var left: float = size.x - width if anchored_right else 0.0
	return Rect2(left, 0.0, width, size.y)
