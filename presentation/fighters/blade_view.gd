class_name BladeView
extends Node2D

const BLADE_LENGTH: float = 92.0
const OUTER_WIDTH: float = 15.0
const INNER_WIDTH: float = 6.5
const CORE_WIDTH: float = 2.6
const OUTER_ALPHA: float = 0.2
const INNER_ALPHA: float = 0.75
const TRAIL_ALPHA: float = 0.45
const MAX_TRAIL_POINTS: int = 24
const LIGHT_ENERGY: float = 0.9
const LIGHT_SCALE: float = 2.6
const LIGHT_TEXTURE_SIZE: int = 256

var color: Color = Color.WHITE
var base: Vector2 = Vector2.ZERO
var angle_degrees: float = 0.0
var length_ratio: float = 0.0
var tremble: bool = false
var flare: float = 0.0
var trail_active: bool = false
var trail_duration: float = 0.12

var _trail_bases: PackedVector2Array = []
var _trail_tips: PackedVector2Array = []
var _trail_times: PackedFloat32Array = []
var _time: float = 0.0
var _light: PointLight2D


func _ready() -> void:
	var additive: CanvasItemMaterial = CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = additive
	_light = PointLight2D.new()
	_light.texture = _light_texture()
	_light.texture_scale = LIGHT_SCALE
	_light.energy = LIGHT_ENERGY
	add_child(_light)


func tip() -> Vector2:
	return base + Vector2.from_angle(deg_to_rad(angle_degrees)) * BLADE_LENGTH * length_ratio


func _process(delta: float) -> void:
	_time += delta
	flare = maxf(flare - delta, 0.0)
	_light.color = color
	_light.position = base.lerp(tip(), 0.5)
	_light.energy = LIGHT_ENERGY * length_ratio * (1.0 + flare * 4.0)
	_update_trail()
	queue_redraw()


func _update_trail() -> void:
	while not _trail_times.is_empty() and _time - _trail_times[0] > trail_duration:
		_trail_bases.remove_at(0)
		_trail_tips.remove_at(0)
		_trail_times.remove_at(0)
	if trail_active and length_ratio > 0.0:
		_trail_bases.append(to_global(base.lerp(tip(), 0.35)))
		_trail_tips.append(to_global(tip()))
		_trail_times.append(_time)
		if _trail_times.size() > MAX_TRAIL_POINTS:
			_trail_bases.remove_at(0)
			_trail_tips.remove_at(0)
			_trail_times.remove_at(0)


func _draw() -> void:
	if length_ratio <= 0.0:
		return
	_draw_trail()
	var end: Vector2 = tip()
	var outer_alpha: float = OUTER_ALPHA * (randf_range(0.3, 1.0) if tremble else 1.0)
	var boost: float = 1.0 + flare * 3.0
	draw_line(base, end, Color(color, outer_alpha * boost), OUTER_WIDTH * boost)
	draw_line(base, end, Color(color, INNER_ALPHA), INNER_WIDTH)
	draw_line(base, end, Color(1.0, 1.0, 1.0, 1.0), CORE_WIDTH)


func _draw_trail() -> void:
	var count: int = _trail_times.size()
	if count < 2:
		return
	draw_set_transform_matrix(get_global_transform().affine_inverse())
	for i in count - 1:
		var age: float = 1.0 - (_time - _trail_times[i]) / trail_duration
		var quad: PackedVector2Array = [_trail_bases[i], _trail_tips[i], _trail_tips[i + 1], _trail_bases[i + 1]]
		draw_colored_polygon(quad, Color(color, TRAIL_ALPHA * clampf(age, 0.0, 1.0)))
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _light_texture() -> GradientTexture2D:
	var gradient: Gradient = Gradient.new()
	gradient.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	gradient.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = LIGHT_TEXTURE_SIZE
	texture.height = LIGHT_TEXTURE_SIZE
	return texture
