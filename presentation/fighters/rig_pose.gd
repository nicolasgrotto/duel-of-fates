class_name RigPose
extends RefCounted

var pelvis: Vector2 = Vector2(0.0, -72.0)
var torso_angle: float = 0.0
var head_angle: float = 0.0
var grip: Vector2 = Vector2(14.0, -96.0)
var off_hand: Vector2 = Vector2(8.0, -92.0)
var blade_angle: float = -55.0
var off_blade_angle: float = 120.0
var front_foot: Vector2 = Vector2(15.0, 0.0)
var back_foot: Vector2 = Vector2(-15.0, 0.0)
var spin: float = 0.0
var turn: float = 0.0
var open_hand: bool = false
var tremble: bool = false
var trail: bool = false
var off_trail: bool = false
var hand_spacing: float = 0.0
var arm_extension: float = 0.0
var sidearm_raise: float = 0.0
var front_elbow_hint: Vector2 = Vector2.DOWN
var back_elbow_hint: Vector2 = Vector2.DOWN


func copy_from(other: RigPose) -> void:
	pelvis = other.pelvis
	torso_angle = other.torso_angle
	head_angle = other.head_angle
	grip = other.grip
	off_hand = other.off_hand
	blade_angle = other.blade_angle
	off_blade_angle = other.off_blade_angle
	front_foot = other.front_foot
	back_foot = other.back_foot
	spin = other.spin
	turn = other.turn
	open_hand = other.open_hand
	tremble = other.tremble
	trail = other.trail
	off_trail = other.off_trail
	hand_spacing = other.hand_spacing
	arm_extension = other.arm_extension
	sidearm_raise = other.sidearm_raise
	front_elbow_hint = other.front_elbow_hint
	back_elbow_hint = other.back_elbow_hint


func blend_toward(target: RigPose, weight: float) -> void:
	pelvis = pelvis.lerp(target.pelvis, weight)
	torso_angle = lerp_angle(torso_angle, target.torso_angle, weight)
	head_angle = lerp_angle(head_angle, target.head_angle, weight)
	grip = grip.lerp(target.grip, weight)
	off_hand = off_hand.lerp(target.off_hand, weight)
	blade_angle = rad_to_deg(lerp_angle(deg_to_rad(blade_angle), deg_to_rad(target.blade_angle), weight))
	off_blade_angle = rad_to_deg(lerp_angle(deg_to_rad(off_blade_angle), deg_to_rad(target.off_blade_angle), weight))
	front_foot = front_foot.lerp(target.front_foot, weight)
	back_foot = back_foot.lerp(target.back_foot, weight)
	spin = target.spin
	turn = target.turn
	open_hand = target.open_hand
	tremble = target.tremble
	trail = target.trail
	off_trail = target.off_trail
	hand_spacing = target.hand_spacing
	arm_extension = lerpf(arm_extension, target.arm_extension, weight)
	sidearm_raise = lerpf(sidearm_raise, target.sidearm_raise, weight)
	front_elbow_hint = front_elbow_hint.lerp(target.front_elbow_hint, weight)
	back_elbow_hint = back_elbow_hint.lerp(target.back_elbow_hint, weight)


func blade_direction() -> Vector2:
	return Vector2.from_angle(deg_to_rad(blade_angle))
