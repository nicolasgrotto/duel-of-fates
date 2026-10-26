class_name FinisherPlayer
extends Node2D

const PALETTE: UiPalette = preload("res://ui/palette.tres")
const GRID: float = 2.0
const FADE_STEPS: float = 3.0
const EMBER_POOL: int = 48
const SMOKE_POOL: int = 12
const FALL_ANGLE: float = 1.45
const WAIST_SHARE: float = 0.3
const DIAGONAL_SHARE: float = 0.8
const DIAGONAL_NORMAL: Vector2 = Vector2(0.5, -0.87)
const EDGE_HALF: float = 16.0
const VERTICAL_EDGE_HALF: float = 46.0
const SMOKE_RISE: float = 30.0
const SMOKE_LIFE: float = 1.1
const BONE_WIDTH: float = 2.0
const SKULL_RADIUS: float = 6.0
const HOLE_SHARE: float = 0.7
const HOLE_OPEN_TIME: float = 0.1

var kind: Finisher.Kind = Finisher.Kind.NONE
var config: EffectsConfig
var view: FighterView
var rig: FighterRig
var half: FighterRig
var age: float = 0.0
var slide: float = 1.0

var _cut_point: Vector2 = Vector2.ZERO
var _cut_normal: Vector2 = Vector2.UP
var _edge_half: float = EDGE_HALF
var _ember_at: PackedVector2Array = []
var _ember_velocity: PackedVector2Array = []
var _ember_life: PackedFloat32Array = []
var _next_ember: int = 0
var _smoke_at: PackedVector2Array = []
var _smoke_age: PackedFloat32Array = []
var _next_smoke: int = 0
var _smoke_clock: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _away: int = 1
var _motion: FinisherMotion
var _split_as: Finisher.Kind = Finisher.Kind.NONE
var _split_offset: float = 0.0


func _init() -> void:
	_ember_at.resize(EMBER_POOL)
	_ember_velocity.resize(EMBER_POOL)
	_ember_life.resize(EMBER_POOL)
	_ember_life.fill(0.0)
	_smoke_at.resize(SMOKE_POOL)
	_smoke_age.resize(SMOKE_POOL)
	_smoke_age.fill(INF)
	z_index = FighterRig.BODY_DEPTH + 20


func start(owner_view: FighterView, finisher: Finisher.Kind, killer_x: float, style: FinisherStyle = null) -> void:
	view = owner_view
	rig = view.rig
	config = view.effects
	kind = finisher
	var away_world: float = signf(view.fighter.x - killer_x) if view.fighter.x != killer_x else -float(view.fighter.facing)
	var away_local: float = away_world * signf(view.scale.x)
	slide = -away_local if kind == Finisher.Kind.DASH_THROUGH or kind == Finisher.Kind.PULL_CUT else away_local
	_away = int(away_world)
	_split_as = kind
	_motion = FinisherMotion.for_kind(kind, style)
	if _motion != null:
		_fire(-1.0, 0.0)
	match kind:
		Finisher.Kind.BLAST:
			_burst(_local_point(rig.chest), config.blast_embers, config.ember_speed)
		Finisher.Kind.CHOKED:
			_burst(_local_point(rig.head_base), config.neck_embers, config.ember_speed * 0.6)
	if is_split():
		_prepare_split()


func is_split() -> bool:
	return (_split_as if _split_as != Finisher.Kind.NONE else kind) in [Finisher.Kind.DASH_THROUGH, Finisher.Kind.WAIST, Finisher.Kind.VERTICAL, Finisher.Kind.DIAGONAL, Finisher.Kind.PULL_CUT]


func moves_body() -> bool:
	return is_split() or kind == Finisher.Kind.BLAST


func fall_delay() -> float:
	if _motion != null:
		return _motion.reaction.fall_at
	return config.xray_time if kind == Finisher.Kind.CHARRED else 0.0


func fall_limb() -> MoveData.Limb:
	return MoveData.Limb.HEAD if _motion != null and not _motion.reaction.fall_backward else MoveData.Limb.NONE


func clear() -> void:
	if half != null:
		half.queue_free()
		half = null
	rig.set_clip(false)
	rig.set_charred(0.0)
	rig.set_xray(0.0)
	rig.show_hilt(true)
	kind = Finisher.Kind.NONE
	_split_as = Finisher.Kind.NONE
	queue_free()


func _prepare_split() -> void:
	match _split_as:
		Finisher.Kind.VERTICAL:
			_cut_point = rig.pelvis_point
			_cut_normal = Vector2.RIGHT
			_edge_half = VERTICAL_EDGE_HALF
		Finisher.Kind.DIAGONAL:
			_cut_point = rig.pelvis_point.lerp(rig.chest, DIAGONAL_SHARE)
			_cut_normal = DIAGONAL_NORMAL
		_:
			_cut_point = rig.pelvis_point.lerp(rig.chest, WAIST_SHARE)
			_cut_normal = Vector2.UP
	half = FighterRig.new()
	view.add_child(half)
	half.build(view.fighter.character, view.costume)
	half.wind = rig.wind
	var hand_in_half: bool = (rig.front_hand - _cut_point).dot(_cut_normal) > 0.0
	half.show_hilt(hand_in_half)
	rig.show_hilt(not hand_in_half)


func update(delta: float, pose: RigPose, facing: int) -> void:
	var before: float = age
	age += delta
	if _motion != null:
		_fire(before, age)
		var reaction: FinisherReaction = _motion.reaction
		if reaction.push_back != 0.0:
			rig.position.x += slide * reaction.push_back * smoothstep(reaction.push_at, reaction.push_at + reaction.push_time, age)
	var base: Transform2D = rig.transform
	if is_split():
		half.transform = _half_motion(base) * base
		half.apply(pose, facing, delta)
		rig.transform = _rest_motion(base) * base
		_apply_clip(rig, -_cut_normal)
		_apply_clip(half, _cut_normal)
		_emit_smoke(delta)
	match kind:
		Finisher.Kind.BLAST:
			rig.transform = _blast_motion(base) * base
		Finisher.Kind.CHARRED:
			var flicker: bool = int(age * config.xray_flicker) % 2 == 0
			rig.set_xray(0.0 if age >= config.xray_time else (1.0 if flicker else 0.55))
			rig.set_charred(smoothstep(config.xray_time, config.xray_time + config.char_time, age))
			if age >= config.xray_time:
				_emit_smoke(delta)
	_step_particles(delta)
	queue_redraw()


func _fire(before: float, now: float) -> void:
	var reaction: FinisherReaction = _motion.reaction
	if FinisherMotion.fired(reaction.front_arm_at, before, now):
		if reaction.drops_hilt:
			view.drop_hilt()
		view.sever_part(MoveData.Limb.ARM, true, _away)
	if FinisherMotion.fired(reaction.back_arm_at, before, now):
		view.sever_part(MoveData.Limb.ARM, false, _away)
	if FinisherMotion.fired(reaction.kneel_at, before, now):
		view.kneel()
	if FinisherMotion.fired(reaction.turn_at, before, now):
		view.turn_around()
	if FinisherMotion.fired(reaction.head_at, before, now):
		view.sever_part(MoveData.Limb.HEAD, true, _away)
		_burst(_local_point(rig.head_base), config.neck_embers, config.ember_speed * 0.6)
	if FinisherMotion.fired(reaction.split_at, before, now):
		_split_as = Finisher.Kind.VERTICAL
		_split_offset = reaction.split_at
		_prepare_split()


func _split_clock() -> float:
	return age - _split_offset


func _apply_clip(target: FighterRig, normal: Vector2) -> void:
	var global_pose: Transform2D = target.get_global_transform()
	target.set_clip(true, global_pose * _cut_point, global_pose.basis_xform(normal).normalized())


func _pivot(base: Transform2D, local: Vector2) -> Vector2:
	return base * local


func _rotation_about(pivot: Vector2, angle: float, offset: Vector2) -> Transform2D:
	return Transform2D(0.0, pivot + offset) * Transform2D(angle, Vector2.ZERO) * Transform2D(0.0, -pivot)


func _half_motion(base: Transform2D) -> Transform2D:
	var pivot: Vector2 = _pivot(base, _cut_point)
	var after: float = maxf(_split_clock() - config.finisher_hold, 0.0)
	match _split_as:
		Finisher.Kind.PULL_CUT:
			return _fling(pivot, _split_clock())
		Finisher.Kind.VERTICAL:
			var ground: Vector2 = Vector2(pivot.x, 0.0)
			return _rotation_about(ground, minf(after * config.finisher_topple_speed, FALL_ANGLE), Vector2(config.finisher_slide_distance * 0.3, 0.0))
	var sliding: float = smoothstep(0.0, config.finisher_slide_time, after)
	var along: Vector2 = Vector2(slide, 0.0)
	if _split_as == Finisher.Kind.DIAGONAL:
		along = Vector2(-DIAGONAL_NORMAL.y, DIAGONAL_NORMAL.x) * signf(slide * -DIAGONAL_NORMAL.y)
	var offset: Vector2 = along * config.finisher_slide_distance * sliding
	var falling: float = maxf(after - config.finisher_slide_time, 0.0)
	var angle: float = slide * minf(falling * config.finisher_topple_speed, FALL_ANGLE)
	offset.y += minf(0.5 * config.finisher_drop_gravity * falling * falling, -pivot.y * 0.85)
	return _rotation_about(pivot, angle, offset)


func _fling(pivot: Vector2, time: float) -> Transform2D:
	var speed: Vector2 = Vector2(config.finisher_fling_speed.x * slide, config.finisher_fling_speed.y)
	var offset: Vector2 = speed * time + Vector2(0.0, 0.5 * config.finisher_fling_gravity * time * time)
	var floor_offset: float = -pivot.y * 0.85
	var angle: float = slide * config.finisher_fling_spin * time
	var gravity: float = config.finisher_fling_gravity
	var landing: float = (-speed.y + sqrt(speed.y * speed.y + 2.0 * gravity * maxf(floor_offset, 0.0))) / gravity
	if time >= landing:
		var skid: float = minf(time - landing, config.finisher_fling_skid)
		var skid_distance: float = skid - skid * skid / (2.0 * maxf(config.finisher_fling_skid, Ticks.DELTA))
		offset = Vector2(speed.x * (landing + skid_distance), floor_offset)
		angle = slide * FALL_ANGLE
	return _rotation_about(pivot, angle, offset)


func _rest_motion(base: Transform2D) -> Transform2D:
	var feet: Vector2 = _pivot(base, Vector2.ZERO)
	if _split_as == Finisher.Kind.VERTICAL:
		var after: float = maxf(_split_clock() - config.finisher_hold, 0.0)
		var ground: Vector2 = Vector2(_pivot(base, _cut_point).x, 0.0)
		return _rotation_about(ground, -minf(after * config.finisher_topple_speed, FALL_ANGLE), Vector2(-config.finisher_slide_distance * 0.3, 0.0))
	var push: float = 0.0
	if _split_as == Finisher.Kind.PULL_CUT:
		push = slide * config.finisher_fling_speed.x * 0.4 * minf(_split_clock(), config.finisher_lower_delay)
	var sinking: float = maxf(_split_clock() - config.finisher_lower_delay, 0.0)
	return _rotation_about(feet, -slide * minf(sinking * config.finisher_topple_speed, FALL_ANGLE), Vector2(push, 0.0))


func _blast_motion(base: Transform2D) -> Transform2D:
	var progress: float = clampf(age / config.blast_time, 0.0, 1.0)
	var pivot: Vector2 = _pivot(base, rig.pelvis_point)
	var away: float = -slide if slide != 0.0 else 1.0
	var offset: Vector2 = Vector2(slide * config.blast_distance * (1.0 - pow(1.0 - progress, 2.0)), -config.blast_arc * sin(PI * progress))
	return _rotation_about(pivot, -away * FALL_ANGLE * progress, offset)


func _local_point(rig_point: Vector2) -> Vector2:
	return to_local(rig.to_global(rig_point))


func _burst(at: Vector2, count: int, speed: float) -> void:
	for i in count:
		var angle: float = -PI * 0.5 + _rng.randf_range(-1.3, 1.3)
		_ember_at[_next_ember] = at
		_ember_velocity[_next_ember] = Vector2.from_angle(angle) * speed * _rng.randf_range(0.4, 1.0)
		_ember_life[_next_ember] = config.ember_life * _rng.randf_range(0.5, 1.0)
		_next_ember = (_next_ember + 1) % EMBER_POOL


func _emit_smoke(delta: float) -> void:
	_smoke_clock += delta
	if _smoke_clock < config.finisher_smoke_interval:
		return
	_smoke_clock = 0.0
	var at: Vector2 = _local_point(_cut_point) if is_split() else _local_point(rig.chest)
	_smoke_at[_next_smoke] = at + Vector2(_rng.randf_range(-6.0, 6.0), 0.0)
	_smoke_age[_next_smoke] = 0.0
	_next_smoke = (_next_smoke + 1) % SMOKE_POOL


func _step_particles(delta: float) -> void:
	for i in EMBER_POOL:
		if _ember_life[i] <= 0.0:
			continue
		_ember_life[i] -= delta
		_ember_velocity[i].y += config.finisher_fling_gravity * 0.5 * delta
		_ember_at[i] += _ember_velocity[i] * delta
	for i in SMOKE_POOL:
		_smoke_age[i] += delta


func _draw() -> void:
	if is_split():
		_draw_edge(rig)
		_draw_edge(half)
	if kind == Finisher.Kind.CHARRED and age < config.xray_time and int(age * config.xray_flicker) % 2 == 0:
		_draw_skeleton()
	if _motion != null and _motion.effects.hole and age >= _motion.effects.hole_at:
		_draw_hole()
	for i in EMBER_POOL:
		if _ember_life[i] <= 0.0:
			continue
		var heat: float = _banded(_ember_life[i] / config.ember_life)
		var color: Color = PALETTE.ember_hot.lerp(PALETTE.ember, 1.0 - heat)
		draw_rect(Rect2(_ember_at[i].snapped(Vector2(GRID, GRID)), Vector2(GRID, GRID)), Color(color, heat))
	for i in SMOKE_POOL:
		var progress: float = _smoke_age[i] / SMOKE_LIFE
		if progress >= 1.0:
			continue
		draw_circle(_smoke_at[i] + Vector2(0.0, -SMOKE_RISE * progress), 4.0 + 6.0 * progress, Color(PALETTE.smoke, 0.3 * _banded(1.0 - progress)))


func _draw_edge(piece: FighterRig) -> void:
	var tangent: Vector2 = _cut_normal.orthogonal()
	var from: Vector2 = to_local(piece.to_global(_cut_point - tangent * _edge_half / piece.scale.y))
	var to: Vector2 = to_local(piece.to_global(_cut_point + tangent * _edge_half / piece.scale.y))
	var color: Color = _cooling_color()
	draw_line(from, to, Color(color, 0.35), config.finisher_edge_width * 2.0)
	draw_line(from, to, color, config.finisher_edge_width)


func _draw_hole() -> void:
	var at: Vector2 = _local_point(rig.pelvis_point.lerp(rig.chest, HOLE_SHARE)).snapped(Vector2(GRID, GRID))
	var color: Color = _cooling_color()
	var radius: float = config.stab_hole_radius * minf((age - _motion.effects.hole_at) / HOLE_OPEN_TIME, 1.0)
	draw_circle(at, radius * 1.8, Color(color, 0.35))
	draw_circle(at, radius, color)
	draw_circle(at, radius * 0.45, PALETTE.scar)


func _cooling_color() -> Color:
	var cooling: float = clampf(age / config.finisher_edge_cooling, 0.0, 1.0)
	return PALETTE.ember_hot.lerp(PALETTE.ember, minf(cooling * 2.0, 1.0)).lerp(PALETTE.scar, maxf(cooling * 2.0 - 1.0, 0.0))


func _draw_skeleton() -> void:
	var lines: PackedVector2Array = rig.skeleton_lines()
	for i in range(0, lines.size(), 2):
		draw_line(_local_point(lines[i]), _local_point(lines[i + 1]), PALETTE.xray_bone, BONE_WIDTH)
	draw_arc(_local_point(rig.head_base + Vector2(0.0, -SKULL_RADIUS / rig.scale.y)), SKULL_RADIUS, 0.0, TAU, 12, PALETTE.xray_bone, BONE_WIDTH)


func _banded(value: float) -> float:
	return ceilf(clampf(value, 0.0, 1.0) * FADE_STEPS) / FADE_STEPS
