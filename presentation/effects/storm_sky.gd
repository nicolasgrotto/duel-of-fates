class_name StormSky
extends Node2D

const PALETTE: UiPalette = preload("res://ui/palette.tres")
const GRID: float = 2.0
const FADE_STEPS: float = 3.0
const BOLT_SEGMENTS: int = 10
const BOLT_JITTER: float = 26.0
const MAX_BOLTS: int = 4
const CLOUD_PUFFS: int = 16

signal flashed(strength: float)

var config: PowerVfxConfig
var intensity: float = 0.0
var color: Color = Color.WHITE
var focus_x: float = 0.0
var view_width: float = 900.0

var _time: float = 0.0
var _clock: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _bolts: Array[PackedVector2Array] = []
var _branches: Array[PackedVector2Array] = []
var _ages: PackedFloat32Array = []


func _ready() -> void:
	light_mask = 0
	for i in MAX_BOLTS:
		var bolt: PackedVector2Array = []
		bolt.resize(BOLT_SEGMENTS + 1)
		_bolts.append(bolt)
		var branch: PackedVector2Array = []
		branch.resize(4)
		_branches.append(branch)
	_ages.resize(MAX_BOLTS)
	_ages.fill(INF)


func _process(delta: float) -> void:
	if config == null:
		return
	_time += delta
	for i in MAX_BOLTS:
		_ages[i] += delta
	if intensity > 0.6:
		_clock += delta
		if _clock >= config.sky_bolt_interval:
			_clock = _rng.randf_range(-0.25, 0.1) * config.sky_bolt_interval
			_strike()
	queue_redraw()


func _strike() -> void:
	var slot: int = 0
	for i in MAX_BOLTS:
		if _ages[i] > _ages[slot]:
			slot = i
	var x: float = focus_x + _rng.randf_range(-0.5, 0.5) * view_width
	var top: Vector2 = Vector2(x, config.sky_top * 0.6)
	var bottom: Vector2 = Vector2(x + _rng.randf_range(-120.0, 120.0), config.sky_horizon + _rng.randf_range(-60.0, 40.0))
	var bolt: PackedVector2Array = _bolts[slot]
	for i in BOLT_SEGMENTS + 1:
		var t: float = float(i) / BOLT_SEGMENTS
		var jitter: float = _rng.randf_range(-BOLT_JITTER, BOLT_JITTER) if i > 0 and i < BOLT_SEGMENTS else 0.0
		bolt[i] = (top.lerp(bottom, t) + Vector2(jitter, 0.0)).snapped(Vector2(GRID, GRID))
	var branch: PackedVector2Array = _branches[slot]
	var root: int = _rng.randi_range(2, BOLT_SEGMENTS - 4)
	branch[0] = bolt[root]
	var lean: float = signf(_rng.randf() - 0.5) * 50.0
	for i in range(1, 4):
		branch[i] = (branch[i - 1] + Vector2(lean + _rng.randf_range(-12.0, 12.0), 46.0)).snapped(Vector2(GRID, GRID))
	_ages[slot] = 0.0
	flashed.emit(config.sky_flash)


func _draw() -> void:
	if config == null or intensity <= 0.0:
		return
	_draw_clouds()
	for i in MAX_BOLTS:
		if _ages[i] >= config.sky_bolt_life:
			continue
		var strength: float = ceilf((1.0 - _ages[i] / config.sky_bolt_life) * FADE_STEPS) / FADE_STEPS * intensity
		draw_polyline(_bolts[i], Color(color, 0.45 * strength), GRID * 4.0)
		draw_polyline(_bolts[i], Color(Color.WHITE, strength), GRID * 2.0)
		draw_polyline(_branches[i], Color(color, 0.6 * strength), GRID)


func _draw_clouds() -> void:
	var lit: float = 0.0
	for i in MAX_BOLTS:
		if _ages[i] < config.sky_bolt_life * 2.0:
			lit = maxf(lit, 1.0 - _ages[i] / (config.sky_bolt_life * 2.0))
	var span: float = view_width * 2.8
	var band: float = (config.sky_horizon - config.sky_top) / config.sky_clouds
	var left: float = snappedf(focus_x - span * 0.5, GRID)
	for row in config.sky_clouds:
		var depth: float = float(row) / maxf(config.sky_clouds - 1, 1)
		var y: float = config.sky_top + band * row
		var drift: float = _time * (10.0 + row * 5.0) * (1.0 if row % 2 == 0 else -1.0)
		var shade: Color = PALETTE.storm_cloud.lerp(color, 0.08 + 0.4 * lit * (1.0 - depth * 0.5))
		var alpha: float = (0.9 - 0.45 * depth) * intensity
		draw_rect(Rect2(left, y, span, band * 0.7), Color(shade, alpha))
		for puff in CLOUD_PUFFS:
			var x: float = left + fposmod(puff * span / CLOUD_PUFFS + drift + row * 131.0, span)
			var bump: float = snappedf(band * (0.28 + 0.18 * sin(puff * 2.3 + row * 1.1)), GRID)
			draw_rect(Rect2(Vector2(x, y + band * 0.7), Vector2(snappedf(span / CLOUD_PUFFS * 0.7, GRID), bump)).abs(), Color(shade, alpha))
			draw_rect(Rect2(Vector2(x + GRID * 4.0, y + band * 0.7 + bump), Vector2(snappedf(span / CLOUD_PUFFS * 0.35, GRID), GRID * 3.0)), Color(shade.lightened(0.15 * lit), alpha * 0.8))
