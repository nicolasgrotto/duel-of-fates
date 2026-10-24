class_name SlashStreak
extends Node2D

const PALETTE: UiPalette = preload("res://ui/palette.tres")
const FADE_STEPS: float = 3.0

var from_point: Vector2 = Vector2.ZERO
var to_point: Vector2 = Vector2.ZERO
var color: Color = Color.WHITE
var life: float = 0.3
var width: float = 6.0
var _age: float = 0.0


func _ready() -> void:
	var additive: CanvasItemMaterial = CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = additive
	z_index = FighterRig.BODY_DEPTH + 30


func _process(delta: float) -> void:
	_age += delta
	if _age >= life:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var strength: float = ceilf((1.0 - _age / life) * FADE_STEPS) / FADE_STEPS
	var head: Vector2 = from_point.lerp(to_point, minf(_age / (life * 0.3), 1.0))
	draw_line(from_point, head, Color(color, 0.35 * strength), width * 2.0)
	draw_line(from_point, head, Color(color, 0.8 * strength), width)
	draw_line(from_point, head, Color(PALETTE.spark_hot, strength), width * 0.35)
