extends Node2D

enum Kind { VOID, FAR_PILLARS, BEAMS, CATWALKS, PLATFORM }

const VOID_WIDTH: float = 8000.0
const VOID_TOP: float = -3200.0
const VOID_BOTTOM: float = 2400.0
const VOID_BANDS: int = 7
const BEAM_LAYERS: int = 3
const BEAM_STEPS: int = 6
const GRID: float = 2.0
const PLATE: float = 60.0
const BOLT: float = 4.0
const LIGHT_SPACING: float = 240.0
const TRUSS_SPACING: float = 120.0

@export var kind: Kind = Kind.VOID
@export var span: float = 3600.0
@export var base_color: Color = Color("#0d121b")
@export var detail_color: Color = Color("#18202c")
@export var accent_color: Color = Color("#3a5470")
@export var warning_color: Color = Color("#c9822e")
@export var spacing: float = 420.0
@export var height: float = 1600.0
@export var element_width: float = 90.0
@export var level: float = -300.0
@export var arena_width: float = 1200.0
@export var seed_value: int = 3


func _draw() -> void:
	match kind:
		Kind.VOID:
			_draw_void()
		Kind.FAR_PILLARS:
			_draw_pillars()
		Kind.BEAMS:
			_draw_beams()
		Kind.CATWALKS:
			_draw_catwalks()
		Kind.PLATFORM:
			_draw_platform()


func _draw_void() -> void:
	var band: float = (VOID_BOTTOM - VOID_TOP) / VOID_BANDS
	for i in VOID_BANDS:
		var color: Color = base_color.lerp(detail_color, float(i) / (VOID_BANDS - 1))
		draw_rect(Rect2(-VOID_WIDTH, VOID_TOP + band * i, VOID_WIDTH * 2.0, band + GRID), color)


func _draw_pillars() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var x: float = -span
	while x < span:
		var width: float = snappedf(element_width * rng.randf_range(0.7, 1.3), GRID * 4.0)
		var top: float = snappedf(level - height * rng.randf_range(0.7, 1.1), GRID)
		draw_rect(Rect2(x, top, width, VOID_BOTTOM - top), base_color)
		draw_rect(Rect2(x, top, GRID, VOID_BOTTOM - top), detail_color)
		draw_rect(Rect2(x + width * 0.2, top, GRID * 2.0, VOID_BOTTOM - top), detail_color)
		var seam: float = top + 140.0
		while seam < level + 700.0:
			draw_rect(Rect2(x, seam, width, GRID), detail_color)
			seam += 140.0
		var window: float = top + snappedf(rng.randf_range(60.0, 300.0), GRID)
		while window < level + 600.0:
			if rng.randf() < 0.6:
				draw_rect(Rect2(x + width * 0.5, window, GRID * 3.0, GRID * 2.0), accent_color)
			window += snappedf(rng.randf_range(120.0, 260.0), GRID)
		draw_rect(Rect2(x - width * 0.3, top - 30.0, width * 1.6, 30.0), detail_color)
		draw_rect(Rect2(x - width * 0.3, top - 30.0, width * 1.6, GRID), accent_color.darkened(0.5))
		x += spacing * rng.randf_range(0.8, 1.25)


func _draw_beams() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var x: float = -span
	while x < span:
		var width: float = element_width * rng.randf_range(0.6, 1.4)
		for layer in BEAM_LAYERS:
			var spread: float = width * (0.4 + layer * 0.3)
			_draw_beam(x, spread)
		x += spacing * rng.randf_range(0.8, 1.6)


func _draw_beam(x: float, spread: float) -> void:
	var top_y: float = level - height
	var bottom_y: float = level + 400.0
	var step: float = (bottom_y - top_y) / BEAM_STEPS
	for i in BEAM_STEPS:
		var t0: float = float(i) / BEAM_STEPS
		var t1: float = float(i + 1) / BEAM_STEPS
		var w0: float = lerpf(spread * 0.3, spread, t0)
		var w1: float = lerpf(spread * 0.3, spread, t1)
		var y0: float = top_y + step * i
		var slice: PackedVector2Array = [Vector2(x - w0, y0), Vector2(x + w0, y0), Vector2(x + w1, y0 + step), Vector2(x - w1, y0 + step)]
		draw_colored_polygon(slice, Color(accent_color, accent_color.a / BEAM_LAYERS * t1))


func _draw_catwalks() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	for row in 2:
		var y: float = level - row * 260.0
		var x: float = -span
		while x < span:
			var length: float = snappedf(rng.randf_range(500.0, 900.0), GRID)
			draw_rect(Rect2(x, y, length, 14.0), base_color)
			draw_rect(Rect2(x, y, length, GRID), detail_color.lightened(0.15))
			draw_rect(Rect2(x, y - 34.0, length, GRID * 1.5), detail_color)
			var post: float = x
			while post < x + length:
				draw_rect(Rect2(post, y - 34.0, GRID, 34.0), detail_color)
				post += 60.0
			var hanger: float = x + 40.0
			while hanger < x + length:
				draw_rect(Rect2(hanger, y - 900.0, GRID, 900.0), Color(detail_color, 0.6))
				hanger += snappedf(rng.randf_range(260.0, 420.0), GRID)
			x += length + rng.randf_range(260.0, 600.0)


func _draw_platform() -> void:
	var half: float = arena_width * 0.5
	var edge: float = half + 80.0
	_draw_deck(edge)
	_draw_truss(edge)
	for side in [-1.0, 1.0]:
		_draw_wall(half if side > 0.0 else -half - 26.0)


func _draw_deck(edge: float) -> void:
	var plate: float = -edge
	var index: int = 0
	while plate < edge:
		var shade: Color = base_color if index % 2 == 0 else base_color.lightened(0.04)
		draw_rect(Rect2(plate, 0.0, PLATE, 38.0), shade)
		draw_rect(Rect2(plate, 0.0, GRID, 38.0), detail_color)
		for bolt_y in [8.0, 28.0]:
			draw_rect(Rect2(plate + 6.0, bolt_y, BOLT, BOLT), detail_color.lightened(0.1))
		plate += PLATE
		index += 1
	draw_rect(Rect2(-edge, 0.0, edge * 2.0, GRID), accent_color)
	draw_rect(Rect2(-edge, 34.0, edge * 2.0, GRID * 2.0), detail_color.darkened(0.3))
	var light: float = -edge + LIGHT_SPACING * 0.5
	while light < edge:
		draw_rect(Rect2(light - GRID * 2.0, 18.0, GRID * 4.0, GRID * 2.0), warning_color)
		draw_rect(Rect2(light - GRID * 4.0, 16.0, GRID * 8.0, GRID * 4.0), Color(warning_color, 0.18))
		light += LIGHT_SPACING


func _draw_truss(edge: float) -> void:
	var support: float = -edge + 60.0
	while support < edge:
		var strut: PackedVector2Array = [
			Vector2(support - 18.0, 38.0), Vector2(support + 18.0, 38.0),
			Vector2(support + 8.0, 420.0), Vector2(support - 8.0, 420.0),
		]
		draw_colored_polygon(strut, detail_color)
		draw_rect(Rect2(support - 2.0, 38.0, GRID, 382.0), detail_color.lightened(0.08))
		support += 240.0
	var brace: float = -edge
	while brace < edge:
		draw_line(Vector2(brace, 40.0), Vector2(brace + TRUSS_SPACING, 140.0), Color(detail_color, 0.8), GRID)
		draw_line(Vector2(brace + TRUSS_SPACING, 40.0), Vector2(brace, 140.0), Color(detail_color, 0.8), GRID)
		brace += TRUSS_SPACING
	draw_rect(Rect2(-edge, 140.0, edge * 2.0, GRID * 2.0), detail_color)


func _draw_wall(wall_x: float) -> void:
	draw_rect(Rect2(wall_x, -height, 26.0, height), base_color)
	draw_rect(Rect2(wall_x + 10.0, -height, GRID * 3.0, height), detail_color)
	var light_y: float = -120.0
	while light_y > -height:
		draw_rect(Rect2(wall_x + 10.0, light_y, GRID * 3.0, 14.0), accent_color)
		light_y -= 180.0
