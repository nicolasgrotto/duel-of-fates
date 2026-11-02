class_name InfiltrationView
extends Node2D

const PALETTE: UiPalette = preload("res://ui/palette.tres")
const PRISONER: Texture2D = preload("res://assets/infiltration/prisoner.png")
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
var _look: InfiltrationLook
var _blade: InfiltrationBlade = InfiltrationBlade.new()
var _guard_blend: float = 0.0


func setup(simulation: InfiltrationSimulation, look: InfiltrationLook) -> void:
	sim = simulation
	_look = look
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
		_guard_blend = move_toward(_guard_blend, 1.0 if sim.player.guard else 0.0, delta / sim.config.guard_blend_seconds)
		for index in _spark_left.size():
			_spark_left[index] = maxf(_spark_left[index] - delta, 0.0)
	queue_redraw()


func _draw() -> void:
	if sim == null:
		return
	_draw_security()
	if sim.mission != null:
		_draw_mission()
	for index in sim.targets.size():
		var actor: InfiltrationActor = sim.targets[index]
		if actor.health <= 0.0:
			continue
		if index < sim.map.targets.size():
			var kind: int = SPRITE_DUMMY if sim.target_data[index].kind == InfiltrationTargetData.Kind.DUMMY else SPRITE_EMITTER
			_draw_actor(actor, kind)
		else:
			var enemy_data: InfiltrationEnemyData = sim.target_data[index] as InfiltrationEnemyData
			_draw_actor(actor, enemy_data.sprite, true, enemy_data.texture)
			_draw_awareness(actor)
	if sim.player.health > 0.0:
		_draw_actor(sim.player, SPRITE_PLAYER)
		_draw_blade()
	for bolt in sim.bolts:
		if not bolt.active:
			continue
		var point: Vector2 = _snap(bolt.previous.lerp(bolt.position, alpha))
		var tail: Vector2 = _snap(point - bolt.velocity.normalized() * sim.config.bolt_length)
		var color: Color = _look.blade_color if bolt.owner == 0 else PALETTE.bolt
		draw_line(tail, point, Color(color, 0.15), bolt.data.size * 2.0)
		draw_line(tail, point, color, sim.config.blade_width)
		draw_line(tail, point, PALETTE.text, sim.config.units_per_pixel)
	_draw_sparks()
	if debug:
		_draw_debug()


func _draw_actor(actor: InfiltrationActor, sprite: int, enemy: bool = false, texture: Texture2D = null) -> void:
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
	if texture != null:
		var large: Vector2 = texture.get_size() * sim.config.units_per_pixel
		draw_texture_rect(texture, Rect2(-large * 0.5, large), false)
	elif not enemy and sprite == SPRITE_PLAYER:
		draw_texture_rect(_look.texture, Rect2(-size * 0.5, size), false)
	else:
		draw_texture_rect_region(sim.map.enemy_sprites if enemy else sim.map.sprites, Rect2(-size * 0.5, size), Rect2(Vector2(sprite * sim.config.sprite_pixels.x, 0), Vector2(sim.config.sprite_pixels)))
	draw_set_transform(Vector2.ZERO)


func _draw_mission() -> void:
	var data: InfiltrationMissionData = sim.mission.data
	var exit: Vector2 = _snap(data.extraction)
	var radius: float = data.extraction_radius
	var color: Color = PALETTE.accent
	draw_rect(Rect2(exit - Vector2.ONE * radius, Vector2.ONE * radius * 2.0), Color(color, 0.08))
	for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		var point: Vector2 = exit + corner * radius
		draw_line(point, point - Vector2(corner.x * 24.0, 0), color, sim.config.units_per_pixel)
		draw_line(point, point - Vector2(0, corner.y * 24.0), color, sim.config.units_per_pixel)
	draw_line(exit - Vector2(20, 0), exit + Vector2(20, 0), color, 4.0)
	draw_line(exit + Vector2(8, -12), exit + Vector2(20, 0), color, 4.0)
	draw_line(exit + Vector2(8, 12), exit + Vector2(20, 0), color, 4.0)
	for index in data.terminals.size():
		var point: Vector2 = _snap(data.terminals[index])
		color = PALETTE.secondary if sim.mission.copied[index] != 0 else PALETTE.accent
		draw_rect(Rect2(point - Vector2(22, 18), Vector2(44, 36)), PALETTE.infiltration_wall)
		draw_rect(Rect2(point - Vector2(22, 18), Vector2(44, 36)), color, false, 2.0)
		draw_line(point + Vector2(-12, -6), point + Vector2(12, -6), color, 4.0)
		draw_line(point + Vector2(-12, 6), point + Vector2(4, 6), color, 4.0)
		if sim.mission.copied[index] != 0:
			_draw_check(point + Vector2(0, -30), PALETTE.text)
	for index in sim.prisoners.size():
		var actor: InfiltrationActor = sim.prisoners[index]
		var point: Vector2 = _snap(actor.previous.lerp(actor.position, alpha))
		color = PALETTE.text if actor.health > 0.0 else PALETTE.danger
		var size: Vector2 = Vector2(sim.config.sprite_pixels) * sim.config.units_per_pixel
		draw_set_transform(point, actor.aim.angle() + PI * 0.5)
		draw_texture_rect(PRISONER, Rect2(-size * 0.5, size), false, Color.WHITE if actor.health > 0.0 else PALETTE.danger)
		draw_set_transform(Vector2.ZERO)
		var marker: Vector2 = point - Vector2(0, 40)
		var locked: bool = sim.mission.prisoners_locked(sim)
		draw_polyline(PackedVector2Array([marker + Vector2(0, -10), marker + Vector2(10, 0), marker + Vector2(0, 10), marker + Vector2(-10, 0), marker + Vector2(0, -10)]), PALETTE.danger if locked else PALETTE.accent, 2.0)
		if locked:
			draw_line(marker + Vector2(-5, -5), marker + Vector2(5, 5), PALETTE.danger, 2.0)
			draw_line(marker + Vector2(5, -5), marker + Vector2(-5, 5), PALETTE.danger, 2.0)
		if sim.mission.recruited[index] != 0:
			_draw_check(marker, PALETTE.text)
		draw_line(point + Vector2(-18, 28), point + Vector2(-18 + 36.0 * actor.health / sim.config.prisoner_health, 28), color, 2.0)


func _draw_check(point: Vector2, color: Color) -> void:
	draw_line(point + Vector2(-6, 0), point + Vector2(-2, 4), color, 2.0)
	draw_line(point + Vector2(-2, 4), point + Vector2(8, -6), color, 2.0)


func _draw_blade() -> void:
	var player: InfiltrationActor = sim.player
	var location: Vector2 = _snap(player.previous.lerp(player.position, alpha))
	var facing: Vector2 = player.swing_aim if player.swing_tick >= 0 else player.aim
	var half: float = sim.config.swing_degrees * 0.5
	var swing_blend: float = 0.0
	var swing_angle: float = -half
	if player.swing_tick >= 0:
		var startup: int = sim.config.startup_ticks()
		var active: int = sim.config.active_ticks()
		var recovery: int = maxi(sim.config.swing_ticks() - startup - active, 1)
		if player.swing_tick < startup:
			swing_blend = float(player.swing_tick + 1) / startup
		elif player.swing_tick < startup + active:
			swing_blend = 1.0
			swing_angle = lerpf(-half, half, float(player.swing_tick - startup + 1) / active)
		else:
			swing_blend = 1.0 - float(player.swing_tick - startup - active + 1) / recovery
			swing_angle = half
	_blade.compose(sim.config, facing, _guard_blend, swing_blend, swing_angle)
	_blade.draw(self, location, _look, sim.config)
	if sim.swing_active():
		draw_arc(location, sim.config.swing_reach, facing.angle() - deg_to_rad(half), facing.angle() + deg_to_rad(swing_angle), 12, Color(_look.blade_color, 0.3), sim.config.units_per_pixel)


func _draw_sparks() -> void:
	for index in _spark_left.size():
		if _spark_left[index] <= 0.0:
			continue
		var progress: float = 1.0 - _spark_left[index] / sim.config.spark_seconds
		var color: Color = _look.blade_color if _spark_kinds[index] != SparkKind.IMPACT else PALETTE.spark_warm
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
		if not debug and _is_cone_hidden(actor, data):
			continue
		var origin: Vector2 = _snap(actor.previous.lerp(actor.position, alpha))
		var color: Color = _awareness_color(actor)
		if data.aim_line and actor.awareness == InfiltrationActor.Awareness.ALERTED and (actor.visible_player or actor.target_prisoner >= 0):
			draw_line(origin, origin + actor.aim * data.vision_range * minf(InfiltrationGeometry.wall_fraction(sim.map, origin, origin + actor.aim * data.vision_range), 1.0), Color(PALETTE.danger, 0.6), sim.config.units_per_pixel)
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


func _is_cone_hidden(actor: InfiltrationActor, data: InfiltrationEnemyData) -> bool:
	var half: Vector2 = get_viewport_rect().size * 0.5 / sim.config.camera_zoom + Vector2.ONE * data.vision_range
	var offset: Vector2 = actor.position - sim.player.position
	return absf(offset.x) > half.x or absf(offset.y) > half.y


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
