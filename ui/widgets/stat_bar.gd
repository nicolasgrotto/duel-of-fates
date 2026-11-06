class_name StatBar
extends Control

const PALETTE: UiPalette = preload("res://ui/palette.tres")
const BAR_HEIGHT: float = 10.0

var ratio: float = 0.0
var bonus_ratio: float = 0.0


func _init() -> void:
	custom_minimum_size.y = BAR_HEIGHT
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_values(base: float, upgraded: float, maximum: float) -> void:
	ratio = clampf(base / maximum, 0.0, 1.0)
	bonus_ratio = clampf(upgraded / maximum, ratio, 1.0)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), PALETTE.tactical_raised)
	if bonus_ratio > ratio:
		draw_rect(Rect2(Vector2(size.x * ratio, 0.0), Vector2(size.x * (bonus_ratio - ratio), size.y)), PALETTE.menu_blade_a)
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * ratio, size.y)), PALETTE.text)
