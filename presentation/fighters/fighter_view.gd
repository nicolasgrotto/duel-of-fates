class_name FighterView
extends Node2D

const PALETTE: UiPalette = preload("res://ui/palette.tres")
const HIP_HEIGHT: float = 72.0
const TORSO_LENGTH: float = 46.0
const NECK_LENGTH: float = 20.0
const HEAD_RADIUS: float = 12.0
const LEG_WIDTH: float = 11.0
const ARM_WIDTH: float = 7.0
const HILT_LENGTH: float = 12.0
const HILT_WIDTH: float = 5.0
const SHOULDER_HALF: float = 13.0
const HIP_HALF: float = 11.0
const TUNIC_HEM: float = 34.0
const HEM_HALF: float = 25.0
const FALL_DURATION: float = 0.6
const FALL_ANGLE: float = 1.45
const HIT_SHAKE: float = 2.5
const WALK_PHASE_PER_UNIT: float = 0.06
const SWAY_PER_SPEED: float = 0.03

var fighter: FighterState
var runner: TickRunner
var effects: EffectsConfig
var show_finishers: bool = true
var reduced_effects: bool = false

var _pose: FighterPose = FighterPose.new()
var _blade: BladeView
var _previous: Vector2 = Vector2.ZERO
var _current: Vector2 = Vector2.ZERO
var _time: float = 0.0
var _walk_phase: float = 0.0
var _flash_left: float = 0.0
var _death_time: float = -1.0
var _ignition: float = 1.0
var _extinguish: float = 0.0
var _missing_limb: MoveData.Limb = MoveData.Limb.NONE
var _severed: SeveredPiece


func setup(state: FighterState, tick_runner: TickRunner, effects_config: EffectsConfig) -> void:
	fighter = state
	runner = tick_runner
	effects = effects_config
	if _blade == null:
		_blade = BladeView.new()
		add_child(_blade)
	_blade.color = fighter.character.blade_color
	_blade.trail_duration = effects.trail_duration
	snap()


func snap() -> void:
	_current = Vector2(fighter.x, -fighter.y)
	_previous = _current
	position = _current


func reset_round(ignite: bool) -> void:
	_death_time = -1.0
	_missing_limb = MoveData.Limb.NONE
	_extinguish = 0.0
	_ignition = 0.0 if ignite else 1.0
	rotation = 0.0
	if _severed != null:
		_severed.queue_free()
		_severed = null
	snap()


func on_ticked() -> void:
	_previous = _current
	_current = Vector2(fighter.x, -fighter.y)


func on_event(event: CombatEvent) -> void:
	match event.type:
		CombatEvent.Type.ROUND_STARTED:
			reset_round(true)
		CombatEvent.Type.PARRY, CombatEvent.Type.PERFECT_PARRY:
			if event.target == fighter.index:
				_blade.flare = effects.parry_flare
		CombatEvent.Type.HIT, CombatEvent.Type.GUARD_BREAK:
			if event.target == fighter.index and not reduced_effects:
				_flash_left = effects.hit_flash_duration
		CombatEvent.Type.DEATH:
			if event.target == fighter.index:
				_start_death(event)


func _start_death(event: CombatEvent) -> void:
	_death_time = 0.0
	if not reduced_effects:
		_flash_left = effects.hit_flash_duration
	if show_finishers and event.limb != MoveData.Limb.NONE:
		_missing_limb = event.limb
		_severed = SeveredPiece.new()
		_severed.setup(event.limb, fighter.character, to_global(_limb_anchor(event.limb)), -fighter.facing if event.from_front else fighter.facing)
		get_parent().add_child(_severed)


func _process(delta: float) -> void:
	if fighter == null:
		return
	_time += delta
	_flash_left = maxf(_flash_left - delta, 0.0)
	var alpha: float = runner.alpha if runner != null else 1.0
	var shake: float = 0.0
	if fighter.freeze_ticks > 0 and fighter.state == FighterState.State.HIT:
		shake = randf_range(-HIT_SHAKE, HIT_SHAKE)
	position = _previous.lerp(_current, alpha) + Vector2(shake, 0.0)
	scale.x = fighter.facing
	if fighter.state == FighterState.State.WALKING:
		_walk_phase += absf(fighter.vx) * delta * WALK_PHASE_PER_UNIT
	_update_death(delta)
	_ignition = minf(_ignition + delta / effects.ignition, 1.0)
	_pose.compute(fighter, _time, _walk_phase)
	_update_blade()
	queue_redraw()


func _update_death(delta: float) -> void:
	if _death_time < 0.0:
		return
	_death_time += delta
	rotation = -fighter.facing * FALL_ANGLE * ease(minf(_death_time / FALL_DURATION, 1.0), 0.4)
	_extinguish = minf(_death_time / effects.extinguish, 1.0)


func _update_blade() -> void:
	_blade.base = _pose.hands + Vector2.from_angle(deg_to_rad(_pose.blade_angle)) * HILT_LENGTH * 0.5
	_blade.angle_degrees = _pose.blade_angle
	_blade.length_ratio = 0.0 if _missing_limb == MoveData.Limb.ARM else _ignition * (1.0 - _extinguish)
	_blade.tremble = _pose.tremble
	_blade.trail_active = _pose.trail


func _limb_anchor(limb: MoveData.Limb) -> Vector2:
	var hip: Vector2 = Vector2(0.0, -HIP_HEIGHT)
	match limb:
		MoveData.Limb.LEG:
			return hip + Vector2(10.0, HIP_HEIGHT * 0.6)
		MoveData.Limb.HEAD:
			return hip + Vector2(0.0, -TORSO_LENGTH - NECK_LENGTH)
	return _pose.hands


func _draw() -> void:
	if fighter == null:
		return
	var look: CharacterData = fighter.character
	var flash: float = 1.0 if _flash_left > 0.0 else 0.0
	var body: Color = look.body_color.lerp(PALETTE.hit_flash, flash)
	var cloak: Color = look.cloak_color.lerp(PALETTE.hit_flash, flash)
	var skin: Color = look.skin_color.lerp(PALETTE.hit_flash, flash)
	var hip: Vector2 = Vector2(0.0, -HIP_HEIGHT + _pose.crouch)
	var up: Vector2 = Vector2(0.0, -1.0).rotated(_pose.lean)
	var shoulder: Vector2 = hip + up * TORSO_LENGTH
	var head: Vector2 = hip + up * (TORSO_LENGTH + NECK_LENGTH)
	_draw_legs(hip, body)
	_draw_cloak(shoulder, up, cloak)
	_draw_torso(hip, shoulder, up, body)
	_draw_head(head, skin, cloak, look)
	_draw_arms(shoulder, body, skin)


func _draw_legs(hip: Vector2, color: Color) -> void:
	var front_foot: Vector2 = Vector2(14.0 + _pose.stride, 0.0)
	var back_foot: Vector2 = Vector2(-14.0 - _pose.stride, 0.0)
	if _pose.tuck > 0.0:
		front_foot = front_foot.lerp(hip + Vector2(14.0, 46.0), _pose.tuck)
		back_foot = back_foot.lerp(hip + Vector2(-6.0, 40.0), _pose.tuck)
	var front_knee: Vector2 = (hip + front_foot) * 0.5 + Vector2(8.0, 0.0)
	var back_knee: Vector2 = (hip + back_foot) * 0.5 + Vector2(4.0, 0.0)
	draw_polyline(PackedVector2Array([hip, back_knee, back_foot]), color.darkened(0.25), LEG_WIDTH)
	if _missing_limb == MoveData.Limb.LEG:
		draw_line(hip, front_knee, color, LEG_WIDTH)
		draw_circle(front_knee, LEG_WIDTH * 0.5, PALETTE.ember)
	else:
		draw_polyline(PackedVector2Array([hip, front_knee, front_foot]), color, LEG_WIDTH)


func _draw_cloak(shoulder: Vector2, up: Vector2, color: Color) -> void:
	var side: Vector2 = up.orthogonal()
	var hem_y: float = -2.0 if fighter.character.cloak_to_floor else -TUNIC_HEM + _pose.crouch * 0.5
	var sway: float = clampf(-fighter.vx * SWAY_PER_SPEED * fighter.facing, -14.0, 14.0)
	var hem_back: Vector2 = Vector2(-HEM_HALF - 4.0 + sway, hem_y)
	var hem_front: Vector2 = Vector2(HEM_HALF - 6.0 + sway * 0.5, hem_y)
	var points: PackedVector2Array = [shoulder - side * (SHOULDER_HALF + 2.0), shoulder + side * (SHOULDER_HALF + 2.0)]
	if fighter.character.cloak_to_floor:
		var steps: int = 6
		for i in steps + 1:
			var t: float = float(i) / steps
			var point: Vector2 = hem_back.lerp(hem_front, t)
			point.y -= 9.0 if i % 2 == 1 else 0.0
			points.append(point)
	else:
		points.append(hem_back)
		points.append(hem_front)
	draw_colored_polygon(points, color)


func _draw_torso(hip: Vector2, shoulder: Vector2, up: Vector2, color: Color) -> void:
	var side: Vector2 = up.orthogonal()
	var torso: PackedVector2Array = [
		hip - side * HIP_HALF, hip + side * HIP_HALF,
		shoulder + side * SHOULDER_HALF, shoulder - side * SHOULDER_HALF,
	]
	draw_colored_polygon(torso, color)


func _draw_head(head: Vector2, skin: Color, cloak: Color, look: CharacterData) -> void:
	if _missing_limb == MoveData.Limb.HEAD:
		draw_circle(head + Vector2(0.0, HEAD_RADIUS), 4.0, PALETTE.ember)
		return
	if look.hood_up:
		var hood: PackedVector2Array = [
			head + Vector2(-HEAD_RADIUS - 5.0, HEAD_RADIUS + 4.0),
			head + Vector2(-HEAD_RADIUS - 2.0, -HEAD_RADIUS),
			head + Vector2(-HEAD_RADIUS - 10.0, -HEAD_RADIUS - 14.0),
			head + Vector2(HEAD_RADIUS + 1.0, -HEAD_RADIUS - 1.0),
			head + Vector2(HEAD_RADIUS + 4.0, HEAD_RADIUS + 4.0),
		]
		draw_colored_polygon(hood, cloak)
		draw_circle(head + Vector2(5.0, 2.0), HEAD_RADIUS * 0.55, skin.darkened(0.6))
	else:
		draw_circle(head, HEAD_RADIUS, skin)
		draw_arc(head, HEAD_RADIUS, PI * 0.95, PI * 2.15, 12, look.hair_color, 6.0)


func _draw_arms(shoulder: Vector2, body: Color, skin: Color) -> void:
	var hands: Vector2 = _pose.hands
	var back_shoulder: Vector2 = shoulder + Vector2(-6.0, 2.0)
	var elbow: Vector2 = (back_shoulder + hands) * 0.5 + Vector2(-2.0, 10.0)
	draw_polyline(PackedVector2Array([back_shoulder, elbow, hands]), body.darkened(0.2), ARM_WIDTH)
	var front_shoulder: Vector2 = shoulder + Vector2(6.0, 0.0)
	var front_elbow: Vector2 = (front_shoulder + hands) * 0.5 + Vector2(4.0, 10.0)
	if _missing_limb == MoveData.Limb.ARM:
		draw_line(front_shoulder, front_elbow, body, ARM_WIDTH)
		draw_circle(front_elbow, ARM_WIDTH * 0.5, PALETTE.ember)
		return
	draw_polyline(PackedVector2Array([front_shoulder, front_elbow, hands]), body, ARM_WIDTH)
	draw_circle(hands, ARM_WIDTH * 0.6, skin)
	var direction: Vector2 = Vector2.from_angle(deg_to_rad(_pose.blade_angle))
	draw_line(hands - direction * HILT_LENGTH * 0.5, hands + direction * HILT_LENGTH * 0.5, fighter.character.hilt_color, HILT_WIDTH)
