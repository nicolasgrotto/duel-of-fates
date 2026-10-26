class_name PixelStage
extends Node

const UPSCALE_SHADER: Shader = preload("res://presentation/camera/pixel_upscale.gdshader")
const MARGIN_PIXELS: int = 2

var units_per_pixel: float = 2.0
var rig: Camera2D
var viewport: SubViewport
var pixel_scale: float = 4.0

var _camera: Camera2D
var _layer: CanvasLayer
var _display: TextureRect


func _init(grid_units_per_pixel: float) -> void:
	units_per_pixel = grid_units_per_pixel
	viewport = SubViewport.new()
	viewport.snap_2d_transforms_to_pixel = true
	viewport.snap_2d_vertices_to_pixel = true
	viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.size = Vector2i(480, 270)
	add_child(viewport)
	_camera = Camera2D.new()
	_camera.zoom = Vector2.ONE / units_per_pixel
	viewport.add_child(_camera)
	_layer = CanvasLayer.new()
	_layer.layer = 0
	add_child(_layer)
	_display = TextureRect.new()
	_display.texture = viewport.get_texture()
	_display.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_display.stretch_mode = TextureRect.STRETCH_SCALE
	_display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var upscale: ShaderMaterial = ShaderMaterial.new()
	upscale.shader = UPSCALE_SHADER
	_display.material = upscale
	_layer.add_child(_display)


func _ready() -> void:
	process_priority = 100
	_camera.make_current()


func _process(_delta: float) -> void:
	if rig == null:
		return
	var screen: Vector2 = get_viewport().get_visible_rect().size
	pixel_scale = maxf(rig.zoom.x * units_per_pixel, 1.0)
	var grid: Vector2i = Vector2i(ceili(screen.x / pixel_scale) + MARGIN_PIXELS * 2, ceili(screen.y / pixel_scale) + MARGIN_PIXELS * 2)
	if viewport.size != grid:
		viewport.size = grid
	var center: Vector2 = rig.get_screen_center_position()
	var grid_center: Vector2 = (center / units_per_pixel).round() * units_per_pixel
	_camera.position = grid_center
	var remainder: Vector2 = (center - grid_center) / units_per_pixel * pixel_scale
	var shown: Vector2 = Vector2(grid) * pixel_scale
	_display.size = shown
	_display.position = (screen - shown) * 0.5 - remainder
