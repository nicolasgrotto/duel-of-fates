class_name EvadeGlow
extends Node2D

const GRID: float = 2.0
const LAYERS: Array[Vector3] = [Vector3(1.0, 0.35, 0.0), Vector3(0.62, 0.6, 0.25), Vector3(0.3, 1.0, 0.7)]

var color: Color = Color.WHITE
var duration: float = 0.3
var radius: float = 22.0
var alpha: float = 0.55
var bloom: float = 0.35
var fade_steps: int = 3
var _left: float = 0.0


func _ready() -> void:
	var additive: CanvasItemMaterial = CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = additive


func flash() -> void:
	_left = duration
	queue_redraw()


func follow(at: Vector2) -> void:
	global_position = at.snapped(Vector2.ONE * GRID)


func is_lit() -> bool:
	return _left > 0.0


func _process(delta: float) -> void:
	if _left <= 0.0:
		return
	_left = maxf(_left - delta, 0.0)
	queue_redraw()


func _draw() -> void:
	if _left <= 0.0:
		return
	var life: float = _left / maxf(duration, 0.001)
	var strength: float = ceilf(life * fade_steps) / fade_steps * alpha
	var size: float = radius * (1.0 + (1.0 - life) * bloom)
	for layer in LAYERS:
		var layer_radius: float = maxf(snappedf(size * layer.x, GRID), GRID)
		var tint: Color = color.lerp(Color.WHITE, layer.z)
		draw_circle(Vector2.ZERO, layer_radius, Color(tint, strength * layer.y), true, -1.0, false)
