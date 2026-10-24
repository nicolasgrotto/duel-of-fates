class_name FighterReflection
extends Node2D

const FLIP: Transform2D = Transform2D(Vector2(1.0, 0.0), Vector2(0.0, -1.0), Vector2.ZERO)

var view: FighterView
var tint: Color = Color.WHITE


func setup(fighter_view: FighterView, strength: float, shade: Color) -> void:
	view = fighter_view
	tint = Color(shade, strength)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if view == null or view.rig == null:
		return
	if material != view.rig.shader_material:
		material = view.rig.shader_material
	view.rig.draw_reflection(self, FLIP, tint)
