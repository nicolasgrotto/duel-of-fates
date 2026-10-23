class_name SeveredPiece
extends Node2D

const PALETTE: UiPalette = preload("res://ui/palette.tres")
const GRID: float = 2.0
const GRAVITY: float = 2200.0
const LAUNCH_SPEED: Vector2 = Vector2(260.0, -620.0)
const HEAD_LAUNCH_SPEED: Vector2 = Vector2(200.0, -720.0)
const SPIN: float = 11.0
const BOUNCE: float = 0.25
const FLOOR_FRICTION: float = 6.0
const HEAD_ROLL_FRICTION: float = 1.6
const HEAD_RADIUS: float = 10.0
const EMBER_COOLING: float = 1.4
const EMBER_RADIUS: float = 3.5
const REST_HEIGHT: float = -3.0
const TRAIL_POINTS: int = 10
const TRAIL_SPACING: float = 0.03
const SMOKE_PUFFS: int = 6
const SMOKE_LIFE: float = 1.2
const SMOKE_RISE: float = 30.0

var _velocity: Vector2 = Vector2.ZERO
var _spin: float = 0.0
var _age: float = 0.0
var _rolls: bool = false
var _landed_at: float = -1.0
var _trail: PackedVector2Array = []
var _trail_clock: float = 0.0
var _smoke: PackedVector2Array = []
var _smoke_start: PackedFloat32Array = []


func setup(rig: FighterRig, limb: MoveData.Limb, direction: int, front: bool = true) -> void:
	global_position = rig.to_global(rig.limb_anchor(limb, front))
	_rolls = limb == MoveData.Limb.HEAD
	var launch: Vector2 = HEAD_LAUNCH_SPEED if _rolls else LAUNCH_SPEED
	_velocity = Vector2(launch.x * direction, launch.y)
	_spin = SPIN * direction
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
		if not front:
			sprite.self_modulate = FighterRig.BACK_SHADE
		add_child(sprite)
		if part == "forearm":
			offset = Vector2(art.dim("forearm"), 0.0) * rig.scale
		elif part == "shin":
			offset = Vector2(art.dim("shin"), 0.0) * rig.scale
	_trail.resize(TRAIL_POINTS)
	_trail.fill(global_position)
	_smoke.resize(SMOKE_PUFFS)
	_smoke_start.resize(SMOKE_PUFFS)
	_smoke_start.fill(-1.0)


func _process(delta: float) -> void:
	_age += delta
	_velocity.y += GRAVITY * delta
	position += _velocity * delta
	if position.y >= REST_HEIGHT:
		position.y = REST_HEIGHT
		if _landed_at < 0.0:
			_land()
		_velocity.y = -_velocity.y * BOUNCE
		if _rolls:
			_velocity.x = move_toward(_velocity.x, 0.0, absf(_velocity.x) * HEAD_ROLL_FRICTION * delta + 0.5)
			_spin = _velocity.x / HEAD_RADIUS
		else:
			_velocity.x = move_toward(_velocity.x, 0.0, absf(_velocity.x) * FLOOR_FRICTION * delta + 1.0)
			_spin = move_toward(_spin, 0.0, absf(_spin) * FLOOR_FRICTION * delta + 0.5)
	rotation += _spin * delta
	_trail_clock += delta
	if _trail_clock >= TRAIL_SPACING:
		_trail_clock = 0.0
		for i in range(TRAIL_POINTS - 1, 0, -1):
			_trail[i] = _trail[i - 1]
		_trail[0] = global_position
	queue_redraw()


func _land() -> void:
	_landed_at = _age
	for i in SMOKE_PUFFS:
		_smoke[i] = global_position + Vector2(randf_range(-8.0, 8.0), 0.0)
		_smoke_start[i] = _age + i * 0.12


func _draw() -> void:
	var cooled: float = clampf(_age / EMBER_COOLING, 0.0, 1.0)
	if _landed_at < 0.0:
		for i in range(1, TRAIL_POINTS):
			var fade: float = 1.0 - float(i) / TRAIL_POINTS
			var at: Vector2 = to_local(_trail[i]).snapped(Vector2(GRID, GRID))
			draw_rect(Rect2(at, Vector2.ONE * GRID), Color(PALETTE.ember if i % 2 == 0 else PALETTE.ember_hot, fade * (1.0 - cooled)))
	draw_circle(Vector2.ZERO, EMBER_RADIUS * (1.0 - cooled * 0.4), PALETTE.ember.lerp(PALETTE.scar, cooled))
	if cooled < 1.0:
		draw_rect(Rect2(Vector2(-GRID, -GRID) * 0.5, Vector2.ONE * GRID), Color(PALETTE.ember_hot, 1.0 - cooled))
	for i in SMOKE_PUFFS:
		if _smoke_start[i] < 0.0 or _age < _smoke_start[i]:
			continue
		var progress: float = (_age - _smoke_start[i]) / SMOKE_LIFE
		if progress >= 1.0:
			continue
		var at: Vector2 = to_local(_smoke[i] + Vector2(sin(progress * 5.0 + i) * 3.0, -SMOKE_RISE * progress)).snapped(Vector2(GRID, GRID))
		draw_rect(Rect2(at, Vector2.ONE * GRID * (2.0 + progress * 2.0)), Color(PALETTE.smoke, 0.45 * (1.0 - progress)))
