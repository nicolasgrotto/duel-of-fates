class_name MenuEmblem
extends Control

const UPSCALE_SHADER: Shader = preload("res://presentation/camera/pixel_upscale.gdshader")
const PALETTE: UiPalette = preload("res://ui/palette.tres")
const PIXEL_SCALE: float = 4.0
const BLADE_HALF: Vector2 = Vector2(78.0, 44.0)
const HILT_LENGTH: float = 9.0
const IGNITE_DELAY: float = 0.25
const IGNITE_TIME: float = 0.45
const CONTACT_FLASH: float = 0.35
const SPARK_POOL: int = 24
const SPARK_INTERVAL: float = 0.22
const SPARK_GRAVITY: float = 60.0
const MOTES: int = 18
const HORIZON_RATIOS: PackedFloat32Array = [0.86, 0.885]

var cross_point: Vector2 = Vector2.ZERO

var _viewport: SubViewport
var _canvas: Node2D
var _glow: Node2D
var _display: TextureRect
var _time: float = 0.0
var _spark_clock: float = 0.0
var _sparks: PackedVector2Array = []
var _spark_speeds: PackedVector2Array = []
var _spark_ages: PackedFloat32Array = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_viewport = SubViewport.new()
	_viewport.transparent_bg = false
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.snap_2d_transforms_to_pixel = true
	_viewport.snap_2d_vertices_to_pixel = true
	_viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	add_child(_viewport)
	var backdrop: ColorRect = ColorRect.new()
	backdrop.color = PALETTE.background
	backdrop.size = Vector2(4096.0, 4096.0)
	_viewport.add_child(backdrop)
	_canvas = Node2D.new()
	_canvas.draw.connect(_draw_scene)
	_viewport.add_child(_canvas)
	_glow = Node2D.new()
	var additive: CanvasItemMaterial = CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow.material = additive
	_glow.draw.connect(_draw_glow)
	_viewport.add_child(_glow)
	_display = TextureRect.new()
	_display.texture = _viewport.get_texture()
	_display.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var upscale: ShaderMaterial = ShaderMaterial.new()
	upscale.shader = UPSCALE_SHADER
	_display.material = upscale
	_display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_display.stretch_mode = TextureRect.STRETCH_SCALE
	_display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_display)
	_sparks.resize(SPARK_POOL)
	_spark_speeds.resize(SPARK_POOL)
	_spark_ages.resize(SPARK_POOL)
	_spark_ages.fill(INF)


func _process(delta: float) -> void:
	_time += delta
	var screen: Vector2 = get_viewport_rect().size
	var grid: Vector2i = Vector2i(ceili(screen.x / PIXEL_SCALE), ceili(screen.y / PIXEL_SCALE))
	if grid.x > 0 and _viewport.size != grid:
		_viewport.size = grid
		_display.size = Vector2(grid) * PIXEL_SCALE
	_spark_clock += delta
	if _ignition() >= 1.0 and _spark_clock >= SPARK_INTERVAL:
		_spark_clock = _rng.randf_range(-0.1, 0.1)
		_emit_spark()
	for i in SPARK_POOL:
		_spark_ages[i] += delta
		_spark_speeds[i].y += SPARK_GRAVITY * delta
		_sparks[i] += _spark_speeds[i] * delta
	_canvas.queue_redraw()
	_glow.queue_redraw()


func _ignition() -> float:
	return clampf((_time - IGNITE_DELAY) / IGNITE_TIME, 0.0, 1.0)


func _center() -> Vector2:
	return (cross_point / PIXEL_SCALE).round()


func _emit_spark() -> void:
	var slot: int = 0
	for i in SPARK_POOL:
		if _spark_ages[i] > _spark_ages[slot]:
			slot = i
	_sparks[slot] = _center()
	_spark_speeds[slot] = Vector2(_rng.randf_range(-22.0, 22.0), _rng.randf_range(-26.0, -6.0))
	_spark_ages[slot] = 0.0


func _blades() -> Array[PackedVector2Array]:
	var center: Vector2 = _center()
	var a: PackedVector2Array = [center + Vector2(-BLADE_HALF.x, BLADE_HALF.y), center + Vector2(BLADE_HALF.x, -BLADE_HALF.y)]
	var b: PackedVector2Array = [center + Vector2(BLADE_HALF.x, BLADE_HALF.y), center + Vector2(-BLADE_HALF.x, -BLADE_HALF.y)]
	return [a, b]


func _draw_scene() -> void:
	var center: Vector2 = _center()
	var width: float = float(_viewport.size.x)
	for ratio in HORIZON_RATIOS:
		_canvas.draw_rect(Rect2(0.0, round(_viewport.size.y * ratio), width, 1.0), PALETTE.menu_horizon)
	for i in MOTES:
		var drift: float = fposmod(_time * (3.0 + i % 4) + i * 37.0, float(_viewport.size.y))
		var x: float = fposmod(i * 53.0 + sin(_time * 0.3 + i) * 6.0, width)
		_canvas.draw_rect(Rect2(Vector2(x, _viewport.size.y - drift).round(), Vector2.ONE), Color(PALETTE.secondary, 0.25))
	for blade in _blades():
		var direction: Vector2 = (blade[1] - blade[0]).normalized()
		_canvas.draw_line(blade[0] - direction * HILT_LENGTH, blade[0], PALETTE.menu_hilt, 3.0)
		_canvas.draw_line(blade[0] - direction * HILT_LENGTH, blade[0] - direction * (HILT_LENGTH - 2.0), PALETTE.menu_hilt.lightened(0.3), 3.0)


func _draw_glow() -> void:
	var lit: float = _ignition()
	if lit <= 0.0:
		return
	var colors: Array[Color] = [PALETTE.menu_blade_a, PALETTE.menu_blade_b]
	var blades: Array[PackedVector2Array] = _blades()
	var hum: float = 0.85 + 0.15 * sin(_time * 9.0) * sin(_time * 5.3)
	for i in blades.size():
		var tip: Vector2 = blades[i][0].lerp(blades[i][1], lit)
		_glow.draw_line(blades[i][0], tip, Color(colors[i], 0.12 * hum), 9.0)
		_glow.draw_line(blades[i][0], tip, Color(colors[i], 0.22 * hum), 5.0)
		_glow.draw_line(blades[i][0], tip, Color(colors[i], 0.9), 3.0)
		_glow.draw_line(blades[i][0], tip, Color.WHITE, 1.0)
	if lit < 1.0:
		return
	var center: Vector2 = _center()
	var since: float = _time - IGNITE_DELAY - IGNITE_TIME
	var flash: float = clampf(1.0 - since / CONTACT_FLASH, 0.0, 1.0)
	var pulse: float = 0.6 + 0.4 * sin(_time * 6.0)
	var arm: float = round(3.0 + 3.0 * pulse + 10.0 * flash)
	_glow.draw_rect(Rect2(center - Vector2(arm, 0.0), Vector2(arm * 2.0 + 1.0, 1.0)), Color(PALETTE.spark_warm, 0.9))
	_glow.draw_rect(Rect2(center - Vector2(0.0, arm), Vector2(1.0, arm * 2.0 + 1.0)), Color(PALETTE.spark_warm, 0.9))
	_glow.draw_rect(Rect2(center - Vector2.ONE, Vector2(3.0, 3.0)), Color.WHITE)
	if flash > 0.0:
		_glow.draw_circle(center, 6.0 + 30.0 * (1.0 - flash), Color(PALETTE.spark_hot, 0.3 * flash))
	for i in SPARK_POOL:
		if _spark_ages[i] < 1.2:
			var tint: Color = PALETTE.spark_hot if i % 2 == 0 else PALETTE.spark_warm
			_glow.draw_rect(Rect2(_sparks[i].round(), Vector2.ONE), Color(tint, 1.0 - _spark_ages[i] / 1.2))
