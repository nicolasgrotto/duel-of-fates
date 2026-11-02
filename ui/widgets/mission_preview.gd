class_name MissionPreview
extends TextureRect

const UPSCALE_SHADER: Shader = preload("res://presentation/camera/pixel_upscale.gdshader")
const DISPLAY_SIZE: Vector2 = Vector2(960.0, 340.0)


func _ready() -> void:
	custom_minimum_size = DISPLAY_SIZE
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var upscale: ShaderMaterial = ShaderMaterial.new()
	upscale.shader = UPSCALE_SHADER
	material = upscale
	visible = false


func show_texture(image: Texture2D) -> void:
	texture = image
	visible = image != null
