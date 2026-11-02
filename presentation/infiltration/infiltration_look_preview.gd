class_name InfiltrationLookPreview
extends Control

const CONFIG: InfiltrationConfig = preload("res://data/balance/infiltration_config.tres")
const PREVIEW_SCALE: float = 3.0
const PREVIEW_SIZE: Vector2 = Vector2(480.0, 340.0)
const FACING: Vector2 = Vector2.UP
const FIGURE_SPACING: float = 120.0
const FIGURE_HEIGHT: float = 84.0
const REST_BLEND: float = 0.0
const GUARD_BLEND: float = 1.0

var _look: InfiltrationLook
var _blade: InfiltrationBlade = InfiltrationBlade.new()


func _ready() -> void:
	custom_minimum_size = PREVIEW_SIZE
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visible = false


func show_look(look: InfiltrationLook) -> void:
	_look = look
	visible = look != null
	queue_redraw()


func _draw() -> void:
	if _look == null:
		return
	var middle: float = PREVIEW_SIZE.x * 0.5 / PREVIEW_SCALE
	_draw_figure(Vector2(middle - FIGURE_SPACING * 0.5, FIGURE_HEIGHT), REST_BLEND)
	_draw_figure(Vector2(middle + FIGURE_SPACING * 0.5, FIGURE_HEIGHT), GUARD_BLEND)


func _draw_figure(center: Vector2, guard_blend: float) -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * PREVIEW_SCALE)
	var size: Vector2 = Vector2(CONFIG.sprite_pixels) * CONFIG.units_per_pixel
	draw_texture_rect(_look.texture, Rect2(center - size * 0.5, size), false)
	_blade.compose(CONFIG, FACING, guard_blend, 0.0, 0.0)
	_blade.draw(self, center, _look, CONFIG)
	draw_set_transform(Vector2.ZERO)
