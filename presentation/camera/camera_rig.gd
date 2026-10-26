class_name CameraRig
extends Camera2D

var sim: MatchSimulation
var config: EffectsConfig

var _shake: float = 0.0
var _shake_left: float = 0.0
var _shake_duration: float = 0.0
var _punch: float = 0.0
var _punch_left: float = 0.0
var _focus_x: float = 0.0
var _focus_y: float = 0.0
var _zoom: float = 1.0
var _pull_back: float = 0.0
var _pull_back_left: float = 0.0
var _pull_back_target: float = 0.0
var _sky_offset: float = 0.0
var _sky_time: float = -1.0
var _sky_rise: float = 0.2
var _sky_hold: float = 0.1
var _sky_descend: float = 0.2


func setup(simulation: MatchSimulation, effects_config: EffectsConfig) -> void:
	sim = simulation
	config = effects_config
	_frame(true, 0.0)


func impulse(shake: float, duration: float, punch_in: float, _focus: Vector2) -> void:
	if shake > _shake * (_shake_left / maxf(_shake_duration, 0.001)):
		_shake = shake
		_shake_duration = duration
		_shake_left = duration
	if punch_in > 0.0:
		_punch = maxf(_punch, punch_in)
		_punch_left = config.punch_in_return


func pull_back(amount: float, seconds: float) -> void:
	_pull_back_left = maxf(_pull_back_left, seconds)
	_pull_back_target = amount


func sky_shot(sky_offset: float, rise: float, hold: float, descend: float) -> void:
	_sky_offset = sky_offset
	_sky_rise = rise
	_sky_hold = hold
	_sky_descend = descend
	_sky_time = 0.0


func _sky_lift() -> float:
	if _sky_time < 0.0:
		return 0.0
	if _sky_time < _sky_rise:
		return _sky_offset * smoothstep(0.0, 1.0, _sky_time / _sky_rise)
	var held: float = _sky_time - _sky_rise - _sky_hold
	if held < 0.0:
		return _sky_offset
	return _sky_offset * (1.0 - smoothstep(0.0, 1.0, held / maxf(_sky_descend, 0.001)))


func _process(delta: float) -> void:
	if sim == null:
		return
	if _sky_time >= 0.0:
		_sky_time += delta
		if _sky_time > _sky_rise + _sky_hold + _sky_descend:
			_sky_time = -1.0
	_pull_back_left = maxf(_pull_back_left - delta, 0.0)
	_pull_back = move_toward(_pull_back, _pull_back_target if _pull_back_left > 0.0 else 0.0, config.pull_back_speed * delta * 0.5)
	_frame(false, delta)
	_shake_left = maxf(_shake_left - delta, 0.0)
	_punch_left = maxf(_punch_left - delta, 0.0)
	if _punch_left == 0.0:
		_punch = 0.0


func _frame(instant: bool, delta: float) -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var a: FighterState = sim.fighters[0]
	var b: FighterState = sim.fighters[1]
	var base_zoom: float = viewport_size.y * config.fighter_screen_ratio / sim.config.body_height
	var needed_width: float = absf(b.x - a.x) + config.framing_margin * 2.0
	var target_zoom: float = minf(base_zoom, viewport_size.x / needed_width)
	var target_x: float = (a.x + b.x) * 0.5
	var lift: float = maxf(a.y, b.y) * config.jump_follow
	if instant:
		_zoom = target_zoom
		_focus_x = target_x
		_focus_y = lift
	else:
		_zoom = lerpf(_zoom, target_zoom, clampf(config.zoom_speed * delta, 0.0, 1.0))
		_focus_x = lerpf(_focus_x, target_x, clampf(config.follow_speed * delta, 0.0, 1.0))
		_focus_y = lerpf(_focus_y, lift, clampf(config.follow_speed * delta, 0.0, 1.0))
	var final_zoom: float = _zoom * (1.0 - _pull_back) * (1.0 + _punch * (_punch_left / maxf(config.punch_in_return, 0.001)))
	zoom = Vector2(final_zoom, final_zoom)
	var half_view: float = viewport_size.x * 0.5 / final_zoom
	var limit: float = maxf(sim.config.half_width() + config.arena_margin - half_view, 0.0)
	var center_x: float = clampf(_focus_x, -limit, limit)
	var ground_offset: float = viewport_size.y * (config.ground_screen_ratio - 0.5) / final_zoom
	var center: Vector2 = Vector2(center_x, -ground_offset - _focus_y - _sky_lift())
	if _shake_left > 0.0:
		var strength: float = _shake * (_shake_left / maxf(_shake_duration, 0.001))
		center += Vector2(randf_range(-strength, strength), randf_range(-strength, strength))
	position = center
