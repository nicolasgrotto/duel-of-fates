class_name InfiltrationBlade
extends RefCounted

const LANCE_HILT_RATIO: float = 3.0
const STAFF_HILT_RATIO: float = 2.0

var hand: Vector2 = Vector2.ZERO
var direction: Vector2 = Vector2.RIGHT
var off_hand: Vector2 = Vector2.ZERO
var off_direction: Vector2 = Vector2.RIGHT


func compose(config: InfiltrationConfig, facing: Vector2, guard_blend: float, swing_blend: float, swing_degrees: float) -> void:
	var side: Vector2 = facing.rotated(PI * 0.5)
	var rest_forward: float = lerpf(config.blade_hand_forward, config.guard_hand_forward, guard_blend)
	var rest_side: float = lerpf(config.blade_hand_side, config.guard_hand_side, guard_blend)
	var rest_degrees: float = lerpf(config.blade_rest_degrees, config.guard_blade_degrees, guard_blend)
	var swing_radians: float = deg_to_rad(swing_degrees)
	var forward_offset: float = lerpf(rest_forward, cos(swing_radians) * config.blade_grip, swing_blend)
	var side_offset: float = lerpf(rest_side, sin(swing_radians) * config.blade_grip, swing_blend)
	hand = facing * forward_offset + side * side_offset
	direction = facing.rotated(deg_to_rad(lerpf(rest_degrees, swing_degrees, swing_blend)))
	off_hand = facing * rest_forward - side * rest_side
	off_direction = facing.rotated(deg_to_rad(-rest_degrees))


func draw(canvas: CanvasItem, origin: Vector2, look: InfiltrationLook, config: InfiltrationConfig) -> void:
	var hilt_tail_ratio: float = 1.0
	if look.kind == WeaponData.Kind.LANCE:
		hilt_tail_ratio = LANCE_HILT_RATIO
	elif look.kind == WeaponData.Kind.STAFF:
		hilt_tail_ratio = STAFF_HILT_RATIO
	var grip: Vector2 = origin + hand
	var tail: Vector2 = grip - direction * config.blade_hilt_half * hilt_tail_ratio
	var emitter: Vector2 = grip + direction * config.blade_hilt_half
	var blade_length: float = config.blade_length - config.blade_hilt_half
	_draw_beam(canvas, emitter, emitter + direction * blade_length, look.blade_color, config)
	if look.kind == WeaponData.Kind.STAFF:
		_draw_beam(canvas, tail, tail - direction * blade_length * look.second_blade_ratio, look.blade_color, config)
	_draw_hilt(canvas, tail, emitter, look, config)
	_draw_hand(canvas, grip, look, config)
	if look.kind == WeaponData.Kind.DUAL:
		var off_grip: Vector2 = origin + off_hand
		var off_emitter: Vector2 = off_grip + off_direction * config.blade_hilt_half
		_draw_beam(canvas, off_emitter, off_emitter + off_direction * blade_length * look.second_blade_ratio, look.blade_color, config)
		_draw_hilt(canvas, off_grip - off_direction * config.blade_hilt_half, off_emitter, look, config)
		_draw_hand(canvas, off_grip, look, config)


func tip(config: InfiltrationConfig) -> Vector2:
	return hand + direction * config.blade_length


func _draw_beam(canvas: CanvasItem, start: Vector2, end: Vector2, color: Color, config: InfiltrationConfig) -> void:
	var from: Vector2 = _snap(start, config)
	var to: Vector2 = _snap(end, config)
	canvas.draw_line(from, to, Color(color, 0.08), config.blade_width * 4.0)
	canvas.draw_line(from, to, Color(color, 0.25), config.blade_width * 2.0)
	canvas.draw_line(from, to, color, config.blade_width)
	canvas.draw_line(from, to, Color.WHITE, config.units_per_pixel)


func _draw_hilt(canvas: CanvasItem, tail: Vector2, emitter: Vector2, look: InfiltrationLook, config: InfiltrationConfig) -> void:
	canvas.draw_line(_snap(tail, config), _snap(emitter, config), look.hilt_color, config.blade_width)


func _draw_hand(canvas: CanvasItem, grip: Vector2, look: InfiltrationLook, config: InfiltrationConfig) -> void:
	var size: Vector2 = Vector2.ONE * config.blade_hand_size
	canvas.draw_rect(Rect2(_snap(grip - size * 0.5, config), size), look.skin_color)


func _snap(point: Vector2, config: InfiltrationConfig) -> Vector2:
	return (point / config.units_per_pixel).round() * config.units_per_pixel
