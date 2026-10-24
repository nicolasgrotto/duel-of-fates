class_name ArenaThumbnail
extends Node2D

const UPSCALE_SHADER: Shader = preload("res://presentation/camera/pixel_upscale.gdshader")
const GRID: Vector2i = Vector2i(300, 170)
const PIXEL_SCALE: float = 2.0
const UNITS_PER_PIXEL: float = 2.0
const CAMERA_HEIGHT: float = -130.0

var _viewport: SubViewport
var _ambient: CanvasModulate
var _scene: Node
var _arena: ArenaData


func _ready() -> void:
	_viewport = SubViewport.new()
	_viewport.size = GRID
	_viewport.transparent_bg = false
	_viewport.snap_2d_transforms_to_pixel = true
	_viewport.snap_2d_vertices_to_pixel = true
	_viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_viewport)
	var camera: Camera2D = Camera2D.new()
	camera.zoom = Vector2.ONE / UNITS_PER_PIXEL
	camera.position = Vector2(0.0, CAMERA_HEIGHT)
	_viewport.add_child(camera)
	camera.make_current()
	_ambient = CanvasModulate.new()
	_viewport.add_child(_ambient)
	var display: Sprite2D = Sprite2D.new()
	display.texture = _viewport.get_texture()
	display.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	display.scale = Vector2.ONE * PIXEL_SCALE
	var upscale: ShaderMaterial = ShaderMaterial.new()
	upscale.shader = UPSCALE_SHADER
	display.material = upscale
	add_child(display)
	visible = false


func show_arena(arena: ArenaData) -> void:
	if arena == _arena:
		visible = arena != null
		return
	_arena = arena
	if _scene != null:
		_scene.queue_free()
		_scene = null
	visible = arena != null
	if arena == null:
		return
	_scene = arena.scene.instantiate()
	_viewport.add_child(_scene)
	_ambient.color = arena.ambient
