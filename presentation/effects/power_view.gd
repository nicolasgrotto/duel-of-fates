class_name PowerView
extends Node2D

const PALETTE: UiPalette = preload("res://ui/palette.tres")
const POOL: int = 48
const BEAM_SEGMENTS: int = 9
const BEAM_JITTER: float = 9.0
const BEAM_REFRESH: float = 0.05
const ROCK_POINTS: int = 7
const SKY_HEIGHT: float = 900.0
const CLEAVE_SPREAD: float = 1.05
const ARSENAL_LENGTH: float = 30.0
const STORM_DARKEN: float = 0.45
const STORM_FADE: float = 3.0
const FADE_STEPS: float = 3.0

enum Burst { WAVE, RING_IN, RING_OUT, BOLT, FLASH, CHEVRONS }

var sim: MatchSimulation
var views: Array[FighterView] = []
var blade_colors: Array[Color] = [Color.WHITE, Color.WHITE]
var ambient: CanvasModulate
var base_ambient: Color = Color.WHITE

var _kinds: PackedInt32Array = []
var _positions: PackedVector2Array = []
var _directions: PackedFloat32Array = []
var _ages: PackedFloat32Array = []
var _lives: PackedFloat32Array = []
var _sizes: PackedFloat32Array = []
var _colors: PackedColorArray = []
var _next: int = 0
var _time: float = 0.0
var _beam_clock: float = 0.0
var _beam_seed: int = 0
var _storm: float = 0.0


func _ready() -> void:
	var additive: CanvasItemMaterial = CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = additive
	_kinds.resize(POOL)
	_positions.resize(POOL)
	_directions.resize(POOL)
	_ages.resize(POOL)
	_lives.resize(POOL)
	_sizes.resize(POOL)
	_colors.resize(POOL)
	_lives.fill(0.0)


func tier_color(tier: int) -> Color:
	return PALETTE.flow_tiers[clampi(tier, 0, PALETTE.flow_tiers.size() - 1)]


func on_event(event: CombatEvent) -> void:
	if sim == null:
		return
	var at: Vector2 = Vector2(event.position.x, -event.position.y)
	match event.type:
		CombatEvent.Type.POWER_ACTIVE:
			_on_power_active(event)
		CombatEvent.Type.POWER_RESISTED:
			_burst(Burst.RING_OUT, at, 0.0, 0.25, 70.0, tier_color(int(event.amount)))
		CombatEvent.Type.POWER_ABSORBED, CombatEvent.Type.POWER_BLOCKED:
			if event.target >= 0:
				_burst(Burst.RING_OUT, at, 0.0, 0.25, 60.0, tier_color(sim.fighters[event.target].flow_tier))
		CombatEvent.Type.POWER_HIT:
			if event.source >= 0:
				_burst(Burst.FLASH, at, 0.0, 0.12, 34.0, tier_color(sim.fighters[event.source].flow_tier))
		CombatEvent.Type.HAZARD_TRIGGERED:
			_on_hazard(event, at)
		CombatEvent.Type.PROJECTILE_REFLECTED:
			_burst(Burst.RING_OUT, at, 0.0, 0.25, 70.0, blade_colors[event.source])


func _on_power_active(event: CombatEvent) -> void:
	var caster: FighterState = sim.fighters[event.source]
	var color: Color = tier_color(caster.flow_tier)
	var hand: Vector2 = views[caster.index].hand_position(false)
	match event.power.kind:
		PowerData.Kind.REPULSE:
			for i in 3:
				_burst(Burst.CHEVRONS, hand, caster.facing, 0.35 + i * 0.06, event.power.reach * (0.6 + i * 0.2), color)
		PowerData.Kind.SUPREME_PUSH:
			_burst(Burst.RING_OUT, views[caster.index].body_center(), 0.0, 0.35, event.power.reach, color)
			for side in [-1.0, 1.0]:
				_burst(Burst.CHEVRONS, views[caster.index].body_center(), side, 0.35, event.power.reach, color)
		PowerData.Kind.PULL:
			var target: FighterState = sim.opponent_of(caster)
			_burst(Burst.RING_IN, views[target.index].body_center(), 0.0, 0.3, 90.0, color)
		PowerData.Kind.FRACTURE:
			_burst(Burst.FLASH, Vector2(hand.x, 0.0), 0.0, 0.2, 60.0, color)
		PowerData.Kind.HEAL, PowerData.Kind.FOCUS, PowerData.Kind.WRATH, PowerData.Kind.SANCTUARY:
			_burst(Burst.RING_OUT, views[caster.index].body_center(), 0.0, 0.3, 80.0, color)


func _on_hazard(event: CombatEvent, at: Vector2) -> void:
	var owner: FighterState = sim.fighters[event.source]
	var color: Color = tier_color(owner.flow_tier)
	match int(event.amount):
		Hazard.Kind.BOLT:
			_burst(Burst.BOLT, at, 0.0, 0.16, SKY_HEIGHT, color)
			_burst(Burst.FLASH, at, 0.0, 0.18, 40.0, color)
		Hazard.Kind.FRACTURE:
			_burst(Burst.FLASH, at, 0.0, 0.22, 46.0, color)
		Hazard.Kind.ROCK_DROP:
			_burst(Burst.RING_OUT, at, 0.0, 0.3, 70.0, color)


func _burst(kind: Burst, at: Vector2, direction: float, life: float, size: float, color: Color) -> void:
	_kinds[_next] = kind
	_positions[_next] = at
	_directions[_next] = direction
	_ages[_next] = 0.0
	_lives[_next] = life
	_sizes[_next] = size
	_colors[_next] = color
	_next = (_next + 1) % POOL


func _process(delta: float) -> void:
	_time += delta
	_beam_clock += delta
	if _beam_clock >= BEAM_REFRESH:
		_beam_clock = 0.0
		_beam_seed += 1
	for i in POOL:
		if _lives[i] > 0.0:
			_ages[i] += delta
			if _ages[i] >= _lives[i]:
				_lives[i] = 0.0
	_update_storm(delta)
	queue_redraw()


func _update_storm(delta: float) -> void:
	if sim == null or ambient == null:
		return
	var storming: bool = false
	for fighter in sim.fighters:
		storming = storming or (fighter.power_kind_active(PowerData.Kind.STORM))
	_storm = move_toward(_storm, 1.0 if storming else 0.0, delta * STORM_FADE)
	var flash: float = 0.0
	for i in POOL:
		if _lives[i] > 0.0 and _kinds[i] == Burst.BOLT:
			flash = maxf(flash, 1.0 - _ages[i] / _lives[i])
	ambient.color = base_ambient.darkened(STORM_DARKEN * _storm).lerp(base_ambient, flash * 0.6)


func _draw() -> void:
	if sim == null or views.size() < 2:
		return
	for fighter in sim.fighters:
		_draw_fighter(fighter)
	for projectile in sim.projectiles:
		if projectile.active:
			_draw_projectile(projectile)
	for hazard in sim.hazards:
		if hazard.active:
			_draw_hazard(hazard)
	_draw_bursts()


func _draw_fighter(fighter: FighterState) -> void:
	var view: FighterView = views[fighter.index]
	var color: Color = tier_color(fighter.flow_tier)
	var center: Vector2 = view.body_center()
	if fighter.state == FighterState.State.CASTING and fighter.power_phase == FighterState.Phase.STARTUP and fighter.power != null:
		var progress: float = clampf(float(fighter.power_ticks) / maxf(fighter.power.startup_ticks(), 1.0), 0.0, 1.0)
		var hand: Vector2 = view.hand_position(false)
		draw_circle(hand, 4.0 + 10.0 * progress, Color(color, 0.25 + 0.4 * progress))
		draw_circle(hand, 2.0 + 3.0 * progress, Color(Color.WHITE, 0.6))
	if fighter.state == FighterState.State.CHANNELING and fighter.power != null:
		_draw_channel(fighter, view, color)
	if fighter.heal_ticks > 0:
		var rise: float = fmod(_time * 1.6, 1.0)
		draw_circle(center + Vector2(0.0, 30.0 - rise * 70.0), 16.0, Color(color, 0.25 * (1.0 - rise)))
	if fighter.focus_ticks > 0:
		var breath: float = 0.5 + 0.5 * sin(_time * 2.0)
		_draw_ellipse(center, Vector2(32.0, 86.0), Color(color, 0.18 + 0.12 * breath), 3.0)
		for i in 2:
			var angle: float = _time * 3.0 + i * PI
			draw_circle(center + Vector2(cos(angle) * 22.0, -20.0 + sin(angle) * 8.0), 3.0, Color(color, 0.8))
	if fighter.wrath_ticks > 0:
		var flicker: float = randf_range(0.6, 1.0)
		_draw_ellipse(center + Vector2(randf_range(-2.0, 2.0), 0.0), Vector2(34.0, 88.0) * flicker, Color(color, 0.3), 3.0)
		for i in 4:
			var ember: float = fmod(_time * 0.9 + i * 0.25, 1.0)
			draw_circle(center + Vector2((i - 1.5) * 9.0, -40.0 - ember * 50.0), 2.0, Color(PALETTE.ember, 1.0 - ember))
		for i in fighter.wrath_armor:
			draw_arc(center, 10.0 + i * 6.0, 0.0, TAU, 20, Color(color, 0.7), 2.0)
	if fighter.sanctuary_hp > 0.0:
		var shell: Vector2 = Vector2(30.0, 82.0)
		_draw_ellipse(center, shell, Color(color, 0.35), 2.5)
		var cracks: int = int((1.0 - fighter.sanctuary_hp / maxf(fighter.flow_potency * 20.0, 1.0)) * 5.0)
		for i in cracks:
			var angle: float = i * 1.3
			var from: Vector2 = center + Vector2(cos(angle) * shell.x, sin(angle) * shell.y)
			draw_line(from, from.lerp(center, 0.25), Color(Color.WHITE, 0.5), 1.5)
	if fighter.twisted_ticks > 0:
		var head: Vector2 = view.head_position() + Vector2(0.0, -22.0)
		for i in 3:
			var wobble: float = sin(_time * 6.0 + i) * 3.0
			_draw_ellipse(head + Vector2(0.0, -i * 6.0), Vector2(16.0 + i * 5.0 + wobble, 4.0 + i), Color(color, 0.6 - i * 0.15), 1.5)
	if fighter.state == FighterState.State.HELD and not fighter.held_by_choke:
		_draw_ellipse(center, Vector2(30.0, 84.0), Color(color, 0.45), 3.0)
		for i in 2:
			var offset: Vector2 = Vector2(randf_range(-3.0, 3.0), 0.0) * (i + 1)
			_draw_ellipse(center + offset, Vector2(26.0, 80.0), Color(color, 0.15), 1.5)
	if fighter.state == FighterState.State.HELD and fighter.held_by_choke:
		var neck: Vector2 = view.head_position() + Vector2(0.0, 16.0)
		draw_circle(neck, 7.0 + 2.0 * sin(_time * 12.0), Color(color, 0.5))
	if fighter.arsenal_count > 0:
		_draw_arsenal(fighter, view, color)


func _draw_channel(fighter: FighterState, view: FighterView, color: Color) -> void:
	var target: FighterState = sim.opponent_of(fighter)
	var hand: Vector2 = view.hand_position(false)
	var center: Vector2 = view.body_center()
	match fighter.power.kind:
		PowerData.Kind.BARRIER:
			var pulse: float = 0.5 + 0.5 * sin(_time * 8.0)
			var radius: float = fighter.power.strength * (1.0 + fighter.flow_tier * 0.08)
			draw_arc(center, radius, 0.0, TAU, 48, Color(color, 0.35 + 0.2 * pulse), 4.0)
			draw_circle(center, radius, Color(color, 0.05))
		PowerData.Kind.ABSORPTION:
			draw_circle(hand, 8.0, Color(color, 0.5))
			for i in 4:
				var angle: float = _time * 6.0 + i * TAU / 4.0
				draw_circle(hand + Vector2(cos(angle), sin(angle)) * 16.0, 2.0, Color(color, 0.9))
		PowerData.Kind.LIGHTNING:
			if PowerEffects.in_front(sim, fighter, target, fighter.power.reach):
				var beams: int = int(fighter.power.tier_value(fighter.flow_tier))
				for i in beams:
					_draw_beam(hand, views[target.index].chest_position(), color, _beam_seed * 7 + i, 2.5)
				if fighter.flow_tier == 1:
					_draw_beam(hand, views[target.index].body_center(), color, _beam_seed * 5 + 3, 1.5)
		PowerData.Kind.DRAIN:
			var from: Vector2 = views[target.index].chest_position()
			for i in 8:
				var t: float = fmod(_time * 1.5 + i / 8.0, 1.0)
				draw_circle(from.lerp(hand, t), 2.5 * (1.0 - t * 0.5), Color(color, 0.8 - 0.5 * t))
		PowerData.Kind.STORM:
			for i in 3:
				var angle: float = _time * 4.0 + i * TAU / 3.0
				var from: Vector2 = center + Vector2(cos(angle) * 46.0, sin(angle) * 80.0)
				_draw_beam(from, center + Vector2(cos(angle + 0.8) * 46.0, sin(angle + 0.8) * 80.0), color, _beam_seed + i, 1.5)
		PowerData.Kind.CHOKE:
			draw_circle(hand, 6.0, Color(color, 0.5))


func _draw_arsenal(fighter: FighterState, view: FighterView, color: Color) -> void:
	var center: Vector2 = view.body_center()
	for i in fighter.arsenal_count:
		var angle: float = _time * 2.4 + i * TAU / fighter.arsenal_count
		var front: bool = sin(angle) > 0.0
		var at: Vector2 = center + Vector2(cos(angle) * 48.0, sin(angle) * 14.0 - 10.0)
		var length: float = ARSENAL_LENGTH if front else ARSENAL_LENGTH * 0.7
		var tilt: Vector2 = Vector2.from_angle(-0.5 + sin(angle) * 0.3) * length * 0.5
		var tint: Color = Color(blade_colors[fighter.index], 0.95 if front else 0.4)
		draw_line(at - tilt, at + tilt, Color(tint, tint.a * 0.35), 9.0)
		draw_line(at - tilt, at + tilt, tint, 4.0 if front else 2.5)
		draw_line(at - tilt, at + tilt, Color(Color.WHITE, 0.8 if front else 0.3), 1.4)


func _draw_projectile(projectile: Projectile) -> void:
	var at: Vector2 = Vector2(projectile.x, -projectile.y)
	var color: Color = tier_color(projectile.tier)
	match projectile.kind:
		Projectile.Kind.ROCK:
			var points: PackedVector2Array = []
			for i in ROCK_POINTS:
				var angle: float = i * TAU / ROCK_POINTS + _time * 6.0
				var radius: float = projectile.size * (0.8 + 0.25 * sin(i * 2.3))
				points.append(at + Vector2(cos(angle), sin(angle)) * radius)
			points.append(points[0])
			draw_colored_polygon(points, Color(0.08, 0.08, 0.1, 0.9))
			draw_polyline(points, Color(color, 0.9), 1.5)
		Projectile.Kind.CLEAVE:
			var heading: float = 0.0 if projectile.vx >= 0.0 else PI
			var center: Vector2 = at - Vector2.from_angle(heading) * projectile.size
			draw_arc(center, projectile.size * 1.4, heading - CLEAVE_SPREAD, heading + CLEAVE_SPREAD, 18, Color(blade_colors[projectile.owner], 0.35), 14.0)
			draw_arc(center, projectile.size * 1.4, heading - CLEAVE_SPREAD, heading + CLEAVE_SPREAD, 18, Color(blade_colors[projectile.owner], 0.85), 6.0)
			draw_arc(center, projectile.size * 1.4, heading - CLEAVE_SPREAD, heading + CLEAVE_SPREAD, 18, Color(Color.WHITE, 0.9), 2.0)
		Projectile.Kind.BLADE, Projectile.Kind.ARSENAL:
			var spin: float = _time * 22.0
			var half: float = 46.0 if projectile.kind == Projectile.Kind.BLADE else 12.0
			var direction: Vector2 = Vector2.from_angle(spin) * half
			var tint: Color = blade_colors[projectile.owner]
			draw_line(at - direction, at + direction, Color(tint, 0.35), 12.0)
			draw_line(at - direction, at + direction, Color(tint, 0.85), 4.5)
			draw_line(at - direction, at + direction, Color.WHITE, 1.8)


func _draw_hazard(hazard: Hazard) -> void:
	var owner: FighterState = sim.fighters[hazard.owner]
	var color: Color = tier_color(owner.flow_tier)
	var closing: float = 1.0 - float(hazard.delay_ticks) / maxf(hazard.total_delay, 1.0)
	match hazard.kind:
		Hazard.Kind.FRACTURE:
			if closing > 0.55:
				var crack: Color = Color(color, 0.4 + 0.5 * closing)
				var left: float = hazard.x - hazard.half_width
				var points: PackedVector2Array = []
				for i in 6:
					points.append(Vector2(left + i * hazard.half_width * 0.4, -2.0 + sin(i * 2.7 + hazard.x) * 3.0))
				draw_polyline(points, crack, 2.5)
		Hazard.Kind.ROCK_DROP, Hazard.Kind.BOLT:
			var radius: float = hazard.half_width * (1.6 - closing)
			_draw_ellipse(Vector2(hazard.x, 2.0), Vector2(radius, radius * 0.25), Color(color, 0.5 + 0.4 * closing), 2.0)
			if hazard.kind == Hazard.Kind.ROCK_DROP:
				var fall: Vector2 = Vector2(hazard.x - 120.0 * (1.0 - closing), -SKY_HEIGHT * (1.0 - closing))
				draw_circle(fall, 16.0, Color(0.1, 0.1, 0.12, 0.9))
				draw_arc(fall, 16.0, 0.0, TAU, 14, Color(color, 0.8), 1.5)
				draw_line(fall, fall + Vector2(-30.0, -60.0), Color(color, 0.25), 6.0)
			else:
				draw_line(Vector2(hazard.x, 0.0), Vector2(hazard.x, -SKY_HEIGHT * closing * 0.3), Color(color, 0.12), 10.0)


func _draw_bursts() -> void:
	for i in POOL:
		if _lives[i] <= 0.0:
			continue
		var progress: float = _ages[i] / _lives[i]
		var color: Color = Color(_colors[i], 1.0 - progress)
		var at: Vector2 = _positions[i]
		match _kinds[i]:
			Burst.RING_OUT:
				draw_arc(at, _sizes[i] * ease(progress, 0.4), 0.0, TAU, 36, color, 3.0)
			Burst.RING_IN:
				draw_arc(at, _sizes[i] * (1.0 - progress), 0.0, TAU, 36, color, 3.0)
			Burst.FLASH:
				var radius: float = _sizes[i] * (0.5 + progress * 0.5)
				var strength: float = ceilf((1.0 - progress) * FADE_STEPS) / FADE_STEPS
				draw_circle(at, radius, Color(_colors[i], 0.18 * strength))
				draw_circle(at, radius * 0.45, Color(_colors[i], 0.45 * strength))
			Burst.BOLT:
				_draw_beam(at + Vector2(0.0, -_sizes[i]), at, _colors[i] * Color(1, 1, 1, 1.0 - progress), i * 13 + _beam_seed, 3.0)
			Burst.CHEVRONS:
				var reach: float = _sizes[i] * progress
				var tip: Vector2 = at + Vector2(_directions[i] * reach, 0.0)
				var back: float = -_directions[i] * 18.0
				draw_polyline(PackedVector2Array([tip + Vector2(back, -26.0), tip, tip + Vector2(back, 26.0)]), color, 4.0)


func _draw_beam(from: Vector2, to: Vector2, color: Color, seed_value: int, width: float) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var points: PackedVector2Array = [from]
	var normal: Vector2 = (to - from).orthogonal().normalized()
	for i in range(1, BEAM_SEGMENTS):
		var t: float = float(i) / BEAM_SEGMENTS
		points.append(from.lerp(to, t) + normal * rng.randf_range(-BEAM_JITTER, BEAM_JITTER))
	points.append(to)
	draw_polyline(points, Color(color, color.a * 0.45), width * 3.0)
	draw_polyline(points, Color(Color.WHITE, color.a * 0.9), width)


func _draw_ellipse(center: Vector2, radii: Vector2, color: Color, width: float) -> void:
	var points: PackedVector2Array = []
	for i in 33:
		var angle: float = i * TAU / 32.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_polyline(points, color, width)
