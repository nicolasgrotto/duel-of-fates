class_name PoseSolver
extends RefCounted

const HIP_HEIGHT_FALLBACK: float = 72.0
const BLOCK_GRIP: Vector2 = Vector2(18.0, -36.0)
const BLOCK_ANGLE: float = -84.0
const LOCK_GRIP: Vector2 = Vector2(22.0, -44.0)
const LOCK_ANGLE: float = -62.0
const HIT_GRIP: Vector2 = Vector2(6.0, -20.0)
const HIT_ANGLE: float = 52.0
const STUN_GRIP: Vector2 = Vector2(12.0, -8.0)
const STUN_ANGLE: float = 96.0
const WINDUP_GRIP: Vector2 = Vector2(-6.0, -40.0)
const HEAVY_WINDUP_GRIP: Vector2 = Vector2(-8.0, -54.0)
const STRIKE_GRIP: Vector2 = Vector2(24.0, -28.0)
const STANCE_GRIP: Vector2 = Vector2(20.0, -30.0)
const STANCE_ANGLE: float = -35.0
const CAST_GRIP: Vector2 = Vector2(-8.0, -28.0)
const CAST_ANGLE: float = 150.0
const CAST_HAND: Vector2 = Vector2(32.0, -42.0)
const INVOKE_HAND: Vector2 = Vector2(10.0, -88.0)
const INVOKE_ANGLE: float = 100.0
const GROUND_HAND: Vector2 = Vector2(26.0, 6.0)
const SELF_HAND: Vector2 = Vector2(14.0, -38.0)
const CHOKED_GRIP: Vector2 = Vector2(8.0, -50.0)
const CHOKED_HAND: Vector2 = Vector2(4.0, -54.0)
const TREMOR: float = 1.2
const RELAXED_HAND: Vector2 = Vector2(-4.0, -30.0)
const SHOVE_HAND: Vector2 = Vector2(34.0, -38.0)
const TUCK_FRONT: Vector2 = Vector2(14.0, -20.0)
const TUCK_BACK: Vector2 = Vector2(-10.0, -26.0)
const EXHAUSTED_DROP: float = 16.0
const OFF_HAND_SPACING: float = 5.5
const LANCE_SPACING: float = 22.0
const STAFF_SPACING: float = 11.0
const LANDING_CROUCH: float = 12.0
const LANDING_TIME: float = 0.12
const HEAVY_SCALE: float = 1.6
const ANTICIPATION_EASE: float = 2.4
const SWING_SMOOTHING: float = 0.35
const FOLLOW_SHARE: float = 0.35
const ARC_CENTER: Vector2 = Vector2(-2.0, -34.0)
const MAX_FROM_REACH: float = 60.0
const HIT_DECAY: float = 9.0
const REBOUND_GRIP: Vector2 = Vector2(4.0, -50.0)
const REBOUND_ANGLE: float = -125.0
const HIT_LEAN: float = -26.0
const CLASH_RECOIL_TIME: float = 0.22
const CLASH_LEAN: float = 12.0
const CLASH_SHIFT: float = 6.0
const CLASH_BLADE: float = 22.0
const LOCK_FACE_HEIGHT: float = 66.0
const LOCK_SLIDE: float = 7.0
const LOCK_PUSH: float = 5.0
const LOCK_PULSE_DECAY: float = 10.0
const JUMP_APEX_SPEED: float = 260.0

var character: CharacterData
var family: MotionFamily
var hip_height: float = HIP_HEIGHT_FALLBACK
var time: float = 0.0
var walk_phase: float = 0.0
var flip_progress: float = -1.0
var landing_left: float = 0.0

var _attack_key: int = -1
var _from_angle: float = 0.0
var _from_grip: Vector2 = Vector2.ZERO
var _body_shift: float = 0.0
var _head_snap: float = 0.0
var _lock_presses: int = 0
var _lock_pulse: float = 0.0
var clash_left: float = 0.0
var rebounding: bool = false


func setup(data: CharacterData, art: FighterArt) -> void:
	character = data
	family = data.family
	if art != null:
		hip_height = art.dim("thigh") + art.dim("shin") + art.dim("ankle")


func advance(delta: float) -> void:
	time += delta
	landing_left = maxf(landing_left - delta, 0.0)
	clash_left = maxf(clash_left - delta, 0.0)
	_lock_pulse = maxf(_lock_pulse - delta * LOCK_PULSE_DECAY, 0.0)


func solve(fighter: FighterState, opponent: FighterState, pose: RigPose) -> void:
	var guard_angle: float = character.guard_angle
	var guard_grip: Vector2 = character.guard_grip
	if fighter.exhausted:
		guard_angle += EXHAUSTED_DROP
		guard_grip.y += EXHAUSTED_DROP * 0.5
	_track_attack(fighter, pose, guard_angle, guard_grip)
	if fighter.state != FighterState.State.HIT and clash_left == 0.0:
		rebounding = false
	_body_shift = 0.0
	_head_snap = 0.0
	var breath: float = sin(time * 2.2) * family.breath * (2.0 if fighter.exhausted else 1.0)
	var crouch: float = family.crouch + breath + LANDING_CROUCH * clampf(landing_left / LANDING_TIME, 0.0, 1.0)
	var lean: float = family.lean + (6.0 if fighter.exhausted else 0.0)
	pose.spin = 0.0
	pose.tremble = false
	pose.trail = false
	pose.off_trail = false
	pose.grip = guard_grip
	pose.blade_angle = guard_angle + sin(time * 1.3) * family.sway
	pose.front_foot = Vector2(family.stance_width * 0.5, 0.0)
	pose.back_foot = Vector2(-family.stance_width * 0.5, 0.0)
	pose.off_hand = RELAXED_HAND
	var off_free: bool = false
	match fighter.state:
		FighterState.State.WALKING:
			_walk(fighter, pose)
			crouch += absf(sin(walk_phase)) * family.bob
		FighterState.State.JUMPING:
			_jump_pose(fighter, pose)
		FighterState.State.ATTACKING, FighterState.State.HEAVY_ATTACK:
			var extra: Vector2 = _attack(fighter, pose, guard_angle, guard_grip)
			crouch += extra.x
			lean += extra.y
			off_free = fighter.move != null and fighter.move.kind == MoveData.Kind.SHOVE
		FighterState.State.BLOCKING:
			pose.grip = BLOCK_GRIP
			pose.blade_angle = BLOCK_ANGLE
			crouch += 4.0
		FighterState.State.DODGING:
			var dodge: Vector2 = _dodge(fighter, pose)
			crouch += dodge.x
			lean += dodge.y
		FighterState.State.BLADE_LOCK:
			var lock: Vector2 = _blade_lock(fighter, opponent, pose)
			crouch += lock.x
			lean = lock.y
		FighterState.State.HIT:
			var jolt: float = exp(-Ticks.to_seconds(fighter.state_ticks) * HIT_DECAY)
			lean = HIT_LEAN * (0.4 + 0.6 * jolt)
			crouch += 6.0 * jolt
			if rebounding:
				pose.grip = guard_grip.lerp(REBOUND_GRIP, jolt)
				pose.blade_angle = lerpf(guard_angle, REBOUND_ANGLE, jolt)
			else:
				pose.grip = guard_grip.lerp(HIT_GRIP, 0.4 + 0.6 * jolt)
				pose.blade_angle = lerpf(guard_angle, HIT_ANGLE, 0.5 + 0.5 * jolt)
			pose.back_foot.x -= 8.0 * jolt
			pose.front_foot.y = -4.0 * jolt
			_head_snap = -0.5 * jolt
			_body_shift = -6.0 * jolt
			off_free = true
		FighterState.State.STAGGERED:
			var wobble: float = sin(time * 7.0)
			lean = -14.0 + wobble * 5.0
			pose.grip = guard_grip + Vector2(-14.0, 12.0 + wobble * 3.0)
			pose.blade_angle = guard_angle + 40.0 + wobble * 8.0
			pose.front_foot.x += 4.0
			pose.back_foot.x -= 6.0
			pose.front_foot.y = -maxf(wobble, 0.0) * 3.0
			_head_snap = -0.25
			pose.tremble = true
			off_free = true
		FighterState.State.STUNNED:
			lean = 30.0
			crouch += 12.0
			pose.grip = STUN_GRIP
			pose.blade_angle = STUN_ANGLE + sin(time * 1.6) * 5.0
			off_free = true
		FighterState.State.DEAD:
			pose.grip = HIT_GRIP
			pose.blade_angle = HIT_ANGLE
			off_free = true
		FighterState.State.CASTING, FighterState.State.CHANNELING:
			var cast: Vector2 = _cast(fighter, pose)
			crouch += cast.x
			lean += cast.y
		FighterState.State.HELD:
			if fighter.held_by_choke:
				pose.grip = CHOKED_GRIP
				pose.off_hand = CHOKED_HAND
				pose.blade_angle = STUN_ANGLE
				pose.front_foot = Vector2(6.0, 8.0)
				pose.back_foot = Vector2(-4.0, 12.0)
				lean = -10.0
	if fighter.is_airborne() and fighter.state != FighterState.State.JUMPING:
		_tuck(pose, 0.7)
	pose.pelvis = Vector2(_body_shift, -hip_height + crouch)
	if clash_left > 0.0:
		var recoil: float = clash_left / CLASH_RECOIL_TIME
		lean -= CLASH_LEAN * recoil
		_body_shift -= CLASH_SHIFT * recoil
		pose.grip += Vector2(-CLASH_SHIFT, -4.0) * recoil
		pose.blade_angle -= CLASH_BLADE * recoil
		pose.pelvis.x = _body_shift
	pose.torso_angle = deg_to_rad(lean)
	pose.head_angle = -pose.torso_angle * 0.55 + _head_snap
	pose.grip += pose.pelvis
	if off_free and pose.off_hand == RELAXED_HAND:
		pose.off_hand = RELAXED_HAND + pose.pelvis
	elif pose.off_hand == RELAXED_HAND:
		_place_off_hand(fighter, pose)
	else:
		pose.off_hand += pose.pelvis


func _walk(fighter: FighterState, pose: RigPose) -> void:
	var backward: bool = signf(fighter.vx) != float(fighter.facing) and fighter.vx != 0.0
	var phase: float = walk_phase * (-1.0 if backward else 1.0)
	pose.front_foot.x += sin(phase) * family.stride
	pose.front_foot.y = -maxf(cos(phase), 0.0) * 5.0
	pose.back_foot.x -= sin(phase) * family.stride
	pose.back_foot.y = -maxf(-cos(phase), 0.0) * 5.0


func _blade_lock(fighter: FighterState, opponent: FighterState, pose: RigPose) -> Vector2:
	if fighter.lock_presses > _lock_presses:
		_lock_pulse = 1.0
	_lock_presses = fighter.lock_presses
	var pressure: float = clampf(float(fighter.lock_presses - opponent.lock_presses) / 5.0, -1.0, 1.0)
	var push: float = _lock_pulse
	var half: float = maxf(absf(opponent.x - fighter.x) * 0.5, 20.0)
	pose.grip = LOCK_GRIP + Vector2(pressure * LOCK_SLIDE * 0.5 + push * LOCK_PUSH, -pressure * 3.0)
	var cross: Vector2 = Vector2(half + pressure * LOCK_SLIDE, -LOCK_FACE_HEIGHT)
	pose.blade_angle = rad_to_deg((cross - pose.grip).angle())
	pose.front_foot.x = family.stance_width * 0.35
	pose.back_foot.x = -family.stance_width * 0.75 - maxf(pressure, 0.0) * 6.0
	pose.tremble = true
	_body_shift = pressure * 4.0 + push * 2.0
	var lean: float = family.lock_lean * (1.0 + pressure * 0.5) + push * 4.0
	return Vector2(family.lock_crouch - pressure * 4.0, lean)


func _jump_pose(fighter: FighterState, pose: RigPose) -> void:
	var rise: float = clampf(fighter.vy / JUMP_APEX_SPEED, -1.0, 1.0)
	if rise > 0.0:
		_tuck(pose, 1.0 - rise * 0.55)
		pose.back_foot += Vector2(-6.0, 4.0) * rise
	else:
		_tuck(pose, 1.0 + rise * 0.45)
		pose.front_foot += Vector2(4.0, 6.0) * -rise
	if flip_progress >= 0.0 and family.flip_on_double_jump:
		pose.spin = TAU * ease(flip_progress, 0.6)


func _tuck(pose: RigPose, amount: float) -> void:
	pose.front_foot = pose.front_foot.lerp(TUCK_FRONT, amount)
	pose.back_foot = pose.back_foot.lerp(TUCK_BACK, amount)


func _attack(fighter: FighterState, pose: RigPose, guard_angle: float, guard_grip: Vector2) -> Vector2:
	var move: MoveData = fighter.move
	if move == null:
		return Vector2.ZERO
	if move.kind == MoveData.Kind.STANCE:
		var ready: float = 1.0 if fighter.move_phase == FighterState.Phase.ACTIVE else 1.0 - _progress(fighter, move)
		pose.grip = guard_grip.lerp(STANCE_GRIP, ready)
		pose.blade_angle = lerpf(guard_angle, STANCE_ANGLE, ready)
		return Vector2(8.0 * ready, -4.0 * ready)
	if move.kind == MoveData.Kind.SHOVE:
		var push: float = _progress(fighter, move)
		var amount: float = ease(push, 0.5) if fighter.move_phase != FighterState.Phase.RECOVERY else 1.0 - push
		if fighter.move_phase == FighterState.Phase.ACTIVE:
			amount = 1.0
		pose.off_hand = RELAXED_HAND.lerp(SHOVE_HAND, amount)
		pose.grip = guard_grip + Vector2(-8.0, 4.0) * amount
		pose.front_foot.x += family.heavy_step * amount
		_body_shift = family.lunge * amount
		return Vector2(4.0 * amount, 16.0 * amount)
	var heavy: bool = move.is_heavy()
	var power: float = HEAVY_SCALE if heavy else 1.0
	var windup_grip: Vector2 = (HEAVY_WINDUP_GRIP if heavy else WINDUP_GRIP) * Vector2(family.windup_pull, 1.0)
	var strike_grip: Vector2 = STRIKE_GRIP * Vector2(family.strike_reach, 1.0)
	var progress: float = _progress(fighter, move)
	var crouch: float = 0.0
	var lean: float = 0.0
	var step: float = family.heavy_step if heavy else family.heavy_step * 0.5
	match fighter.move_phase:
		FighterState.Phase.STARTUP:
			var eased: float = 1.0 - pow(1.0 - progress, ANTICIPATION_EASE)
			pose.blade_angle = rad_to_deg(lerp_angle(deg_to_rad(_from_angle), deg_to_rad(move.blade_angle_windup), eased))
			pose.grip = _arc(_from_grip, windup_grip, eased)
			lean = family.windup_lean * power * eased
			crouch = family.heavy_crouch * 0.4 * power * eased
			_body_shift = -family.windup_shift * power * eased
			pose.back_foot.x -= 2.0 * power * eased
		FighterState.Phase.ACTIVE:
			var swing: float = lerpf(progress, smoothstep(0.0, 1.0, progress), SWING_SMOOTHING)
			pose.blade_angle = lerpf(move.blade_angle_windup, move.blade_angle_strike, swing)
			pose.grip = _arc(windup_grip, strike_grip, swing)
			lean = lerpf(family.windup_lean * power, family.strike_lean * power, swing)
			crouch = lerpf(family.heavy_crouch * 0.4, family.heavy_crouch, swing) * power
			_body_shift = lerpf(-family.windup_shift, family.lunge, swing) * power
			pose.front_foot.x += step * swing
			pose.back_foot.x -= 2.0 * power * (1.0 - swing)
			pose.trail = true
		FighterState.Phase.RECOVERY:
			var through: float = 1.0 - pow(1.0 - minf(progress / FOLLOW_SHARE, 1.0), 2.0)
			var settle: float = smoothstep(FOLLOW_SHARE * 0.6, 1.0, progress)
			var sweep: float = signf(move.blade_angle_strike - move.blade_angle_windup)
			var follow: float = move.blade_angle_strike + sweep * family.follow_through * through
			var follow_grip: Vector2 = strike_grip + Vector2(family.follow_through * 0.12, family.follow_through * 0.2 * sweep) * through
			pose.blade_angle = rad_to_deg(lerp_angle(deg_to_rad(follow), deg_to_rad(guard_angle), settle))
			pose.grip = _arc(follow_grip, guard_grip, settle)
			lean = family.strike_lean * power * (1.0 - settle)
			crouch = family.heavy_crouch * power * (1.0 - settle)
			_body_shift = family.lunge * power * (1.0 - settle)
			pose.front_foot.x += step * (1.0 - settle)
			if family.finisher_twirl and _is_last_chain(fighter):
				pose.blade_angle += 360.0 * smoothstep(0.1, 0.9, progress)
	if move.is_aerial():
		_tuck(pose, 0.8)
		_body_shift = 0.0
	return Vector2(crouch, lean)


func _arc(from: Vector2, to: Vector2, weight: float) -> Vector2:
	var chord: Vector2 = to - from
	var middle: Vector2 = (from + to) * 0.5
	var outward: Vector2 = (middle - ARC_CENTER)
	if outward.length_squared() < 0.01:
		outward = Vector2.RIGHT
	var control: Vector2 = middle + outward.normalized() * chord.length() * family.arc_bulge
	var a: Vector2 = from.lerp(control, weight)
	var b: Vector2 = control.lerp(to, weight)
	return a.lerp(b, weight)


func _track_attack(fighter: FighterState, pose: RigPose, guard_angle: float, guard_grip: Vector2) -> void:
	var key: int = -1
	if fighter.is_attacking() and fighter.move != null:
		key = fighter.move.get_instance_id() * 8 + fighter.chain_index
	if key == _attack_key:
		return
	_attack_key = key
	var started: bool = pose.grip != Vector2.ZERO and pose.pelvis != Vector2.ZERO
	_from_angle = pose.blade_angle if started else guard_angle
	_from_grip = pose.grip - pose.pelvis if started else guard_grip
	if _from_grip.length() > MAX_FROM_REACH:
		_from_grip = guard_grip


func _cast(fighter: FighterState, pose: RigPose) -> Vector2:
	var power: PowerData = fighter.power
	if power == null:
		return Vector2.ZERO
	var progress: float = clampf(float(fighter.power_ticks) / maxf(power.startup_ticks(), 1.0), 0.0, 1.0)
	if fighter.power_phase == FighterState.Phase.RECOVERY:
		progress = 1.0 - clampf(float(fighter.power_ticks) / maxf(power.recovery_ticks(), 1.0), 0.0, 1.0)
	elif fighter.power_phase == FighterState.Phase.ACTIVE:
		progress = 1.0
	var tremor: Vector2 = Vector2(sin(time * 41.0), cos(time * 37.0)) * TREMOR if fighter.state == FighterState.State.CHANNELING else Vector2.ZERO
	match power.kind:
		PowerData.Kind.STORM, PowerData.Kind.MASS_TELEKINESIS:
			pose.off_hand = RELAXED_HAND.lerp(INVOKE_HAND, progress) + tremor
			pose.grip = pose.grip.lerp(Vector2(10.0, -10.0), progress)
			pose.blade_angle = lerpf(pose.blade_angle, INVOKE_ANGLE, progress)
			return Vector2(0.0, -6.0 * progress)
		PowerData.Kind.FRACTURE:
			pose.off_hand = RELAXED_HAND.lerp(GROUND_HAND, progress)
			pose.grip = pose.grip.lerp(CAST_GRIP, progress)
			pose.blade_angle = lerpf(pose.blade_angle, CAST_ANGLE, progress)
			return Vector2(26.0 * progress, 30.0 * progress)
		PowerData.Kind.HEAL, PowerData.Kind.FOCUS, PowerData.Kind.WRATH, PowerData.Kind.SANCTUARY, PowerData.Kind.ARSENAL:
			pose.off_hand = RELAXED_HAND.lerp(SELF_HAND, progress)
			pose.blade_angle = lerpf(pose.blade_angle, INVOKE_ANGLE, progress * 0.6)
			return Vector2(4.0 * progress, 0.0)
		PowerData.Kind.FLOW_CLEAVE:
			pose.blade_angle = lerpf(-170.0, 60.0, ease(progress, 2.0))
			pose.grip = STRIKE_GRIP if progress > 0.5 else HEAVY_WINDUP_GRIP
			pose.trail = progress > 0.4 and fighter.power_phase == FighterState.Phase.STARTUP
			return Vector2(6.0, 12.0 * progress)
	pose.off_hand = RELAXED_HAND.lerp(CAST_HAND, progress) + tremor
	pose.grip = pose.grip.lerp(CAST_GRIP, progress)
	pose.blade_angle = lerpf(pose.blade_angle, CAST_ANGLE, progress)
	return Vector2(4.0 * progress, 10.0 * progress)


func _is_last_chain(fighter: FighterState) -> bool:
	return fighter.move.kind == MoveData.Kind.LIGHT and fighter.chain_index == character.light_chain.size() - 1


func _dodge(fighter: FighterState, pose: RigPose) -> Vector2:
	var toward: bool = fighter.dodge_direction == fighter.facing
	match fighter.dodge_kind:
		FighterState.DodgeKind.GROUND:
			if family.roll_on_dodge:
				var duration: float = 0.28
				pose.spin = TAU * clampf(Ticks.to_seconds(fighter.state_ticks) / duration, 0.0, 1.0) * (1.0 if toward else -1.0)
			return Vector2(16.0, 22.0 if toward else -20.0)
		FighterState.DodgeKind.AIR:
			_tuck(pose, 0.6)
			return Vector2(0.0, 28.0)
		FighterState.DodgeKind.DASH:
			return Vector2(14.0, 26.0 if toward else -18.0)
		FighterState.DodgeKind.EVADE:
			pose.back_foot.x -= 8.0
			return Vector2(12.0, -24.0 if fighter.evade_streak % 2 == 0 else -16.0)
	return Vector2.ZERO


func _place_off_hand(fighter: FighterState, pose: RigPose) -> void:
	var direction: Vector2 = pose.blade_direction()
	match family.grip:
		MotionFamily.Grip.TWO_HANDED:
			var spacing: float = LANCE_SPACING if character.weapon.kind == WeaponData.Kind.LANCE else OFF_HAND_SPACING
			pose.off_hand = pose.grip - direction * spacing
		MotionFamily.Grip.STAFF:
			pose.off_hand = pose.grip - direction * STAFF_SPACING
		MotionFamily.Grip.DUAL:
			pose.off_hand = pose.pelvis + Vector2(-6.0, -34.0)
			pose.off_blade_angle = 180.0 - pose.blade_angle * 0.4
			if fighter.is_attacking() and fighter.chain_index % 2 == 1:
				pose.off_hand = pose.grip + Vector2(6.0, 8.0)
				pose.off_blade_angle = pose.blade_angle + 20.0
				pose.off_trail = pose.trail
		MotionFamily.Grip.ONE_HANDED:
			pose.off_hand = RELAXED_HAND + pose.pelvis + Vector2(sin(time * 1.1) * 1.5, 0.0)


static func _progress(fighter: FighterState, move: MoveData) -> float:
	var length: int = 1
	match fighter.move_phase:
		FighterState.Phase.STARTUP:
			length = move.startup_ticks()
		FighterState.Phase.ACTIVE:
			length = move.active_ticks()
		FighterState.Phase.RECOVERY:
			length = move.recovery_ticks()
	return clampf(float(fighter.phase_ticks) / maxf(length, 1.0), 0.0, 1.0)
