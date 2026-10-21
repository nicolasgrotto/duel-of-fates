class_name Afterimages
extends Node2D

const SILHOUETTE: Shader = preload("res://presentation/fighters/silhouette.gdshader")
const COUNT: int = 3
const LIFE: float = 0.22
const ALPHA: float = 0.35
const INTERVAL: float = 0.05

var color: Color = Color.WHITE
var _images: Array = []
var _ages: PackedFloat32Array = []
var _since_last: float = 0.0
var _shader_material: ShaderMaterial


func _ready() -> void:
	_shader_material = ShaderMaterial.new()
	_shader_material.shader = SILHOUETTE
	material = _shader_material


func capture(rig: FighterRig, delta: float) -> void:
	_since_last += delta
	if _since_last < INTERVAL:
		return
	_since_last = 0.0
	_images.append(rig.sprite_snapshots())
	_ages.append(0.0)
	if _images.size() > COUNT:
		_images.remove_at(0)
		_ages.remove_at(0)


func _process(delta: float) -> void:
	for i in range(_ages.size() - 1, -1, -1):
		_ages[i] += delta
		if _ages[i] > LIFE:
			_images.remove_at(i)
			_ages.remove_at(i)
	queue_redraw()


func _draw() -> void:
	for i in _images.size():
		var fade: float = (1.0 - _ages[i] / LIFE) * ALPHA
		_shader_material.set_shader_parameter(&"tint", Color(color, 1.0))
		for shot in _images[i]:
			var texture: CanvasTexture = shot[0]
			draw_set_transform_matrix(shot[1])
			draw_texture(texture.diffuse_texture, Vector2.ZERO, Color(1.0, 1.0, 1.0, fade))
	draw_set_transform_matrix(Transform2D.IDENTITY)
