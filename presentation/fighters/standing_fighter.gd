class_name StandingFighter
extends Node2D

const CONFIG: CombatConfig = preload("res://data/balance/combat_config.tres")

var _rig: FighterRig
var _blade: BladeView
var _solver: PoseSolver = PoseSolver.new()
var _pose: RigPose = RigPose.new()
var _geometry: WeaponPose = WeaponPose.new()
var _fighter: FighterState = FighterState.new()
var _character: CharacterData
var _facing: int = 1


func show_fighter(data: CharacterData, costume: CostumeData, blade_color: Color, facing: int) -> void:
	if _rig != null:
		_rig.queue_free()
		_rig = null
	_character = data
	_facing = facing
	if data == null:
		return
	_fighter.setup(0, data, CONFIG)
	_fighter.state = FighterState.State.IDLE
	_rig = FighterRig.new()
	add_child(_rig)
	_rig.build(data, costume)
	_rig.scale.x *= facing
	_solver.setup(data, data.art)
	if _blade == null:
		_blade = BladeView.new()
		_blade.top_level = true
		add_child(_blade)
	_blade.color = blade_color
	_blade.width_scale = data.weapon.blade_width
	_blade.length_ratio = 1.0


func _process(delta: float) -> void:
	if _character == null or _rig == null:
		return
	_solver.advance(delta)
	_solver.solve(_fighter, _fighter, _pose)
	_rig.apply(_pose, _facing, delta)
	_geometry.compute(_character.weapon, _pose)
	var to_global: Transform2D = _rig.get_global_transform()
	var main_span: Vector2 = to_global.basis_xform(_geometry.blade_direction)
	var second_span: Vector2 = to_global.basis_xform(_geometry.second_direction)
	_geometry.blade_base = to_global * _geometry.blade_base
	_geometry.blade_direction = main_span.normalized()
	_geometry.second_base = to_global * _geometry.second_base
	_geometry.second_direction = second_span.normalized()
	_geometry.blade_length *= main_span.length()
	_geometry.second_length *= second_span.length()
	_blade.set_blades(_geometry, false, false)
	_blade.eyes_visible = _rig.shows_eyes()
	_blade.eyes_position = _rig.to_global(_rig.eye_position())
