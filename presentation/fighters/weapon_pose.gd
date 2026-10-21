class_name WeaponPose
extends RefCounted

const DUAL_HILT: float = 10.0

var hilt_from: Vector2 = Vector2.ZERO
var hilt_to: Vector2 = Vector2.ZERO
var blade_base: Vector2 = Vector2.ZERO
var blade_direction: Vector2 = Vector2.RIGHT
var blade_length: float = 0.0
var has_second: bool = false
var second_hilt_from: Vector2 = Vector2.ZERO
var second_hilt_to: Vector2 = Vector2.ZERO
var second_base: Vector2 = Vector2.ZERO
var second_direction: Vector2 = Vector2.LEFT
var second_length: float = 0.0


func compute(weapon: WeaponData, pose: RigPose) -> void:
	var direction: Vector2 = pose.blade_direction()
	var hilt: float = weapon.hilt_length
	var behind: float = 0.5
	match weapon.kind:
		WeaponData.Kind.LANCE:
			behind = 0.6
		WeaponData.Kind.STAFF:
			behind = 0.65
	hilt_from = pose.grip - direction * hilt * behind
	hilt_to = pose.grip + direction * hilt * (1.0 - behind)
	blade_base = hilt_to
	blade_direction = direction
	blade_length = weapon.blade_length
	has_second = false
	match weapon.kind:
		WeaponData.Kind.STAFF:
			has_second = true
			second_hilt_from = hilt_from
			second_hilt_to = hilt_from
			second_base = hilt_from
			second_direction = -direction
			second_length = weapon.second_blade_length
		WeaponData.Kind.DUAL:
			has_second = true
			second_direction = Vector2.from_angle(deg_to_rad(pose.off_blade_angle))
			second_hilt_from = pose.off_hand - second_direction * DUAL_HILT * 0.5
			second_hilt_to = pose.off_hand + second_direction * DUAL_HILT * 0.5
			second_base = second_hilt_to
			second_length = weapon.second_blade_length


func tip() -> Vector2:
	return blade_base + blade_direction * blade_length
