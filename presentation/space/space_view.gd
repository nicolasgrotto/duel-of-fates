class_name SpaceView
extends Node2D

const PALETTE: UiPalette = preload("res://ui/palette.tres")
const FRAGMENTS: int = 8

var sim: SpaceSimulation
var alpha: float = 1.0
var reduced: bool = false
var debug: bool = false
var animate: bool = true
var _time: float = 0.0
var _trail_time: float = 0.0
var _trail_positions: PackedVector2Array = []
var _trail_angles: PackedFloat32Array = []
var _trail_left: PackedFloat32Array = []
var _trail_next: int = 0
var _positions: PackedVector2Array = []
var _angles: PackedFloat32Array = []
var _kinds: PackedInt32Array = []
var _left: PackedFloat32Array = []
var _next: int = 0


func setup(simulation: SpaceSimulation) -> void:
	sim = simulation
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_positions.resize(sim.config.effect_capacity)
	_angles.resize(_positions.size())
	_kinds.resize(_positions.size())
	_left.resize(_positions.size())
	_left.fill(0.0)
	_trail_positions.resize(sim.config.trail_capacity)
	_trail_angles.resize(_trail_positions.size())
	_trail_left.resize(_trail_positions.size())
	_trail_left.fill(0.0)
	_next = 0
	_trail_next = 0
	_trail_time = 0.0


func on_event(event: SpaceEvent) -> void:
	if event.type != SpaceEvent.Type.SHIELD_HIT and event.type != SpaceEvent.Type.HULL_HIT and event.type != SpaceEvent.Type.SHIP_DESTROYED:
		return
	if _left.is_empty():
		return
	_positions[_next] = sim.ships[event.target].position if event.type == SpaceEvent.Type.SHIELD_HIT else event.position
	_angles[_next] = (event.position - sim.ships[event.target].position).angle()
	_kinds[_next] = event.type
	_left[_next] = _duration(event.type)
	_next = (_next + 1) % _left.size()


func _process(delta: float) -> void:
	if sim == null:
		return
	if animate:
		_time += delta
		for index in _left.size():
			_left[index] = maxf(_left[index] - delta, 0.0)
		for index in _trail_left.size():
			_trail_left[index] = maxf(_trail_left[index] - delta, 0.0)
		_trail_time += delta
		var ship: SpaceShipState = sim.ships[0]
		var interval: float = sim.config.trail_interval * (2.0 if reduced else 1.0)
		if _trail_time >= interval and ship.hull > 0.0 and ship.velocity.length_squared() > 25.0 and not _trail_left.is_empty():
			_trail_time = 0.0
			_trail_positions[_trail_next] = ship.previous.lerp(ship.position, alpha) - ship.forward() * 34.0
			_trail_angles[_trail_next] = ship.angle
			_trail_left[_trail_next] = sim.config.trail_seconds
			_trail_next = (_trail_next + 1) % _trail_left.size()
	queue_redraw()


func _draw() -> void:
	if sim == null:
		return
	_draw_trails()
	for index in sim.ships.size():
		var ship: SpaceShipState = sim.ships[index]
		if ship.hull <= 0.0:
			continue
		_draw_ship(index)
	for projectile in sim.projectiles:
		if not projectile.active:
			continue
		var point: Vector2 = _snap(projectile.previous.lerp(projectile.position, alpha))
		var direction: Vector2 = projectile.velocity.normalized()
		var tail: Vector2 = _snap(point - direction * sim.config.bolt_length)
		var enemy: bool = sim.ships[projectile.source].team != sim.ships[0].team
		draw_line(tail, point, PALETTE.danger if enemy else PALETTE.bolt, 4.0)
		draw_line(tail, point, PALETTE.spark_hot, sim.config.units_per_pixel)
		if enemy:
			draw_line(point - direction.orthogonal() * 4.0, point - direction * 6.0, PALETTE.danger, 2.0)
	_draw_impacts()


func _draw_ship(index: int) -> void:
	var ship: SpaceShipState = sim.ships[index]
	var point: Vector2 = _snap(ship.previous.lerp(ship.position, alpha))
	var angle: float = lerp_angle(ship.previous_angle, ship.angle, alpha)
	var direction: Vector2 = Vector2.from_angle(angle)
	var boosting: bool = ship.boost_tick >= 0
	if not ship.data.immobile and (absf(ship.thrust) > 0.01 or boosting):
		var length: float = sim.config.engine_length * (2.0 if boosting else absf(ship.thrust))
		var base: Vector2 = point - direction * 32.0
		var tail: Vector2 = base - direction * length
		draw_line(_snap(base), _snap(tail), Color(PALETTE.menu_blade_b, 0.3), 12.0)
		draw_line(_snap(base), _snap(tail), PALETTE.menu_blade_b, 6.0)
		draw_line(_snap(base), _snap(base.lerp(tail, 0.6)), PALETTE.spark_hot, 2.0)
	var size: Vector2 = ship.data.sprite.get_size() * sim.config.units_per_pixel
	var scale: Vector2 = Vector2(0.65, 1.0) if boosting else Vector2.ONE
	if boosting and not reduced:
		for echo in range(1, 3):
			draw_set_transform(_snap(point - ship.boost_direction * echo * 22.0), angle + PI * 0.5, scale)
			draw_texture_rect(ship.data.sprite, Rect2(-size * 0.5, size), false, Color(PALETTE.text, 0.12 / echo))
	draw_set_transform(point, angle + PI * 0.5, scale)
	draw_texture_rect(ship.data.sprite, Rect2(-size * 0.5, size), false)
	draw_set_transform(Vector2.ZERO)
	if ship.invulnerable(sim.config):
		for segment in 8:
			draw_arc(point, ship.data.radius + 8.0, segment * TAU / 8, (segment + 0.55) * TAU / 8, 3, PALETTE.menu_blade_a, 2.0)
	if index > 0:
		_draw_target(ship, point, direction)
	if debug:
		draw_arc(point, ship.data.radius, 0, TAU, 20, PALETTE.text, 2.0)
		draw_line(point, point + ship.velocity * 0.3, PALETTE.aurora, 2.0)
		draw_line(point, point + direction * 70.0, PALETTE.potential, 2.0)


func _draw_target(ship: SpaceShipState, point: Vector2, direction: Vector2) -> void:
	draw_line(point + Vector2(-20, 40), point + Vector2(20, 40), Color(PALETTE.secondary, 0.25), 2.0)
	draw_line(point + Vector2(-20, 40), point + Vector2(-20 + ship.hull / ship.data.hull * 40.0, 40), PALETTE.secondary, 2.0)
	draw_line(point + Vector2(-8, -44), point + Vector2(0, -38), PALETTE.accent, 2.0)
	draw_line(point + Vector2(8, -44), point + Vector2(0, -38), PALETTE.accent, 2.0)
	if ship.charges[0] >= 0 and ship.data.primary != null:
		var progress: float = clampf(float(ship.charges[0]) / maxi(Ticks.from_seconds(ship.data.primary.windup), 1), 0.0, 1.0)
		draw_arc(point, ship.data.radius + 12.0, -PI * 0.5, -PI * 0.5 + TAU * progress, 20, PALETTE.danger, 2.0)
		for dash in 8:
			var begin: Vector2 = point + direction * (ship.data.radius + 14.0 + dash * 24.0)
			draw_line(_snap(begin), _snap(begin + direction * 10.0), Color(PALETTE.danger, 0.35 + progress * 0.35), 2.0)


func _draw_trails() -> void:
	for index in _trail_left.size():
		if _trail_left[index] <= 0.0:
			continue
		var fade: float = ceilf(_trail_left[index] / sim.config.trail_seconds * 3.0) / 3.0
		var point: Vector2 = _snap(_trail_positions[index])
		draw_line(point, _snap(point - Vector2.from_angle(_trail_angles[index]) * 8.0), Color(PALETTE.menu_blade_b, fade * 0.35), sim.config.units_per_pixel)


func _draw_impacts() -> void:
	for index in _left.size():
		if _left[index] <= 0.0:
			continue
		var progress: float = 1.0 - _left[index] / _duration(_kinds[index])
		var fade: float = ceilf((1.0 - progress) * 3.0) / 3.0
		var point: Vector2 = _snap(_positions[index])
		if _kinds[index] == SpaceEvent.Type.SHIELD_HIT:
			draw_arc(point, 30.0 + progress * 8.0, _angles[index] - 1.1, _angles[index] + 1.1, 12, Color(PALETTE.menu_blade_a, fade), 4.0)
			continue
		var explosion: bool = _kinds[index] == SpaceEvent.Type.SHIP_DESTROYED
		var reach: float = (64.0 if explosion else 24.0) * progress
		var color: Color = Color(PALETTE.menu_blade_b if explosion else PALETTE.spark_warm, fade)
		if explosion and progress < 0.3:
			draw_rect(Rect2(point - Vector2.ONE * (18.0 - progress * 40.0), Vector2.ONE * (36.0 - progress * 80.0)), color)
		for fragment in (4 if reduced else FRAGMENTS):
			var direction: Vector2 = Vector2.from_angle(fragment * TAU / FRAGMENTS + index)
			draw_line(_snap(point + direction * reach), _snap(point + direction * (reach + 8.0)), color, 4.0 if explosion else 2.0)


func _duration(kind: int) -> float:
	return sim.config.shield_hit_seconds if kind == SpaceEvent.Type.SHIELD_HIT else sim.config.explosion_seconds if kind == SpaceEvent.Type.SHIP_DESTROYED else sim.config.hull_hit_seconds


func _snap(point: Vector2) -> Vector2:
	return (point / sim.config.units_per_pixel).round() * sim.config.units_per_pixel
