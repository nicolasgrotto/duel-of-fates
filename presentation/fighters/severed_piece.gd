class_name SeveredPiece
extends Node2D

const PALETTE: UiPalette = preload("res://ui/palette.tres")
const GRAVITY: float = 2200.0
const LAUNCH_SPEED: Vector2 = Vector2(260.0, -620.0)
const SPIN: float = 11.0
const BOUNCE: float = 0.25
const FLOOR_FRICTION: float = 6.0
const EMBER_COOLING: float = 1.2
const EMBER_RADIUS: float = 3.5
const REST_HEIGHT: float = -3.0

var _velocity: Vector2 = Vector2.ZERO
var _spin: float = 0.0
var _age: float = 0.0
var _ember: Color = Color.ORANGE


func setup(rig: FighterRig, limb: MoveData.Limb, direction: int) -> void:
	global_position = rig.to_global(rig.limb_anchor(limb))
	_velocity = Vector2(LAUNCH_SPEED.x * direction, LAUNCH_SPEED.y)
	_spin = SPIN * direction
	_ember = PALETTE.ember
	var art: FighterArt = rig.art
	var offset: Vector2 = Vector2.ZERO
	for part in rig.severed_parts(limb):
		var sprite: Sprite2D = Sprite2D.new()
		sprite.texture = art.canvas_texture(part)
		sprite.centered = false
		sprite.offset = -art.pivot(part)
		sprite.scale = Vector2.ONE / art.pixels_per_unit * rig.scale
		sprite.material = rig.shader_material
		sprite.position = offset
		add_child(sprite)
		if part == "forearm":
			offset = Vector2(art.dim("forearm"), 0.0) * rig.scale
		elif part == "shin":
			offset = Vector2(art.dim("shin"), 0.0) * rig.scale


func _process(delta: float) -> void:
	_age += delta
	_velocity.y += GRAVITY * delta
	position += _velocity * delta
	rotation += _spin * delta
	if position.y >= REST_HEIGHT:
		position.y = REST_HEIGHT
		_velocity.y = -_velocity.y * BOUNCE
		_velocity.x = move_toward(_velocity.x, 0.0, absf(_velocity.x) * FLOOR_FRICTION * delta + 1.0)
		_spin = move_toward(_spin, 0.0, absf(_spin) * FLOOR_FRICTION * delta + 0.5)
	queue_redraw()


func _draw() -> void:
	var cooled: float = clampf(_age / EMBER_COOLING, 0.0, 1.0)
	draw_circle(Vector2.ZERO, EMBER_RADIUS * (1.0 - cooled * 0.5), Color(_ember, 1.0 - cooled * 0.8))
