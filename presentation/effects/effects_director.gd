class_name EffectsDirector
extends Node2D

signal camera_impulse(shake: float, duration: float, punch_in: float, focus: Vector2)
signal screen_flash(alpha: float)
signal rumbled(weak: float, strong: float, duration: float, source: int, target: int)

const PALETTE: UiPalette = preload("res://ui/palette.tres")
const SPARK_POOL: int = 256
const RING_POOL: int = 8
const SPARK_WIDTH: float = 2.4
const RING_WIDTH: float = 3.0

var config: EffectsConfig
var sim: MatchSimulation
var reduced: bool = false
var blade_colors: Array[Color] = [Color.WHITE, Color.WHITE]

var _positions: PackedVector2Array = []
var _velocities: PackedVector2Array = []
var _lives: PackedFloat32Array = []
var _colors: PackedColorArray = []
var _next_spark: int = 0
var _ring_positions: PackedVector2Array = []
var _ring_ages: PackedFloat32Array = []
var _ring_radii: PackedFloat32Array = []
var _ring_colors: PackedColorArray = []
var _next_ring: int = 0
var _lock_height: float = 0.0
var _lock_spark_clock: float = 0.0
var _lock_pulse_clock: float = 0.0
var _lock_pulse_side: int = 0


func _ready() -> void:
	var additive: CanvasItemMaterial = CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = additive
	_positions.resize(SPARK_POOL)
	_velocities.resize(SPARK_POOL)
	_lives.resize(SPARK_POOL)
	_colors.resize(SPARK_POOL)
	_ring_positions.resize(RING_POOL)
	_ring_ages.resize(RING_POOL)
	_ring_radii.resize(RING_POOL)
	_ring_colors.resize(RING_POOL)
	_ring_ages.fill(INF)


func on_event(event: CombatEvent) -> void:
	if event.type == CombatEvent.Type.BLADE_LOCK_STARTED:
		_lock_height = -event.position.y
	var recipe: EffectRecipe = _recipe_for(event)
	if recipe == null:
		return
	var contact: Vector2 = Vector2(event.position.x, -event.position.y)
	var direction: float = _direction(event)
	_burst(recipe, contact, direction, event)
	if recipe.ring_radius > 0.0:
		_ring(contact, recipe.ring_radius, _ring_color(event))
	var motion: float = config.reduced_motion_scale if reduced else 1.0
	camera_impulse.emit(recipe.shake * motion, recipe.shake_duration, recipe.punch_in * motion, contact)
	if recipe.flash > 0.0 and not reduced:
		screen_flash.emit(recipe.flash)
	if recipe.rumble_duration > 0.0:
		rumbled.emit(recipe.rumble_weak, recipe.rumble_strong, recipe.rumble_duration, event.source, event.target)


func _recipe_for(event: CombatEvent) -> EffectRecipe:
	match event.type:
		CombatEvent.Type.HIT:
			return config.hit_heavy if event.heavy else config.hit_light
		CombatEvent.Type.BLOCK:
			return config.block
		CombatEvent.Type.GUARD_BREAK:
			return config.guard_break
		CombatEvent.Type.CLASH:
			return config.clash
		CombatEvent.Type.PARRY, CombatEvent.Type.RESPONSE:
			return config.parry
		CombatEvent.Type.ARMOR_ABSORBED:
			return config.hit_light
		CombatEvent.Type.PERFECT_PARRY:
			return config.perfect_parry
		CombatEvent.Type.SHOVE:
			return config.shove
		CombatEvent.Type.BLADE_LOCK_STARTED:
			return config.blade_lock_start
		CombatEvent.Type.BLADE_LOCK_PRESSED:
			return config.blade_lock_press
		CombatEvent.Type.BLADE_LOCK_ENDED:
			return config.blade_lock_end
		CombatEvent.Type.DEATH:
			return config.knockout
		CombatEvent.Type.POWER_HIT:
			return config.power_hit
		CombatEvent.Type.POWER_BLOCKED:
			return config.power_blocked
		CombatEvent.Type.HAZARD_TRIGGERED:
			return config.hazard
		CombatEvent.Type.TECHNIQUE_CLASH:
			return config.technique_clash
		CombatEvent.Type.PROJECTILE_REFLECTED:
			return config.parry
	return null


func _direction(event: CombatEvent) -> float:
	if sim == null or event.source == CombatEvent.NO_FIGHTER or event.target == CombatEvent.NO_FIGHTER:
		return 0.0
	return float(sim.fighters[event.source].facing)


func _ring_color(event: CombatEvent) -> Color:
	if event.target >= 0:
		return blade_colors[event.target]
	return PALETTE.spark_hot


func _burst(recipe: EffectRecipe, origin: Vector2, direction: float, event: CombatEvent) -> void:
	var count: int = randi_range(recipe.sparks_min, recipe.sparks_max)
	if reduced:
		count = int(count * config.reduced_spark_scale)
	var base_angle: float = -deg_to_rad(recipe.lift_degrees)
	if direction < 0.0:
		base_angle = PI - base_angle
	var spread: float = deg_to_rad(recipe.spread_degrees)
	var tint: Color = _spark_tint(event)
	for i in count:
		var angle: float = base_angle + randf_range(-spread, spread) * 0.5
		if direction == 0.0:
			angle = -PI * 0.5 + randf_range(-spread, spread)
		var speed: float = recipe.spark_speed * randf_range(0.5, 1.1)
		_spawn_spark(origin, Vector2.from_angle(angle) * speed, PALETTE.spark_hot if i % 2 == 0 else tint)


func _spark_tint(event: CombatEvent) -> Color:
	if event.source < 0 or sim == null:
		return PALETTE.spark_warm
	match event.type:
		CombatEvent.Type.BLADE_LOCK_PRESSED:
			return blade_colors[event.source]
		CombatEvent.Type.POWER_HIT, CombatEvent.Type.POWER_BLOCKED, CombatEvent.Type.HAZARD_TRIGGERED:
			var tiers: PackedColorArray = PALETTE.flow_tiers
			return tiers[clampi(sim.fighters[event.source].flow_tier, 0, tiers.size() - 1)]
	return PALETTE.spark_warm


func _spawn_spark(origin: Vector2, velocity: Vector2, color: Color) -> void:
	_positions[_next_spark] = origin
	_velocities[_next_spark] = velocity
	_lives[_next_spark] = config.spark_life * randf_range(0.6, 1.0)
	_colors[_next_spark] = color
	_next_spark = (_next_spark + 1) % SPARK_POOL


func _ring(origin: Vector2, radius: float, color: Color) -> void:
	_ring_positions[_next_ring] = origin
	_ring_ages[_next_ring] = 0.0
	_ring_radii[_next_ring] = radius
	_ring_colors[_next_ring] = color
	_next_ring = (_next_ring + 1) % RING_POOL


func _process(delta: float) -> void:
	var drag: float = clampf(1.0 - config.spark_drag * delta, 0.0, 1.0)
	for i in SPARK_POOL:
		if _lives[i] <= 0.0:
			continue
		_lives[i] -= delta
		var velocity: Vector2 = _velocities[i] * drag
		velocity.y += config.spark_gravity * delta
		_velocities[i] = velocity
		_positions[i] += velocity * delta
	for i in RING_POOL:
		_ring_ages[i] += delta
	_feed_lock(delta)
	queue_redraw()


func _feed_lock(delta: float) -> void:
	if sim == null or not BladeLockResolver.is_active(sim):
		return
	var contact: Vector2 = Vector2((sim.fighters[0].x + sim.fighters[1].x) * 0.5, _lock_height)
	_lock_spark_clock += delta
	if _lock_spark_clock >= config.lock_spark_interval and not reduced:
		_lock_spark_clock = 0.0
		for side in 2:
			var angle: float = -PI * 0.5 + randf_range(-1.2, 1.2)
			_spawn_spark(contact, Vector2.from_angle(angle) * randf_range(180.0, 380.0), blade_colors[side] if randf() < 0.5 else PALETTE.spark_hot)
	_lock_pulse_clock += delta
	if _lock_pulse_clock >= config.lock_pulse_interval:
		_lock_pulse_clock = 0.0
		_lock_pulse_side = 1 - _lock_pulse_side
		_ring(contact, config.lock_pulse_radius, blade_colors[_lock_pulse_side])


func _draw() -> void:
	for i in SPARK_POOL:
		if _lives[i] <= 0.0:
			continue
		var fade: float = _banded(_lives[i] / config.spark_life)
		var tail: Vector2 = _positions[i] - _velocities[i] * config.spark_length
		draw_line(tail, _positions[i], Color(_colors[i], fade), SPARK_WIDTH)
	for i in RING_POOL:
		var progress: float = _ring_ages[i] / config.ring_duration
		if progress >= 1.0:
			continue
		var radius: float = _ring_radii[i] * ease(progress, 0.4)
		draw_arc(_ring_positions[i], radius, 0.0, TAU, 40, Color(_ring_colors[i], _banded(1.0 - progress)), RING_WIDTH)


func _banded(value: float) -> float:
	return ceilf(clampf(value, 0.0, 1.0) * config.fade_steps) / config.fade_steps
