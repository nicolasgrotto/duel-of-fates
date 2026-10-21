class_name FighterPreview
extends Node2D

const CONFIG: CombatConfig = preload("res://data/balance/combat_config.tres")

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
	_rig = FighterRig.new()
	add_child(_rig)
	_rig.build(data, costume)
	_solver.setup(data, data.art)
	if _blade == null:
		_blade = BladeView.new()
		_blade.top_level = true
		add_child(_blade)
	_blade.color = blade_color
	_blade.width_scale = data.weapon.blade_width
	_blade.length_ratio = 1.0
	_blade.eyes_color = costume.color(CostumeData.Slot.EYES)


func _process(delta: float) -> void:
	if _character == null or _rig == null:
		return
	_solver.time += delta
	_solver.solve(_fighter, _fighter, _pose)
	_rig.floor_y = global_position.y
	_rig.apply(_pose, 1, delta)
	_geometry.compute(_character.weapon, _pose)
	var to_global: Transform2D = _rig.get_global_transform()
	_geometry.blade_base = to_global * _geometry.blade_base
	_geometry.blade_direction = to_global.basis_xform(_geometry.blade_direction).normalized()
	_geometry.second_base = to_global * _geometry.second_base
	_geometry.second_direction = to_global.basis_xform(_geometry.second_direction).normalized()
	var length_scale: float = to_global.get_scale().x
	_geometry.blade_length *= length_scale
	_geometry.second_length *= length_scale
	_blade.width_scale = _character.weapon.blade_width * length_scale
	_blade.set_blades(_geometry, false, false)
	_blade.eyes_visible = _rig.shows_eyes()
	_blade.eyes_position = _rig.to_global(_rig.eye_position())
