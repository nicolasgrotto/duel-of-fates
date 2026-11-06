class_name LevelPips
extends Control

const PALETTE: UiPalette = preload("res://ui/palette.tres")
const PIP_SIDE: float = 16.0
const PIP_GAP: float = 6.0
const OUTLINE: float = 2.0

var level: int = 0:
	set(value):
		level = value
		_refit()
var limit: int = 0:
	set(value):
		limit = value
		_refit()
var diamonds: bool = false:
	set(value):
		diamonds = value
		queue_redraw()
var filled_color: Color = PALETTE.menu_blade_a:
	set(value):
		filled_color = value
		queue_redraw()


func _init(current: int = 0, maximum: int = 0) -> void:
	level = current
	limit = maximum
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _refit() -> void:
	custom_minimum_size = Vector2(limit * PIP_SIDE + maxi(limit - 1, 0) * PIP_GAP, PIP_SIDE)
	queue_redraw()


func _draw() -> void:
	for index in limit:
		var pip: Rect2 = Rect2(Vector2(index * (PIP_SIDE + PIP_GAP), (size.y - PIP_SIDE) * 0.5), Vector2.ONE * PIP_SIDE)
		if diamonds:
			_draw_diamond(pip, index < level)
		elif index < level:
			draw_rect(pip, filled_color)
		else:
			draw_rect(pip.grow(-OUTLINE * 0.5), PALETTE.tactical_line_strong, false, OUTLINE)


func _draw_diamond(pip: Rect2, filled: bool) -> void:
	var center: Vector2 = pip.get_center()
	var reach: float = PIP_SIDE * 0.5
	var points: PackedVector2Array = [center + Vector2(0.0, -reach), center + Vector2(reach, 0.0), center + Vector2(0.0, reach), center + Vector2(-reach, 0.0)]
	if filled:
		draw_colored_polygon(points, filled_color)
	else:
		points.append(points[0])
		draw_polyline(points, PALETTE.tactical_line_strong, OUTLINE)
