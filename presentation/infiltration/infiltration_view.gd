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


func setup(simulation: InfiltrationSimulation) -> void:
	sim = simulation
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_spark_positions.resize(sim.config.spark_capacity)
	_spark_left.resize(sim.config.spark_capacity)
	_spark_left.fill(0.0)
	_spark_kinds.resize(sim.config.spark_capacity)


func on_event(event: InfiltrationEvent) -> void:
	if event.type != InfiltrationEvent.Type.BOLT_BLOCKED and event.type != InfiltrationEvent.Type.BOLT_REFLECTED and event.type != InfiltrationEvent.Type.SWING_HIT and event.type != InfiltrationEvent.Type.BOLT_HIT:
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
	for index in sim.targets.size():
		var actor: InfiltrationActor = sim.targets[index]
		if actor.health <= 0.0:
			continue
		var kind: int = SPRITE_DUMMY if sim.map.targets[index].kind == InfiltrationTargetData.Kind.DUMMY else SPRITE_EMITTER
		_draw_actor(actor, kind)
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


func _draw_actor(actor: InfiltrationActor, sprite: int) -> void:
	var location: Vector2 = actor.previous.lerp(actor.position, alpha)
	var aim: Vector2 = actor.aim
	if sprite == SPRITE_PLAYER and actor.swing_tick >= 0:
		aim = actor.swing_aim
	var size: Vector2 = Vector2(sim.config.sprite_pixels) * sim.config.units_per_pixel
	if sprite == SPRITE_PLAYER and actor.velocity.length_squared() > 1.0:
		location += aim.orthogonal() * sin(_time * actor.velocity.length() / sim.config.step_distance * TAU) * sim.config.units_per_pixel
	var scale: Vector2 = Vector2.ONE
	if sprite == SPRITE_PLAYER and actor.locomotion == InfiltrationActor.Locomotion.SNEAK:
		scale.y = 0.9
	draw_set_transform(_snap(location), aim.angle() + PI * 0.5, scale)
	draw_texture_rect_region(sim.map.sprites, Rect2(-size * 0.5, size), Rect2(Vector2(sprite * sim.config.sprite_pixels.x, 0), Vector2(sim.config.sprite_pixels)))
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
