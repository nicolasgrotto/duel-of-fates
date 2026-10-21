extends Node2D

enum Kind { VOID, FAR_PILLARS, BEAMS, CATWALKS, PLATFORM }

const VOID_WIDTH: float = 8000.0
const VOID_TOP: float = -3200.0
const VOID_BOTTOM: float = 2400.0
const BEAM_LAYERS: int = 3

@export var kind: Kind = Kind.VOID
@export var span: float = 3600.0
@export var base_color: Color = Color("#0d121b")
@export var detail_color: Color = Color("#18202c")
@export var accent_color: Color = Color("#3a5470")
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
	var rect: PackedVector2Array = [
		Vector2(-VOID_WIDTH, VOID_TOP), Vector2(VOID_WIDTH, VOID_TOP),
		Vector2(VOID_WIDTH, VOID_BOTTOM), Vector2(-VOID_WIDTH, VOID_BOTTOM),
	]
	draw_polygon(rect, PackedColorArray([base_color, base_color, detail_color, detail_color]))


func _draw_pillars() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var x: float = -span
	while x < span:
		var width: float = element_width * rng.randf_range(0.7, 1.3)
		var top: float = level - height * rng.randf_range(0.7, 1.1)
		draw_rect(Rect2(x, top, width, VOID_BOTTOM - top), base_color)
		draw_rect(Rect2(x + width * 0.15, top, width * 0.1, VOID_BOTTOM - top), detail_color)
		var lamp_y: float = top + rng.randf_range(80.0, 400.0)
		while lamp_y < level + 600.0:
			draw_rect(Rect2(x + width * 0.45, lamp_y, 6.0, 3.0), accent_color)
			lamp_y += rng.randf_range(180.0, 320.0)
		draw_rect(Rect2(x - width * 0.3, top - 30.0, width * 1.6, 30.0), detail_color)
		x += spacing * rng.randf_range(0.8, 1.25)


func _draw_beams() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var x: float = -span
	while x < span:
		var width: float = element_width * rng.randf_range(0.6, 1.4)
		for layer in BEAM_LAYERS:
			var spread: float = width * (0.4 + layer * 0.3)
			var beam: PackedVector2Array = [
				Vector2(x - spread * 0.3, level - height), Vector2(x + spread * 0.3, level - height),
				Vector2(x + spread, level + 400.0), Vector2(x - spread, level + 400.0),
			]
			var top: Color = Color(accent_color, 0.0)
			var bottom: Color = Color(accent_color, accent_color.a / BEAM_LAYERS)
			draw_polygon(beam, PackedColorArray([top, top, bottom, bottom]))
		x += spacing * rng.randf_range(0.8, 1.6)


func _draw_catwalks() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	for row in 2:
		var y: float = level - row * 260.0
		var x: float = -span
		while x < span:
			var length: float = rng.randf_range(500.0, 900.0)
			draw_rect(Rect2(x, y, length, 14.0), base_color)
			draw_line(Vector2(x, y - 34.0), Vector2(x + length, y - 34.0), detail_color, 3.0)
			var post: float = x
			while post < x + length:
				draw_line(Vector2(post, y), Vector2(post, y - 34.0), detail_color, 2.0)
				post += 60.0
			var hanger: float = x + 40.0
			while hanger < x + length:
				draw_line(Vector2(hanger, y), Vector2(hanger, y - 900.0), Color(detail_color, 0.6), 2.0)
				hanger += rng.randf_range(260.0, 420.0)
			x += length + rng.randf_range(260.0, 600.0)


func _draw_platform() -> void:
	var half: float = arena_width * 0.5
	var edge: float = half + 80.0
	draw_rect(Rect2(-edge, 0.0, edge * 2.0, 38.0), base_color)
	draw_line(Vector2(-edge, 0.0), Vector2(edge, 0.0), accent_color, 2.0)
	var segment: float = -edge
	while segment <= edge:
		draw_line(Vector2(segment, 2.0), Vector2(segment, 38.0), detail_color, 2.0)
		draw_rect(Rect2(segment + 8.0, 12.0, 6.0, 6.0), detail_color)
		segment += 120.0
	var support: float = -edge + 60.0
	while support < edge:
		var strut: PackedVector2Array = [
			Vector2(support - 18.0, 38.0), Vector2(support + 18.0, 38.0),
			Vector2(support + 8.0, 420.0), Vector2(support - 8.0, 420.0),
		]
		draw_colored_polygon(strut, detail_color)
		draw_line(Vector2(support, 60.0), Vector2(support + 240.0, 300.0), Color(detail_color, 0.7), 4.0)
		support += 240.0
	for side in [-1.0, 1.0]:
		var wall_x: float = half if side > 0.0 else -half - 26.0
		draw_rect(Rect2(wall_x, -height, 26.0, height), base_color)
		draw_rect(Rect2(wall_x + 9.0, -height, 6.0, height), detail_color)
		var light_y: float = -120.0
		while light_y > -height:
			draw_rect(Rect2(wall_x + 10.0, light_y, 6.0, 14.0), accent_color)
			light_y -= 180.0
