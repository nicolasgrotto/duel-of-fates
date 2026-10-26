class_name SidearmView
extends Node2D

const PALETTE: UiPalette = preload("res://ui/palette.tres")
const REST_ANGLE: float = 50.0
const GRIP: PackedVector2Array = [Vector2(-4.0, 0.0), Vector2(1.0, 0.0), Vector2(-1.0, 8.0), Vector2(-6.0, 8.0)]
const TRIGGER_GUARD: Rect2 = Rect2(1.0, 0.0, 4.0, 3.5)
const BODY: Rect2 = Rect2(-5.0, -5.5, 15.0, 5.5)
const RAIL: Rect2 = Rect2(-3.0, -7.0, 10.0, 1.5)
const BARREL: Rect2 = Rect2(10.0, -4.5, 6.0, 3.0)
const MUZZLE: Rect2 = Rect2(16.0, -5.0, 2.0, 4.0)
const CELL: Rect2 = Rect2(-1.0, -4.0, 7.0, 1.5)
const UNDERSIDE: Rect2 = Rect2(-5.0, -1.0, 15.0, 1.0)
const LINE_WIDTH: float = 1.0
const CELL_ALPHA: float = 0.85

var metal: Color = Color.GRAY
var grip_color: Color = Color.DIM_GRAY
var hand: Vector2 = Vector2.ZERO
var angle: float = 0.0


func setup(costume: CostumeData) -> void:
	metal = costume.color(CostumeData.Slot.METAL)
	grip_color = costume.color(CostumeData.Slot.LEATHER).darkened(0.2)


func update_pose(pose: RigPose) -> void:
	hand = pose.off_hand
	angle = deg_to_rad(lerpf(REST_ANGLE, 0.0, pose.sidearm_raise)) + pose.torso_angle * (1.0 - pose.sidearm_raise)
	queue_redraw()


func _draw() -> void:
	draw_set_transform(hand, angle)
	var dark: Color = metal.darkened(0.5)
	draw_colored_polygon(GRIP, grip_color)
	draw_rect(TRIGGER_GUARD, dark, false, LINE_WIDTH)
	draw_rect(BODY, metal)
	draw_rect(UNDERSIDE, dark)
	draw_rect(RAIL, metal.lightened(0.3))
	draw_rect(BARREL, metal.darkened(0.25))
	draw_rect(MUZZLE, metal.lightened(0.15))
	draw_rect(CELL, Color(PALETTE.bolt, CELL_ALPHA))
	draw_set_transform(Vector2.ZERO)
