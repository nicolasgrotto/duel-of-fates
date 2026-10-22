class_name FighterView
extends Node2D

const FALL_DURATION: float = 0.6
const FALL_ANGLE: float = 1.45
const HIT_SHAKE: float = 2.5
const WALK_PHASE_PER_UNIT: float = 0.06
const ATTACK_FOLLOW: float = 60.0
const POSE_FOLLOW: float = 16.0
const FLIP_DURATION: float = 0.42
const LIGHT_ENERGY: float = 1.1
const LIGHT_SCALE: float = 2.8
const LIGHT_HEIGHT: float = 40.0
const LIGHT_TEXTURE_SIZE: int = 256
const CHARGE_FLARE: float = 0.08

var fighter: FighterState
var opponent: FighterState
var runner: TickRunner
var effects: EffectsConfig
var costume: CostumeData
var show_finishers: bool = true
var reduced_effects: bool = false

var rig: FighterRig
var blade: BladeView
var afterimages: Afterimages
var _light: PointLight2D
var _solver: PoseSolver = PoseSolver.new()
var _target: RigPose = RigPose.new()
var _pose: RigPose = RigPose.new()
var _geometry: WeaponPose = WeaponPose.new()
var _previous: Vector2 = Vector2.ZERO
var _current: Vector2 = Vector2.ZERO
var _flash_left: float = 0.0
var _death_time: float = -1.0
var _ignition: float = 1.0
var _extinguish: float = 0.0
var _snap_pose: bool = true
var _severed: SeveredPiece
var _lost_blade: bool = false


func setup(state: FighterState, other: FighterState, tick_runner: TickRunner, effects_config: EffectsConfig, glow_layer: Node, look: CostumeData, reflect: bool) -> void:
	fighter = state
	opponent = other
	runner = tick_runner
	effects = effects_config
	if rig == null or costume != look:
		costume = look
		_build(glow_layer)
	blade.reflect = reflect
	snap()


func set_blade_color(color: Color) -> void:
	blade.color = color
	_light.color = color
	afterimages.color = color


func _build(glow_layer: Node) -> void:
	if rig != null:
		rig.queue_free()
	rig = FighterRig.new()
	add_child(rig)
	rig.build(fighter.character, costume)
	_solver.setup(fighter.character, fighter.character.art)
	if blade == null:
		blade = BladeView.new()
		blade.z_index = 5
		glow_layer.add_child(blade)
		afterimages = Afterimages.new()
		glow_layer.add_child(afterimages)
		_light = PointLight2D.new()
		_light.texture = _light_gradient()
		_light.texture_scale = LIGHT_SCALE
		_light.height = LIGHT_HEIGHT
		add_child(_light)
	blade.trail_duration = effects.trail_duration
	blade.width_scale = fighter.character.weapon.blade_width
	blade.eyes_color = costume.color(CostumeData.Slot.EYES)
	set_blade_color(fighter.character.blade_colors[0])


func _exit_tree() -> void:
	if blade != null:
		blade.queue_free()
		afterimages.queue_free()


func snap() -> void:
	_current = Vector2(fighter.x, -fighter.y)
	_previous = _current
	position = _current
	_snap_pose = true


func reset_round(ignite: bool) -> void:
	_death_time = -1.0
	_lost_blade = false
	_extinguish = 0.0
	_ignition = 0.0 if ignite else 1.0
	rotation = 0.0
	rig.restore()
	rig.reset_cloths()
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
		CombatEvent.Type.PARRY, CombatEvent.Type.PERFECT_PARRY, CombatEvent.Type.RESPONSE:
			if event.target == fighter.index:
				blade.flare = effects.parry_flare
		CombatEvent.Type.HIT, CombatEvent.Type.GUARD_BREAK, CombatEvent.Type.BLADE_LOCK_ENDED:
			if event.target == fighter.index and not reduced_effects:
				_flash_left = effects.hit_flash_duration
		CombatEvent.Type.JUMP:
			if event.source == fighter.index and event.amount >= 2.0:
				_solver.flip_progress = 0.0
		CombatEvent.Type.LAND:
			if event.source == fighter.index:
				_solver.landing_left = PoseSolver.LANDING_TIME
				_solver.flip_progress = -1.0
		CombatEvent.Type.DEATH:
			if event.target == fighter.index:
				_start_death(event)


func _start_death(event: CombatEvent) -> void:
	_death_time = 0.0
	if not reduced_effects:
		_flash_left = effects.hit_flash_duration
	if show_finishers and event.limb != MoveData.Limb.NONE:
		_severed = SeveredPiece.new()
		get_parent().add_child(_severed)
		_severed.setup(rig, event.limb, -fighter.facing if event.from_front else fighter.facing)
		rig.sever(event.limb)
		_lost_blade = event.limb == MoveData.Limb.ARM


func _process(delta: float) -> void:
	if fighter == null:
		return
	_flash_left = maxf(_flash_left - delta, 0.0)
	var alpha: float = runner.alpha if runner != null else 1.0
	var shake: float = 0.0
	if fighter.freeze_ticks > 0 and fighter.state == FighterState.State.HIT:
		shake = randf_range(-HIT_SHAKE, HIT_SHAKE)
	position = _previous.lerp(_current, alpha) + Vector2(shake, 0.0)
	scale.x = fighter.facing
	_advance_solver(delta)
	var frozen: bool = fighter.state == FighterState.State.HELD and not fighter.held_by_choke
	if not frozen:
		_solver.solve(fighter, opponent, _target)
		var follow: float = ATTACK_FOLLOW if fighter.is_attacking() else POSE_FOLLOW
		if _snap_pose:
			_pose.copy_from(_target)
			_snap_pose = false
		else:
			_pose.blend_toward(_target, 1.0 - exp(-follow * delta))
	_update_death(delta)
	_ignition = minf(_ignition + delta / effects.ignition, 1.0)
	rig.rotation = _pose.spin
	rig.position = _pose.pelvis - _pose.pelvis.rotated(_pose.spin) if _pose.spin != 0.0 else Vector2.ZERO
	rig.apply(_pose, fighter.facing, delta)
	rig.set_flash(1.0 if _flash_left > 0.0 else 0.0)
	rig.set_wound(fighter.wound)
	rig.set_blade_out(fighter.blade_out)
	_update_blade()
	if fighter.state == FighterState.State.DODGING and not reduced_effects:
		afterimages.capture(rig, delta)


func _advance_solver(delta: float) -> void:
	_solver.time += delta
	_solver.landing_left = maxf(_solver.landing_left - delta, 0.0)
	if _solver.flip_progress >= 0.0:
		_solver.flip_progress = minf(_solver.flip_progress + delta / FLIP_DURATION, 1.0)
	if fighter.state == FighterState.State.WALKING:
		_solver.walk_phase += absf(fighter.vx) * delta * WALK_PHASE_PER_UNIT


func _update_death(delta: float) -> void:
	if _death_time < 0.0:
		return
	_death_time += delta
	rotation = -FALL_ANGLE * ease(minf(_death_time / FALL_DURATION, 1.0), 0.4) * fighter.facing
	_extinguish = minf(_death_time / effects.extinguish, 1.0)


func _update_blade() -> void:
	_geometry.compute(fighter.character.weapon, _pose)
	var global_pose: Transform2D = rig.get_global_transform()
	_geometry.blade_base = global_pose * _geometry.blade_base
	_geometry.blade_direction = (global_pose.basis_xform(_geometry.blade_direction)).normalized()
	_geometry.second_base = global_pose * _geometry.second_base
	_geometry.second_direction = (global_pose.basis_xform(_geometry.second_direction)).normalized()
	_geometry.blade_length *= rig.scale.x
	_geometry.second_length *= rig.scale.x
	blade.length_ratio = 0.0 if _lost_blade or fighter.blade_out else _ignition * (1.0 - _extinguish)
	blade.tremble = _pose.tremble
	if fighter.charge_level > 1:
		blade.flare = maxf(blade.flare, CHARGE_FLARE * (fighter.charge_level - 1))
	blade.set_blades(_geometry, _pose.trail, _pose.off_trail or (_pose.trail and fighter.character.weapon.kind == WeaponData.Kind.STAFF))
	blade.eyes_visible = rig.shows_eyes() and _death_time < 0.0
	blade.eyes_position = rig.to_global(rig.eye_position())
	_light.global_position = blade.center()
	_light.energy = LIGHT_ENERGY * blade.length_ratio * (1.0 + blade.flare * 4.0)


func _light_gradient() -> GradientTexture2D:
	var gradient: Gradient = Gradient.new()
	gradient.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	gradient.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = LIGHT_TEXTURE_SIZE
	texture.height = LIGHT_TEXTURE_SIZE
	return texture


func hand_position(front: bool) -> Vector2:
	return rig.to_global(rig.front_hand if front else rig.back_hand)


func chest_position() -> Vector2:
	return rig.to_global(rig.chest)


func head_position() -> Vector2:
	return rig.to_global(rig.head_base + Vector2(0.0, -14.0))


func body_center() -> Vector2:
	return global_position + Vector2(0.0, -75.0)
