class_name PoseSolver
extends RefCounted

const HIP_HEIGHT_FALLBACK: float = 72.0
const BLOCK_GRIP: Vector2 = Vector2(18.0, -36.0)
const BLOCK_ANGLE: float = -84.0
const LOCK_GRIP: Vector2 = Vector2(22.0, -52.0)
const LOCK_ANGLE: float = -62.0
const HIT_GRIP: Vector2 = Vector2(6.0, -20.0)
const HIT_ANGLE: float = 52.0
const STUN_GRIP: Vector2 = Vector2(12.0, -8.0)
const STUN_ANGLE: float = 96.0
const WINDUP_GRIP: Vector2 = Vector2(-6.0, -40.0)
const HEAVY_WINDUP_GRIP: Vector2 = Vector2(-8.0, -54.0)
const STRIKE_GRIP: Vector2 = Vector2(24.0, -28.0)
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

var character: CharacterData
var family: MotionFamily
var hip_height: float = HIP_HEIGHT_FALLBACK
var time: float = 0.0
var walk_phase: float = 0.0
var flip_progress: float = -1.0
var landing_left: float = 0.0


func setup(data: CharacterData, art: FighterArt) -> void:
	character = data
	family = data.family
	if art != null:
		hip_height = art.dim("thigh") + art.dim("shin") + art.dim("ankle")


func solve(fighter: FighterState, opponent: FighterState, pose: RigPose) -> void:
	var guard_angle: float = character.guard_angle
	var guard_grip: Vector2 = character.guard_grip
	if fighter.exhausted:
		guard_angle += EXHAUSTED_DROP
		guard_grip.y += EXHAUSTED_DROP * 0.5
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
			_tuck(pose, 1.0)
			if flip_progress >= 0.0 and family.flip_on_double_jump:
				pose.spin = TAU * ease(flip_progress, 0.6)
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
			var pressure: float = clampf(float(fighter.lock_presses - opponent.lock_presses) / 5.0, -1.0, 1.0)
			lean = family.lock_lean * (1.0 + pressure * 0.5)
			crouch += family.lock_crouch - pressure * 4.0
			pose.grip = LOCK_GRIP + Vector2(pressure * 6.0, 0.0)
			pose.blade_angle = LOCK_ANGLE
			pose.tremble = true
		FighterState.State.HIT:
			lean = -18.0
			pose.grip = HIT_GRIP
			pose.blade_angle = HIT_ANGLE
			off_free = true
		FighterState.State.STAGGERED:
			lean = -14.0
			pose.grip = guard_grip + Vector2(-12.0, 10.0)
			pose.blade_angle = guard_angle + 34.0
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
	if fighter.is_airborne() and fighter.state != FighterState.State.JUMPING:
		_tuck(pose, 0.7)
	pose.pelvis = Vector2(0.0, -hip_height + crouch)
	pose.torso_angle = deg_to_rad(lean)
	pose.head_angle = -pose.torso_angle * 0.55
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


func _tuck(pose: RigPose, amount: float) -> void:
	pose.front_foot = pose.front_foot.lerp(TUCK_FRONT, amount)
	pose.back_foot = pose.back_foot.lerp(TUCK_BACK, amount)


func _attack(fighter: FighterState, pose: RigPose, guard_angle: float, guard_grip: Vector2) -> Vector2:
	var move: MoveData = fighter.move
	if move == null:
		return Vector2.ZERO
	if move.kind == MoveData.Kind.SHOVE:
		var push: float = _progress(fighter, move)
		var amount: float = ease(push, 0.5) if fighter.move_phase != FighterState.Phase.RECOVERY else 1.0 - push
		if fighter.move_phase == FighterState.Phase.ACTIVE:
			amount = 1.0
		pose.off_hand = RELAXED_HAND.lerp(SHOVE_HAND, amount)
		pose.grip = guard_grip + Vector2(-8.0, 4.0) * amount
		pose.front_foot.x += family.heavy_step * amount
		return Vector2(4.0 * amount, 16.0 * amount)
	var heavy: bool = move.is_heavy()
	var windup_grip: Vector2 = (HEAVY_WINDUP_GRIP if heavy else WINDUP_GRIP) * Vector2(family.windup_pull, 1.0)
	var strike_grip: Vector2 = STRIKE_GRIP * Vector2(family.strike_reach, 1.0)
	var progress: float = _progress(fighter, move)
	var crouch: float = family.heavy_crouch if heavy else 0.0
	var lean: float = 0.0
	var step: float = family.heavy_step if heavy else family.heavy_step * 0.4
	match fighter.move_phase:
		FighterState.Phase.STARTUP:
			var eased: float = ease(progress, 0.45)
			pose.blade_angle = lerpf(guard_angle, move.blade_angle_windup, eased)
			pose.grip = guard_grip.lerp(windup_grip, eased)
			lean = -5.0 * eased
			crouch *= eased
		FighterState.Phase.ACTIVE:
			pose.blade_angle = lerpf(move.blade_angle_windup, move.blade_angle_strike, progress)
			pose.grip = windup_grip.lerp(strike_grip, ease(progress, 0.7))
			lean = family.strike_lean
			pose.front_foot.x += step
			pose.trail = true
		FighterState.Phase.RECOVERY:
			var through: float = minf(progress / 0.3, 1.0)
			var settle: float = smoothstep(0.3, 1.0, progress)
			var follow: float = move.blade_angle_strike + signf(move.blade_angle_strike - move.blade_angle_windup) * family.follow_through * through
			pose.blade_angle = lerpf(follow, guard_angle, settle)
			pose.grip = strike_grip.lerp(guard_grip, settle)
			lean = family.strike_lean * (1.0 - settle)
			pose.front_foot.x += step * (1.0 - settle)
			crouch *= 1.0 - settle
			if family.finisher_twirl and _is_last_chain(fighter):
				pose.blade_angle += 360.0 * smoothstep(0.1, 0.9, progress)
	if move.is_aerial():
		_tuck(pose, 0.8)
	return Vector2(crouch, lean)


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
