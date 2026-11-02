class_name CarriedBlasterView
extends Node2D

const PIXELS_PER_UNIT: float = 0.5

var data: BlasterData
var weapon: Sprite2D
var support: Sprite2D


func setup(blaster: BlasterData, shader: ShaderMaterial) -> void:
	data = blaster
	support = _part(data.support_texture, data.support_normal, data.support_pivot, shader)
	weapon = _part(data.texture, data.normal, data.pivot, shader)


func _part(texture: Texture2D, normal: Texture2D, pivot: Vector2, shader: ShaderMaterial) -> Sprite2D:
	var canvas: CanvasTexture = CanvasTexture.new()
	canvas.diffuse_texture = texture
	canvas.normal_texture = normal
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = canvas
	sprite.centered = false
	sprite.offset = -pivot
	sprite.scale = Vector2.ONE / PIXELS_PER_UNIT
	sprite.material = shader
	add_child(sprite)
	return sprite


func update_pose(pose: RigPose) -> void:
	var drawn: bool = pose.sidearm_active and pose.sidearm_draw > 0.0
	var anchor: Vector2 = pose.pelvis + data.carry_anchor.rotated(pose.torso_angle)
	var angle: float = deg_to_rad(data.carry_angle) + pose.torso_angle
	support.position = anchor
	support.rotation = angle
	support.z_index = -8 if data.carry == BlasterData.Carry.BACK else 5
	weapon.position = pose.off_hand if drawn else anchor
	weapon.rotation = pose.sidearm_angle + pose.torso_angle * (1.0 - pose.sidearm_draw) if drawn else angle
	weapon.z_index = 14 if drawn else support.z_index + 1
