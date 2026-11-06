class_name SectorMap
extends Control

signal node_clicked(index: int)

const PALETTE: UiPalette = preload("res://ui/palette.tres")
const DESIGN_SIZE: Vector2 = Vector2(1120.0, 720.0)
const RADAR_CENTER: Vector2 = Vector2(560.0, 300.0)
const RADAR_RINGS: PackedFloat32Array = [130.0, 280.0, 450.0, 640.0]
const CROSSHAIR_ALPHA: float = 0.35
const STAR_COUNT: int = 150
const STAR_SEED: int = 7301
const MARKER_REACH: float = 40.0
const BRACKET_SIZE: float = 132.0
const BRACKET_CORNER: float = 24.0
const BRACKET_WIDTH: float = 4.0
const HOVER_RADIUS: float = 54.0
const LABEL_GAP: float = 62.0
const RIGHT_LABEL_GAP: float = 54.0
const LABEL_NUDGE: float = 11.0
const SELECTED_GAP: float = 76.0
const DASH: float = 12.0
const ROUTE_WIDTH: float = 3.0
const RATING_REACH: float = 7.0
const RATING_STEP: float = 20.0
const RATING_DROP: float = 16.0
const RATING_TOTAL: int = 3
const LINE_WIDTH: float = 1.0
const CROSS_WIDTH: float = 2.0
const PLATE_MARGIN: float = 8.0
const PLATE_ALPHA: float = 0.85

var missions: Array[SpaceMissionData] = []
var completed: Array[bool] = []
var ratings: PackedInt32Array = []
var selected: int = 0:
	set(value):
		selected = value
		queue_redraw()
var _hovered: int = -1
var _stars: PackedVector3Array = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	clip_contents = true
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = STAR_SEED
	for index in STAR_COUNT:
		_stars.append(Vector3(random.randf(), random.randf(), random.randf()))


func configure(data: Array[SpaceMissionData], done: Array[bool], rates: PackedInt32Array) -> void:
	missions = data
	completed = done
	ratings = rates
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var hovered: int = _node_at(event.position)
		if hovered != _hovered:
			_hovered = hovered
			queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var index: int = _node_at(event.position)
		if index >= 0:
			node_clicked.emit(index)


func _node_at(point: Vector2) -> int:
	for index in missions.size():
		if _node_point(index).distance_to(point) <= HOVER_RADIUS:
			return index
	return -1


func _origin() -> Vector2:
	return ((size - DESIGN_SIZE) * 0.5).floor()


func _node_point(index: int) -> Vector2:
	return _origin() + missions[index].map_position


func _draw() -> void:
	_draw_sky()
	_draw_radar()
	_draw_route()
	for index in missions.size():
		_draw_node(index)
	if _hovered >= 0 and _hovered != selected:
		_draw_hover(_hovered)
	if selected >= 0 and selected < missions.size():
		_draw_brackets(_node_point(selected))


func _draw_sky() -> void:
	for star in _stars:
		var brightness: float = 0.15 + star.z * 0.55
		var side: float = 1.0 + floorf(star.z * 2.0)
		draw_rect(Rect2(Vector2(star.x, star.y) * size, Vector2.ONE * side), Color(PALETTE.tactical_muted, brightness))


func _draw_radar() -> void:
	var center: Vector2 = _origin() + RADAR_CENTER
	for radius in RADAR_RINGS:
		draw_arc(center, radius, 0.0, TAU, 96, PALETTE.tactical_line, LINE_WIDTH)
	var cross: Color = Color(PALETTE.menu_blade_b, CROSSHAIR_ALPHA)
	draw_line(Vector2(0.0, center.y), Vector2(size.x, center.y), cross, CROSS_WIDTH)
	draw_line(Vector2(center.x, 0.0), Vector2(center.x, size.y), cross, CROSS_WIDTH)


func _draw_route() -> void:
	for index in range(0, missions.size() - 1):
		var from: Vector2 = _node_point(index)
		var to: Vector2 = _node_point(index + 1)
		if completed[index]:
			draw_line(from, to, PALETTE.menu_blade_a, ROUTE_WIDTH)
		else:
			draw_dashed_line(from, to, PALETTE.tactical_line_strong, ROUTE_WIDTH, DASH)


func _draw_node(index: int) -> void:
	var center: Vector2 = _node_point(index)
	var done: bool = completed[index]
	var points: PackedVector2Array = [center + Vector2(0.0, -MARKER_REACH), center + Vector2(MARKER_REACH, 0.0), center + Vector2(0.0, MARKER_REACH), center + Vector2(-MARKER_REACH, 0.0)]
	draw_colored_polygon(points, PALETTE.tactical_panel)
	points.append(points[0])
	var active: bool = index == selected
	var edge: Color = PALETTE.menu_blade_b if active else PALETTE.menu_blade_a if done else PALETTE.tactical_line_strong
	draw_polyline(points, edge, BRACKET_WIDTH * 0.5 if not active else BRACKET_WIDTH * 0.75, true)
	_draw_state(center, done, edge)
	_draw_label(index, center, active, done)


func _draw_state(center: Vector2, done: bool, edge: Color) -> void:
	if done:
		draw_polyline(PackedVector2Array([center + Vector2(-12.0, 0.0), center + Vector2(-3.0, 10.0), center + Vector2(13.0, -10.0)]), edge, 4.0)
	else:
		draw_circle(center, 6.0, edge)


func _draw_label(index: int, center: Vector2, active: bool, done: bool) -> void:
	var font: Font = get_theme_font(&"font", &"TacticalRowLabel")
	var font_size: int = get_theme_font_size(&"font_size", &"TacticalNameLabel") - 8 if active else get_theme_font_size(&"font_size", &"TacticalNoteLabel")
	var text: String = tr(missions[index].title_key)
	var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var color: Color = PALETTE.menu_blade_b if active else PALETTE.text if done else PALETTE.tactical_muted
	var place: Vector2 = _label_place(missions[index].map_label if not active else SpaceMissionData.MapLabel.ABOVE, center, width, active)
	place.x = clampf(place.x, LABEL_NUDGE, maxf(size.x - width - LABEL_NUDGE, LABEL_NUDGE))
	var plate: Rect2 = Rect2(place + Vector2(-PLATE_MARGIN, -font.get_ascent(font_size)), Vector2(width + PLATE_MARGIN * 2.0, font.get_height(font_size)))
	draw_rect(plate, Color(PALETTE.tactical_deep, PLATE_ALPHA))
	draw_string(font, place, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
	if done:
		_draw_rating(index, place + Vector2(width * 0.5, 0.0))


func _label_place(side: SpaceMissionData.MapLabel, center: Vector2, width: float, active: bool) -> Vector2:
	match side:
		SpaceMissionData.MapLabel.ABOVE:
			return center + Vector2(-width * 0.5, -(SELECTED_GAP if active else LABEL_GAP))
		SpaceMissionData.MapLabel.RIGHT:
			return center + Vector2(RIGHT_LABEL_GAP, LABEL_NUDGE)
		_:
			return center + Vector2(-width * 0.5, LABEL_GAP + LABEL_NUDGE)


func _draw_rating(index: int, middle: Vector2) -> void:
	var rating: int = ratings[index]
	for step in RATING_TOTAL:
		var center: Vector2 = middle + Vector2((step - 1) * RATING_STEP, RATING_DROP)
		var points: PackedVector2Array = [center + Vector2(0.0, -RATING_REACH), center + Vector2(RATING_REACH, 0.0), center + Vector2(0.0, RATING_REACH), center + Vector2(-RATING_REACH, 0.0)]
		if step < rating:
			draw_colored_polygon(points, PALETTE.menu_blade_a)
		else:
			points.append(points[0])
			draw_polyline(points, PALETTE.tactical_line_strong, 2.0)


func _draw_hover(index: int) -> void:
	var center: Vector2 = _node_point(index)
	var segments: int = 24
	for segment in segments:
		if segment % 2 == 0:
			var angle: float = TAU * segment / segments
			draw_arc(center, HOVER_RADIUS, angle, angle + TAU / segments, 5, PALETTE.menu_blade_a, 2.0)


func _draw_brackets(center: Vector2) -> void:
	var half: float = BRACKET_SIZE * 0.5
	for sign_x: float in [-1.0, 1.0]:
		for sign_y: float in [-1.0, 1.0]:
			var corner: Vector2 = center + Vector2(sign_x, sign_y) * half
			draw_line(corner, corner - Vector2(sign_x * BRACKET_CORNER, 0.0), PALETTE.menu_blade_b, BRACKET_WIDTH)
			draw_line(corner, corner - Vector2(0.0, sign_y * BRACKET_CORNER), PALETTE.menu_blade_b, BRACKET_WIDTH)
