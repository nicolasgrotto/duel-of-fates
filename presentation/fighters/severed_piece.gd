class_name SeveredPiece
extends Node2D

const PALETTE: UiPalette = preload("res://ui/palette.tres")
const GRAVITY: float = 2200.0
const LAUNCH_SPEED: Vector2 = Vector2(260.0, -620.0)
const SPIN: float = 11.0
const BOUNCE: float = 0.25
const FLOOR_FRICTION: float = 6.0
const EMBER_COOLING: float = 1.2
const LIMB_LENGTH: float = 34.0
const LIMB_WIDTH: float = 9.0
const HEAD_RADIUS: float = 12.0

var _limb: MoveData.Limb = MoveData.Limb.ARM
var _look: CharacterData
var _velocity: Vector2 = Vector2.ZERO
var _spin: float = 0.0
var _age: float = 0.0


func setup(limb: MoveData.Limb, look: CharacterData, start: Vector2, direction: int) -> void:
	_limb = limb
	_look = look
	global_position = start
	_velocity = Vector2(LAUNCH_SPEED.x * direction, LAUNCH_SPEED.y)
	_spin = SPIN * direction


func _process(delta: float) -> void:
	_age += delta
	_velocity.y += GRAVITY * delta
	position += _velocity * delta
	rotation += _spin * delta
	if position.y >= 0.0:
		position.y = 0.0
		_velocity.y = -_velocity.y * BOUNCE
		_velocity.x = move_toward(_velocity.x, 0.0, absf(_velocity.x) * FLOOR_FRICTION * delta + 1.0)
		_spin = move_toward(_spin, 0.0, absf(_spin) * FLOOR_FRICTION * delta + 0.5)
	queue_redraw()


func _draw() -> void:
	var ember: Color = PALETTE.ember.lerp(_look.body_color, clampf(_age / EMBER_COOLING, 0.0, 1.0))
	if _limb == MoveData.Limb.HEAD:
		var cover: Color = _look.cloak_color if _look.hood_up else _look.hair_color
		draw_circle(Vector2.ZERO, HEAD_RADIUS, cover)
		draw_circle(Vector2(0.0, HEAD_RADIUS * 0.8), 4.0, ember)
		return
	var color: Color = _look.body_color
	draw_line(Vector2(-LIMB_LENGTH * 0.5, 0.0), Vector2(LIMB_LENGTH * 0.5, 0.0), color, LIMB_WIDTH)
	draw_circle(Vector2(-LIMB_LENGTH * 0.5, 0.0), LIMB_WIDTH * 0.5, ember)
	if _limb == MoveData.Limb.ARM:
		draw_line(Vector2(LIMB_LENGTH * 0.5, 0.0), Vector2(LIMB_LENGTH * 0.5 + 12.0, 0.0), _look.hilt_color, 5.0)
