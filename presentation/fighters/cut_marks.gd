class_name CutMarks
extends Node2D

const PALETTE: UiPalette = preload("res://ui/palette.tres")
const GRID: float = 2.0
const FADE_STEPS: float = 3.0
const COOLING: float = 1.6
const CAP_HALF: float = 4.0
const SMOKE_POOL: int = 16
const SMOKE_INTERVAL: float = 0.22
const SMOKE_DURATION: float = 3.0
const SMOKE_LIFE: float = 1.1
const SMOKE_RISE: float = 34.0
const DRIP_TIME: float = 0.7
const WOUND_HALF: float = 6.0
const WOUND_PULSE: float = 3.0
const WOUND_EMBER_INTERVAL: float = 0.45

var cuts: Array[PackedVector2Array] = []
var wound: PackedVector2Array = []

var _cut_age: float = -1.0
var _wound_age: float = 0.0
var _smoke_clock: float = 0.0
var _smoke_at: PackedVector2Array = []
var _smoke_age: PackedFloat32Array = []
var _smoke_kind: PackedInt32Array = []
var _next: int = 0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _init() -> void:
	_smoke_at.resize(SMOKE_POOL)
	_smoke_age.resize(SMOKE_POOL)
	_smoke_age.fill(INF)
	_smoke_kind.resize(SMOKE_POOL)


func start_cut() -> void:
	_cut_age = 0.0


func clear() -> void:
	_cut_age = -1.0
	cuts.clear()
	_smoke_age.fill(INF)


func advance(delta: float) -> void:
	_wound_age += delta
	for i in SMOKE_POOL:
		_smoke_age[i] += delta
	if _cut_age >= 0.0:
		_cut_age += delta
		_smoke_clock += delta
		if _cut_age < SMOKE_DURATION and _smoke_clock >= SMOKE_INTERVAL:
			_smoke_clock = 0.0
			for cut in cuts:
				_puff(cut[0], 0)
	elif wound.size() == 2:
		_smoke_clock += delta
		if _smoke_clock >= WOUND_EMBER_INTERVAL:
			_smoke_clock = 0.0
			_puff(wound[0].lerp(wound[1], _rng.randf()), 1)
	queue_redraw()


func _puff(at: Vector2, kind: int) -> void:
	_smoke_at[_next] = at + Vector2(_rng.randf_range(-2.0, 2.0), 0.0)
	_smoke_age[_next] = 0.0
	_smoke_kind[_next] = kind
	_next = (_next + 1) % SMOKE_POOL


func _draw() -> void:
	if _cut_age >= 0.0:
		for cut in cuts:
			_draw_cap(cut[0], cut[1])
	if wound.size() == 2:
		_draw_wound(wound[0], wound[1])
	for i in SMOKE_POOL:
		if _smoke_age[i] >= SMOKE_LIFE:
			continue
		var progress: float = _smoke_age[i] / SMOKE_LIFE
		var strength: float = ceilf((1.0 - progress) * FADE_STEPS) / FADE_STEPS
		var at: Vector2 = _smoke_at[i] + Vector2(sin(progress * 6.0 + i) * 3.0, -SMOKE_RISE * progress)
		if _smoke_kind[i] == 0:
			draw_rect(Rect2(at.snapped(Vector2(GRID, GRID)) - Vector2.ONE * GRID, Vector2.ONE * GRID * (2.0 + progress * 2.0)), Color(PALETTE.smoke, 0.5 * strength))
		else:
			draw_rect(Rect2(at.snapped(Vector2(GRID, GRID)), Vector2.ONE * GRID), Color(PALETTE.ember, strength))


func _draw_cap(at: Vector2, direction: Vector2) -> void:
	var cooled: float = clampf(_cut_age / COOLING, 0.0, 1.0)
	var side: Vector2 = direction.orthogonal().normalized() * CAP_HALF
	var outer: Color = PALETTE.ember.lerp(PALETTE.scar, cooled)
	draw_line(at - side, at + side, outer, GRID * 2.0)
	if cooled < 1.0:
		draw_line(at - side * 0.5, at + side * 0.5, Color(PALETTE.ember_hot, 1.0 - cooled), GRID)
	if _cut_age < DRIP_TIME and int(_cut_age * 20.0) % 2 == 0:
		var drop: Vector2 = at + Vector2(_rng.randf_range(-CAP_HALF, CAP_HALF), _cut_age * 40.0)
		draw_rect(Rect2(drop.snapped(Vector2(GRID, GRID)), Vector2.ONE * GRID), PALETTE.ember_hot)


func _draw_wound(from: Vector2, to: Vector2) -> void:
	var middle: Vector2 = from.lerp(to, 0.5)
	var along: Vector2 = (to - from).normalized()
	var slash: Vector2 = (along.orthogonal() + along * 0.6).normalized() * WOUND_HALF
	var pulse: float = 0.6 + 0.4 * sin(_wound_age * WOUND_PULSE)
	draw_line(middle - slash, middle + slash, PALETTE.wound_edge, GRID * 2.0)
	draw_line(middle - slash * 0.8, middle + slash * 0.8, Color(PALETTE.ember, pulse), GRID)
	draw_rect(Rect2((middle - Vector2.ONE).snapped(Vector2(GRID, GRID)), Vector2.ONE * GRID), Color(PALETTE.ember_hot, pulse))
