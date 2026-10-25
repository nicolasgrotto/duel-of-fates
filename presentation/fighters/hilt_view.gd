class_name HiltView
extends Node2D

const HILT_WIDTH: float = 4.5
const HAFT_WIDTH: float = 3.6
const GRIP_WIDTH: float = 5.2
const RING_RADIUS: float = 2.8
const BAND_COUNT: int = 4
const EMITTER_LENGTH: float = 3.0
const EMITTER_EXTRA: float = 2.0
const POMMEL_LENGTH: float = 2.5
const SHINE_WIDTH: float = 1.2
const BUTTON_SIZE: float = 2.0
const BUTTON_AT: float = 0.62
const BORROWED_GRIP_FROM: float = 0.2
const BORROWED_GRIP_TO: float = 0.7

var weapon: WeaponData
var metal: Color = Color.GRAY
var grip_color: Color = Color.DIM_GRAY
var geometry: WeaponPose = WeaponPose.new()
var hidden_main: bool = false
var button_color: Color = Color.WHITE
var borrowed_shown: bool = false
var borrowed_from: Vector2 = Vector2.ZERO
var borrowed_to: Vector2 = Vector2.ZERO
var borrowed_metal: Color = Color.GRAY
var borrowed_grip: Color = Color.DIM_GRAY


func setup(weapon_data: WeaponData, costume: CostumeData) -> void:
	weapon = weapon_data
	metal = costume.color(CostumeData.Slot.METAL)
	grip_color = costume.color(CostumeData.Slot.LEATHER).darkened(0.3)


func update_pose(pose: RigPose, _front_hand: Vector2, _back_hand: Vector2) -> void:
	geometry.compute(weapon, pose)
	queue_redraw()


func _draw() -> void:
	if borrowed_shown:
		draw_line(borrowed_from, borrowed_to, borrowed_metal, HILT_WIDTH)
		draw_line(borrowed_from.lerp(borrowed_to, BORROWED_GRIP_FROM), borrowed_from.lerp(borrowed_to, BORROWED_GRIP_TO), borrowed_grip, GRIP_WIDTH)
	if weapon == null or hidden_main:
		return
	var long_haft: bool = weapon.kind == WeaponData.Kind.LANCE or weapon.kind == WeaponData.Kind.STAFF
	var width: float = HAFT_WIDTH if long_haft else HILT_WIDTH
	draw_line(geometry.hilt_from, geometry.hilt_to, metal, width)
	_draw_details(geometry.hilt_from, geometry.hilt_to, long_haft)
	_draw_finish(geometry.hilt_from, geometry.hilt_to, width, long_haft)
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


func _draw_finish(from: Vector2, to: Vector2, width: float, long_haft: bool) -> void:
	var direction: Vector2 = (to - from).normalized()
	var side: Vector2 = direction.orthogonal()
	var shine: Color = metal.lightened(0.45)
	draw_line(from.lerp(to, 0.15) - side * width * 0.3, from.lerp(to, 0.85) - side * width * 0.3, shine, SHINE_WIDTH)
	draw_line(to - direction * EMITTER_LENGTH, to, metal.lightened(0.25), width + EMITTER_EXTRA)
	draw_line(to - direction * 1.0, to, shine, width + EMITTER_EXTRA)
	if not long_haft:
		draw_line(from, from + direction * POMMEL_LENGTH, metal.darkened(0.45), width + 1.0)
	var button: Vector2 = from.lerp(to, BUTTON_AT) + side * width * 0.5
	draw_rect(Rect2(button - Vector2.ONE * BUTTON_SIZE * 0.5, Vector2.ONE * BUTTON_SIZE), button_color)


func _draw_grip(from: Vector2, to: Vector2) -> void:
	draw_line(from, to, grip_color, GRIP_WIDTH)
