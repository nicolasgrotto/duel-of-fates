class_name SceneryLayer
extends Node2D

enum Kind { SKY, DISC, RIDGE, TOWERS, COLUMNS, TRUNKS, CRYSTALS, CEILING, CLOUDS, SHIP, MONASTERY, BRUTALIST, RING, FLOOR, MIRAGE }
enum Disc { MOON, SUN, PLANET, ECLIPSE }
enum Floor { STONE, WATER, ROOF, METAL, MOSS, SALT, DECK, SNOW, POLISHED }

const GRID: float = 2.0
const SKY_TOP: float = -2400.0
const SKY_BOTTOM: float = 900.0
const FLOOR_DEPTH: float = 900.0
const STAR_COUNT: int = 140

@export var kind: Kind = Kind.SKY
@export var base_color: Color = Color("#0b0f18")
@export var detail_color: Color = Color("#141a26")
@export var accent_color: Color = Color("#3a5470")
@export var span: float = 3600.0
@export var level: float = 0.0
@export var height: float = 600.0
@export var spacing: float = 300.0
@export var element_width: float = 80.0
@export var bands: int = 7
@export var radius: float = 160.0
@export var disc: Disc = Disc.MOON
@export var floor_style: Floor = Floor.STONE
@export var arena_width: float = 1200.0
@export var stars: bool = false
@export var drift: float = 0.0
@export var lit_by_blades: bool = true
@export var seed_value: int = 3

var _offset: float = 0.0
var _time: float = 0.0


func _ready() -> void:
	if not lit_by_blades:
		light_mask = 0
	set_process(drift != 0.0 or kind == Kind.MIRAGE)


func _process(delta: float) -> void:
	_offset = fposmod(_offset + drift * delta, spacing * 4.0)
	_time += delta
	queue_redraw()


func _draw() -> void:
	match kind:
		Kind.SKY:
			_draw_sky()
		Kind.DISC:
			_draw_disc()
		Kind.RIDGE:
			_draw_ridge()
		Kind.TOWERS:
			_draw_towers()
		Kind.COLUMNS:
			_draw_columns()
		Kind.TRUNKS:
			_draw_trunks()
		Kind.CRYSTALS:
			_draw_crystals()
		Kind.CEILING:
			_draw_ceiling()
		Kind.CLOUDS:
			_draw_clouds()
		Kind.SHIP:
			_draw_ship()
		Kind.MONASTERY:
			_draw_monastery()
		Kind.BRUTALIST:
			_draw_brutalist()
		Kind.RING:
			_draw_ring()
		Kind.FLOOR:
			_draw_floor()
		Kind.MIRAGE:
			_draw_mirage()


func _rng() -> RandomNumberGenerator:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func _snap(value: float) -> float:
	return snappedf(value, GRID)


func _draw_sky() -> void:
	var top: float = level - height
	var band: float = _snap(height / maxf(bands, 1))
	draw_rect(Rect2(-span, SKY_TOP, span * 2.0, top - SKY_TOP), base_color)
	for i in bands:
		var color: Color = base_color.lerp(detail_color, float(i + 1) / bands)
		draw_rect(Rect2(-span, top + band * i, span * 2.0, band + GRID), color)
	draw_rect(Rect2(-span, top + band * bands, span * 2.0, SKY_BOTTOM - top - band * bands), detail_color)
	if stars:
		var rng: RandomNumberGenerator = _rng()
		for i in STAR_COUNT:
			var at: Vector2 = Vector2(_snap(rng.randf_range(-span, span)), _snap(rng.randf_range(SKY_TOP * 0.5, top + band * 2.0)))
			var bright: float = rng.randf_range(0.3, 1.0)
			draw_rect(Rect2(at, Vector2.ONE * GRID), Color(accent_color, bright))


func _draw_disc() -> void:
	var center: Vector2 = Vector2(0.0, level)
	match disc:
		Disc.MOON:
			draw_circle(center, radius * 1.35, Color(base_color, 0.08))
			draw_circle(center, radius, base_color)
			var rng: RandomNumberGenerator = _rng()
			for i in 6:
				var spot: Vector2 = center + Vector2(rng.randf_range(-0.6, 0.6), rng.randf_range(-0.6, 0.6)) * radius
				draw_circle(spot, radius * rng.randf_range(0.08, 0.2), detail_color)
		Disc.SUN:
			for i in 3:
				draw_circle(center, radius * (1.0 + 0.25 * (3 - i)), Color(base_color, 0.08 * (i + 1)))
			draw_circle(center, radius, base_color)
			draw_rect(Rect2(center.x - radius * 2.0, center.y + radius * 0.35, radius * 4.0, radius * 2.0), detail_color)
		Disc.PLANET:
			draw_circle(center, radius + GRID * 6.0, Color(accent_color, 0.35))
			draw_circle(center, radius + GRID * 2.0, accent_color)
			draw_circle(center, radius, base_color)
			draw_circle(center + Vector2(radius * 0.35, 0.0), radius * 0.92, detail_color)
		Disc.ECLIPSE:
			for i in 4:
				draw_circle(center, radius * (1.0 + 0.12 * (4 - i)), Color(accent_color, 0.08 * (i + 1)))
			draw_arc(center, radius + GRID * 2.0, 0.0, TAU, 64, accent_color, GRID * 2.0)
			draw_circle(center, radius, base_color)
			draw_arc(center, radius * 1.6, -0.4, 0.4 + PI, 64, Color(accent_color, 0.5), GRID)


func _draw_ridge() -> void:
	var rng: RandomNumberGenerator = _rng()
	var points: PackedVector2Array = [Vector2(-span, SKY_BOTTOM)]
	var x: float = -span
	while x <= span:
		points.append(Vector2(_snap(x), _snap(level - height * rng.randf_range(0.35, 1.0))))
		x += spacing * rng.randf_range(0.5, 1.2)
	points.append(Vector2(span, SKY_BOTTOM))
	draw_colored_polygon(points, base_color)
	for i in range(1, points.size() - 1):
		var peak: Vector2 = points[i]
		if peak.y < level - height * 0.7:
			var cap: PackedVector2Array = [peak, peak + Vector2(spacing * 0.18, height * 0.16), peak + Vector2(-spacing * 0.18, height * 0.16)]
			draw_colored_polygon(cap, detail_color)


func _draw_towers() -> void:
	var rng: RandomNumberGenerator = _rng()
	var x: float = -span
	while x < span:
		var width: float = _snap(element_width * rng.randf_range(0.6, 1.6))
		var top: float = _snap(level - height * rng.randf_range(0.4, 1.0))
		draw_rect(Rect2(x, top, width, SKY_BOTTOM - top), base_color)
		var row: float = top + GRID * 8.0
		while row < level + 200.0:
			var column: float = x + GRID * 4.0
			while column < x + width - GRID * 4.0:
				if rng.randf() < 0.12:
					draw_rect(Rect2(column, row, GRID * 2.0, GRID * 3.0), detail_color)
				column += GRID * 6.0
			row += GRID * 10.0
		if rng.randf() < 0.45:
			_draw_glyph_sign(Vector2(x + width * 0.5, top + rng.randf_range(40.0, 160.0)), rng)
		x += width + _snap(spacing * rng.randf_range(0.1, 0.5))


func _draw_glyph_sign(at: Vector2, rng: RandomNumberGenerator) -> void:
	var glyphs: int = rng.randi_range(2, 4)
	var start: Vector2 = Vector2(_snap(at.x - glyphs * GRID * 5.0), _snap(at.y))
	draw_rect(Rect2(start - Vector2(GRID * 2.0, GRID * 2.0), Vector2(glyphs * GRID * 10.0 + GRID * 2.0, GRID * 12.0)), Color(accent_color, 0.12))
	for i in glyphs:
		var origin: Vector2 = start + Vector2(i * GRID * 10.0, 0.0)
		for stroke in 3:
			var vertical: bool = rng.randf() < 0.5
			var offset: Vector2 = Vector2(_snap(rng.randf_range(0.0, 6.0)), _snap(rng.randf_range(0.0, 6.0)))
			var size: Vector2 = Vector2(GRID, GRID * 4.0) if vertical else Vector2(GRID * 4.0, GRID)
			draw_rect(Rect2(origin + offset, size), accent_color)


func _draw_columns() -> void:
	var rng: RandomNumberGenerator = _rng()
	var x: float = -span
	var index: int = 0
	while x < span:
		var width: float = _snap(element_width * rng.randf_range(0.8, 1.2))
		var top: float = _snap(level - height * rng.randf_range(0.3, 1.0))
		draw_rect(Rect2(x, top, width, level - top), base_color)
		draw_rect(Rect2(x + GRID * 2.0, top, GRID * 2.0, level - top), detail_color)
		draw_rect(Rect2(x - GRID * 4.0, level - GRID * 8.0, width + GRID * 8.0, GRID * 8.0), base_color)
		for step in 3:
			var chunk: float = _snap(width / 3.0)
			draw_rect(Rect2(x + chunk * step, top - GRID * rng.randi_range(0, 4), chunk, GRID * 4.0), base_color)
		if index % 3 == 1:
			draw_arc(Vector2(x + width + spacing * 0.5, top + height * 0.25), spacing * 0.5, PI, PI * 1.55, 18, base_color, element_width * 0.5)
		index += 1
		x += width + _snap(spacing * rng.randf_range(0.7, 1.3))


func _draw_trunks() -> void:
	var rng: RandomNumberGenerator = _rng()
	draw_rect(Rect2(-span, level - height - 400.0, span * 2.0, 460.0), base_color)
	var x: float = -span
	while x < span:
		var width: float = _snap(element_width * rng.randf_range(0.6, 1.4))
		draw_rect(Rect2(x, level - height - 100.0, width, height + 100.0), base_color)
		draw_rect(Rect2(x + width * 0.25, level - height - 100.0, GRID * 2.0, height + 100.0), detail_color)
		var root: PackedVector2Array = [Vector2(x - width * 0.6, level), Vector2(x, level - height * 0.12), Vector2(x + width, level - height * 0.12), Vector2(x + width * 1.6, level)]
		draw_colored_polygon(root, base_color)
		for spot in rng.randi_range(2, 5):
			var at: Vector2 = Vector2(_snap(x + rng.randf_range(0.0, width)), _snap(level - rng.randf_range(20.0, height * 0.8)))
			draw_rect(Rect2(at, Vector2(GRID * 4.0, GRID * 2.0)), accent_color)
			draw_rect(Rect2(at + Vector2(GRID, -GRID), Vector2(GRID * 2.0, GRID)), accent_color.lightened(0.2))
		x += width + _snap(spacing * rng.randf_range(0.6, 1.4))


func _draw_crystals() -> void:
	var rng: RandomNumberGenerator = _rng()
	var x: float = -span
	while x < span:
		for shard in rng.randi_range(2, 4):
			var w: float = element_width * rng.randf_range(0.3, 0.7)
			var h: float = height * rng.randf_range(0.4, 1.0)
			var lean: float = rng.randf_range(-0.4, 0.4) * h
			var base_x: float = x + shard * w * 0.7
			var points: PackedVector2Array = [Vector2(base_x, level), Vector2(base_x + w, level), Vector2(base_x + w * 0.6 + lean, level - h), Vector2(base_x + w * 0.3 + lean, level - h * 0.92)]
			draw_colored_polygon(points, base_color)
			draw_line(points[2], points[1], accent_color, GRID)
			draw_line(points[2], points[0].lerp(points[1], 0.45), detail_color, GRID)
		x += _snap(spacing * rng.randf_range(0.7, 1.5))


func _draw_ceiling() -> void:
	var rng: RandomNumberGenerator = _rng()
	draw_rect(Rect2(-span, SKY_TOP, span * 2.0, level - SKY_TOP), base_color)
	var x: float = -span
	while x < span:
		var w: float = element_width * rng.randf_range(0.4, 1.2)
		var h: float = height * rng.randf_range(0.2, 1.0)
		draw_colored_polygon(PackedVector2Array([Vector2(x, level - GRID), Vector2(x + w, level - GRID), Vector2(x + w * 0.5, level + h)]), base_color)
		draw_line(Vector2(x + w * 0.5, level + h), Vector2(x + w * 0.8, level), detail_color, GRID)
		x += _snap(spacing * rng.randf_range(0.3, 0.9))


func _draw_clouds() -> void:
	var rng: RandomNumberGenerator = _rng()
	var x: float = -span - spacing * 4.0 + _offset
	while x < span + spacing * 4.0:
		var w: float = _snap(element_width * rng.randf_range(1.0, 3.0))
		var h: float = _snap(height * rng.randf_range(0.4, 1.0))
		draw_rect(Rect2(x, level - h, w, h + 400.0), base_color)
		draw_rect(Rect2(x + w * 0.15, level - h - GRID * 6.0, w * 0.6, GRID * 6.0), base_color)
		draw_rect(Rect2(x + w * 0.15, level - h - GRID * 6.0, w * 0.6, GRID), detail_color)
		x += w + _snap(spacing * rng.randf_range(0.0, 0.6))


func _draw_ship() -> void:
	var half: float = arena_width * 0.5
	var bridge: Rect2 = Rect2(-half - 360.0, level - height, 300.0, height)
	draw_rect(bridge, base_color)
	draw_rect(Rect2(bridge.position + Vector2(20.0, 30.0), Vector2(260.0, GRID * 6.0)), detail_color)
	for i in 6:
		draw_rect(Rect2(bridge.position + Vector2(30.0 + i * 42.0, 34.0), Vector2(GRID * 8.0, GRID * 3.0)), Color(accent_color, 0.4))
	draw_rect(Rect2(half + 140.0, level - height * 1.6, GRID * 6.0, height * 1.6), base_color)
	for i in 3:
		draw_rect(Rect2(half + 110.0, level - height * (1.4 - i * 0.3), 80.0 - i * 16.0, GRID * 2.0), base_color)
	draw_rect(Rect2(half + 144.0, level - height * 1.6 - GRID * 2.0, GRID * 2.0, GRID * 2.0), accent_color)
	draw_rect(Rect2(-half - 340.0, level - height - GRID * 2.0, GRID * 2.0, GRID * 2.0), Color("#c8483c"))
	draw_rect(Rect2(-span, level - GRID * 14.0, span * 2.0, GRID * 2.0), base_color)
	var post: float = -span
	while post < span:
		draw_rect(Rect2(post, level - GRID * 14.0, GRID * 2.0, GRID * 14.0), base_color)
		post += 80.0


func _draw_monastery() -> void:
	var rng: RandomNumberGenerator = _rng()
	var half: float = arena_width * 0.5
	for side in [-1.0, 1.0]:
		for terrace in 3:
			var width: float = 260.0 - terrace * 40.0
			var x: float = half * side + (60.0 + terrace * 50.0) * side - (width if side < 0.0 else 0.0)
			var top: float = level - 90.0 - terrace * 110.0
			draw_rect(Rect2(x, top, width, 110.0 + terrace * 110.0), base_color)
			var roof: PackedVector2Array = [Vector2(x - 24.0, top), Vector2(x + width + 24.0, top), Vector2(x + width * 0.5, top - 44.0)]
			draw_colored_polygon(roof, detail_color)
			for window in 3:
				if rng.randf() < 0.5:
					draw_rect(Rect2(x + 30.0 + window * 60.0, top + 36.0, GRID * 4.0, GRID * 6.0), Color(accent_color, 0.35))
		var tower_x: float = half * side + 420.0 * side - (60.0 if side < 0.0 else 0.0)
		draw_rect(Rect2(tower_x, level - 520.0, 60.0, 520.0), base_color)
		draw_colored_polygon(PackedVector2Array([Vector2(tower_x - 16.0, level - 520.0), Vector2(tower_x + 76.0, level - 520.0), Vector2(tower_x + 30.0, level - 600.0)]), detail_color)


func _draw_brutalist() -> void:
	var window: Rect2 = Rect2(-radius * 1.6, level - height, radius * 3.2, height * 0.8)
	var wall_top: float = level - height * 1.6
	draw_rect(Rect2(-span, SKY_TOP, span * 2.0, window.position.y - SKY_TOP), base_color)
	draw_rect(Rect2(-span, window.end.y, span * 2.0, level - window.end.y + 40.0), base_color)
	draw_rect(Rect2(-span, window.position.y, span - window.size.x * 0.5, window.size.y), base_color)
	draw_rect(Rect2(window.end.x, window.position.y, span - window.end.x, window.size.y), base_color)
	var x: float = -span
	while x < span:
		if x + element_width < window.position.x - GRID * 8.0 or x > window.end.x + GRID * 8.0:
			draw_rect(Rect2(x, wall_top, element_width, level - wall_top + 40.0), detail_color)
			draw_rect(Rect2(x + element_width - GRID * 2.0, wall_top, GRID * 2.0, level - wall_top + 40.0), base_color.darkened(0.3))
		x += element_width + spacing
	var block_y: float = wall_top
	while block_y < level:
		if block_y < window.position.y or block_y > window.end.y:
			draw_rect(Rect2(-span, block_y, span * 2.0, GRID), base_color.darkened(0.25))
		block_y += 120.0
	var mullion: float = window.position.x
	while mullion <= window.end.x + 0.5:
		draw_rect(Rect2(mullion - GRID, window.position.y, GRID * 3.0, window.size.y), detail_color)
		mullion += window.size.x / 6.0
	var transom: float = window.position.y
	while transom <= window.end.y + 0.5:
		draw_rect(Rect2(window.position.x, transom - GRID, window.size.x, GRID * 3.0), detail_color)
		transom += window.size.y / 4.0


func _draw_ring() -> void:
	var center: Vector2 = Vector2(0.0, level + radius)
	for i in 3:
		draw_arc(center, radius - i * GRID * 6.0, PI * 1.08, PI * 1.92, 96, base_color if i == 1 else detail_color, GRID * 4.0)
	draw_arc(center, radius + GRID * 6.0, PI * 1.08, PI * 1.92, 96, Color(accent_color, 0.5), GRID)


func _draw_mirage() -> void:
	var rng: RandomNumberGenerator = _rng()
	for i in bands:
		var y: float = _snap(level - height * float(i) / bands)
		var x: float = rng.randf_range(-span, span)
		var width: float = _snap(element_width * rng.randf_range(0.5, 1.5))
		var shimmer: float = sin(_time * 7.0 + i * 1.9)
		if shimmer < 0.2:
			continue
		var wobble: float = _snap(sin(_time * 3.0 + i) * GRID * 2.0)
		draw_rect(Rect2(x + wobble, y, width, GRID), Color(accent_color, accent_color.a * shimmer))


func _draw_floor() -> void:
	var half: float = arena_width * 0.5
	var edge: float = span
	draw_rect(Rect2(-edge, 0.0, edge * 2.0, FLOOR_DEPTH), base_color)
	match floor_style:
		Floor.STONE, Floor.POLISHED:
			var slab: float = 120.0 if floor_style == Floor.POLISHED else 80.0
			var x: float = -edge
			while x < edge:
				draw_rect(Rect2(x, 0.0, GRID, 40.0), detail_color)
				x += slab
			draw_rect(Rect2(-edge, 40.0, edge * 2.0, GRID), detail_color)
			if floor_style == Floor.POLISHED:
				draw_rect(Rect2(-edge, GRID * 2.0, edge * 2.0, GRID), Color(accent_color, 0.25))
		Floor.WATER:
			for i in 6:
				var y: float = GRID * 3.0 + i * 14.0
				var x: float = -edge + i * 37.0
				while x < edge:
					draw_rect(Rect2(x, y, 40.0 + i * 6.0, GRID), Color(detail_color, 0.6 - i * 0.08))
					x += 140.0 + i * 20.0
		Floor.ROOF, Floor.METAL, Floor.DECK:
			var plate: float = 60.0 if floor_style != Floor.ROOF else 100.0
			var x: float = -edge
			var index: int = 0
			while x < edge:
				draw_rect(Rect2(x, 0.0, plate, 30.0), base_color if index % 2 == 0 else base_color.lightened(0.04))
				draw_rect(Rect2(x, 0.0, GRID, 30.0), detail_color)
				if floor_style == Floor.DECK:
					draw_rect(Rect2(x + 8.0, 10.0, GRID * 2.0, GRID * 2.0), detail_color.lightened(0.1))
				x += plate
				index += 1
			if floor_style == Floor.ROOF:
				var puddle: float = -edge + 50.0
				while puddle < edge:
					draw_rect(Rect2(puddle, GRID * 2.0, 70.0, GRID), Color(accent_color, 0.25))
					puddle += 230.0
		Floor.MOSS:
			var rng: RandomNumberGenerator = _rng()
			var x: float = -edge
			while x < edge:
				draw_rect(Rect2(x, -GRID * rng.randi_range(0, 2), GRID * 2.0, GRID * 3.0), detail_color)
				x += GRID * rng.randi_range(3, 9)
		Floor.SALT:
			var rng: RandomNumberGenerator = _rng()
			var x: float = -edge
			while x < edge:
				var w: float = rng.randf_range(60.0, 140.0)
				draw_line(Vector2(x, GRID * 2.0), Vector2(x + w * 0.5, rng.randf_range(10.0, 34.0)), detail_color, GRID)
				draw_line(Vector2(x + w * 0.5, rng.randf_range(10.0, 34.0)), Vector2(x + w, GRID * 2.0), detail_color, GRID)
				x += w
		Floor.SNOW:
			var rng: RandomNumberGenerator = _rng()
			for side in [-1.0, 1.0]:
				var mound: PackedVector2Array = [Vector2(half * side, 0.0), Vector2((half + 160.0) * side, -46.0), Vector2((half + 420.0) * side, -20.0), Vector2(edge * side, 0.0)]
				draw_colored_polygon(mound, detail_color)
			var x: float = -edge
			while x < edge:
				draw_rect(Rect2(x, GRID, GRID * rng.randi_range(2, 6), GRID), detail_color)
				x += GRID * rng.randi_range(8, 20)
	draw_rect(Rect2(-edge, 0.0, edge * 2.0, GRID), accent_color)
	for side in [-1.0, 1.0]:
		var post_x: float = half * side - (GRID * 6.0 if side < 0.0 else 0.0)
		draw_rect(Rect2(post_x, -height, GRID * 6.0, height), detail_color)
		draw_rect(Rect2(post_x + GRID * 2.0, -height, GRID * 2.0, height), Color(accent_color, 0.6))
