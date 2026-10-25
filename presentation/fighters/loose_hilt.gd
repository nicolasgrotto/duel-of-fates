class_name LooseHilt
extends Node2D

const PALETTE: UiPalette = preload("res://ui/palette.tres")
const GRID: float = 2.0
const FADE_STEPS: float = 3.0
const GRAVITY: float = 2200.0
const BOUNCE: float = 0.3
const FLOOR_FRICTION: float = 6.0
const REST_HEIGHT: float = -2.0
const HILT_WIDTH: float = 4.5
const GRIP_WIDTH: float = 5.2
const GRIP_FROM: float = 0.2
const GRIP_TO: float = 0.7
const LIFT_SHARE: float = 0.35
const LIFT_HEIGHT: float = 26.0
const TREMBLE: float = 1.5
const ARC_HEIGHT: float = 70.0
const SPIN_TURNS: float = 2.0
const RING_COUNT: int = 2
const RING_RADIUS: float = 9.0
const RING_SPREAD: float = 7.0
const RING_PULSE: float = 9.0
const ORB_RADIUS: float = 16.0

var length: float = 12.0
var metal: Color = Color.GRAY
var grip: Color = Color.DIM_GRAY
var caught: bool = false

var _velocity: Vector2 = Vector2.ZERO
var _spin: float = 0.0
var _pulling: bool = false
var _pull_time: float = 0.0
var _pull_duration: float = 1.0
var _pull_start: Vector2 = Vector2.ZERO
var _start_rotation: float = 0.0
var _target: Callable


func setup(hilt_length: float, colors: PackedColorArray) -> void:
	length = hilt_length
	metal = colors[0]
	grip = colors[1]
	z_index = FighterRig.BODY_DEPTH + 18


func drop(segment: PackedVector2Array, velocity: Vector2) -> void:
	global_position = segment[0].lerp(segment[1], 0.5)
	rotation = (segment[1] - segment[0]).angle()
	_velocity = velocity
	_spin = signf(velocity.x) * 6.0 if velocity.x != 0.0 else 6.0
	_pulling = false
	caught = false
	visible = true


func pull(target: Callable, duration: float) -> void:
	_target = target
	_pull_duration = maxf(duration, 0.01)
	_pull_time = 0.0
	_pull_start = global_position
	_start_rotation = rotation
	_pulling = true


func pulling() -> bool:
	return _pulling


func _process(delta: float) -> void:
	if _pulling:
		_fly(delta)
	elif not caught:
		_fall(delta)
	queue_redraw()


func _fall(delta: float) -> void:
	_velocity.y += GRAVITY * delta
	position += _velocity * delta
	rotation += _spin * delta
	if position.y >= REST_HEIGHT:
		position.y = REST_HEIGHT
		_velocity.y = -_velocity.y * BOUNCE
		_velocity.x = move_toward(_velocity.x, 0.0, absf(_velocity.x) * FLOOR_FRICTION * delta + 1.0)
		_spin = move_toward(_spin, 0.0, absf(_spin) * FLOOR_FRICTION * delta + 0.5)
		rotation = lerp_angle(rotation, 0.0, minf(FLOOR_FRICTION * delta, 1.0))


func _fly(delta: float) -> void:
	_pull_time += delta
	var progress: float = clampf(_pull_time / _pull_duration, 0.0, 1.0)
	var lifted: Vector2 = _pull_start + Vector2(0.0, -LIFT_HEIGHT)
	if progress < LIFT_SHARE:
		var rise: float = smoothstep(0.0, 1.0, progress / LIFT_SHARE)
		global_position = _pull_start.lerp(lifted, rise) + Vector2(randf_range(-TREMBLE, TREMBLE), 0.0)
		rotation = lerp_angle(_start_rotation, -PI * 0.5, rise)
		return
	var flight: float = (progress - LIFT_SHARE) / (1.0 - LIFT_SHARE)
	var eased: float = flight * flight * (3.0 - 2.0 * flight)
	var target: Vector2 = _target.call()
	var control: Vector2 = lifted.lerp(target, 0.5) + Vector2(0.0, -ARC_HEIGHT)
	global_position = lifted.lerp(control, eased).lerp(control.lerp(target, eased), eased)
	rotation = -PI * 0.5 + TAU * SPIN_TURNS * eased
	if progress >= 1.0:
		_pulling = false
		caught = true
		visible = false


func _draw() -> void:
	var half: Vector2 = Vector2(length * 0.5, 0.0)
	draw_line(-half, half, metal, HILT_WIDTH)
	draw_line((-half).lerp(half, GRIP_FROM), (-half).lerp(half, GRIP_TO), grip, GRIP_WIDTH)
	if not _pulling:
		return
	var glow: Color = PALETTE.flow_tiers[0]
	for i in RING_COUNT:
		var phase: float = fposmod(_pull_time * RING_PULSE / TAU + float(i) / RING_COUNT, 1.0)
		var strength: float = ceilf((1.0 - phase) * FADE_STEPS) / FADE_STEPS
		draw_arc(Vector2.ZERO, RING_RADIUS + RING_SPREAD * phase, 0.0, TAU, 16, Color(glow, 0.7 * strength), GRID)
	var shrink: float = 1.0 - clampf(_pull_time / _pull_duration, 0.0, 1.0)
	draw_set_transform_matrix(get_global_transform().affine_inverse())
	var palm: Vector2 = _target.call()
	draw_circle(palm, ORB_RADIUS * shrink, Color(glow, 0.25 * ceilf(shrink * FADE_STEPS) / FADE_STEPS))
	draw_arc(palm, ORB_RADIUS * shrink, 0.0, TAU, 20, Color(glow, 0.8), GRID)
	draw_circle(palm, ORB_RADIUS * shrink * 0.3, PALETTE.spark_hot)
	draw_set_transform_matrix(Transform2D.IDENTITY)
