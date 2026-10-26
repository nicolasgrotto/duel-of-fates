class_name FighterPreview
extends Node2D

const UPSCALE_SHADER: Shader = preload("res://presentation/camera/pixel_upscale.gdshader")
const CONFIG: CombatConfig = preload("res://data/balance/combat_config.tres")
const EFFECTS: EffectsConfig = preload("res://data/balance/effects_config.tres")
const GRID: Vector2i = Vector2i(120, 130)
const FLOOR_MARGIN: int = 6
const PIXEL_SCALE: float = 4.0

var _viewport: SubViewport
var _display: Sprite2D

var _rig: FighterRig
var _blade: BladeView
var _solver: PoseSolver = PoseSolver.new()
var _pose: RigPose = RigPose.new()
var _geometry: WeaponPose = WeaponPose.new()
var _fighter: FighterState = FighterState.new()
var _character: CharacterData


func show_fighter(data: CharacterData, costume: CostumeData, blade_color: Color) -> void:
	if _rig != null:
		_rig.queue_free()
	_character = data
	visible = data != null
	if data == null:
		return
	_fighter.setup(0, data, CONFIG)
	_fighter.state = FighterState.State.IDLE
	if _viewport == null:
		_build_grid()
	_rig = FighterRig.new()
	_viewport.add_child(_rig)
	_rig.build(data, costume)
	_solver.setup(data, data.art)
	if _blade == null:
		_blade = BladeView.new()
		_blade.top_level = true
		_viewport.add_child(_blade)
	_blade.color = blade_color
	_blade.width_scale = data.weapon.blade_width
	_blade.length_ratio = 1.0
	_blade.eyes_color = costume.color(CostumeData.Slot.EYES)


func _build_grid() -> void:
	_viewport = SubViewport.new()
	_viewport.size = GRID
	_viewport.transparent_bg = true
	_viewport.snap_2d_transforms_to_pixel = true
	_viewport.snap_2d_vertices_to_pixel = true
	_viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	add_child(_viewport)
	var camera: Camera2D = Camera2D.new()
	camera.zoom = Vector2.ONE / EFFECTS.units_per_pixel
	camera.position = Vector2(0.0, -(GRID.y * 0.5 - FLOOR_MARGIN) * EFFECTS.units_per_pixel)
	_viewport.add_child(camera)
	camera.make_current()
	_display = Sprite2D.new()
	_display.texture = _viewport.get_texture()
	_display.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var upscale: ShaderMaterial = ShaderMaterial.new()
	upscale.shader = UPSCALE_SHADER
	_display.material = upscale
	_display.centered = true
	_display.scale = Vector2.ONE * PIXEL_SCALE
	_display.position = Vector2(0.0, -(GRID.y * 0.5 - FLOOR_MARGIN) * PIXEL_SCALE)
	add_child(_display)


func _process(delta: float) -> void:
	if _character == null or _rig == null:
		return
	_solver.time += delta
	_solver.solve(_fighter, _fighter, _pose)
	_rig.floor_y = 0.0
	_rig.apply(_pose, 1, delta)
	_geometry.compute(_character.weapon, _pose)
	var rig_transform: Transform2D = _rig.get_global_transform()
	_geometry.blade_base = rig_transform * _geometry.blade_base
	_geometry.blade_direction = rig_transform.basis_xform(_geometry.blade_direction).normalized()
	_geometry.second_base = rig_transform * _geometry.second_base
	_geometry.second_direction = rig_transform.basis_xform(_geometry.second_direction).normalized()
	var length_scale: float = rig_transform.get_scale().x
	_geometry.blade_length *= length_scale
	_geometry.second_length *= length_scale
	_blade.width_scale = _character.weapon.blade_width * length_scale
	_blade.set_blades(_geometry, false, false)
	_blade.eyes_visible = _rig.shows_eyes()
	_blade.eyes_position = _rig.to_global(_rig.eye_position())
