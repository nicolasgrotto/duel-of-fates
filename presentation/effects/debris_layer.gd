class_name DebrisLayer
extends Node2D

const PALETTE: UiPalette = preload("res://ui/palette.tres")
const POOL: int = 96
const GRID: float = 2.0
const FADE_STEPS: float = 3.0
const CHUNK_POINTS: int = 5
const DUST_ALPHA: float = 0.45

enum Kind { DUST, CHUNK }
enum Mark { FOOTPRINT, RIPPLE }

const MARK_POOL: int = 40
const FOOTPRINT_LIFE: float = 4.0
const RIPPLE_LIFE: float = 0.9
const RIPPLE_RADIUS: float = 26.0
const STEP_DISTANCE: float = 26.0
const STEAM_INTERVAL: float = 0.14

var config: PowerVfxConfig
var sim: MatchSimulation
var floor_y: float = 0.0
var meteors: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]
var meteor_times: PackedFloat32Array = PackedFloat32Array([-1.0, -1.0])
var meteor_facing: PackedInt32Array = PackedInt32Array([1, 1])

var views: Array[FighterView] = []
var arena: ArenaData

var _hover: PackedFloat32Array = PackedFloat32Array([0.0, 0.0])
var _tints: PackedColorArray = []
var _tint: Color = Color.WHITE
var _marks: PackedVector2Array = []
var _mark_ages: PackedFloat32Array = []
var _mark_kinds: PackedInt32Array = []
var _next_mark: int = 0
var _last_step: PackedFloat32Array = PackedFloat32Array([0.0, 0.0])
var _steam_clock: float = 0.0
var _time: float = 0.0

var _kinds: PackedInt32Array = []
var _positions: PackedVector2Array = []
var _velocities: PackedVector2Array = []
var _ages: PackedFloat32Array = []
var _lives: PackedFloat32Array = []
var _sizes: PackedFloat32Array = []
var _spins: PackedFloat32Array = []
var _next: int = 0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _shape: PackedVector2Array = []


func _ready() -> void:
	_kinds.resize(POOL)
	_positions.resize(POOL)
	_velocities.resize(POOL)
	_ages.resize(POOL)
	_lives.resize(POOL)
	_lives.fill(0.0)
	_sizes.resize(POOL)
	_spins.resize(POOL)
	_tints.resize(POOL)
	_tints.fill(PALETTE.dust)
	_marks.resize(MARK_POOL)
	_mark_ages.resize(MARK_POOL)
	_mark_ages.fill(INF)
	_mark_kinds.resize(MARK_POOL)
	_shape.resize(CHUNK_POINTS)


func on_event(event: CombatEvent) -> void:
	if sim == null:
		return
	var at: Vector2 = Vector2(event.position.x, -event.position.y)
	match event.type:
		CombatEvent.Type.POWER_ACTIVE:
			_on_power_active(event)
		CombatEvent.Type.SHOVE:
			var shover: FighterState = sim.fighters[event.source]
			dust(Vector2(shover.x + shover.facing * 20.0, floor_y), config.shove_dust, 10.0, 60.0)
		CombatEvent.Type.PROJECTILE_ENDED:
			if event.power != null and event.power.kind == PowerData.Kind.THROW:
				chunks(at, config.throw_impact_chunks, 360.0, 6.0)
				dust(Vector2(at.x, minf(at.y + 10.0, floor_y)), 2, 8.0, 40.0)
		CombatEvent.Type.HAZARD_TRIGGERED:
			match int(event.amount):
				Hazard.Kind.FRACTURE:
					chunks(Vector2(at.x, floor_y), config.fracture_chunks, 520.0, 5.0)
					dust(Vector2(at.x, floor_y), config.fracture_dust, 16.0, 50.0)
				Hazard.Kind.ROCK_DROP:
					chunks(Vector2(at.x, floor_y - 4.0), config.rain_chunks, 480.0, 7.0)
					dust(Vector2(at.x, floor_y), config.rain_dust, 24.0, 90.0)
				Hazard.Kind.BOLT:
					dust(Vector2(at.x, floor_y), 2, 10.0, 50.0)
		CombatEvent.Type.ROUND_STARTED:
			meteor_times.fill(-1.0)
			_lives.fill(0.0)
			_mark_ages.fill(INF)
		CombatEvent.Type.HIT, CombatEvent.Type.GUARD_BREAK:
			if arena != null and arena.knockback_dust and event.target >= 0 and sim.fighters[event.target].on_ground:
				var struck: FighterState = sim.fighters[event.target]
				var push: float = float(sim.fighters[event.source].facing) if event.source >= 0 else 0.0
				for puff in 4:
					_tint = PALETTE.salt
					_spawn(Kind.DUST, Vector2(struck.x - push * 6.0 * puff, floor_y), Vector2(push * _rng.randf_range(90.0, 180.0), -config.dust_rise * 0.5), config.dust_life, config.dust_size)
				_tint = PALETTE.dust
		CombatEvent.Type.LAND, CombatEvent.Type.DODGE:
			_kick(event.source)
			if event.type == CombatEvent.Type.LAND and EffectsDirector.is_plunging(sim, event.source):
				_plunge_impact(event.source)


func _on_power_active(event: CombatEvent) -> void:
	var caster: FighterState = sim.fighters[event.source]
	match event.power.kind:
		PowerData.Kind.REPULSE:
			for i in config.repulse_dust:
				var reach: float = event.power.reach * (i + 1.0) / config.repulse_dust
				dust(Vector2(caster.x + caster.facing * reach, floor_y), 1, 6.0, 30.0)
		PowerData.Kind.SUPREME_PUSH:
			for side in [-1.0, 1.0]:
				for i in config.repulse_dust / 2:
					dust(Vector2(caster.x + side * event.power.reach * (i + 1.0) / (config.repulse_dust / 2), floor_y), 1, 6.0, 40.0)
		PowerData.Kind.FRACTURE:
			dust(Vector2(caster.x + caster.facing * 30.0, floor_y), config.fracture_dust + 2, 12.0, 120.0)
			chunks(Vector2(caster.x + caster.facing * 30.0, floor_y), 3, 300.0, 4.0)
		PowerData.Kind.MASS_TELEKINESIS:
			var target: FighterState = sim.opponent_of(caster)
			meteors[caster.index] = Vector2(target.x, -config.meteor_height)
			meteor_times[caster.index] = 0.0
			meteor_facing[caster.index] = caster.facing


func _plunge_impact(index: int) -> void:
	var fighter: FighterState = sim.fighters[index]
	var x: float = fighter.x + fighter.facing * fighter.character.family.stance_width
	if index < views.size():
		var segment: PackedVector2Array = views[index].blade_segment()
		if not segment.is_empty():
			x = segment[1].x
	dust(Vector2(x, floor_y), config.plunge_dust, 12.0, 80.0)
	chunks(Vector2(x, floor_y - 2.0), config.plunge_chunks, 260.0, 3.0)


func _kick(index: int) -> void:
	if arena == null or index < 0:
		return
	var fighter: FighterState = sim.fighters[index]
	if arena.footprints:
		tinted_dust(Vector2(fighter.x, floor_y), 3, 10.0, 70.0, PALETTE.snow)
	if arena.ripples:
		_mark(Vector2(fighter.x, floor_y), Mark.RIPPLE)


func _mark(at: Vector2, kind: Mark) -> void:
	_marks[_next_mark] = at.snapped(Vector2(GRID, GRID))
	_mark_ages[_next_mark] = 0.0
	_mark_kinds[_next_mark] = kind
	_next_mark = (_next_mark + 1) % MARK_POOL


func _track_floor(delta: float) -> void:
	if arena == null or sim == null:
		return
	for fighter in sim.fighters:
		if not fighter.on_ground:
			continue
		if absf(fighter.x - _last_step[fighter.index]) >= STEP_DISTANCE:
			_last_step[fighter.index] = fighter.x
			if arena.footprints:
				_mark(Vector2(fighter.x + _rng.randf_range(-4.0, 4.0), floor_y + GRID * 2.0), Mark.FOOTPRINT)
			if arena.ripples:
				_mark(Vector2(fighter.x, floor_y), Mark.RIPPLE)
	if arena.rain_steam:
		_steam_clock += delta
		if _steam_clock >= STEAM_INTERVAL:
			_steam_clock = 0.0
			for view in views:
				if view.blade != null and view.blade.length_ratio > 0.0:
					var at: Vector2 = view.blade.point_along(_rng.randf_range(0.2, 1.0))
					_tint = PALETTE.steam
					_spawn(Kind.DUST, at, Vector2(_rng.randf_range(-10.0, 10.0), -config.dust_rise * 0.8), config.dust_life * 0.6, config.dust_size * 0.5)
					_tint = PALETTE.dust


func meteor_progress(index: int) -> float:
	if meteor_times[index] < 0.0:
		return -1.0
	return meteor_times[index] / config.meteor_crack


func rain_position(hazard: Hazard) -> Vector2:
	var meteor: Vector2 = meteors[hazard.owner]
	var total: float = Ticks.to_seconds(int(hazard.total_delay))
	var elapsed: float = total - Ticks.to_seconds(hazard.delay_ticks)
	var spread: Vector2 = Vector2(sin(hazard.group * 2.1) * config.meteor_radius * 0.6, cos(hazard.group * 1.3) * config.meteor_radius * 0.4)
	if meteor_times[hazard.owner] >= 0.0 and meteor_times[hazard.owner] < config.meteor_crack:
		return meteor + spread
	var fall: float = clampf(elapsed / maxf(total, 0.01), 0.0, 1.0)
	return (meteor + spread).lerp(Vector2(hazard.x, floor_y), fall * fall)


func tinted_dust(at: Vector2, count: int, spread: float, speed: float, tint: Color) -> void:
	_tint = tint
	dust(at, count, spread, speed)
	_tint = PALETTE.dust


func dust(at: Vector2, count: int, spread: float, speed: float) -> void:
	for i in count:
		var side: float = _rng.randf_range(-1.0, 1.0)
		var velocity: Vector2 = Vector2(side * speed, -config.dust_rise * _rng.randf_range(0.4, 1.0))
		_spawn(Kind.DUST, at + Vector2(side * spread, 0.0), velocity, config.dust_life * _rng.randf_range(0.7, 1.2), config.dust_size * _rng.randf_range(0.7, 1.3))


func chunks(at: Vector2, count: int, speed: float, size: float, direction: float = 0.0) -> void:
	for i in count:
		var angle: float = -PI * 0.5 + _rng.randf_range(-0.9, 0.9) + direction * 0.5
		var velocity: Vector2 = Vector2.from_angle(angle) * speed * _rng.randf_range(0.5, 1.1)
		_spawn(Kind.CHUNK, at, velocity, config.chunk_life * _rng.randf_range(0.7, 1.1), size * _rng.randf_range(0.5, 1.0))


func _spawn(kind: Kind, at: Vector2, velocity: Vector2, life: float, size: float) -> void:
	_kinds[_next] = kind
	_tints[_next] = _tint if kind == Kind.DUST else PALETTE.dust
	_positions[_next] = at
	_velocities[_next] = velocity
	_ages[_next] = 0.0
	_lives[_next] = life
	_sizes[_next] = size
	_spins[_next] = _rng.randf_range(-12.0, 12.0)
	_next = (_next + 1) % POOL


func _process(delta: float) -> void:
	if config == null:
		return
	_time += delta
	_track_floor(delta)
	for i in MARK_POOL:
		_mark_ages[i] += delta
	for i in meteor_times.size():
		if meteor_times[i] >= 0.0:
			var before: float = meteor_times[i]
			meteor_times[i] += delta
			if before < config.meteor_crack and meteor_times[i] >= config.meteor_crack:
				chunks(meteors[i], 5, 260.0, 6.0)
			if meteor_times[i] > config.meteor_crack + 2.0:
				meteor_times[i] = -1.0
	for i in POOL:
		if _lives[i] <= 0.0:
			continue
		_ages[i] += delta
		if _ages[i] >= _lives[i]:
			_lives[i] = 0.0
			continue
		if _kinds[i] == Kind.CHUNK:
			_velocities[i].y += config.chunk_gravity * delta
			_positions[i] += _velocities[i] * delta
			if _positions[i].y > floor_y and _velocities[i].y > 0.0:
				_positions[i].y = floor_y
				_velocities[i] = Vector2(_velocities[i].x * 0.6, -_velocities[i].y * config.chunk_bounce)
				_spins[i] *= 0.5
		else:
			_velocities[i] *= 1.0 - minf(delta * 3.0, 1.0)
			_positions[i] += _velocities[i] * delta
	queue_redraw()


func _draw() -> void:
	_draw_marks()
	if sim != null:
		_draw_powers()
	for i in POOL:
		if _lives[i] <= 0.0:
			continue
		var progress: float = _ages[i] / _lives[i]
		var at: Vector2 = _positions[i].snapped(Vector2(GRID, GRID))
		match _kinds[i]:
			Kind.DUST:
				var strength: float = ceilf((1.0 - progress) * FADE_STEPS) / FADE_STEPS
				var radius: float = snappedf(_sizes[i] * (0.6 + progress), GRID)
				draw_circle(at, radius, Color(_tints[i], DUST_ALPHA * strength))
				draw_circle(at + Vector2(-GRID, -GRID), radius * 0.5, Color(_tints[i].lightened(0.2), DUST_ALPHA * strength))
			Kind.CHUNK:
				if progress > 0.8 and int(_ages[i] * 30.0) % 2 == 0:
					continue
				draw_rock(self, at, _sizes[i], _ages[i] * _spins[i], i)


static func rock_points(at: Vector2, size: float, angle: float, variant: int, out: PackedVector2Array) -> void:
	var count: int = out.size()
	for p in count:
		var a: float = angle + p * TAU / count
		var radius: float = size * (0.75 + 0.3 * sin(variant * 1.7 + p * 2.3))
		out[p] = at + Vector2(cos(a), sin(a)) * radius


func draw_rock(canvas: CanvasItem, at: Vector2, size: float, angle: float, variant: int) -> void:
	rock_points(at, size, angle, variant, _shape)
	canvas.draw_colored_polygon(_shape, PALETTE.rock)
	canvas.draw_line(_shape[0], _shape[1], PALETTE.rock_light, GRID)


func _draw_marks() -> void:
	for i in MARK_POOL:
		match _mark_kinds[i]:
			Mark.FOOTPRINT:
				if _mark_ages[i] < FOOTPRINT_LIFE:
					var fade: float = ceilf((1.0 - _mark_ages[i] / FOOTPRINT_LIFE) * FADE_STEPS) / FADE_STEPS
					draw_rect(Rect2(_marks[i], Vector2(GRID * 3.0, GRID)), Color(PALETTE.scar.lerp(PALETTE.snow, 0.4), 0.5 * fade))
			Mark.RIPPLE:
				if _mark_ages[i] < RIPPLE_LIFE:
					var progress: float = _mark_ages[i] / RIPPLE_LIFE
					var radius: float = snappedf(RIPPLE_RADIUS * (0.3 + progress), GRID)
					var strength: float = ceilf((1.0 - progress) * FADE_STEPS) / FADE_STEPS
					draw_rect(Rect2(_marks[i] + Vector2(-radius, GRID * 2.0), Vector2(radius * 2.0, GRID)), Color(PALETTE.ripple, 0.35 * strength))
					draw_rect(Rect2(_marks[i] + Vector2(-radius * 0.6, GRID * 4.0), Vector2(radius * 1.2, GRID)), Color(PALETTE.ripple, 0.2 * strength))


func _draw_powers() -> void:
	for fighter in sim.fighters:
		_draw_hover_rocks(fighter)
		var progress: float = meteor_progress(fighter.index)
		if progress >= 0.0 and progress < 1.0:
			var arrive: float = 1.0 - pow(1.0 - progress, 2.0)
			var start: Vector2 = meteors[fighter.index] + Vector2(-meteor_facing[fighter.index] * config.meteor_pull, -config.meteor_pull * 0.6)
			var at: Vector2 = start.lerp(meteors[fighter.index], arrive)
			var radius: float = config.meteor_radius * (0.7 + 0.3 * arrive)
			draw_rock(self, at, radius, _time * 0.8, 7)
			draw_circle(at + Vector2(-radius * 0.3, -radius * 0.3), radius * 0.25, PALETTE.rock_light)
	for projectile in sim.projectiles:
		if projectile.active and projectile.kind == Projectile.Kind.ROCK:
			draw_rock(self, Vector2(projectile.x, -projectile.y), projectile.size, _time * 6.0, projectile.owner * 3 + int(projectile.travelled) % 3)
	for hazard in sim.hazards:
		if hazard.active and hazard.kind == Hazard.Kind.ROCK_DROP and meteor_times[hazard.owner] >= config.meteor_crack:
			draw_rock(self, rain_position(hazard), 12.0, _time * 5.0 + hazard.group, hazard.group)


func _draw_hover_rocks(fighter: FighterState) -> void:
	var throwing: bool = fighter.power != null and fighter.power.kind == PowerData.Kind.THROW and (fighter.state == FighterState.State.CASTING or fighter.state == FighterState.State.CHANNELING)
	var count: int = int(fighter.power.tier_value(fighter.flow_tier)) if throwing else 0
	var lift: float = 0.0
	if throwing:
		if fighter.power_phase == FighterState.Phase.STARTUP:
			lift = clampf(float(fighter.power_ticks) / maxf(fighter.power.startup_ticks(), 1.0), 0.0, 1.0)
			if _hover[fighter.index] == 0.0:
				dust(Vector2(fighter.x + fighter.facing * 34.0, floor_y), config.throw_rise_dust, 18.0, 40.0)
		elif fighter.power_phase == FighterState.Phase.ACTIVE:
			lift = 1.0
	if lift == 0.0 and _hover[fighter.index] > 0.0 and fighter.state != FighterState.State.CASTING:
		for i in _hover_count(fighter):
			chunks(_hover_at(fighter, i, _hover[fighter.index]), 1, 80.0, 6.0)
	_hover[fighter.index] = lift
	for i in range(fighter.spawned if fighter.power_phase == FighterState.Phase.ACTIVE else 0, count):
		draw_rock(self, _hover_at(fighter, i, lift), 9.0 + fighter.flow_tier * 2.5, _time * 2.0 + i, i)


func _hover_count(fighter: FighterState) -> int:
	return maxi(fighter.flow_tier + 1, 1)


func _hover_at(fighter: FighterState, index: int, lift: float) -> Vector2:
	var eased: float = 1.0 - pow(1.0 - lift, 3.0)
	var x: float = fighter.x + fighter.facing * (30.0 + index * 16.0)
	var height: float = config.throw_rise_height * eased + index * 8.0 * eased + sin(_time * 5.0 + index) * 2.0 * eased
	return Vector2(x, floor_y - 6.0 - height)
