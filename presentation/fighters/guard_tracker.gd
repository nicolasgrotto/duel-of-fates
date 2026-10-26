class_name GuardTracker
extends RefCounted

var family: MotionFamily
var active: bool = false
var has_live: bool = false
var reverse: bool = false
var live_base: Vector2 = Vector2.ZERO
var live_tip: Vector2 = Vector2.ZERO
var predicted_base: Vector2 = Vector2.ZERO
var predicted_tip: Vector2 = Vector2.ZERO
var position: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
var angle: float = 0.0
var angular_velocity: float = 0.0
var intercept: Vector2 = Vector2.ZERO
var contact_time: float = 0.0
var engagement: float = 0.0
var lean: float = 0.0
var delta: float = Ticks.DELTA

var target_position: Vector2 = Vector2.ZERO
var target_angle: float = 0.0
var _incoming: Vector2 = Vector2.LEFT
var _hold_left: float = 0.0


func configure(data: MotionFamily) -> void:
	family = data
	active = false
	has_live = false
	_hold_left = 0.0
	velocity = Vector2.ZERO
	angular_velocity = 0.0
	engagement = 0.0
	lean = 0.0


func begin(grip: Vector2, blade_angle: float) -> void:
	if active:
		return
	active = true
	position = grip
	angle = deg_to_rad(blade_angle)
	velocity = Vector2.ZERO
	angular_velocity = 0.0
	engagement = 0.0


func advance(seconds: float) -> void:
	delta = minf(seconds, 1.0 / 30.0)
	_hold_left = maxf(_hold_left - seconds, 0.0)
	lean *= exp(-family.block_frequency * seconds)


func observe_segment(base: Vector2, tip: Vector2) -> void:
	live_base = base
	live_tip = tip
	has_live = base.distance_squared_to(tip) > 1.0


func recoil(heavy: bool, parry: bool) -> void:
	var strength: float = family.block_recoil * (family.block_heavy_recoil if heavy else 1.0) * (family.block_parry_recoil if parry else 1.0)
	velocity += _incoming * strength * family.block_frequency
	angular_velocity += signf(_incoming.y) * deg_to_rad(strength) * family.block_frequency
	lean = -strength
	_hold_left = family.block_recovery


func follow(rest: Vector2, rest_angle: float, pelvis: Vector2, torso: float, scale: float, weapon: WeaponData, threat: bool, blockstun: bool, seconds_to_contact: float) -> void:
	contact_time = seconds_to_contact
	engagement = lerpf(engagement, 1.0, 1.0 - exp(-family.block_frequency * delta))
	if threat and has_live:
		_target_interception(pelvis, torso, scale, weapon)
	elif not blockstun and _hold_left <= 0.0:
		target_position = rest
		target_angle = deg_to_rad(rest_angle)
		if has_live:
			var height: float = ((live_base + live_tip) * 0.5 / scale - pelvis).rotated(-torso).y
			target_position.y = lerpf(rest.y, height, family.block_drift)
	target_position = _in_envelope(target_position)


func fit_grip(grip: Vector2, torso: float, aim: bool) -> void:
	target_position = grip
	if aim and not reverse and grip.distance_squared_to(intercept) > 1.0:
		target_angle = (intercept - grip).angle() + torso


func _target_interception(pelvis: Vector2, torso: float, scale: float, weapon: WeaponData) -> void:
	var weight: float = 1.0 - smoothstep(0.0, family.block_live_lead, contact_time)
	var base: Vector2 = ((predicted_base.lerp(live_base, weight) / scale) - pelvis).rotated(-torso)
	var tip: Vector2 = ((predicted_tip.lerp(live_tip, weight) / scale) - pelvis).rotated(-torso)
	var segment: Vector2 = tip - base
	_incoming = segment.normalized()
	var share: float = clampf((family.block_plane - base.x) / segment.x, 0.0, 1.0) if absf(segment.x) > 0.001 else 0.5
	intercept = base + segment * share
	var transverse: Vector2 = _incoming.orthogonal()
	if transverse.y > 0.0:
		transverse = -transverse
	if reverse and transverse.x > 0.0:
		transverse = -transverse
	var depth: float = weapon.blade_length * family.block_blade_share + weapon.hilt_length * 0.5
	if weapon.kind == WeaponData.Kind.STAFF or weapon.kind == WeaponData.Kind.LANCE:
		depth = 0.0
	target_position = intercept - transverse * depth
	var anticipation: float = smoothstep(0.0, family.block_live_lead, contact_time) * family.block_anticipation
	target_position -= _incoming * anticipation
	target_angle = transverse.angle() + torso
	var reachable: Vector2 = _in_envelope(target_position)
	if not reverse and depth > 0.0 and reachable.distance_squared_to(intercept) > 1.0:
		target_angle = (intercept - reachable).angle() + torso


func fallback(grip: Vector2, blade_angle: float) -> void:
	position = grip
	angle = deg_to_rad(blade_angle)
	velocity = Vector2.ZERO
	angular_velocity = 0.0
	target_position = grip
	target_angle = angle


func _in_envelope(point: Vector2) -> Vector2:
	return point.clamp(family.block_envelope.position, family.block_envelope.end)


func integrate() -> void:
	var frequency: float = family.block_frequency
	var f: float = 1.0 + 2.0 * delta * family.block_damping * frequency
	var acceleration: float = frequency * frequency
	var divisor: float = 1.0 / (f + delta * delta * acceleration)
	var previous: Vector2 = position
	position = (f * position + delta * velocity + delta * delta * acceleration * target_position) * divisor
	velocity = (velocity + delta * acceleration * (target_position - previous)) * divisor
	var goal_angle: float = angle + wrapf(target_angle - angle, -PI, PI)
	var previous_angle: float = angle
	angle = (f * angle + delta * angular_velocity + delta * delta * acceleration * goal_angle) * divisor
	angular_velocity = (angular_velocity + delta * acceleration * (goal_angle - previous_angle)) * divisor
