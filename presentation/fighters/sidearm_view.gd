class_name SidearmView
extends Node2D

const REST_ANGLE: float = 50.0
const BODY_BACK: float = 3.0
const BODY_FRONT: float = 9.0
const BODY_WIDTH: float = 5.0
const BARREL_END: float = 13.0
const BARREL_WIDTH: float = 3.0
const GRIP_DROP: float = 5.0
const GRIP_BACK: float = 2.0
const GRIP_WIDTH: float = 3.0
const FIN_HEIGHT: float = 3.0
const FIN_FROM: float = 1.0
const FIN_TO: float = 7.0
const FIN_WIDTH: float = 1.5

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
	var direction: Vector2 = Vector2.from_angle(angle)
	var up: Vector2 = direction.orthogonal()
	draw_line(hand, hand - up * GRIP_DROP - direction * GRIP_BACK, grip_color, GRIP_WIDTH)
	draw_line(hand - direction * BODY_BACK, hand + direction * BODY_FRONT, metal, BODY_WIDTH)
	draw_line(hand + direction * BODY_FRONT, hand + direction * BARREL_END, metal.darkened(0.35), BARREL_WIDTH)
	draw_line(hand + up * FIN_HEIGHT + direction * FIN_FROM, hand + up * FIN_HEIGHT + direction * FIN_TO, metal.lightened(0.35), FIN_WIDTH)
