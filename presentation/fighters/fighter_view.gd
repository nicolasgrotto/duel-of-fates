class_name FighterView
extends Node2D

signal finisher_cue(cue: FinisherCue, at: Vector2)

const FALL_DURATION: float = 0.6
const FALL_ANGLE: float = 1.45
const KNEEL_TIME: float = 0.45
const LEG_FALL_SPEED: float = 0.7
const HIT_SHAKE: float = 2.5
const WALK_PHASE_PER_UNIT: float = 0.06
const ATTACK_FOLLOW: float = 60.0
const POSE_FOLLOW: float = 16.0
const LIGHT_ENERGY: float = 1.1
const LIGHT_SCALE: float = 2.8
const WEB_FEATURE: String = "web"
const LIGHT_HEIGHT: float = 40.0
const LIGHT_TEXTURE_SIZE: int = 256
const CHARGE_FLARE: float = 0.08
const TELEPORT_DISTANCE: float = 150.0
const MIN_TURN_WIDTH: float = 0.2
const HILT_DROP_TOSS: Vector2 = Vector2(70.0, -260.0)
const TRAVEL_DEPTH: int = -1
const PALETTE: UiPalette = preload("res://ui/palette.tres")

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
var _emitter_left: float = 0.0
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
var _second_ignition: float = 1.0
var _staging: bool = false
var _extinguish: float = 0.0
var _sheathed: bool = false
var _turned: bool = false
var _snap_pose: bool = true
var _severed: Array[SeveredPiece] = []
var _fall_limb: MoveData.Limb = MoveData.Limb.NONE
var _lost_blade: bool = false
var _finisher: FinisherPlayer
var _cutter: FinisherMotion
var _cutter_time: float = -1.0
var _borrowing: bool = false
var _borrow_ignition: float = 0.0
var _borrow_weapon: WeaponData
var _borrow_colors: PackedColorArray = PackedColorArray()
var _geometry_hilt_from: Vector2 = Vector2.ZERO
var _geometry_hilt_to: Vector2 = Vector2.ZERO

var _travel_offset: float = 0.0
var _snap_travel: bool = false

var rival: FighterView
var loose_hilt: LooseHilt
var _prosthetics: Array[Vector2i] = []


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
	rig.set_hilt_button(color)
	_light.color = color
	afterimages.color = color


func _build(glow_layer: Node) -> void:
	if rig != null:
		rig.queue_free()
	rig = FighterRig.new()
	add_child(rig)
	rig.build(fighter.character, costume)
	_solver.setup(fighter.character, fighter.character.art)
	_solver.rival_lock_style = opponent.character.lock_style if opponent != null else CharacterData.LockStyle.BLADE
	if blade == null:
		blade = BladeView.new()
		blade.z_index = 5
		glow_layer.add_child(blade)
		afterimages = Afterimages.new()
		glow_layer.add_child(afterimages)
		_light = PointLight2D.new()
		_light.texture = _light_gradient()
		_light.texture_scale = effects.web_light_scale if OS.has_feature(WEB_FEATURE) else LIGHT_SCALE
		_light.height = LIGHT_HEIGHT
		add_child(_light)
	blade.trail_duration = effects.trail_duration
	blade.fade_steps = effects.fade_steps
	blade.glint_duration = effects.heavy_glint
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
	_sheathed = false
	_turned = false
	_ignition = 0.0 if ignite else 1.0
	_second_ignition = 1.0
	_staging = false
	_solver.intro_time = -1.0
	_solver.kneeling = false
	_solver.stop_motion()
	_cutter = null
	_cutter_time = -1.0
	_travel_offset = 0.0
	_snap_travel = false
	z_index = 0
	_release_borrowed(false)
	if loose_hilt != null:
		loose_hilt.queue_free()
		loose_hilt = null
	rig.remove_intro_cloak()
	rotation = 0.0
	if _finisher != null:
		_finisher.clear()
		_finisher = null
	rig.restore()
	rig.clear_prosthetics()
	for lost in _prosthetics:
		rig.set_prosthetic(lost.x as MoveData.Limb, lost.y == 1)
	rig.reset_cloths()
	for piece in _severed:
		piece.queue_free()
	_severed.clear()
	_fall_limb = MoveData.Limb.NONE
	snap()


func on_ticked() -> void:
	_previous = _current
	_current = Vector2(fighter.x, -fighter.y)
	if _snap_travel:
		_previous = _current
		_snap_travel = false
	if _previous.distance_to(_current) > TELEPORT_DISTANCE:
		snap()
		rig.reset_cloths()


func on_event(event: CombatEvent) -> void:
	match event.type:
		CombatEvent.Type.ROUND_STARTED:
			reset_round(true)
		CombatEvent.Type.PARRY, CombatEvent.Type.PERFECT_PARRY, CombatEvent.Type.RESPONSE:
			if event.target == fighter.index:
				blade.flare = effects.parry_flare
				_solver.guard_recoiled(event.heavy, true)
		CombatEvent.Type.BLOCK:
			if event.target == fighter.index:
				blade.flare = effects.parry_flare * fighter.character.family.block_parry_recoil
				_solver.guard_recoiled(event.heavy, false)
		CombatEvent.Type.PROJECTILE_SPAWNED:
			if event.source == fighter.index and int(event.amount) == Projectile.Kind.BOLT:
				_emitter_left = effects.emitter_flash
		CombatEvent.Type.BOLT_BLOCKED:
			if event.target == fighter.index and event.power == null:
				blade.flare = effects.parry_flare * fighter.character.family.block_parry_recoil
		CombatEvent.Type.BOLT_REFLECTED:
			if event.source == fighter.index:
				blade.flare = effects.parry_flare
				_solver.guard_recoiled(false, true)
		CombatEvent.Type.CLASH, CombatEvent.Type.TECHNIQUE_CLASH:
			if event.source == fighter.index or event.target == fighter.index:
				_solver.clash_left = PoseSolver.CLASH_RECOIL_TIME
				_solver.rebounding = true
				if event.type == CombatEvent.Type.TECHNIQUE_CLASH:
					_solver.start_tumble()
		CombatEvent.Type.HIT, CombatEvent.Type.GUARD_BREAK, CombatEvent.Type.BLADE_LOCK_ENDED, CombatEvent.Type.BLADE_PRESS_ENDED, CombatEvent.Type.BOLT_HIT:
			if event.target == fighter.index and not reduced_effects:
				_flash_left = effects.hit_flash_duration
			if event.type != CombatEvent.Type.HIT and event.type != CombatEvent.Type.GUARD_BREAK and event.type != CombatEvent.Type.BOLT_HIT and event.target == fighter.index:
				_solver.start_tumble()
		CombatEvent.Type.POWER_HIT:
			if event.target == fighter.index and event.power != null and (event.power.kind == PowerData.Kind.REPULSE or event.power.kind == PowerData.Kind.SUPREME_PUSH):
				_solver.start_tumble()
		CombatEvent.Type.ATTACK_STARTED:
			if event.source == fighter.index and event.heavy:
				blade.glint = effects.heavy_glint
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
			elif event.source == fighter.index and show_finishers:
				_start_cutter_pose(event)


func _start_death(event: CombatEvent) -> void:
	_death_time = 0.0
	if not reduced_effects:
		_flash_left = effects.hit_flash_duration
	_fall_limb = event.limb if show_finishers else MoveData.Limb.NONE
	if show_finishers and event.finisher != Finisher.Kind.NONE:
		_finisher = FinisherPlayer.new()
		add_child(_finisher)
		_finisher.start(self, event.finisher, opponent.x, rival.fighter.character.finisher_style if rival != null else null)
		_fall_limb = _finisher.fall_limb()
		return
	if show_finishers and event.limb != MoveData.Limb.NONE and (event.limb == MoveData.Limb.ARM or event.limb == MoveData.Limb.LEG):
		_prosthetics.append(Vector2i(event.limb, 1 if event.from_front else 0))
	if show_finishers and event.limb != MoveData.Limb.NONE:
		var away: int = -fighter.facing if event.from_front else fighter.facing
		_spawn_piece(event.limb, event.from_front, away)
		rig.sever(event.limb, event.from_front)
		_lost_blade = rig.lost_main_hand()


func _start_cutter_pose(event: CombatEvent) -> void:
	if Finisher.is_staged(event.finisher):
		_cutter = FinisherMotion.for_kind(event.finisher, fighter.character.finisher_style)
		_solver.start_motion(_cutter)
		_cutter_time = 0.0 if _cutter != null else -1.0
		if _cutter != null and _cutter.travels():
			_travel_offset = _current.x - fighter.x
			_snap_travel = true
		return
	if event.finisher != Finisher.Kind.DASH_THROUGH and event.finisher != Finisher.Kind.PULL_CUT:
		return
	_solver.finish_hold_left = effects.finisher_cutter_pose
	if event.finisher != Finisher.Kind.DASH_THROUGH or reduced_effects:
		return
	var streak: SlashStreak = SlashStreak.new()
	var lift: Vector2 = Vector2(0.0, -effects.finisher_streak_height)
	streak.from_point = global_position + lift
	streak.to_point = Vector2(fighter.x, -fighter.y) + lift
	streak.color = blade.color
	streak.life = effects.finisher_streak_time
	streak.width = effects.finisher_streak_width
	get_parent().add_child(streak)


func sever_part(limb: MoveData.Limb, front: bool, away: int) -> void:
	_spawn_piece(limb, front, away)
	rig.sever(limb, front)
	_lost_blade = rig.lost_main_hand()


func kneel() -> void:
	_solver.kneeling = true


func turn_around() -> void:
	_turned = true


func _fall_facing() -> int:
	return -fighter.facing if _turned else fighter.facing


func drop_hilt() -> void:
	if loose_hilt != null:
		return
	loose_hilt = LooseHilt.new()
	get_parent().add_child(loose_hilt)
	loose_hilt.setup(fighter.character.weapon.hilt_length, rig.hilt_colors())
	loose_hilt.drop(rig.hilt_segment(), Vector2(-fighter.facing * HILT_DROP_TOSS.x, HILT_DROP_TOSS.y))


func _update_cutter(delta: float) -> void:
	if _borrowing:
		_borrow_ignition = minf(_borrow_ignition + delta / effects.ignition, 1.0)
	if _cutter == null:
		return
	var before: float = _cutter_time
	_cutter_time += delta
	var effects_layer: FinisherEffects = _cutter.effects
	for streak_at in effects_layer.streaks:
		if FinisherMotion.fired(streak_at, before, _cutter_time) and not reduced_effects:
			_add_streak(_geometry.blade_base, _geometry.tip(), blade.color)
			if effects_layer.streaks_both and _geometry.has_second:
				_add_streak(_geometry.second_base, _geometry.second_base + _geometry.second_direction * _geometry.second_length, blade.second_color if blade.own_second_color else blade.color)
	for cue in _cutter.cues:
		if FinisherMotion.fired(cue.time, before, _cutter_time):
			finisher_cue.emit(cue, blade.center())
	if FinisherMotion.fired(_cutter.pull_at, before, _cutter_time) and rival != null and rival.loose_hilt != null:
		rival.loose_hilt.pull(_off_hand_position, _cutter.catch_at - _cutter.pull_at)
	if FinisherMotion.fired(_cutter.catch_at, before, _cutter_time) and rival != null and rival.loose_hilt != null:
		_borrow(rival)
	for shot_at in effects_layer.shots:
		if FinisherMotion.fired(shot_at, before, _cutter_time):
			_finisher_shot()
	if FinisherMotion.fired(_cutter.extinguish_at, before, _cutter_time):
		_sheathed = true
	if FinisherMotion.fired(_cutter.release_at, before, _cutter_time):
		_release_borrowed(true)
	if _cutter_time > _cutter.end_time() and not _borrowing:
		_cutter = null
		_travel_offset = 0.0
		z_index = 0


func _travel_shift() -> float:
	if _travel_offset == 0.0 or _cutter == null:
		return 0.0
	var progress: float = smoothstep(_cutter.travel_from, _cutter.travel_to, _cutter_time)
	z_index = TRAVEL_DEPTH if progress < 1.0 else 0
	return _travel_offset * (1.0 - progress)


func _faces_back() -> bool:
	return _travel_offset != 0.0 and _cutter != null and _cutter.travel_faces_back and _cutter_time < (_cutter.travel_from + _cutter.travel_to) * 0.5


func _off_hand_position() -> Vector2:
	return rig.to_global(_pose.off_hand)


func _borrow(lender: FighterView) -> void:
	_borrowing = true
	_borrow_ignition = 0.0
	_borrow_weapon = lender.fighter.character.weapon
	_borrow_colors = lender.rig.hilt_colors()
	blade.second_color = lender.blade.color
	blade.own_second_color = true


func _release_borrowed(drop: bool) -> void:
	if not _borrowing:
		return
	_borrowing = false
	blade.own_second_color = false
	rig.hold_borrowed_hilt(false)
	if drop and rival != null and rival.loose_hilt != null:
		var segment: PackedVector2Array = PackedVector2Array([rig.to_global(_geometry_hilt_from), rig.to_global(_geometry_hilt_to)])
		rival.loose_hilt.drop(segment, Vector2(fighter.facing * HILT_DROP_TOSS.x, HILT_DROP_TOSS.y))


func _apply_borrowed() -> void:
	if not _borrowing or _geometry.has_second:
		return
	var direction: Vector2 = Vector2.from_angle(deg_to_rad(_pose.off_blade_angle))
	var half: Vector2 = direction * _borrow_weapon.hilt_length * 0.5
	_geometry_hilt_from = _pose.off_hand - half
	_geometry_hilt_to = _pose.off_hand + half
	_geometry.has_second = true
	_geometry.second_hilt_from = _geometry_hilt_from
	_geometry.second_hilt_to = _geometry_hilt_to
	_geometry.second_base = _geometry_hilt_to
	_geometry.second_direction = direction
	_geometry.second_length = _borrow_weapon.blade_length
	rig.hold_borrowed_hilt(true, _geometry_hilt_from, _geometry_hilt_to, _borrow_colors)


func _finisher_shot() -> void:
	if rival == null or not is_instance_valid(rival):
		return
	_emitter_left = effects.emitter_flash
	var muzzle: Vector2 = rig.to_global(_pose.off_hand) if fighter.character.weapon.sidearm == WeaponData.Sidearm.BLASTER else _geometry.blade_base
	var streak: SlashStreak = SlashStreak.new()
	streak.from_point = muzzle
	streak.to_point = rival.rig.to_global(rival.rig.chest)
	streak.color = PALETTE.bolt
	streak.life = effects.finisher_shot_time
	streak.width = effects.finisher_shot_width
	get_parent().add_child(streak)


func _add_streak(from_point: Vector2, to_point: Vector2, tint: Color) -> void:
	var streak: SlashStreak = SlashStreak.new()
	streak.from_point = from_point
	streak.to_point = to_point
	streak.color = tint
	streak.life = effects.finisher_streak_time
	streak.width = effects.finisher_streak_width
	get_parent().add_child(streak)


func _spawn_piece(limb: MoveData.Limb, front: bool, away: int) -> void:
	var piece: SeveredPiece = SeveredPiece.new()
	get_parent().add_child(piece)
	piece.setup(rig, limb, away, front)
	_severed.append(piece)


func _process(delta: float) -> void:
	if fighter == null:
		return
	_flash_left = maxf(_flash_left - delta, 0.0)
	_emitter_left = maxf(_emitter_left - delta, 0.0)
	var alpha: float = runner.alpha if runner != null else 1.0
	var shake: float = 0.0
	if fighter.freeze_ticks > 0 and fighter.state == FighterState.State.HIT:
		shake = randf_range(-HIT_SHAKE, HIT_SHAKE)
	position = _previous.lerp(_current, alpha) + Vector2(shake + _travel_shift(), 0.0)
	_advance_solver(delta)
	_check_vault()
	scale.x = -fighter.facing if (_solver.vault_turned() and _solver.vault_progress < 1.0 and not fighter.on_ground) or _faces_back() else fighter.facing
	if _turned:
		scale.x = -scale.x
	_update_intro()
	var frozen: bool = fighter.state == FighterState.State.HELD and not fighter.held_by_choke
	if not frozen:
		_observe_guard()
		_solver.solve(fighter, opponent, _target)
		var follow: float = ATTACK_FOLLOW if fighter.is_attacking() else POSE_FOLLOW
		if fighter.state == FighterState.State.CASTING and fighter.power != null and fighter.power.kind == PowerData.Kind.REPULSE and fighter.power_phase != FighterState.Phase.STARTUP:
			follow = ATTACK_FOLLOW
		if _snap_pose or fighter.state == FighterState.State.BLOCKING:
			_pose.copy_from(_target)
			_snap_pose = false
		else:
			_pose.blend_toward(_target, 1.0 - exp(-follow * delta))
	_update_death(delta)
	if not _staging:
		_ignition = maxf(_ignition - delta / effects.ignition, 0.0) if _sheathed else minf(_ignition + delta / effects.ignition, 1.0)
		_second_ignition = 1.0
	rig.rotation = _pose.spin
	rig.scale.x = fighter.character.art.dim("scale") * _turn_factor(_pose.turn)
	rig.position = _pose.pelvis - _pose.pelvis.rotated(_pose.spin) if _pose.spin != 0.0 else Vector2.ZERO
	if _finisher != null:
		_finisher.update(delta, _pose, fighter.facing)
	rig.apply(_pose, fighter.facing, delta)
	rig.set_flash(1.0 if _flash_left > 0.0 else 0.0)
	if fighter.character.weapon.sidearm == WeaponData.Sidearm.HILT_EMITTER:
		rig.set_emitter_glow(_emitter_left / maxf(effects.emitter_flash, 0.001), PALETTE.bolt)
	rig.set_wound(fighter.wound)
	rig.set_blade_out(fighter.blade_out)
	_update_blade()
	_update_cutter(delta)
	if (fighter.state == FighterState.State.DODGING or _solver.afterimage) and not reduced_effects:
		afterimages.capture(rig, delta)


func blade_segment() -> PackedVector2Array:
	if _geometry.blade_length <= 0.0 or blade.length_ratio <= 0.0:
		return PackedVector2Array()
	if fighter.state == FighterState.State.BLOCKING and (fighter.character.weapon.kind == WeaponData.Kind.STAFF or fighter.character.weapon.kind == WeaponData.Kind.LANCE):
		return PackedVector2Array([rig.to_global(_geometry.hilt_from), rig.to_global(_geometry.hilt_to)])
	return PackedVector2Array([active_blade_base(), active_blade_tip()])


func active_blade_base() -> Vector2:
	return _geometry.second_base if _uses_off_blade() else _geometry.blade_base


func active_blade_tip() -> Vector2:
	return _geometry.second_base + _geometry.second_direction * _geometry.second_length if _uses_off_blade() else _geometry.tip()


func _uses_off_blade() -> bool:
	return _geometry.has_second and fighter.character.weapon.kind == WeaponData.Kind.DUAL and fighter.is_attacking() and fighter.move != null and fighter.move.kind == MoveData.Kind.LIGHT and fighter.chain_index % 2 == 1


func _observe_guard() -> void:
	_solver.guard.has_live = false
	_solver.bolt_contact = -1.0
	if _observe_bolt():
		return
	if rival == null or not is_instance_valid(rival) or rival.blade == null or rival.blade.length_ratio <= 0.0 or opponent.blade_out:
		return
	_solver.guard.observe_segment(to_local(rival.active_blade_base()), to_local(rival.active_blade_tip()))


func _observe_bolt() -> bool:
	var sim: MatchSimulation = runner.sim
	var closest: Projectile = null
	var soonest: float = effects.bolt_guard_lead
	for projectile in sim.projectiles:
		if not projectile.active or projectile.kind != Projectile.Kind.BOLT or projectile.owner == fighter.index or projectile.vx == 0.0:
			continue
		var ahead: float = (fighter.x - projectile.x) * signf(projectile.vx)
		if ahead <= 0.0:
			continue
		var seconds: float = maxf(ahead - sim.config.body_width * 0.5, 0.0) / absf(projectile.vx)
		if seconds < soonest:
			soonest = seconds
			closest = projectile
	if closest == null:
		return false
	var head: Vector2 = Vector2(closest.x, -closest.y)
	var heading: Vector2 = Vector2(closest.vx, -closest.vy).normalized()
	_solver.guard.observe_segment(to_local(head - heading * effects.bolt_guard_segment), to_local(head))
	_solver.bolt_contact = soonest
	return true


func guard_debug_lines() -> PackedStringArray:
	return _solver.guard_debug_lines()


static func _turn_factor(turn: float) -> float:
	if turn == 0.0:
		return 1.0
	var factor: float = cos(turn)
	return signf(factor) * maxf(absf(factor), MIN_TURN_WIDTH) if factor != 0.0 else MIN_TURN_WIDTH


func _update_intro() -> void:
	var sim: MatchSimulation = runner.sim
	var intro: IntroData = fighter.character.intro
	var staging: bool = intro != null and sim.phase == MatchSimulation.Phase.INTRO and sim.plays_fighter_intros()
	if not staging:
		if _staging:
			rig.remove_intro_cloak()
		_staging = false
		_solver.intro_time = -1.0
		return
	var time: float = Ticks.to_seconds(sim.phase_ticks)
	var title: bool = sim.phase_ticks >= sim.intro_title_tick()
	if title and _solver.intro_time >= 0.0 and _solver.intro_time < intro.last_time() + intro.blend_time:
		_snap_pose = true
	if not _staging and intro.wears_cloak and not title:
		rig.wear_intro_cloak()
	_staging = true
	_solver.intro = intro
	_solver.intro_time = time
	_ignition = clampf((time - intro.ignite_at) / effects.ignition, 0.0, 1.0)
	_second_ignition = clampf((time - intro.second_ignition()) / effects.ignition, 0.0, 1.0)
	if intro.hood_down_at >= 0.0:
		rig.lower_hood(clampf((time - intro.hood_down_at) / effects.hood_lower_time, 0.0, 1.0), effects.hood_lower_offset, effects.units_per_pixel)
	if intro.cloak_drop_at >= 0.0 and time >= intro.cloak_drop_at:
		rig.shed_cloak(Vector2(-fighter.facing * effects.cloak_fling.x, effects.cloak_fling.y))
		var opacity: float = 1.0 - clampf((time - intro.cloak_drop_at) / effects.cloak_fade_time, 0.0, 1.0)
		rig.fade_intro_cloak(ceilf(opacity * effects.fade_steps) / effects.fade_steps)
	if title:
		rig.remove_intro_cloak()


func finisher_debug_line() -> String:
	var playing: String = Finisher.Kind.keys()[_finisher.kind] if _finisher != null else "-"
	return "finisher %s  cutter %.2f  borrowed %s %.2f  kneel %s  limb %s" % [playing, _cutter_time, _borrowing, _borrow_ignition, _solver.kneeling, MoveData.Limb.keys()[fighter.finisher_limb]]


func intro_debug_lines() -> PackedStringArray:
	return PackedStringArray([
		"intro %s  time %.2f / %.2f" % [_staging, _solver.intro_time, runner.sim.intro_seconds()],
		"ignition %.2f / %.2f  hood %s  cloak %s" % [_ignition, _second_ignition, rig._intro_hood != null and rig._intro_hood.visible, rig._intro_cloak != null and rig._intro_cloak.visible],
	])


func _check_vault() -> void:
	if fighter.on_ground:
		_solver.vault_progress = -1.0
		return
	if _solver.vault_progress >= 0.0 or fighter.state != FighterState.State.JUMPING:
		return
	var crossed: bool = (opponent.x - fighter.x) * fighter.facing < 0.0
	if crossed and fighter.y > opponent.y + fighter.character.family.stance_width:
		_solver.vault_progress = 0.0


func _advance_solver(delta: float) -> void:
	_solver.advance(delta)
	if _solver.flip_progress >= 0.0:
		_solver.flip_progress = minf(_solver.flip_progress + delta / fighter.character.family.double_jump_time, 1.0)
	if fighter.state == FighterState.State.WALKING or (fighter.state == FighterState.State.BLOCKING and fighter.vx != 0.0):
		_solver.walk_phase += absf(fighter.vx) * delta * WALK_PHASE_PER_UNIT


func _update_death(delta: float) -> void:
	if _death_time < 0.0:
		return
	_death_time += delta
	_extinguish = minf(_death_time / effects.extinguish, 1.0)
	if _finisher != null:
		if _finisher.moves_body():
			return
		var delay: float = _finisher.fall_delay()
		if _death_time < delay:
			return
	var falling: float = _death_time - (_finisher.fall_delay() if _finisher != null else 0.0)
	match _fall_limb:
		MoveData.Limb.HEAD:
			var topple: float = clampf((falling - KNEEL_TIME) / FALL_DURATION, 0.0, 1.0)
			rotation = FALL_ANGLE * ease(topple, 2.2) * _fall_facing()
		MoveData.Limb.LEG:
			rotation = -FALL_ANGLE * ease(minf(falling / (FALL_DURATION * LEG_FALL_SPEED), 1.0), 1.8) * fighter.facing
		_:
			rotation = -FALL_ANGLE * ease(minf(falling / FALL_DURATION, 1.0), 0.4) * _fall_facing()


func _update_blade() -> void:
	_geometry.compute(fighter.character.weapon, _pose)
	_apply_borrowed()
	var global_pose: Transform2D = rig.get_global_transform()
	_geometry.blade_base = global_pose * _geometry.blade_base
	var main_span: Vector2 = global_pose.basis_xform(_geometry.blade_direction)
	var second_span: Vector2 = global_pose.basis_xform(_geometry.second_direction)
	_geometry.blade_direction = main_span.normalized()
	_geometry.second_base = global_pose * _geometry.second_base
	_geometry.second_direction = second_span.normalized()
	_geometry.blade_length *= main_span.length()
	_geometry.second_length *= second_span.length()
	blade.length_ratio = 0.0 if _lost_blade or fighter.blade_out else _ignition * (1.0 - _extinguish)
	blade.second_ratio = _borrow_ignition if _borrowing else _second_ignition
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
