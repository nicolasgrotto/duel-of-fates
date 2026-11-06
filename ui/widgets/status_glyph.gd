class_name StatusGlyph
extends Control

enum State { NONE, AVAILABLE, COMPLETED, LOCKED, ACTIVE }

const PALETTE: UiPalette = preload("res://ui/palette.tres")
const BOX_RATIO: float = 0.72
const STROKE: float = 2.0
const CHECK_STROKE: float = 3.0

var state: State = State.NONE:
	set(value):
		state = value
		queue_redraw()
var tint_override: Color = Color.TRANSPARENT:
	set(value):
		tint_override = value
		queue_redraw()


func _init(initial: State = State.NONE, side: float = 24.0) -> void:
	state = initial
	custom_minimum_size = Vector2(side, side)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var center: Vector2 = size * 0.5
	var half: float = minf(size.x, size.y) * BOX_RATIO * 0.5
	match state:
		State.COMPLETED:
			_draw_completed(center, half)
		State.AVAILABLE:
			_draw_diamond(center, half, _tint(PALETTE.tactical_muted))
		State.LOCKED:
			_draw_padlock(center, half)
		State.ACTIVE:
			_draw_diamond(center, half, _tint(PALETTE.menu_blade_b))
			draw_circle(center, half * 0.35, _tint(PALETTE.menu_blade_b))


func _tint(fallback: Color) -> Color:
	return tint_override if tint_override.a > 0.0 else fallback


func _draw_completed(center: Vector2, half: float) -> void:
	var color: Color = _tint(PALETTE.menu_blade_a)
	draw_rect(Rect2(center - Vector2.ONE * half, Vector2.ONE * half * 2.0), color, false, STROKE)
	draw_polyline(PackedVector2Array([center + Vector2(-half * 0.55, 0.0), center + Vector2(-half * 0.1, half * 0.5), center + Vector2(half * 0.6, -half * 0.5)]), color, CHECK_STROKE)


func _draw_diamond(center: Vector2, half: float, color: Color) -> void:
	var reach: float = half * 1.15
	draw_polyline(PackedVector2Array([center + Vector2(0.0, -reach), center + Vector2(reach, 0.0), center + Vector2(0.0, reach), center + Vector2(-reach, 0.0), center + Vector2(0.0, -reach)]), color, STROKE)


func _draw_padlock(center: Vector2, half: float) -> void:
	var color: Color = _tint(PALETTE.tactical_dim)
	draw_rect(Rect2(center + Vector2(-half, -half * 0.1), Vector2(half * 2.0, half * 1.2)), color)
	draw_arc(center + Vector2(0.0, -half * 0.1), half * 0.6, PI, TAU, 10, color, STROKE)
