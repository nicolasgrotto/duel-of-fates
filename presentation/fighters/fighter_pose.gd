class_name FighterPose
extends RefCounted

const GUARD_HIGH_ANGLE: float = -55.0
const GUARD_LOW_ANGLE: float = 28.0
const BLOCK_ANGLE: float = -82.0
const LOCK_ANGLE: float = -68.0
const HIT_ANGLE: float = 55.0
const STUN_ANGLE: float = 100.0
const GUARD_HANDS_HIGH: Vector2 = Vector2(14.0, -96.0)
const GUARD_HANDS_LOW: Vector2 = Vector2(18.0, -82.0)
const WINDUP_HANDS: Vector2 = Vector2(-4.0, -104.0)
const STRIKE_HANDS: Vector2 = Vector2(26.0, -98.0)
const BLOCK_HANDS: Vector2 = Vector2(20.0, -102.0)
const LOCK_HANDS: Vector2 = Vector2(18.0, -114.0)
const SHOVE_HANDS: Vector2 = Vector2(30.0, -100.0)
const EXHAUSTED_DROP: float = 18.0
const BREATH_SPEED: float = 2.2
const BREATH_DEPTH: float = 1.6

var lean: float = 0.0
var crouch: float = 0.0
var hands: Vector2 = GUARD_HANDS_HIGH
var blade_angle: float = GUARD_HIGH_ANGLE
var stride: float = 0.0
var tuck: float = 0.0
var tremble: bool = false
var trail: bool = false


func compute(fighter: FighterState, time: float, walk_phase: float) -> void:
	var low: bool = fighter.character.guard_style == CharacterData.GuardStyle.LOW
	var guard_angle: float = GUARD_LOW_ANGLE if low else GUARD_HIGH_ANGLE
	var guard_hands: Vector2 = GUARD_HANDS_LOW if low else GUARD_HANDS_HIGH
	if fighter.exhausted:
		guard_angle += EXHAUSTED_DROP
		guard_hands.y += EXHAUSTED_DROP * 0.4
	var breath: float = sin(time * BREATH_SPEED) * BREATH_DEPTH * (2.0 if fighter.exhausted else 1.0)
	lean = 0.12 if low else 0.04
	crouch = breath
	hands = guard_hands + Vector2(0.0, breath)
	blade_angle = guard_angle + breath
	stride = 0.0
	tuck = 0.0
	tremble = false
	trail = false
	match fighter.state:
		FighterState.State.WALKING:
			stride = sin(walk_phase) * 9.0
			crouch += absf(sin(walk_phase)) * 2.0
		FighterState.State.JUMPING:
			tuck = 1.0
		FighterState.State.ATTACKING, FighterState.State.HEAVY_ATTACK:
			_attack(fighter, guard_angle, guard_hands)
		FighterState.State.BLOCKING:
			hands = BLOCK_HANDS
			blade_angle = BLOCK_ANGLE
			crouch += 6.0
		FighterState.State.DODGING:
			_dodge(fighter)
		FighterState.State.BLADE_LOCK:
			lean = 0.28
			crouch += 10.0
			hands = LOCK_HANDS
			blade_angle = LOCK_ANGLE
		FighterState.State.HIT:
			lean = -0.3
			blade_angle = HIT_ANGLE
			hands = guard_hands + Vector2(-8.0, 10.0)
		FighterState.State.STAGGERED:
			lean = -0.22
			blade_angle = guard_angle + 30.0
			hands = guard_hands + Vector2(-10.0, 6.0)
			tremble = true
		FighterState.State.STUNNED:
			lean = 0.45
			crouch += 14.0
			blade_angle = STUN_ANGLE + sin(time * 1.5) * 6.0
			hands = Vector2(16.0, -70.0)
		FighterState.State.DEAD:
			blade_angle = HIT_ANGLE
	if fighter.is_airborne() and not fighter.is_attacking():
		tuck = 1.0


func _attack(fighter: FighterState, guard_angle: float, guard_hands: Vector2) -> void:
	var move: MoveData = fighter.move
	if move == null:
		return
	if move.kind == MoveData.Kind.SHOVE:
		var reach: float = _phase_progress(fighter, move)
		hands = guard_hands.lerp(SHOVE_HANDS, reach if fighter.move_phase != FighterState.Phase.RECOVERY else 1.0 - reach)
		blade_angle = guard_angle + 40.0
		lean = 0.2
		return
	var progress: float = _phase_progress(fighter, move)
	match fighter.move_phase:
		FighterState.Phase.STARTUP:
			var eased: float = ease(progress, 0.5)
			blade_angle = lerpf(guard_angle, move.blade_angle_windup, eased)
			hands = guard_hands.lerp(WINDUP_HANDS, eased)
			lean = lerpf(lean, -0.08, eased)
		FighterState.Phase.ACTIVE:
			blade_angle = lerpf(move.blade_angle_windup, move.blade_angle_strike, progress)
			hands = WINDUP_HANDS.lerp(STRIKE_HANDS, progress)
			lean = 0.22
			trail = true
		FighterState.Phase.RECOVERY:
			var settle: float = smoothstep(0.0, 1.0, progress)
			blade_angle = lerpf(move.blade_angle_strike, guard_angle, settle)
			hands = STRIKE_HANDS.lerp(guard_hands, settle)
			lean = lerpf(0.22, lean, settle)
	if move.is_heavy():
		crouch += 6.0


func _dodge(fighter: FighterState) -> void:
	var away: bool = fighter.dodge_direction != fighter.facing
	match fighter.dodge_kind:
		FighterState.DodgeKind.GROUND:
			lean = -0.35 if away else 0.35
			crouch += 18.0
		FighterState.DodgeKind.AIR:
			lean = 0.5
			tuck = 0.6
		FighterState.DodgeKind.EVADE:
			lean = -0.4 if fighter.evade_streak % 2 == 0 else -0.25
			crouch += 12.0


static func _phase_progress(fighter: FighterState, move: MoveData) -> float:
	var length: int = 1
	match fighter.move_phase:
		FighterState.Phase.STARTUP:
			length = move.startup_ticks()
		FighterState.Phase.ACTIVE:
			length = move.active_ticks()
		FighterState.Phase.RECOVERY:
			length = move.recovery_ticks()
	return clampf(float(fighter.phase_ticks) / maxf(length, 1.0), 0.0, 1.0)
