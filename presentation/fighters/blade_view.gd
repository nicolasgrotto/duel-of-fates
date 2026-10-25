class_name BladeView
extends Node2D

const OUTER_WIDTH: float = 11.0
const GRID: float = 2.0
const OUTER_PIXELS: float = 7.0
const GLOW_PIXELS: float = 5.0
const INNER_PIXELS: float = 3.0
const CORE_PIXELS: float = 1.5
const TIP_WIDTH: float = 0.35
const OUTER_ALPHA: float = 0.16
const INNER_ALPHA: float = 0.78
const TRAIL_ALPHA: float = 0.32
const REFLECTION_ALPHA: float = 0.16
const REFLECTION_WIDTH: float = 3.2
const REFLECTION_SQUASH: float = 0.16
const EYE_RADIUS: float = 1.4
const EYE_HALO: float = 5.0
const EYE_HALO_ALPHA: float = 0.25
const GLINT_SIZE: float = 9.0
const GLINT_CORE: float = 2.0

var color: Color = Color.WHITE
var width_scale: float = 1.0
var length_ratio: float = 0.0
var second_ratio: float = 1.0
var tremble: bool = false
var flare: float = 0.0
var trail_duration: float = 0.12
var fade_steps: int = 3
var glint: float = 0.0
var glint_duration: float = 0.2
var reflect: bool = false
var eyes_visible: bool = false
var eyes_position: Vector2 = Vector2.ZERO
var eyes_color: Color = Color("#ffb22e")
var eyes_core: Color = Color("#e2321e")

var _blades: Array[PackedVector2Array] = [PackedVector2Array([Vector2.ZERO, Vector2.ZERO]), PackedVector2Array([Vector2.ZERO, Vector2.ZERO])]
var _blade_count: int = 0
var _trails: Array[BladeTrail] = [BladeTrail.new(), BladeTrail.new()]
var _trail_active: Array[bool] = [false, false]
var _time: float = 0.0
var _beam: PackedVector2Array = PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])


func _ready() -> void:
	var additive: CanvasItemMaterial = CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = additive


func set_blades(geometry: WeaponPose, main_trail: bool, second_trail: bool) -> void:
	_blade_count = 2 if geometry.has_second and geometry.second_length > 0.0 else 1
	_blades[0][0] = geometry.blade_base
	_blades[0][1] = geometry.blade_base + geometry.blade_direction * geometry.blade_length * length_ratio
	if _blade_count == 2:
		_blades[1][0] = geometry.second_base
		_blades[1][1] = geometry.second_base + geometry.second_direction * geometry.second_length * length_ratio * second_ratio
	_trail_active[0] = main_trail
	_trail_active[1] = second_trail


func point_along(weight: float) -> Vector2:
	return _blades[0][0].lerp(_blades[0][1], weight)


func center() -> Vector2:
	return _blades[0][0].lerp(_blades[0][1], 0.5)


func _process(delta: float) -> void:
	_time += delta
	flare = maxf(flare - delta, 0.0)
	glint = maxf(glint - delta, 0.0)
	for i in _blade_count:
		_trails[i].update(_time, trail_duration, _trail_active[i] and length_ratio > 0.0, _blades[i][0].lerp(_blades[i][1], 0.3), _blades[i][1])
	queue_redraw()


func _draw() -> void:
	if eyes_visible:
		draw_circle(eyes_position, EYE_HALO, Color(eyes_color, EYE_HALO_ALPHA))
		draw_circle(eyes_position, EYE_RADIUS, eyes_core.lerp(eyes_color, 0.5))
	if length_ratio <= 0.0:
		return
	for i in _blade_count:
		_trails[i].draw_on(self, color, TRAIL_ALPHA, fade_steps)
	for i in _blade_count:
		_draw_blade(_blades[i][0], _blades[i][1])
		if reflect:
			_draw_reflection(_blades[i][0], _blades[i][1])
	if glint > 0.0:
		_draw_glint(_blades[0][1])


func _draw_glint(at: Vector2) -> void:
	var size: float = GLINT_SIZE * sin(glint / glint_duration * PI)
	draw_line(at - Vector2(size, 0.0), at + Vector2(size, 0.0), color, GLINT_CORE)
	draw_line(at - Vector2(0.0, size), at + Vector2(0.0, size), color, GLINT_CORE)
	draw_rect(Rect2(at - Vector2.ONE * GLINT_CORE, Vector2.ONE * GLINT_CORE * 2.0), Color.WHITE)


func _draw_blade(base: Vector2, tip: Vector2) -> void:
	var outer_alpha: float = OUTER_ALPHA * (randf_range(0.3, 1.0) if tremble else 1.0)
	var boost: float = 1.0 + flare * 3.0
	var thickness: float = maxf(width_scale, 0.6)
	_pixel_beam(base, tip, _odd(OUTER_PIXELS * thickness * boost), Color(color, outer_alpha * 0.6 * boost), 0)
	_pixel_beam(base, tip, _odd(GLOW_PIXELS * thickness * boost), Color(color, outer_alpha * boost), 1)
	_pixel_beam(base, tip, _odd(INNER_PIXELS * thickness), Color(color, INNER_ALPHA), 1)
	_pixel_beam(base, tip, CORE_PIXELS * thickness, Color.WHITE, 2)
	var emitter: Vector2 = base.snapped(Vector2(GRID, GRID))
	draw_rect(Rect2(emitter - Vector2(GRID, GRID), Vector2(GRID, GRID) * 2.0), Color(Color.WHITE, 0.9))


func _pixel_beam(base: Vector2, tip: Vector2, pixels: float, tint: Color, taper: int) -> void:
	var span: Vector2 = tip - base
	var length: float = span.length()
	if length < GRID:
		return
	var direction: Vector2 = span / length
	var side: Vector2 = direction.orthogonal() * pixels * GRID * 0.5
	var shoulder: Vector2 = base + direction * maxf(length - taper * GRID * 2.0, 0.0)
	var point: Vector2 = side * TIP_WIDTH
	_beam[0] = base - side
	_beam[1] = shoulder - side
	_beam[2] = tip - point
	_beam[3] = tip + point
	_beam[4] = shoulder + side
	_beam[5] = base + side
	draw_colored_polygon(_beam, tint)


static func _odd(pixels: float) -> float:
	var whole: int = maxi(int(round(pixels)), 1)
	return float(whole if whole % 2 == 1 else whole + 1)


func _draw_reflection(base: Vector2, tip: Vector2) -> void:
	var mirrored_base: Vector2 = Vector2(base.x, -base.y * REFLECTION_SQUASH)
	var mirrored_tip: Vector2 = Vector2(tip.x, -tip.y * REFLECTION_SQUASH)
	draw_line(mirrored_base, mirrored_tip, Color(color, REFLECTION_ALPHA), OUTER_WIDTH * width_scale)
	draw_line(mirrored_base, mirrored_tip, Color(color, REFLECTION_ALPHA * 1.5), REFLECTION_WIDTH * width_scale)
