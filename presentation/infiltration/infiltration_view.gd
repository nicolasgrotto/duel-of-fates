class_name InfiltrationView
extends Node2D

const PALETTE: UiPalette = preload("res://ui/palette.tres")
const SPRITE_PLAYER: int = 0
const SPRITE_DUMMY: int = 1
const SPRITE_EMITTER: int = 2
const SPARK_DIRECTIONS: int = 8
enum SparkKind { IMPACT, REFLECTED, PERFECT }

var sim: InfiltrationSimulation
var alpha: float = 1.0
var debug: bool = false
var reduced: bool = false
var animate: bool = true
var _time: float = 0.0
var _spark_positions: PackedVector2Array = []
var _spark_left: PackedFloat32Array = []
var _spark_kinds: PackedByteArray = []
var _next_spark: int = 0
const CONE_SAMPLES: int = 24
var _cone_points: PackedVector2Array = []


func setup(simulation: InfiltrationSimulation) -> void:
	sim = simulation
	_cone_points.resize(CONE_SAMPLES + 2)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_spark_positions.resize(sim.config.spark_capacity)
	_spark_left.resize(sim.config.spark_capacity)
	_spark_left.fill(0.0)
	_spark_kinds.resize(sim.config.spark_capacity)


func on_event(event: InfiltrationEvent) -> void:
	if event.type != InfiltrationEvent.Type.BOLT_BLOCKED and event.type != InfiltrationEvent.Type.BOLT_REFLECTED and event.type != InfiltrationEvent.Type.SWING_HIT and event.type != InfiltrationEvent.Type.BOLT_HIT and event.type != InfiltrationEvent.Type.TAKEDOWN_LANDED:
		return
	_spark_positions[_next_spark] = event.position
	_spark_left[_next_spark] = sim.config.spark_seconds
	_spark_kinds[_next_spark] = SparkKind.IMPACT
	if event.type == InfiltrationEvent.Type.BOLT_REFLECTED:
		_spark_kinds[_next_spark] = SparkKind.PERFECT if event.amount > 0.0 else SparkKind.REFLECTED
	_next_spark = (_next_spark + 1) % _spark_positions.size()


func _process(delta: float) -> void:
	if sim == null:
		return
	if animate:
		_time += delta
		for index in _spark_left.size():
			_spark_left[index] = maxf(_spark_left[index] - delta, 0.0)
	queue_redraw()


func _draw() -> void:
	if sim == null:
		return
	_draw_security()
	for index in sim.targets.size():
		var actor: InfiltrationActor = sim.targets[index]
		if actor.health <= 0.0:
			continue
		if index < sim.map.targets.size():
			var kind: int = SPRITE_DUMMY if sim.target_data[index].kind == InfiltrationTargetData.Kind.DUMMY else SPRITE_EMITTER
			_draw_actor(actor, kind)
		else:
			_draw_actor(actor, (sim.target_data[index] as InfiltrationEnemyData).sprite, true)
			_draw_awareness(actor)
	if sim.player.health > 0.0:
		_draw_actor(sim.player, SPRITE_PLAYER)
		_draw_blade()
	for bolt in sim.bolts:
		if not bolt.active:
			continue
		var point: Vector2 = _snap(bolt.previous.lerp(bolt.position, alpha))
		var tail: Vector2 = _snap(point - bolt.velocity.normalized() * sim.config.bolt_length)
		var color: Color = PALETTE.menu_blade_a if bolt.owner == 0 else PALETTE.bolt
		draw_line(tail, point, Color(color, 0.15), bolt.data.size * 2.0)
		draw_line(tail, point, color, sim.config.blade_width)
		draw_line(tail, point, PALETTE.text, sim.config.units_per_pixel)
	_draw_sparks()
	if debug:
		_draw_debug()


func _draw_actor(actor: InfiltrationActor, sprite: int, enemy: bool = false) -> void:
	var location: Vector2 = actor.previous.lerp(actor.position, alpha)
	var aim: Vector2 = actor.aim
	if not enemy and sprite == SPRITE_PLAYER and actor.swing_tick >= 0:
		aim = actor.swing_aim
	var size: Vector2 = Vector2(sim.config.sprite_pixels) * sim.config.units_per_pixel
	if (enemy or sprite == SPRITE_PLAYER) and actor.velocity.length_squared() > 1.0:
		location += aim.orthogonal() * sin(_time * actor.velocity.length() / sim.config.step_distance * TAU) * sim.config.units_per_pixel
	var scale: Vector2 = Vector2.ONE
	if not enemy and sprite == SPRITE_PLAYER and actor.locomotion == InfiltrationActor.Locomotion.SNEAK:
		scale.y = 0.9
	draw_set_transform(_snap(location), aim.angle() + PI * 0.5, scale)
	draw_texture_rect_region(sim.map.enemy_sprites if enemy else sim.map.sprites, Rect2(-size * 0.5, size), Rect2(Vector2(sprite * sim.config.sprite_pixels.x, 0), Vector2(sim.config.sprite_pixels)))
	draw_set_transform(Vector2.ZERO)


func _draw_blade() -> void:
	var player: InfiltrationActor = sim.player
	var location: Vector2 = _snap(player.previous.lerp(player.position, alpha))
	var facing: Vector2 = player.swing_aim if player.swing_tick >= 0 else player.aim
	var angle: float = facing.angle()
	if player.swing_tick >= 0:
		var progress: float = clampf(float(player.swing_tick - sim.config.startup_ticks() + 1) / sim.config.active_ticks(), 0.0, 1.0)
		angle = player.swing_aim.angle() + deg_to_rad(lerpf(-sim.config.swing_degrees * 0.5, sim.config.swing_degrees * 0.5, progress))
	elif player.guard:
		angle += PI * 0.5
	var direction: Vector2 = Vector2.from_angle(angle)
	var grip: Vector2 = _snap(location + facing * sim.config.blade_grip)
	var tip: Vector2 = _snap(grip + direction * sim.config.blade_length)
	if player.guard:
		grip = _snap(location + facing * sim.config.blade_grip - direction * sim.config.blade_length * 0.5)
		tip = _snap(grip + direction * sim.config.blade_length)
	draw_line(grip, tip, Color(PALETTE.menu_blade_a, 0.08), sim.config.blade_width * 4.0)
	draw_line(grip, tip, Color(PALETTE.menu_blade_a, 0.25), sim.config.blade_width * 2.0)
	draw_line(grip, tip, PALETTE.menu_blade_a, sim.config.blade_width)
	draw_line(grip, tip, PALETTE.text, sim.config.units_per_pixel)
	draw_line(grip - direction * sim.config.blade_grip * 0.5, grip, PALETTE.menu_hilt, sim.config.blade_width)
	if sim.swing_active():
		draw_arc(location, sim.config.swing_reach, player.swing_aim.angle() - deg_to_rad(sim.config.swing_degrees * 0.5), angle, 12, Color(PALETTE.menu_blade_a, 0.3), sim.config.units_per_pixel)


func _draw_sparks() -> void:
	for index in _spark_left.size():
		if _spark_left[index] <= 0.0:
			continue
		var progress: float = 1.0 - _spark_left[index] / sim.config.spark_seconds
		var color: Color = PALETTE.menu_blade_a if _spark_kinds[index] != SparkKind.IMPACT else PALETTE.spark_warm
		color.a = 1.0 - progress
		if _spark_kinds[index] == SparkKind.PERFECT:
			draw_arc(_snap(_spark_positions[index]), sim.config.blade_grip * (0.5 + progress), 0.0, TAU, 12, color, sim.config.units_per_pixel)
		var count: int = 2 if reduced else SPARK_DIRECTIONS
		for direction in count:
			var offset: Vector2 = Vector2.from_angle(TAU * direction / count) * sim.config.blade_grip * progress
			draw_line(_snap(_spark_positions[index] + offset), _snap(_spark_positions[index] + offset * 0.5), color, sim.config.units_per_pixel)


func _draw_debug() -> void:
	for y in sim.map.rows.size():
		for x in sim.map.width():
			if sim.map.is_solid(x, y):
				draw_rect(Rect2(Vector2(x, y) * sim.map.tile_size, Vector2.ONE * sim.map.tile_size), Color(PALETTE.danger, 0.5), false, sim.config.units_per_pixel)
	var player: InfiltrationActor = sim.player
	var body: Rect2 = Rect2(player.position - Vector2.ONE * sim.config.body_radius, Vector2.ONE * sim.config.body_radius * 2.0)
	draw_rect(body, PALETTE.accent, false, sim.config.units_per_pixel)
	draw_line(player.position, player.position + player.aim * sim.config.swing_reach, PALETTE.text, sim.config.units_per_pixel)
	var degrees: float = sim.config.guard_degrees if player.guard else sim.config.swing_degrees
	var aim: Vector2 = player.swing_aim if player.swing_tick >= 0 else player.aim
	draw_arc(player.position, sim.config.swing_reach, aim.angle() - deg_to_rad(degrees * 0.5), aim.angle() + deg_to_rad(degrees * 0.5), 20, PALETTE.potential, sim.config.units_per_pixel)
	for bolt in sim.bolts:
		if bolt.active:
			draw_line(bolt.previous, bolt.position, PALETTE.danger, sim.config.units_per_pixel)


func _snap(point: Vector2) -> Vector2:
	return (point / sim.config.units_per_pixel).round() * sim.config.units_per_pixel


func _draw_security() -> void:
	for index in range(sim.map.targets.size(), sim.targets.size()):
		var actor: InfiltrationActor = sim.targets[index]
		var placement: InfiltrationEnemyPlacement = sim.enemy_placement(index)
		if placement.reinforcement:
			var access: Vector2 = placement.position
			draw_rect(Rect2(access - Vector2(24, 20), Vector2(48, 40)), Color(PALETTE.accent, 0.4), false, sim.config.units_per_pixel)
			draw_line(access + Vector2(-10, 8), access + Vector2(0, -4), PALETTE.accent, sim.config.units_per_pixel)
			draw_line(access + Vector2(0, -4), access + Vector2(10, 8), PALETTE.accent, sim.config.units_per_pixel)
		if actor.health <= 0.0:
			continue
		var data: InfiltrationEnemyData = sim.target_data[index] as InfiltrationEnemyData
		var origin: Vector2 = _snap(actor.previous.lerp(actor.position, alpha))
		var color: Color = _awareness_color(actor)
		_cone_points[0] = origin
		for point in CONE_SAMPLES + 1:
			var angle: float = actor.aim.angle() + deg_to_rad(data.vision_degrees * (float(point) / CONE_SAMPLES - 0.5))
			var end: Vector2 = origin + Vector2.from_angle(angle) * data.vision_range
			var fraction: float = InfiltrationGeometry.wall_fraction(sim.map, origin, end)
			_cone_points[point + 1] = _snap(origin.lerp(end, minf(fraction, 1.0)))
		draw_colored_polygon(_cone_points, Color(color, 0.045))
		for point in CONE_SAMPLES:
			if point % 2 == 0:
				draw_line(_cone_points[point + 1], _cone_points[point + 2], Color(color, 0.4), sim.config.units_per_pixel)
		for point in range(1, CONE_SAMPLES, 4):
			draw_line(origin.lerp(_cone_points[point + 1], 0.35), origin.lerp(_cone_points[point + 1], 0.65), Color(color, 0.13), sim.config.units_per_pixel)
		if debug:
			draw_rect(Rect2(origin - Vector2.ONE * sim.config.body_radius, Vector2.ONE * sim.config.body_radius * 2.0), color, false, sim.config.units_per_pixel)
			draw_line(origin, actor.last_known, PALETTE.potential, sim.config.units_per_pixel)
			for waypoint in placement.route.size():
				var start: Vector2 = placement.route[waypoint]
				var end: Vector2 = placement.route[(waypoint + 1) % placement.route.size()]
				draw_line(start, end, Color(PALETTE.accent, 0.6), sim.config.units_per_pixel)
				draw_circle(start, 6.0, PALETTE.accent, false, sim.config.units_per_pixel)
	for index in sim.panels.size():
		var point: Vector2 = sim.map.panels[index].position
		var panel: InfiltrationPanel = sim.panels[index]
		var color: Color = PALETTE.secondary if panel.disabled else PALETTE.danger if panel.active else PALETTE.accent
		if panel.active and not reduced:
			draw_circle(point, 36.0, Color(color, 0.06 + 0.04 * sin(_time * TAU * 2.0)))
		draw_rect(Rect2(point - Vector2(20, 16), Vector2(40, 32)), PALETTE.infiltration_seam)
		draw_rect(Rect2(point - Vector2(18, 14), Vector2(36, 28)), PALETTE.infiltration_wall)
		draw_rect(Rect2(point - Vector2(12, 8), Vector2(24, 12)), Color(color, 0.6))
		draw_line(point + Vector2(-12, 10), point + Vector2(-2, 10), color, sim.config.units_per_pixel)
		draw_line(point + Vector2(2, 10), point + Vector2(12, 10), color, sim.config.units_per_pixel)
		if panel.disabled:
			draw_line(point + Vector2(-14, 12), point + Vector2(14, -12), PALETTE.secondary, sim.config.units_per_pixel)


func _awareness_color(actor: InfiltrationActor) -> Color:
	match actor.awareness:
		InfiltrationActor.Awareness.SUSPICIOUS:
			return PALETTE.potential
		InfiltrationActor.Awareness.ALERTED:
			return PALETTE.danger
	return PALETTE.accent


func _draw_awareness(actor: InfiltrationActor) -> void:
	if actor.suspicion <= 0.0:
		return
	var point: Vector2 = _snap(actor.previous.lerp(actor.position, alpha) + Vector2(0, -44))
	var color: Color = _awareness_color(actor)
	draw_circle(point, 14.0, PALETTE.background)
	draw_arc(point, 13.0, -PI * 0.5, -PI * 0.5 + TAU * actor.suspicion, 16, color, sim.config.units_per_pixel)
	if actor.awareness == InfiltrationActor.Awareness.ALERTED:
		draw_line(point + Vector2(0, -8), point + Vector2(0, 2), color, 4.0)
	else:
		draw_arc(point + Vector2(0, -3), 5.0, PI, TAU + PI * 0.5, 6, color, sim.config.units_per_pixel)
		draw_line(point + Vector2(0, 2), point + Vector2(0, 4), color, sim.config.units_per_pixel)
	draw_rect(Rect2(point + Vector2(-2, 7), Vector2(4, 4)), color)
