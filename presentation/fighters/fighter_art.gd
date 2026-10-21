class_name FighterArt
extends Resource

@export var pixels_per_unit: float = 4.0
@export var textures: Dictionary = {}
@export var normals: Dictionary = {}
@export var pivots: Dictionary = {}
@export var dims: Dictionary = {}
@export var cloths: Array = []
@export var default_parts: PackedStringArray = []

var _canvas_textures: Dictionary = {}


func has_part(part: String) -> bool:
	return textures.has(part)


func canvas_texture(part: String) -> CanvasTexture:
	if not _canvas_textures.has(part):
		var texture: CanvasTexture = CanvasTexture.new()
		texture.diffuse_texture = textures[part]
		texture.normal_texture = normals[part]
		_canvas_textures[part] = texture
	return _canvas_textures[part]


func pivot(part: String) -> Vector2:
	return pivots.get(part, Vector2.ZERO)


func dim(key: String) -> float:
	return dims.get(key, 0.0)
