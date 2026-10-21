class_name HiltView
extends Node2D

const HILT_WIDTH: float = 4.5
const HAFT_WIDTH: float = 3.6
const GRIP_WIDTH: float = 5.2
const RING_RADIUS: float = 2.8
const BAND_COUNT: int = 4

var weapon: WeaponData
var metal: Color = Color.GRAY
var grip_color: Color = Color.DIM_GRAY
var geometry: WeaponPose = WeaponPose.new()


func setup(weapon_data: WeaponData, costume: CostumeData) -> void:
	weapon = weapon_data
	metal = costume.color(CostumeData.Slot.METAL)
	grip_color = costume.color(CostumeData.Slot.LEATHER).darkened(0.3)


func update_pose(pose: RigPose, _front_hand: Vector2, _back_hand: Vector2) -> void:
	geometry.compute(weapon, pose)
	queue_redraw()


func _draw() -> void:
	if weapon == null:
		return
	var long_haft: bool = weapon.kind == WeaponData.Kind.LANCE or weapon.kind == WeaponData.Kind.STAFF
	draw_line(geometry.hilt_from, geometry.hilt_to, metal, HAFT_WIDTH if long_haft else HILT_WIDTH)
	_draw_details(geometry.hilt_from, geometry.hilt_to, long_haft)
	if geometry.has_second and weapon.kind == WeaponData.Kind.DUAL:
		draw_line(geometry.second_hilt_from, geometry.second_hilt_to, metal, HILT_WIDTH)
		_draw_grip(geometry.second_hilt_from, geometry.second_hilt_to)


func _draw_details(from: Vector2, to: Vector2, long_haft: bool) -> void:
	var direction: Vector2 = (to - from).normalized()
	var side: Vector2 = direction.orthogonal()
	match weapon.hilt:
		WeaponData.Hilt.RING:
			_draw_grip(from, from.lerp(to, 0.6))
			draw_arc(to, RING_RADIUS, 0.0, TAU, 12, metal.lightened(0.2), 1.6)
		WeaponData.Hilt.CURVED_POMMEL:
			_draw_grip(from.lerp(to, 0.2), from.lerp(to, 0.75))
			draw_polyline(PackedVector2Array([from, from - direction * 3.0 + side * 3.0, from - direction * 1.0 + side * 5.0]), metal, 2.4)
		WeaponData.Hilt.WRAPPED:
			_draw_grip(from, to - direction * 2.0)
		WeaponData.Hilt.CROSSGUARD:
			_draw_grip(from, to - direction * 3.0)
			draw_line(to - side * 6.0, to + side * 6.0, metal.lightened(0.1), 3.0)
		WeaponData.Hilt.BANDED, WeaponData.Hilt.DOUBLE:
			for i in BAND_COUNT * (2 if long_haft else 1):
				var t: float = (i + 0.5) / float(BAND_COUNT * (2 if long_haft else 1))
				var center: Vector2 = from.lerp(to, t)
				draw_line(center - direction * 1.2, center + direction * 1.2, grip_color, GRIP_WIDTH)
			if weapon.hilt == WeaponData.Hilt.DOUBLE:
				var middle: Vector2 = from.lerp(to, 0.5)
				draw_line(middle - side * 3.0, middle + side * 3.0, metal.lightened(0.25), 2.0)
		WeaponData.Hilt.PLAIN:
			pass


func _draw_grip(from: Vector2, to: Vector2) -> void:
	draw_line(from, to, grip_color, GRIP_WIDTH)
