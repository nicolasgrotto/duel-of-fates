class_name PoseSolver
extends RefCounted

const COMBAT: CombatConfig = preload("res://data/balance/combat_config.tres")
const HIP_HEIGHT_FALLBACK: float = 72.0
const BLOCK_GRIP: Vector2 = Vector2(18.0, -36.0)
const BLOCK_ANGLE: float = -84.0
const BLOCK_HIGH_GRIP: Vector2 = Vector2(14.0, -54.0)
const BLOCK_HIGH_ANGLE: float = -14.0
const BLOCK_LOW_GRIP: Vector2 = Vector2(18.0, -16.0)
const BLOCK_LOW_ANGLE: float = 74.0
const BLOCK_THRUST_GRIP: Vector2 = Vector2(22.0, -32.0)
const BLOCK_THRUST_ANGLE: float = -46.0
const HIGH_WINDUP_LIMIT: float = -100.0
const LOW_WINDUP_LIMIT: float = 45.0
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
const REPULSE_DRAW_HAND: Vector2 = Vector2(-2.0, -40.0)
const REPULSE_PALM_HAND: Vector2 = Vector2(42.0, -40.0)
const REPULSE_HOLD: float = 0.45
const PULL_CLAW_HAND: Vector2 = Vector2(-8.0, -42.0)
const PULL_HOLD: float = 0.5
const CLEAVE_HIGH_GRIP: Vector2 = Vector2(-12.0, -64.0)
const CLEAVE_HIGH_ANGLE: float = -140.0
const CLEAVE_FLOOR_GRIP: Vector2 = Vector2(30.0, 10.0)
const CLEAVE_FLOOR_ANGLE: float = 76.0
const CLEAVE_WINDUP_SHARE: float = 0.55
const CLEAVE_HOLD: float = 0.3
const REPULSE_RECOIL: float = 8.0
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
const SHOULDER_LEAD: float = 2.0
const CUT_WINDUP: Dictionary = {
	MoveData.Cut.DESCENDING: Vector2(-4.0, -50.0),
	MoveData.Cut.RISING: Vector2(-8.0, -4.0),
	MoveData.Cut.HORIZONTAL: Vector2(14.0, -36.0),
	MoveData.Cut.THRUST: Vector2(0.0, -34.0),
	MoveData.Cut.SPIN: Vector2(18.0, -36.0),
}
const CUT_STRIKE: Dictionary = {
	MoveData.Cut.DESCENDING: Vector2(24.0, -18.0),
	MoveData.Cut.RISING: Vector2(22.0, -46.0),
	MoveData.Cut.HORIZONTAL: Vector2(28.0, -34.0),
	MoveData.Cut.THRUST: Vector2(42.0, -32.0),
	MoveData.Cut.SPIN: Vector2(26.0, -34.0),
}
const HEAVY_CUT_LIFT: float = 8.0
const HORIZONTAL_TWIST: float = 2.5
const THRUST_SHIFT: float = 8.0
const OFF_SWAY: float = 6.0
const OFF_SWING: float = 40.0
const ARC_CENTER: Vector2 = Vector2(-2.0, -34.0)
const MAX_FROM_REACH: float = 60.0
const HIT_DECAY: float = 9.0
const KNEEL_DROP: float = 30.0
const WOUNDED_ARM_DROP: float = 18.0
const LIMP_DIP: float = 5.0
const LIMP_STRIDE: float = 0.45
const SPIN_GRIP: Vector2 = Vector2(22.0, -36.0)
const SPIN_ANGLE: float = -6.0
const DASH_LOW_TUCK_GRIP: Vector2 = Vector2(-14.0, -6.0)
const DASH_LOW_TUCK_ANGLE: float = 160.0
const DASH_HIGH_TUCK_GRIP: Vector2 = Vector2(-6.0, -46.0)
const DASH_HIGH_TUCK_ANGLE: float = -150.0
const DASH_RISING_GRIP: Vector2 = Vector2(26.0, -50.0)
const DASH_RISING_ANGLE: float = -60.0
const DASH_FALLING_GRIP: Vector2 = Vector2(28.0, -14.0)
const DASH_FALLING_ANGLE: float = 40.0
const DASH_HOLD: float = 0.35
const DASH_TWIRL_TURNS: float = 2.0
const THROW_WINDUP_GRIP: Vector2 = Vector2(-14.0, -44.0)
const THROW_RELEASE_GRIP: Vector2 = Vector2(40.0, -42.0)
const THROW_CATCH_HAND: Vector2 = Vector2(30.0, -44.0)
const DUAL_THROW_OFFSET: Vector2 = Vector2(-4.0, 12.0)
const CATCH_REACH: float = 0.6
const THRUST_CHAMBER_GRIP: Vector2 = Vector2(2.0, -36.0)
const THRUST_EXTEND_GRIP: Vector2 = Vector2(46.0, -34.0)
const THRUST_ANGLE: float = 0.0
const RISING_LOW_GRIP: Vector2 = Vector2(-12.0, -2.0)
const RISING_HIGH_GRIP: Vector2 = Vector2(14.0, -74.0)
const FLURRY_REACH: float = 36.0
const FLURRY_RISE: float = 14.0
const LUNGE_CHAMBER_GRIP: Vector2 = Vector2(-4.0, -6.0)
const LUNGE_EXTEND_GRIP: Vector2 = Vector2(52.0, -24.0)
const PLUNGE_RAISED_GRIP: Vector2 = Vector2(4.0, -56.0)
const PLUNGE_RAISED_ANGLE: float = -100.0
const PLUNGE_THRUST_GRIP: Vector2 = Vector2(16.0, -10.0)
const PLUNGE_THRUST_ANGLE: float = 70.0
const PLUNGE_CUT_GRIP: Vector2 = Vector2(26.0, 2.0)
const PLUNGE_CUT_ANGLE: float = 78.0
const PLUNGE_TILT: float = 0.45
const PLUNGE_CUT_SPEED: float = 5.0
const PLUNGE_THRUST_SPEED: float = 8.0
const PLUNGE_HOLD: float = 0.3
const PLUNGE_KNEEL: float = 26.0
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
const FLIP_EASE: float = 0.6
const FLIP_GRIP: Vector2 = Vector2(20.0, -30.0)
const FLIP_BLADE_ANGLE: float = -10.0
const TUMBLE_LIFT: float = 26.0
const SPIN_DODGE_GRIP: Vector2 = Vector2(-2.0, -18.0)
const SPIN_DODGE_ANGLE: float = 110.0
const SKID_CROUCH: float = 22.0
const SKID_LEAN: float = -20.0
const SKID_HAND: Vector2 = Vector2(-22.0, -2.0)

var character: CharacterData
var family: MotionFamily
var hip_height: float = HIP_HEIGHT_FALLBACK
var time: float = 0.0
var walk_phase: float = 0.0
var flip_progress: float = -1.0
var vault_progress: float = -1.0
var tumble_left: float = 0.0
var landing_left: float = 0.0

var _attack_key: int = -1
var _guard_angle: float = 0.0
var _guard_grip: Vector2 = Vector2.ZERO
var _from_angle: float = 0.0
var _from_grip: Vector2 = Vector2.ZERO
var _body_shift: float = 0.0
var _head_snap: float = 0.0
var _lock_presses: int = 0
var _lock_pulse: float = 0.0
var clash_left: float = 0.0
var rebounding: bool = false
var block_line: MoveData.Cut = MoveData.Cut.HORIZONTAL
var afterimage: bool = false


func setup(data: CharacterData, art: FighterArt) -> void:
	character = data
	family = data.family
	if art != null:
		hip_height = art.dim("thigh") + art.dim("shin") + art.dim("ankle")


func advance(delta: float) -> void:
	time += delta
	landing_left = maxf(landing_left - delta, 0.0)
	clash_left = maxf(clash_left - delta, 0.0)
	tumble_left = maxf(tumble_left - delta, 0.0)
	if vault_progress >= 0.0:
		vault_progress = minf(vault_progress + delta / family.vault_time, 1.0)
	_lock_pulse = maxf(_lock_pulse - delta * LOCK_PULSE_DECAY, 0.0)


func solve(fighter: FighterState, opponent: FighterState, pose: RigPose) -> void:
	var guard_angle: float = character.guard_angle
	var guard_grip: Vector2 = character.guard_grip
	if fighter.exhausted:
		guard_angle += EXHAUSTED_DROP
		guard_grip.y += EXHAUSTED_DROP * 0.5
	if fighter.wound == FighterState.Wound.ARM:
		guard_angle += WOUNDED_ARM_DROP
		guard_grip += Vector2(-3.0, WOUNDED_ARM_DROP * 0.45)
	_track_attack(fighter, pose, guard_angle, guard_grip)
	_guard_angle = guard_angle
	_guard_grip = guard_grip
	if fighter.state != FighterState.State.HIT and clash_left == 0.0:
		rebounding = false
	_body_shift = 0.0
	_head_snap = 0.0
	afterimage = false
	var breath: float = sin(time * 2.2) * family.breath * (2.0 if fighter.exhausted else 1.0)
	var crouch: float = family.crouch + breath + LANDING_CROUCH * clampf(landing_left / LANDING_TIME, 0.0, 1.0)
	var lean: float = family.lean + (6.0 if fighter.exhausted else 0.0)
	pose.spin = 0.0
	pose.turn = 0.0
	pose.open_hand = false
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
			if fighter.wound == FighterState.Wound.LEG:
				crouch += maxf(sin(walk_phase), 0.0) * LIMP_DIP
		FighterState.State.JUMPING:
			_jump_pose(fighter, pose)
		FighterState.State.ATTACKING, FighterState.State.HEAVY_ATTACK:
			var extra: Vector2 = _attack(fighter, pose, guard_angle, guard_grip)
			crouch += extra.x
			lean += extra.y
			off_free = fighter.move != null and fighter.move.kind == MoveData.Kind.SHOVE
		FighterState.State.BLOCKING:
			_block(opponent, pose)
			crouch += 4.0 if block_line != MoveData.Cut.RISING else 8.0
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
			match fighter.finisher_limb:
				MoveData.Limb.HEAD:
					crouch += KNEEL_DROP
					lean = 16.0
					pose.front_foot = Vector2(14.0, 0.0)
					pose.back_foot = Vector2(-20.0, 0.0)
					pose.grip = STUN_GRIP
					pose.blade_angle = STUN_ANGLE
				MoveData.Limb.LEG:
					crouch += KNEEL_DROP * 0.6
					lean = -12.0
		FighterState.State.CASTING, FighterState.State.CHANNELING:
			var cast: Vector2 = _cast(fighter, pose)
			crouch += cast.x
			lean += cast.y
		FighterState.State.HELD:
			if fighter.held_by_choke:
				pose.grip = CHOKED_GRIP
				pose.off_hand = CHOKED_HAND
				pose.open_hand = true
				pose.blade_angle = STUN_ANGLE
				pose.front_foot = Vector2(6.0, 8.0)
				pose.back_foot = Vector2(-4.0, 12.0)
				lean = -10.0
	if fighter.blade_out and (fighter.is_free() or fighter.state == FighterState.State.BLOCKING):
		pose.grip = pose.grip.lerp(THROW_CATCH_HAND, CATCH_REACH)
		pose.open_hand = true
		if family.grip == MotionFamily.Grip.DUAL:
			pose.off_hand = THROW_CATCH_HAND + DUAL_THROW_OFFSET
	if fighter.is_airborne() and fighter.state != FighterState.State.JUMPING:
		_tuck(pose, 0.7)
	if tumble_left > 0.0 and fighter.on_ground:
		crouch = _tumble(pose, crouch)
		lean = SKID_LEAN * tumble_left / family.tumble_time if not family.acrobatic_recovery else lean
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
	if family.grip == MotionFamily.Grip.DUAL:
		_place_second_blade(fighter, pose, off_free)


func _block(opponent: FighterState, pose: RigPose) -> void:
	if opponent.is_attacking() and opponent.move != null and opponent.move.is_blade():
		block_line = threat_line(opponent.move)
	match block_line:
		MoveData.Cut.DESCENDING:
			pose.grip = BLOCK_HIGH_GRIP
			pose.blade_angle = BLOCK_HIGH_ANGLE
		MoveData.Cut.RISING:
			pose.grip = BLOCK_LOW_GRIP
			pose.blade_angle = BLOCK_LOW_ANGLE
		MoveData.Cut.THRUST:
			pose.grip = BLOCK_THRUST_GRIP
			pose.blade_angle = BLOCK_THRUST_ANGLE
		_:
			pose.grip = BLOCK_GRIP
			pose.blade_angle = BLOCK_ANGLE


static func threat_line(move: MoveData) -> MoveData.Cut:
	if move.cut != MoveData.Cut.ARC:
		return MoveData.Cut.HORIZONTAL if move.cut == MoveData.Cut.SPIN else move.cut
	if move.technique_style == MoveData.TechniqueStyle.THRUST or move.technique_style == MoveData.TechniqueStyle.LUNGE or move.technique_style == MoveData.TechniqueStyle.FLURRY:
		return MoveData.Cut.THRUST
	if move.blade_angle_windup <= HIGH_WINDUP_LIMIT:
		return MoveData.Cut.DESCENDING
	if move.blade_angle_windup >= LOW_WINDUP_LIMIT:
		return MoveData.Cut.RISING
	return MoveData.Cut.HORIZONTAL


func _walk(fighter: FighterState, pose: RigPose) -> void:
	var backward: bool = signf(fighter.vx) != float(fighter.facing) and fighter.vx != 0.0
	var phase: float = walk_phase * (-1.0 if backward else 1.0)
	var front_stride: float = family.stride * (LIMP_STRIDE if fighter.wound == FighterState.Wound.LEG else 1.0)
	pose.front_foot.x += sin(phase) * front_stride
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


func start_tumble() -> void:
	tumble_left = family.tumble_time


func is_vaulting() -> bool:
	return vault_progress >= 0.0 and vault_progress < 1.0


func vault_turned() -> bool:
	return vault_progress >= 0.5


func _tumble(pose: RigPose, crouch: float) -> float:
	var progress: float = 1.0 - tumble_left / family.tumble_time
	if family.acrobatic_recovery:
		_tuck(pose, sin(progress * PI))
		pose.spin = -TAU * ease(progress, -1.6)
		return crouch - sin(progress * PI) * TUMBLE_LIFT
	var skid: float = 1.0 - smoothstep(0.5, 1.0, progress)
	pose.off_hand = SKID_HAND + Vector2(0.0, hip_height - crouch - SKID_CROUCH * skid)
	pose.open_hand = true
	pose.back_foot.x -= 10.0 * skid
	return crouch + SKID_CROUCH * skid


func _jump_pose(fighter: FighterState, pose: RigPose) -> void:
	var rise: float = clampf(fighter.vy / JUMP_APEX_SPEED, -1.0, 1.0)
	if rise > 0.0:
		_tuck(pose, 1.0 - rise * 0.55)
		pose.back_foot += Vector2(-6.0, 4.0) * rise
	else:
		_tuck(pose, 1.0 + rise * 0.45)
		pose.front_foot += Vector2(4.0, 6.0) * -rise
	if is_vaulting():
		var roll: float = ease(vault_progress, FLIP_EASE)
		_tuck(pose, 1.0)
		pose.grip = FLIP_GRIP
		pose.blade_angle = FLIP_BLADE_ANGLE
		pose.spin = TAU * roll if not vault_turned() else -TAU * (1.0 - roll)
		return
	if flip_progress >= 0.0 and flip_progress < 1.0 and family.flip_on_double_jump:
		var turn: float = ease(flip_progress, FLIP_EASE)
		_tuck(pose, 1.0)
		pose.grip = FLIP_GRIP
		pose.blade_angle = FLIP_BLADE_ANGLE
		pose.spin = TAU * family.double_jump_turns * turn
		if family.double_jump_corkscrew:
			pose.turn = TAU * turn
		if family.air_twirl:
			pose.blade_angle += 720.0 * turn


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
		pose.open_hand = amount > 0.3
		pose.grip = guard_grip + Vector2(-8.0, 4.0) * amount
		pose.front_foot.x += family.heavy_step * amount
		_body_shift = family.lunge * amount
		return Vector2(4.0 * amount, 16.0 * amount)
	if move.technique_style == MoveData.TechniqueStyle.DASH:
		return _dash_slash(fighter, pose, move, guard_angle, guard_grip)
	if move.technique_style == MoveData.TechniqueStyle.PLUNGE:
		return _plunge(fighter, pose, move, guard_angle, guard_grip)
	if move.technique_style != MoveData.TechniqueStyle.ARC:
		return _technique(fighter, pose, move, guard_angle, guard_grip)
	var heavy: bool = move.is_heavy()
	var power: float = HEAVY_SCALE if heavy else 1.0
	var windup_grip: Vector2 = (HEAVY_WINDUP_GRIP if heavy else WINDUP_GRIP) * Vector2(family.windup_pull, 1.0)
	var strike_grip: Vector2 = STRIKE_GRIP * Vector2(family.strike_reach, 1.0)
	if move.cut != MoveData.Cut.ARC:
		windup_grip = CUT_WINDUP[move.cut] * Vector2(family.windup_pull, 1.0)
		strike_grip = CUT_STRIKE[move.cut] * Vector2(family.strike_reach, 1.0)
		if heavy and move.cut == MoveData.Cut.DESCENDING:
			windup_grip.y -= HEAVY_CUT_LIFT
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
			pose.turn = _cut_turn(move.cut, eased, false)
		FighterState.Phase.ACTIVE:
			var swing: float = lerpf(progress, smoothstep(0.0, 1.0, progress), SWING_SMOOTHING)
			var body: float = 1.0 - pow(1.0 - swing, SHOULDER_LEAD)
			var wrist: float = pow(swing, family.wrist_lag)
			pose.blade_angle = lerpf(move.blade_angle_windup, move.blade_angle_strike, wrist)
			pose.grip = _arc(windup_grip, strike_grip, swing)
			lean = lerpf(family.windup_lean * power, family.strike_lean * power, body)
			crouch = lerpf(family.heavy_crouch * 0.4, family.heavy_crouch, body) * power
			_body_shift = lerpf(-family.windup_shift, family.lunge, body) * power
			pose.front_foot.x += step * body
			pose.back_foot.x -= 2.0 * power * (1.0 - body)
			pose.trail = true
			pose.turn = _cut_turn(move.cut, swing, true)
			if move.cut == MoveData.Cut.THRUST:
				_body_shift += THRUST_SHIFT * body
				pose.front_foot.x += THRUST_SHIFT * body
		FighterState.Phase.RECOVERY:
			var share: float = family.recover_share
			var through: float = 1.0 - pow(1.0 - minf(progress / share, 1.0), 2.0)
			var settle: float = smoothstep(share * 0.6, 1.0, progress)
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
			if family.one_hand_follow and heavy and settle < 1.0:
				pose.off_hand = family.free_hand + Vector2(-family.follow_through * 0.3, -family.follow_through * 0.2) * (1.0 - settle)
	if move.is_aerial():
		_tuck(pose, 0.8)
		_body_shift = 0.0
	return Vector2(crouch, lean)


func _dash_slash(fighter: FighterState, pose: RigPose, move: MoveData, guard_angle: float, guard_grip: Vector2) -> Vector2:
	var progress: float = _progress(fighter, move)
	var descending: bool = family.dash_cut == MoveData.Cut.DESCENDING
	var tuck_grip: Vector2 = DASH_HIGH_TUCK_GRIP if descending else DASH_LOW_TUCK_GRIP
	var tuck_angle: float = DASH_HIGH_TUCK_ANGLE if descending else DASH_LOW_TUCK_ANGLE
	var strike_grip: Vector2 = DASH_FALLING_GRIP if descending else DASH_RISING_GRIP
	var strike_angle: float = DASH_FALLING_ANGLE if descending else DASH_RISING_ANGLE
	match fighter.move_phase:
		FighterState.Phase.STARTUP:
			var ramp: float = 1.0 - pow(1.0 - minf(progress * 2.0, 1.0), 2.0)
			pose.grip = _from_grip.lerp(tuck_grip, ramp)
			pose.blade_angle = rad_to_deg(lerp_angle(deg_to_rad(_from_angle), deg_to_rad(tuck_angle), ramp))
			if family.dash_twirl:
				pose.blade_angle += 360.0 * DASH_TWIRL_TURNS * progress
			pose.front_foot.x += 18.0 * ramp
			pose.back_foot.x -= 18.0 * ramp
			pose.back_foot.y = -6.0 * ramp
			_body_shift = 12.0 * ramp
			afterimage = progress > 0.2
			return Vector2(20.0 * ramp, 34.0 * ramp)
		FighterState.Phase.ACTIVE:
			var swing: float = 1.0 - pow(1.0 - progress, 2.0)
			pose.grip = _arc(tuck_grip, strike_grip, swing)
			pose.blade_angle = lerpf(tuck_angle, strike_angle, swing)
			pose.trail = true
			pose.front_foot.x += 18.0
			pose.back_foot.x -= 14.0
			_body_shift = lerpf(12.0, 8.0, swing)
			return Vector2(lerpf(20.0, 10.0, swing), lerpf(34.0, 6.0 if descending else -6.0, swing))
	var settle: float = smoothstep(DASH_HOLD, 1.0, progress)
	pose.grip = strike_grip.lerp(guard_grip, settle)
	pose.blade_angle = rad_to_deg(lerp_angle(deg_to_rad(strike_angle), deg_to_rad(guard_angle), settle))
	pose.front_foot.x += 18.0 * (1.0 - settle)
	pose.back_foot.x -= 14.0 * (1.0 - settle)
	_body_shift = 8.0 * (1.0 - settle)
	return Vector2(10.0 * (1.0 - settle), (6.0 if descending else -6.0) * (1.0 - settle))


func _plunge(fighter: FighterState, pose: RigPose, move: MoveData, guard_angle: float, guard_grip: Vector2) -> Vector2:
	var progress: float = _progress(fighter, move)
	var cutting: bool = family.plunge_cut == MoveData.Cut.DESCENDING
	var strike_grip: Vector2 = PLUNGE_CUT_GRIP if cutting else PLUNGE_THRUST_GRIP
	var strike_angle: float = PLUNGE_CUT_ANGLE if cutting else PLUNGE_THRUST_ANGLE
	match fighter.move_phase:
		FighterState.Phase.STARTUP:
			var ramp: float = 1.0 - pow(1.0 - progress, ANTICIPATION_EASE)
			_tuck(pose, 1.0)
			pose.grip = _from_grip.lerp(PLUNGE_RAISED_GRIP, ramp)
			pose.blade_angle = rad_to_deg(lerp_angle(deg_to_rad(_from_angle), deg_to_rad(PLUNGE_RAISED_ANGLE), ramp))
			pose.spin = -PLUNGE_TILT * 0.5 * ramp
			if family.plunge_pirouette:
				pose.turn = TAU * ramp
			return Vector2(0.0, -10.0 * ramp)
		FighterState.Phase.ACTIVE:
			var swing: float = minf(progress * (PLUNGE_CUT_SPEED if cutting else PLUNGE_THRUST_SPEED), 1.0)
			_tuck(pose, 0.8)
			pose.grip = _arc(PLUNGE_RAISED_GRIP, strike_grip, swing)
			pose.blade_angle = lerpf(PLUNGE_RAISED_ANGLE, strike_angle, swing)
			pose.spin = PLUNGE_TILT * swing
			pose.trail = true
			return Vector2(0.0, 18.0 * swing)
	var settle: float = smoothstep(PLUNGE_HOLD, 1.0, progress)
	pose.grip = strike_grip.lerp(guard_grip, settle)
	pose.blade_angle = rad_to_deg(lerp_angle(deg_to_rad(strike_angle), deg_to_rad(guard_angle), settle))
	pose.front_foot.x += 10.0 * (1.0 - settle)
	pose.back_foot = pose.back_foot.lerp(Vector2(-16.0, -2.0), 1.0 - settle)
	return Vector2(PLUNGE_KNEEL * (1.0 - settle), 24.0 * (1.0 - settle))


static func _cut_turn(cut: MoveData.Cut, amount: float, active: bool) -> float:
	match cut:
		MoveData.Cut.HORIZONTAL:
			return HORIZONTAL_TWIST * (1.0 - amount) if active else HORIZONTAL_TWIST * amount
		MoveData.Cut.SPIN:
			return PI + PI * amount if active else PI * amount
	return 0.0


func _technique(fighter: FighterState, pose: RigPose, move: MoveData, guard_angle: float, guard_grip: Vector2) -> Vector2:
	var progress: float = _progress(fighter, move)
	var ramp: float = 1.0
	var swing: float = 1.0
	match fighter.move_phase:
		FighterState.Phase.STARTUP:
			ramp = 1.0 - pow(1.0 - progress, ANTICIPATION_EASE)
			swing = 0.0
		FighterState.Phase.ACTIVE:
			swing = progress
		FighterState.Phase.RECOVERY:
			ramp = 1.0 - smoothstep(FOLLOW_SHARE * 0.6, 1.0, progress)
	var active: bool = fighter.move_phase == FighterState.Phase.ACTIVE
	var start_grip: Vector2 = _from_grip
	var start_angle: float = _from_angle
	var crouch: float = 0.0
	var lean: float = 0.0
	var windup_grip: Vector2 = guard_grip
	var strike_grip: Vector2 = guard_grip
	var angle: float = guard_angle
	match move.technique_style:
		MoveData.TechniqueStyle.SPIN:
			windup_grip = SPIN_GRIP
			strike_grip = SPIN_GRIP
			angle = SPIN_ANGLE + sin(swing * TAU) * 8.0
			pose.turn = TAU * smoothstep(0.0, 1.0, swing) if active else 0.0
			crouch = 8.0 * ramp
			lean = 4.0 * ramp
		MoveData.TechniqueStyle.THROW:
			windup_grip = THROW_WINDUP_GRIP
			strike_grip = THROW_RELEASE_GRIP
			angle = lerpf(move.blade_angle_windup, move.blade_angle_strike, swing)
			pose.off_hand = RELAXED_HAND.lerp(THROW_CATCH_HAND, ramp * swing)
			if family.grip == MotionFamily.Grip.DUAL:
				pose.off_hand = THROW_WINDUP_GRIP.lerp(THROW_RELEASE_GRIP, swing).lerp(RELAXED_HAND, 1.0 - ramp) + DUAL_THROW_OFFSET
			pose.open_hand = swing > 0.0
			lean = lerpf(-8.0, 16.0, swing) * ramp
			pose.front_foot.x += 10.0 * swing * ramp
		MoveData.TechniqueStyle.THRUST:
			windup_grip = THRUST_CHAMBER_GRIP
			strike_grip = THRUST_EXTEND_GRIP
			angle = lerpf(THRUST_ANGLE - 6.0, THRUST_ANGLE, swing)
			crouch = 6.0 * ramp
			lean = lerpf(-4.0, 18.0, swing) * ramp
			pose.front_foot.x += 18.0 * swing * ramp
			pose.back_foot.x -= 6.0 * ramp
			_body_shift = 12.0 * swing * ramp
		MoveData.TechniqueStyle.RISING:
			windup_grip = RISING_LOW_GRIP
			strike_grip = RISING_HIGH_GRIP
			angle = lerpf(move.blade_angle_windup, move.blade_angle_strike, swing)
			crouch = lerpf(18.0, -6.0, swing) * ramp
			lean = lerpf(12.0, -8.0, swing) * ramp
		MoveData.TechniqueStyle.FLURRY:
			var stab: int = mini(int(swing * float(maxi(move.multi_hits, 1))), maxi(move.multi_hits, 1) - 1)
			var reach: float = sin(fposmod(swing * maxi(move.multi_hits, 1), 1.0) * PI) if active else 0.0
			windup_grip = THRUST_CHAMBER_GRIP
			strike_grip = THRUST_CHAMBER_GRIP + Vector2(FLURRY_REACH * reach, -FLURRY_RISE * float(stab % 2))
			angle = THRUST_ANGLE + (-14.0 if stab % 2 == 1 else 6.0)
			lean = 14.0 * ramp
			pose.front_foot.x += 8.0 * ramp
			swing = 1.0 if active else swing
		MoveData.TechniqueStyle.LUNGE:
			windup_grip = LUNGE_CHAMBER_GRIP
			strike_grip = LUNGE_EXTEND_GRIP
			angle = lerpf(move.blade_angle_windup, move.blade_angle_strike, swing)
			crouch = lerpf(10.0, 6.0, swing) * ramp
			lean = lerpf(-6.0, 22.0, swing) * ramp
			pose.front_foot.x += 24.0 * swing * ramp
			pose.back_foot.x -= 10.0 * ramp
			_body_shift = lerpf(-6.0, 18.0, swing) * ramp
	match fighter.move_phase:
		FighterState.Phase.STARTUP:
			pose.grip = _arc(start_grip, windup_grip, ramp)
			pose.blade_angle = rad_to_deg(lerp_angle(deg_to_rad(start_angle), deg_to_rad(angle), ramp))
		FighterState.Phase.ACTIVE:
			pose.grip = _arc(windup_grip, strike_grip, swing)
			pose.blade_angle = angle
			pose.trail = true
		FighterState.Phase.RECOVERY:
			pose.grip = _arc(guard_grip, strike_grip, ramp)
			pose.blade_angle = rad_to_deg(lerp_angle(deg_to_rad(guard_angle), deg_to_rad(angle), ramp))
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
	pose.open_hand = power.kind != PowerData.Kind.FLOW_CLEAVE
	var tremor: Vector2 = Vector2(sin(time * 41.0), cos(time * 37.0)) * TREMOR if fighter.state == FighterState.State.CHANNELING else Vector2.ZERO
	match power.kind:
		PowerData.Kind.REPULSE:
			return _repulse(fighter, pose)
		PowerData.Kind.PULL:
			return _pull(fighter, pose)
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
			return _flow_cleave(fighter, pose)
	pose.off_hand = RELAXED_HAND.lerp(CAST_HAND, progress) + tremor
	pose.grip = pose.grip.lerp(CAST_GRIP, progress)
	pose.blade_angle = lerpf(pose.blade_angle, CAST_ANGLE, progress)
	return Vector2(4.0 * progress, 10.0 * progress)


func _repulse(fighter: FighterState, pose: RigPose) -> Vector2:
	var power: PowerData = fighter.power
	pose.open_hand = true
	pose.grip = pose.grip.lerp(CAST_GRIP, 0.7)
	pose.blade_angle = lerpf(pose.blade_angle, CAST_ANGLE, 0.7)
	if fighter.power_phase == FighterState.Phase.STARTUP:
		var draw: float = ease(clampf(float(fighter.power_ticks) / maxf(power.startup_ticks(), 1.0), 0.0, 1.0), 0.6)
		pose.off_hand = RELAXED_HAND.lerp(REPULSE_DRAW_HAND, draw)
		pose.back_foot.x -= 6.0 * draw
		return Vector2(6.0 * draw, -6.0 * draw)
	var released: float = clampf(float(fighter.power_ticks) / maxf(power.recovery_ticks(), 1.0), 0.0, 1.0)
	var settle: float = smoothstep(REPULSE_HOLD, 1.0, released)
	pose.off_hand = REPULSE_PALM_HAND.lerp(RELAXED_HAND, settle)
	pose.back_foot.x -= 12.0 * (1.0 - settle)
	_body_shift = -REPULSE_RECOIL * (1.0 - settle)
	return Vector2(8.0 * (1.0 - settle), -10.0 * (1.0 - settle))


func _pull(fighter: FighterState, pose: RigPose) -> Vector2:
	var power: PowerData = fighter.power
	pose.grip = pose.grip.lerp(CAST_GRIP, 0.7)
	pose.blade_angle = lerpf(pose.blade_angle, CAST_ANGLE, 0.7)
	if fighter.power_phase == FighterState.Phase.STARTUP:
		var reach: float = ease(clampf(float(fighter.power_ticks) / maxf(power.startup_ticks(), 1.0), 0.0, 1.0), 0.6)
		pose.off_hand = RELAXED_HAND.lerp(CAST_HAND, reach)
		pose.open_hand = true
		return Vector2(4.0 * reach, 12.0 * reach)
	var pulled: float = clampf(float(fighter.power_ticks) / maxf(power.recovery_ticks(), 1.0), 0.0, 1.0)
	var yank: float = ease(minf(pulled / PULL_HOLD, 1.0), 0.4)
	var settle: float = smoothstep(PULL_HOLD, 1.0, pulled)
	pose.off_hand = CAST_HAND.lerp(PULL_CLAW_HAND, yank).lerp(RELAXED_HAND, settle)
	pose.open_hand = false
	pose.back_foot.x -= 10.0 * (1.0 - settle)
	_body_shift = -6.0 * yank * (1.0 - settle)
	return Vector2(6.0 * (1.0 - settle), -14.0 * yank * (1.0 - settle))


func _flow_cleave(fighter: FighterState, pose: RigPose) -> Vector2:
	var power: PowerData = fighter.power
	if fighter.power_phase == FighterState.Phase.STARTUP:
		var progress: float = clampf(float(fighter.power_ticks) / maxf(power.startup_ticks(), 1.0), 0.0, 1.0)
		if progress < CLEAVE_WINDUP_SHARE:
			var lift: float = ease(progress / CLEAVE_WINDUP_SHARE, 0.5)
			pose.grip = pose.grip.lerp(CLEAVE_HIGH_GRIP, lift)
			pose.blade_angle = rad_to_deg(lerp_angle(deg_to_rad(pose.blade_angle), deg_to_rad(CLEAVE_HIGH_ANGLE), lift))
			pose.back_foot.x -= 8.0 * lift
			return Vector2(2.0 * lift, -10.0 * lift)
		return _cleave_swing((progress - CLEAVE_WINDUP_SHARE) / (1.0 - CLEAVE_WINDUP_SHARE), pose)
	var seconds: float = Ticks.to_seconds(fighter.power_ticks)
	var repeat: float = power.apex_repeat_delay if fighter.flow_tier >= PowerEffects.APEX_TIER else 0.0
	if seconds < repeat:
		var rewind: float = repeat * (1.0 - CLEAVE_WINDUP_SHARE)
		if seconds < rewind:
			var lift: float = ease(seconds / rewind, 0.5)
			pose.grip = CLEAVE_FLOOR_GRIP.lerp(CLEAVE_HIGH_GRIP, lift)
			pose.blade_angle = lerpf(CLEAVE_FLOOR_ANGLE, CLEAVE_HIGH_ANGLE + 360.0, lift)
			return Vector2(22.0 * (1.0 - lift), 26.0 * (1.0 - lift) - 10.0 * lift)
		return _cleave_swing((seconds - rewind) / (repeat - rewind), pose)
	var remaining: float = maxf(Ticks.to_seconds(power.recovery_ticks_at(repeat > 0.0)) - repeat, Ticks.DELTA)
	var settle: float = smoothstep(CLEAVE_HOLD, 1.0, (seconds - repeat) / remaining)
	pose.grip = CLEAVE_FLOOR_GRIP.lerp(pose.grip, settle)
	pose.blade_angle = rad_to_deg(lerp_angle(deg_to_rad(CLEAVE_FLOOR_ANGLE), deg_to_rad(pose.blade_angle), settle))
	pose.front_foot.x += 14.0 * (1.0 - settle)
	return Vector2(22.0 * (1.0 - settle), 26.0 * (1.0 - settle))


func _cleave_swing(amount: float, pose: RigPose) -> Vector2:
	var swing: float = clampf(amount, 0.0, 1.0)
	pose.grip = _arc(CLEAVE_HIGH_GRIP, CLEAVE_FLOOR_GRIP, swing)
	pose.blade_angle = lerpf(CLEAVE_HIGH_ANGLE, CLEAVE_FLOOR_ANGLE, swing)
	pose.trail = true
	pose.front_foot.x += 14.0 * swing
	return Vector2(22.0 * swing, lerpf(-10.0, 26.0, swing))


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
		FighterState.DodgeKind.SPIN:
			var travel: float = clampf(float(fighter.state_ticks) / maxf(DodgeState.spin_travel_ticks(COMBAT), 1.0), 0.0, 1.0)
			var low: float = 1.0 if travel < 1.0 else 1.0 - clampf(float(fighter.state_ticks - DodgeState.spin_travel_ticks(COMBAT)) / maxf(Ticks.from_seconds(COMBAT.spin_dodge_recovery), 1.0), 0.0, 1.0)
			pose.turn = PI * smoothstep(0.0, 1.0, travel) if travel < 1.0 else 0.0
			pose.grip = SPIN_DODGE_GRIP
			pose.blade_angle = SPIN_DODGE_ANGLE
			_tuck(pose, 0.35 * low)
			afterimage = travel < 1.0
			return Vector2(20.0 * low, 18.0 * low)
	return Vector2.ZERO


func _place_off_hand(_fighter: FighterState, pose: RigPose) -> void:
	var direction: Vector2 = pose.blade_direction()
	if character.weapon.kind == WeaponData.Kind.LANCE:
		pose.off_hand = pose.grip - direction * LANCE_SPACING
		return
	match family.grip:
		MotionFamily.Grip.TWO_HANDED:
			pose.off_hand = pose.grip - direction * family.back_hand_spacing
		MotionFamily.Grip.STAFF:
			pose.off_hand = pose.grip - direction * STAFF_SPACING
		MotionFamily.Grip.DUAL:
			pose.off_hand = family.off_guard_hand + pose.pelvis
		MotionFamily.Grip.ONE_HANDED:
			pose.off_hand = family.free_hand + pose.pelvis + Vector2(sin(time * 1.1) * 1.5, 0.0)


func _place_second_blade(fighter: FighterState, pose: RigPose, off_free: bool) -> void:
	var sway: float = sin(time * 1.7 + 1.3) * family.sway * 2.0
	pose.off_blade_angle = family.off_guard_angle + sway
	if not fighter.is_attacking() or fighter.move == null or off_free:
		return
	var move: MoveData = fighter.move
	if move.kind == MoveData.Kind.LIGHT and fighter.chain_index % 2 == 1:
		pose.off_hand = pose.grip + Vector2(-2.0, 4.0)
		pose.off_blade_angle = pose.blade_angle
		pose.off_trail = pose.trail
		pose.grip = _guard_grip + pose.pelvis + Vector2(-OFF_SWAY, -OFF_SWAY)
		pose.blade_angle = _guard_angle - OFF_SWING * 0.5
		pose.trail = false
		return
	var swing: float = _progress(fighter, move) if fighter.move_phase == FighterState.Phase.ACTIVE else 0.0
	pose.off_hand += Vector2(-OFF_SWAY * swing, OFF_SWAY * 0.5 * swing)
	pose.off_blade_angle = family.off_guard_angle + OFF_SWING * swing


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
