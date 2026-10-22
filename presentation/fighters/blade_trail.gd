class_name BladeTrail
extends RefCounted

const MAX_POINTS: int = 24

var bases: PackedVector2Array = []
var tips: PackedVector2Array = []
var times: PackedFloat32Array = []
var _now: float = 0.0
var _duration: float = 0.12
var _quad: PackedVector2Array = [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
var _colors: PackedColorArray = [Color.WHITE]
var _uvs: PackedVector2Array = []


func update(now: float, duration: float, active: bool, base: Vector2, tip: Vector2) -> void:
	_now = now
	_duration = duration
	while not times.is_empty() and now - times[0] > duration:
		bases.remove_at(0)
		tips.remove_at(0)
		times.remove_at(0)
	if active:
		bases.append(base)
		tips.append(tip)
		times.append(now)
		if times.size() > MAX_POINTS:
			bases.remove_at(0)
			tips.remove_at(0)
			times.remove_at(0)


func draw_on(canvas: CanvasItem, color: Color, alpha: float, steps: int) -> void:
	for i in times.size() - 1:
		var age: float = ceilf((1.0 - (_now - times[i]) / _duration) * steps) / steps
		_quad[0] = bases[i]
		_quad[1] = tips[i]
		_quad[2] = tips[i + 1]
		_quad[3] = bases[i + 1]
		_colors[0] = Color(color, alpha * clampf(age, 0.0, 1.0))
		canvas.draw_primitive(_quad, _colors, _uvs)
