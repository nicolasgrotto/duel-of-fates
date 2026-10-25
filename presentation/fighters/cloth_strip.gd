class_name ClothStrip
extends Node2D

const GRAVITY: float = 1300.0
const DAMPING: float = 0.9
const ITERATIONS: int = 3
const BACK_TILT: float = 0.18
const WIND_FORCE: float = -900.0
const WIND_FLUTTER: float = 9.0
const FLOOR_FRICTION: float = 0.3

var texture: Texture2D
var length: float = 40.0
var top_width: float = 20.0
var bottom_width: float = 26.0
var stiffness: float = 0.5
var segments: int = 5
var back_layer: bool = false
var floor_y: float = 0.0
var wind: float = 0.0
var released: bool = false
var released_time: float = 0.0

var _points: PackedVector2Array = []
var _previous: PackedVector2Array = []
var _rest: PackedVector2Array = []
var _polygon: PackedVector2Array = []
var _uvs: PackedVector2Array = []
var _colors: PackedColorArray = []
var _initialized: bool = false
var _wind_clock: float = 0.0
var _mirror: PackedVector2Array = PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
var _mirror_colors: PackedColorArray = PackedColorArray([Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE])


func configure(spec: Dictionary, cloth_texture: Texture2D) -> void:
	texture = cloth_texture
	length = spec.get("length", length)
	top_width = spec.get("top_width", top_width)
	bottom_width = spec.get("bottom_width", bottom_width)
	stiffness = spec.get("stiffness", stiffness)
	segments = int(spec.get("segments", segments))
	back_layer = spec.get("layer", "front") == "back"
	_points.resize(segments + 1)
	_previous.resize(segments + 1)
	_rest.resize(segments + 1)
	_polygon.resize(4)
	_uvs.resize(4)
	_colors = PackedColorArray([Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE])
	_initialized = false


func reset() -> void:
	_initialized = false


func release(fling: Vector2) -> void:
	if released or not _initialized:
		return
	released = true
	released_time = 0.0
	for i in segments + 1:
		_previous[i] = _points[i] - fling * (1.0 - float(i) / segments) / 60.0


func _fall(delta: float) -> void:
	var step: float = minf(delta, 1.0 / 30.0)
	released_time += delta
	var segment: float = length / segments
	for i in segments + 1:
		var current: Vector2 = _points[i]
		var velocity: Vector2 = (current - _previous[i]) * DAMPING
		_previous[i] = current
		_points[i] = current + velocity + Vector2(0.0, GRAVITY) * step * step
	for iteration in ITERATIONS:
		for i in segments:
			var offset: Vector2 = _points[i + 1] - _points[i]
			var distance: float = maxf(offset.length(), 0.001)
			var correction: Vector2 = offset * ((distance - segment) / distance) * 0.5
			_points[i] += correction
			_points[i + 1] -= correction
		for i in segments + 1:
			if _points[i].y >= floor_y:
				_points[i].y = floor_y
				_previous[i].x = lerpf(_previous[i].x, _points[i].x, FLOOR_FRICTION)
	queue_redraw()


func simulate(anchor: Vector2, body_angle: float, facing: int, delta: float) -> void:
	if released:
		_fall(delta)
		return
	var segment: float = length / segments
	var tilt: float = BACK_TILT if back_layer else 0.0
	var down: Vector2 = Vector2(-tilt * facing, 1.0).normalized().rotated(body_angle * 0.35)
	for i in segments + 1:
		_rest[i] = anchor + down * segment * i
	if not _initialized:
		for i in segments + 1:
			_points[i] = _rest[i]
			_previous[i] = _rest[i]
		_initialized = true
	var step: float = minf(delta, 1.0 / 30.0)
	_wind_clock += delta
	_points[0] = anchor
	_previous[0] = anchor
	for i in range(1, segments + 1):
		var current: Vector2 = _points[i]
		var velocity: Vector2 = (current - _previous[i]) * DAMPING
		_previous[i] = current
		var gust: float = wind * WIND_FORCE * (0.7 + 0.3 * sin(_wind_clock * WIND_FLUTTER + i))
		var next: Vector2 = current + velocity + Vector2(gust, GRAVITY) * step * step
		_points[i] = next.lerp(_rest[i], stiffness * 0.35)
	for iteration in ITERATIONS:
		for i in segments:
			var a: Vector2 = _points[i]
			var b: Vector2 = _points[i + 1]
			var offset: Vector2 = b - a
			var distance: float = maxf(offset.length(), 0.001)
			var correction: Vector2 = offset * ((distance - segment) / distance)
			if i == 0:
				_points[i + 1] = b - correction
			else:
				_points[i] = a + correction * 0.5
				_points[i + 1] = b - correction * 0.5
		for i in range(1, segments + 1):
			if _points[i].y > floor_y:
				_points[i].y = floor_y
	queue_redraw()


func _draw() -> void:
	if not _initialized or texture == null:
		return
	var inverse: Transform2D = get_global_transform().affine_inverse()
	for i in segments:
		var a: Vector2 = _points[i]
		var b: Vector2 = _points[i + 1]
		var t0: float = float(i) / segments
		var t1: float = float(i + 1) / segments
		var side_a: Vector2 = _side(i) * lerpf(top_width, bottom_width, t0) * 0.5
		var side_b: Vector2 = _side(i + 1) * lerpf(top_width, bottom_width, t1) * 0.5
		_polygon[0] = inverse * (a - side_a)
		_polygon[1] = inverse * (a + side_a)
		_polygon[2] = inverse * (b + side_b)
		_polygon[3] = inverse * (b - side_b)
		_uvs[0] = Vector2(0.0, t0)
		_uvs[1] = Vector2(1.0, t0)
		_uvs[2] = Vector2(1.0, t1)
		_uvs[3] = Vector2(0.0, t1)
		draw_primitive(_polygon, _colors, _uvs, texture)


func draw_into(canvas: CanvasItem, transform: Transform2D, tint: Color) -> void:
	if not _initialized or texture == null:
		return
	for i in _mirror_colors.size():
		_mirror_colors[i] = tint
	for i in segments:
		var t0: float = float(i) / segments
		var t1: float = float(i + 1) / segments
		var side_a: Vector2 = _side(i) * lerpf(top_width, bottom_width, t0) * 0.5
		var side_b: Vector2 = _side(i + 1) * lerpf(top_width, bottom_width, t1) * 0.5
		_mirror[0] = transform * (_points[i] - side_a)
		_mirror[1] = transform * (_points[i] + side_a)
		_mirror[2] = transform * (_points[i + 1] + side_b)
		_mirror[3] = transform * (_points[i + 1] - side_b)
		_uvs[0] = Vector2(0.0, t0)
		_uvs[1] = Vector2(1.0, t0)
		_uvs[2] = Vector2(1.0, t1)
		_uvs[3] = Vector2(0.0, t1)
		canvas.draw_primitive(_mirror, _mirror_colors, _uvs, texture)


func _side(index: int) -> Vector2:
	var from: int = maxi(index - 1, 0)
	var to: int = mini(index + 1, segments)
	var direction: Vector2 = (_points[to] - _points[from]).normalized()
	return Vector2(-direction.y, direction.x)
