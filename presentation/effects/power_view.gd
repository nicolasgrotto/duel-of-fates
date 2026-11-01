class_name PowerView
extends Node2D

const PALETTE: UiPalette = preload("res://ui/palette.tres")
const EFFECTS: EffectsConfig = preload("res://data/balance/effects_config.tres")
const POOL: int = 48
const BEAM_SEGMENTS: int = 9
const BEAM_JITTER: float = 9.0
const BEAM_REFRESH: float = 0.05
const ROCK_POINTS: int = 7
const SKY_HEIGHT: float = 900.0
const ARSENAL_LENGTH: float = 30.0
const STORM_DARKEN: float = 0.45
const STORM_FADE: float = 3.0
const FADE_STEPS: float = 3.0
const GRID: float = 2.0
const CLEAVE_SEGMENTS: int = 10
const CLEAVE_GROW: float = 70.0
const CLEAVE_LAYERS: Array[Vector2] = [Vector2(2.4, 0.28), Vector2(1.2, 0.8), Vector2(0.4, 1.0)]
const METEOR_CRACKS: int = 5
const SHOCKWAVE_SEGMENTS: int = 16
const GRID_CELL: Vector2 = Vector2(GRID, GRID)
const STRAND_POINTS: int = 7
const RIPPLE_STRANDS: int = 3
const CRACKLE_CHANCE: float = 0.6
const FREEZE_LIGHTEN: float = 0.35

enum Burst { WAVE, RING_IN, RING_OUT, BOLT, FLASH, SHOCKWAVE, PULL_ORB, FREEZE_RIPPLE, FREEZE_RELEASE }

var sim: MatchSimulation
var views: Array[FighterView] = []
var blade_colors: Array[Color] = [Color.WHITE, Color.WHITE]
var ambient: CanvasModulate
var base_ambient: Color = Color.WHITE
var vfx: PowerVfxConfig
var debris: DebrisLayer
var sky: StormSky
var reduced: bool = false

var _sky_flash: float = 0.0
var _meteor_seen: PackedFloat32Array = PackedFloat32Array([-1.0, -1.0])
var _cleave_points: PackedVector2Array = []
var _beam_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _crackle_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _was_frozen: Array[bool] = [false, false]

var _kinds: PackedInt32Array = []
var _positions: PackedVector2Array = []
var _directions: PackedFloat32Array = []
var _ages: PackedFloat32Array = []
var _lives: PackedFloat32Array = []
var _sizes: PackedFloat32Array = []
var _colors: PackedColorArray = []
var _tiers: PackedInt32Array = []
var _pending_sources: PackedInt32Array = []
var _wave_from_body: PackedByteArray = []
var _wave_ends: PackedFloat32Array = []
var _next: int = 0
var _time: float = 0.0
var _beam_clock: float = 0.0
var _beam_seed: int = 0
var _storm: float = 0.0
var _storm_bolt_flash: float = 0.0


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
	_tiers.resize(POOL)
	_pending_sources.resize(POOL)
	_pending_sources.fill(-1)
	_wave_from_body.resize(POOL)
	_wave_ends.resize(POOL)
	_lives.fill(0.0)


func on_sky_flash(strength: float) -> void:
	_sky_flash = maxf(_sky_flash, strength)


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
			if event.source < 0 or (event.power != null and event.power.kind == PowerData.Kind.FREEZE):
				return
			_burst(Burst.FLASH, at, 0.0, 0.12, 34.0, tier_color(sim.fighters[event.source].flow_tier))
		CombatEvent.Type.HAZARD_TRIGGERED:
			_on_hazard(event, at)
		CombatEvent.Type.PROJECTILE_REFLECTED:
			_burst(Burst.RING_OUT, at, 0.0, 0.25, 70.0, blade_colors[event.source])
		CombatEvent.Type.BLADE_LOCK_ENDED:
			if event.source >= 0 and _flow_holder(event.source):
				var holder: FighterState = sim.fighters[event.source]
				_burst(Burst.RING_OUT, views[event.source].hand_position(false), 0.0, 0.3, vfx.flow_hold_win_radius, tier_color(holder.flow_tier))
				_start_shockwave(holder, vfx.flow_hold_win_reach, holder.facing, false)
		CombatEvent.Type.CLASH:
			for index in [event.source, event.target]:
				if index >= 0 and _flow_holder(index):
					_burst(Burst.RING_OUT, views[index].hand_position(false), 0.0, 0.2, vfx.flow_hold_radius * 3.0, tier_color(sim.fighters[index].flow_tier))


func _flow_holder(index: int) -> bool:
	return sim.fighters[index].character.lock_style == CharacterData.LockStyle.FLOW_HOLD


func _on_power_active(event: CombatEvent) -> void:
	var caster: FighterState = sim.fighters[event.source]
	var color: Color = tier_color(caster.flow_tier)
	var hand: Vector2 = views[caster.index].hand_position(false)
	match event.power.kind:
		PowerData.Kind.REPULSE:
			_start_shockwave(caster, event.power.reach, caster.facing, false)
		PowerData.Kind.SUPREME_PUSH:
			for side in [-1.0, 1.0]:
				_start_shockwave(caster, event.power.reach, side, true)
		PowerData.Kind.PULL:
			_burst(Burst.PULL_ORB, hand, caster.index, vfx.pull_orb_time, vfx.pull_orb_radius * (1.0 + caster.flow_tier * vfx.pull_orb_tier_growth), color)
		PowerData.Kind.FRACTURE:
			_burst(Burst.FLASH, Vector2(hand.x, 0.0), 0.0, 0.2, 60.0, color)
		PowerData.Kind.FREEZE:
			var reach: float = absf(views[1 - caster.index].body_center().x - hand.x)
			_burst(Burst.FREEZE_RIPPLE, hand, caster.facing, vfx.freeze_ripple_time, reach, color)
		PowerData.Kind.HEAL, PowerData.Kind.FOCUS, PowerData.Kind.WRATH, PowerData.Kind.SANCTUARY:
			_burst(Burst.RING_OUT, views[caster.index].body_center(), 0.0, 0.3, 80.0, color)


func _on_hazard(event: CombatEvent, at: Vector2) -> void:
	var caster: FighterState = sim.fighters[event.source]
	var color: Color = tier_color(caster.flow_tier)
	match int(event.amount):
		Hazard.Kind.BOLT:
			_burst(Burst.BOLT, at, 0.0, 0.16, SKY_HEIGHT, color)
			_burst(Burst.FLASH, at, 0.0, 0.18, 40.0, color)
		Hazard.Kind.FRACTURE:
			_burst(Burst.FLASH, at, 0.0, 0.22, 46.0, color)
		Hazard.Kind.ROCK_DROP:
			_burst(Burst.RING_OUT, at, 0.0, 0.3, 70.0, color)


func _start_shockwave(caster: FighterState, reach: float, direction: float, from_body: bool) -> void:
	var index: int = _burst(Burst.SHOCKWAVE, Vector2.ZERO, direction, vfx.repulse_wave_time, reach, tier_color(caster.flow_tier))
	_tiers[index] = caster.flow_tier
	_pending_sources[index] = caster.index
	_wave_from_body[index] = int(from_body)
	_wave_ends[index] = caster.x + direction * (reach + sim.config.body_width * 0.5)


func _burst(kind: Burst, at: Vector2, direction: float, life: float, size: float, color: Color) -> int:
	if reduced and kind == Burst.FLASH:
		return -1
	var index: int = _next
	_kinds[_next] = kind
	_positions[_next] = at
	_directions[_next] = direction
	_ages[_next] = 0.0
	_lives[_next] = life
	_sizes[_next] = size
	_colors[_next] = color
	_pending_sources[_next] = -1
	_next = (_next + 1) % POOL
	return index


func _process(delta: float) -> void:
	_time += delta
	_beam_clock += delta
	if _beam_clock >= BEAM_REFRESH:
		_beam_clock = 0.0
		_beam_seed += 1
	for i in POOL:
		if _lives[i] > 0.0:
			if _pending_sources[i] >= 0:
				var view: FighterView = views[_pending_sources[i]]
				_positions[i] = view.body_center() if _wave_from_body[i] != 0 else view.hand_position(false)
				_pending_sources[i] = -1
				continue
			_ages[i] += delta
			if _ages[i] >= _lives[i]:
				_lives[i] = 0.0
	_update_storm(delta)
	_update_meteors()
	_update_freeze_release()
	queue_redraw()


func _update_freeze_release() -> void:
	if sim == null or views.size() < 2:
		return
	for fighter in sim.fighters:
		var frozen: bool = is_frozen(fighter)
		if _was_frozen[fighter.index] and not frozen and not reduced:
			_burst(Burst.FREEZE_RELEASE, views[fighter.index].body_center(), 0.0, vfx.freeze_release_time, vfx.freeze_release_spread, _freeze_color(fighter))
		_was_frozen[fighter.index] = frozen


static func is_frozen(fighter: FighterState) -> bool:
	return fighter.is_alive() and fighter.state == FighterState.State.HELD and not fighter.held_by_choke


func _freeze_color(fighter: FighterState) -> Color:
	return tier_color(sim.opponent_of(fighter).flow_tier)


func _update_meteors() -> void:
	if debris == null:
		return
	for i in 2:
		var progress: float = debris.meteor_progress(i)
		if progress >= 1.0 and _meteor_seen[i] < 1.0:
			var color: Color = tier_color(sim.fighters[i].flow_tier)
			_burst(Burst.FLASH, debris.meteors[i], 0.0, 0.25, vfx.meteor_radius * 2.0, color)
			_burst(Burst.RING_OUT, debris.meteors[i], 0.0, 0.3, vfx.meteor_radius * 3.0, color)
		_meteor_seen[i] = progress


func _update_storm(delta: float) -> void:
	if sim == null or ambient == null:
		return
	var storming: bool = false
	for fighter in sim.fighters:
		storming = storming or (fighter.power_kind_active(PowerData.Kind.STORM))
	_storm = move_toward(_storm, 1.0 if storming else 0.0, delta * STORM_FADE)
	_sky_flash = maxf(_sky_flash - delta * 4.0, 0.0)
	if sky != null:
		sky.intensity = _storm
		sky.focus_x = (sim.fighters[0].x + sim.fighters[1].x) * 0.5
		for fighter in sim.fighters:
			if fighter.power_kind_active(PowerData.Kind.STORM):
				sky.color = tier_color(fighter.flow_tier)
	var flash: float = _sky_flash
	_storm_bolt_flash = 0.0
	for i in POOL:
		if _lives[i] > 0.0 and _kinds[i] == Burst.BOLT:
			_storm_bolt_flash = maxf(_storm_bolt_flash, 1.0 - _ages[i] / _lives[i])
	flash = maxf(flash, _storm_bolt_flash)
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
	if debris != null:
		for i in 2:
			_draw_meteor(i)
	_draw_bursts()


func _draw_fighter(fighter: FighterState) -> void:
	if not fighter.is_alive():
		return
	var view: FighterView = views[fighter.index]
	var color: Color = tier_color(fighter.flow_tier)
	var center: Vector2 = view.body_center()
	if fighter.state == FighterState.State.BLADE_LOCK and fighter.character.lock_style == CharacterData.LockStyle.FLOW_HOLD:
		_draw_flow_hold(view, views[1 - fighter.index], color)
	if fighter.state == FighterState.State.CASTING and fighter.power_phase == FighterState.Phase.STARTUP and fighter.power != null:
		var progress: float = clampf(float(fighter.power_ticks) / maxf(fighter.power.startup_ticks(), 1.0), 0.0, 1.0)
		var hand: Vector2 = view.hand_position(false)
		draw_circle(hand, 4.0 + 10.0 * progress, Color(color, 0.25 + 0.4 * progress))
		draw_circle(hand, 2.0 + 3.0 * progress, Color(Color.WHITE, 0.6))
	if fighter.state == FighterState.State.CHANNELING and fighter.power != null:
		_draw_channel(fighter, view, color)
	_draw_singularity(fighter)
	if fighter.instinct_ticks > 0:
		_draw_instinct(fighter, view, center)
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
	if is_frozen(fighter):
		_draw_freeze(fighter, view, center)
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
				var chest: Vector2 = views[target.index].chest_position()
				if beams <= 1:
					_draw_beam(hand, chest, color, _beam_seed * 7, 2.5)
					if fighter.flow_tier == 1:
						_draw_beam(hand, views[target.index].body_center(), color, _beam_seed * 5 + 3, 1.5)
				else:
					_draw_lightning_fan(hand, chest, beams, color)
		PowerData.Kind.DRAIN:
			var from: Vector2 = views[target.index].chest_position()
			for i in 8:
				var t: float = fmod(_time * 1.5 + i / 8.0, 1.0)
				draw_circle(from.lerp(hand, t), 2.5 * (1.0 - t * 0.5), Color(color, 0.8 - 0.5 * t))
		PowerData.Kind.STORM:
			_draw_storm_shield(fighter, center, color)
		PowerData.Kind.CHOKE:
			draw_circle(hand, 6.0, Color(color, 0.5))


func _draw_arsenal(fighter: FighterState, view: FighterView, _color: Color) -> void:
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
		Projectile.Kind.SINGULARITY:
			_draw_singularity_core(at, projectile.size, color.lerp(PALETTE.eclipse, vfx.singularity_tier_tint), false)
			if not reduced:
				var direction: Vector2 = Vector2(-projectile.vx, projectile.vy).normalized()
				for trail in 3:
					draw_arc(at + direction * projectile.size * (trail + 1) * 0.6, projectile.size * (1.0 - trail * 0.2), 0.0, TAU, 12, Color(color, 0.2 - trail * 0.05), GRID)
		Projectile.Kind.ROCK:
			var points: PackedVector2Array = []
			for i in ROCK_POINTS:
				var angle: float = i * TAU / ROCK_POINTS + _time * 6.0
				var radius: float = projectile.size * (0.95 + 0.25 * sin(i * 2.3))
				points.append(at + Vector2(cos(angle), sin(angle)) * radius)
			points.append(points[0])
			draw_polyline(points, Color(color, 0.7), GRID)
			var back: float = -signf(projectile.vx)
			for streak in 3:
				var offset: Vector2 = Vector2(back * (projectile.size + streak * 6.0), (streak - 1) * projectile.size * 0.6)
				draw_line(at + offset, at + offset + Vector2(back * projectile.size * (2.2 - streak * 0.5), 0.0), Color(color, 0.5 - streak * 0.12), GRID)
		Projectile.Kind.CLEAVE:
			_draw_cleave(projectile, at)
		Projectile.Kind.BOLT:
			_draw_bolt(projectile, at)
		Projectile.Kind.BLADE, Projectile.Kind.ARSENAL:
			var weapon: WeaponData = sim.fighters[projectile.owner].character.weapon
			var tint: Color = blade_colors[projectile.owner]
			if projectile.kind == Projectile.Kind.BLADE and weapon.kind == WeaponData.Kind.DUAL:
				_draw_dual_throw(projectile, at, weapon, tint)
				return
			var half: float = 46.0 if projectile.kind == Projectile.Kind.BLADE else 12.0
			_draw_spinning_blade(at, _time * vfx.thrown_blade_spin, half, tint)


func _draw_spinning_blade(at: Vector2, spin: float, half: float, tint: Color) -> void:
	var direction: Vector2 = Vector2.from_angle(spin) * half
	draw_line(at - direction, at + direction, Color(tint, 0.35), 12.0)
	draw_line(at - direction, at + direction, Color(tint, 0.85), 4.5)
	draw_line(at - direction, at + direction, Color.WHITE, 1.8)


func _draw_dual_throw(projectile: Projectile, at: Vector2, weapon: WeaponData, tint: Color) -> void:
	var trip: float = clampf(projectile.travelled / maxf(projectile.max_distance, 1.0), 0.0, 2.0)
	var lift: float = vfx.dual_throw_arc * sin(PI * fposmod(trip, 1.0))
	var heading: float = signf(projectile.vx) if projectile.vx != 0.0 else 1.0
	var trailing: Vector2 = at - Vector2(heading * absf(projectile.vx) * vfx.dual_throw_delay, 0.0)
	var spin: float = _time * vfx.thrown_blade_spin
	_draw_spinning_blade(at + Vector2(0.0, -lift), spin, (weapon.blade_length + weapon.hilt_length) * 0.5, tint)
	_draw_spinning_blade(trailing + Vector2(0.0, lift), -spin, (weapon.second_blade_length + weapon.hilt_length) * 0.5, tint)


func _draw_bolt(projectile: Projectile, at: Vector2) -> void:
	var heading: Vector2 = Vector2(projectile.vx, -projectile.vy).normalized()
	if heading == Vector2.ZERO:
		heading = Vector2.RIGHT
	var edge: Color = PALETTE.bolt if projectile.owner == projectile.shooter else blade_colors[projectile.owner]
	var tail: Vector2 = at - heading * vfx.bolt_length
	var snapped_at: Vector2 = at.snapped(Vector2.ONE * GRID)
	var snapped_tail: Vector2 = tail.snapped(Vector2.ONE * GRID)
	draw_line(snapped_tail, snapped_at, edge, vfx.bolt_width)
	draw_line(snapped_tail.lerp(snapped_at, 0.35), snapped_at, Color.WHITE, vfx.bolt_width * 0.5)
	if projectile.travelled < vfx.bolt_muzzle_distance and projectile.owner == projectile.shooter:
		draw_rect(Rect2(snapped_tail - Vector2.ONE * GRID * 1.5, Vector2.ONE * GRID * 3.0), Color(edge, 0.8))


func _draw_cleave(projectile: Projectile, at: Vector2) -> void:
	var direction: float = 1.0 if projectile.vx >= 0.0 else -1.0
	var base_y: float = -(projectile.y - sim.config.flow.projectile_height)
	var grow: float = clampf(projectile.travelled / CLEAVE_GROW, 0.35, 1.0)
	var wave_scale: float = projectile.size / projectile.move.projectile_size if projectile.move != null and projectile.move.projectile_size > 0.0 else 1.0
	var height: float = vfx.cleave_height * grow * wave_scale
	var color: Color = blade_colors[projectile.owner]
	for echo in 2:
		var x: float = at.x - direction * echo * 26.0
		for layer in CLEAVE_LAYERS:
			_cleave_shape(x, base_y, height, direction, layer.x * (0.6 if echo == 1 else 1.0) * wave_scale)
			var tint: Color = color if layer.y < 1.0 else Color.WHITE
			draw_colored_polygon(_cleave_points, Color(tint, layer.y * (0.35 if echo == 1 else 1.0) * (0.9 if layer.y < 1.0 else 0.85)))
	for i in vfx.cleave_ground_sparks + 2:
		var spark: Vector2 = Vector2(at.x - direction * (8.0 + i * 12.0 + randf() * 6.0), base_y - randf() * 6.0).snapped(Vector2(GRID, GRID))
		draw_rect(Rect2(spark, Vector2(GRID, GRID)), Color(Color.WHITE, 0.9 - i * 0.18))
		draw_rect(Rect2(spark + Vector2(0.0, -GRID), Vector2(GRID, GRID)), Color(color, 0.6 - i * 0.12))


func _cleave_shape(x: float, base_y: float, height: float, direction: float, width_scale: float) -> void:
	var count: int = CLEAVE_SEGMENTS + 1
	_cleave_points.resize(count * 2)
	for i in count:
		var t: float = float(i) / CLEAVE_SEGMENTS
		var center: float = x + direction * vfx.cleave_bow * sin(t * PI * 0.5) - direction * vfx.cleave_bow * 0.4 * t * t
		var width: float = lerpf(vfx.cleave_base_width, vfx.cleave_tip_width, pow(t, 0.75)) * width_scale
		var y: float = base_y - height * t
		_cleave_points[i] = Vector2(center + direction * width * 0.5, y)
		_cleave_points[count * 2 - 1 - i] = Vector2(center - direction * width * 0.5, y)


func _draw_meteor(index: int) -> void:
	var progress: float = debris.meteor_progress(index)
	if progress < 0.0 or progress >= 1.0:
		return
	var color: Color = tier_color(sim.fighters[index].flow_tier)
	var arrive: float = 1.0 - pow(1.0 - progress, 2.0)
	var start: Vector2 = debris.meteors[index] + Vector2(-debris.meteor_facing[index] * vfx.meteor_pull, -vfx.meteor_pull * 0.6)
	var at: Vector2 = start.lerp(debris.meteors[index], arrive)
	var radius: float = vfx.meteor_radius * (0.7 + 0.3 * arrive)
	draw_circle(at, radius * 1.6, Color(color, 0.08))
	draw_circle(at, radius * 1.15, Color(color, 0.14))
	draw_arc(at, radius + 2.0, 0.0, TAU, 24, Color(color, 0.8), GRID)
	draw_arc(at + Vector2(-2.0, -2.0), radius - 2.0, PI * 0.9, PI * 1.6, 10, Color(Color.WHITE, 0.35), GRID)
	draw_line(at, start.lerp(at, 0.2), Color(color, 0.2 * (1.0 - arrive)), radius)
	var cracking: float = clampf((progress - 0.45) / 0.55, 0.0, 1.0)
	for i in int(ceil(cracking * METEOR_CRACKS)):
		var angle: float = i * TAU / METEOR_CRACKS + 0.4
		var tip: Vector2 = at + Vector2.from_angle(angle) * radius * cracking
		var bend: Vector2 = at.lerp(tip, 0.5) + Vector2.from_angle(angle + 1.2) * 5.0
		draw_polyline(PackedVector2Array([at, bend, tip]), Color(Color.WHITE, 0.9), GRID)
		draw_polyline(PackedVector2Array([at, bend, tip]), Color(color, 0.5), GRID * 2.5)


func _draw_hazard(hazard: Hazard) -> void:
	var caster: FighterState = sim.fighters[hazard.owner]
	var color: Color = tier_color(caster.flow_tier)
	var closing: float = 1.0 - float(hazard.delay_ticks) / maxf(hazard.total_delay, 1.0)
	match hazard.kind:
		Hazard.Kind.EXTRACTION:
			var left: float = hazard.x - hazard.half_width
			var right: float = hazard.x + hazard.half_width
			var mark_color: Color = Color(color.lerp(PALETTE.eclipse, vfx.singularity_tier_tint), vfx.singularity_mark_alpha)
			draw_line(Vector2(left, 0.0), Vector2(right, 0.0), mark_color, GRID * 2.0)
			for side_index in 2:
				var x: float = left if side_index == 0 else right
				draw_line(Vector2(x, 0.0), Vector2(x, -vfx.singularity_mark_height), mark_color, GRID)
			for hatch in 5:
				var x: float = lerpf(left, right, float(hatch + 1) / 6.0)
				draw_line(Vector2(x - GRID, -GRID * 2.0), Vector2(x + GRID, -vfx.singularity_mark_height * closing), mark_color, GRID)
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
			if hazard.kind == Hazard.Kind.ROCK_DROP and debris != null and debris.meteor_progress(hazard.owner) >= 1.0:
				var fall: Vector2 = debris.rain_position(hazard)
				draw_line(fall, fall + Vector2(0.0, -46.0), Color(color, 0.22), 10.0)
				draw_arc(fall, 13.0, 0.0, TAU, 12, Color(color, 0.75), GRID)
			else:
				draw_line(Vector2(hazard.x, 0.0), Vector2(hazard.x, -SKY_HEIGHT * closing * 0.3), Color(color, 0.12), 10.0)


func _draw_bursts() -> void:
	for i in POOL:
		if _lives[i] <= 0.0 or _pending_sources[i] >= 0:
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
			Burst.PULL_ORB:
				_draw_pull_orb(int(_directions[i]), _sizes[i], _colors[i], progress)
			Burst.SHOCKWAVE:
				_draw_shockwave(i, progress)
			Burst.FREEZE_RIPPLE:
				_draw_freeze_ripple(i, progress)
			Burst.FREEZE_RELEASE:
				_draw_freeze_release(i, progress)


func shockwave_tip(index: int, progress: float) -> Vector2:
	var travel: float = clampf(progress / vfx.repulse_travel_share, 0.0, 1.0)
	return Vector2(lerpf(_positions[index].x, _wave_ends[index], travel), _positions[index].y)


func shockwave_height(tier: int, progress: float) -> float:
	var travel: float = clampf(progress / vfx.repulse_travel_share, 0.0, 1.0)
	return lerpf(vfx.repulse_start_height, vfx.repulse_end_height + tier * vfx.repulse_tier_height, travel)


func shockwave_echoes(tier: int) -> int:
	return 0 if reduced else 2 if tier >= vfx.repulse_echo_tier else 1


static func shockwave_point(tip: Vector2, direction: float, height: float, bow: float, along: float, inset: float) -> Vector2:
	var taper: float = maxf(1.0 - along * along, 0.0)
	return (tip + Vector2(-direction * (bow * along * along + inset * taper), along * height * 0.5)).snapped(Vector2.ONE * GRID)


func _draw_shockwave(index: int, progress: float) -> void:
	var tier: int = _tiers[index]
	var direction: float = _directions[index]
	var tip: Vector2 = shockwave_tip(index, progress)
	var height: float = shockwave_height(tier, progress)
	var width: float = vfx.repulse_width + tier * vfx.repulse_tier_width
	var strength: float = ceilf((1.0 - progress) * EFFECTS.fade_steps) / EFFECTS.fade_steps
	if reduced:
		strength *= vfx.repulse_reduced_alpha
	var travel: float = absf(tip.x - _positions[index].x)
	for echo in range(shockwave_echoes(tier), 0, -1):
		var lag: float = minf(vfx.repulse_echo_spacing * echo, travel)
		if lag < vfx.repulse_echo_spacing * echo:
			continue
		_draw_air_arc(tip - Vector2(direction * lag, 0.0), direction, height, width, _colors[index], strength * pow(vfx.repulse_echo_alpha, echo), false)
	_draw_air_arc(tip, direction, height, width, _colors[index], strength, true)
	if reduced:
		return
	for streak in vfx.repulse_ground_streaks:
		var lag: float = streak * vfx.repulse_streak_gap
		var start: Vector2 = Vector2(tip.x - direction * lag, -GRID - streak * vfx.repulse_streak_gap).snapped(Vector2.ONE * GRID)
		var length: float = minf(vfx.repulse_streak_length, maxf(travel - lag, 0.0))
		draw_line(start, (start - Vector2(direction * length, 0.0)).snapped(Vector2.ONE * GRID), Color(_colors[index], strength * vfx.repulse_streak_alpha), GRID)


func _draw_air_arc(tip: Vector2, direction: float, height: float, width: float, color: Color, strength: float, edge: bool) -> void:
	var bow: float = height * vfx.repulse_bow_ratio
	var bands: int = vfx.repulse_band_alpha.size()
	for band in bands:
		for segment in SHOCKWAVE_SEGMENTS:
			var a: float = -1.0 + 2.0 * segment / SHOCKWAVE_SEGMENTS
			var b: float = -1.0 + 2.0 * (segment + 1) / SHOCKWAVE_SEGMENTS
			var outer: float = width * band / bands
			var inner: float = width * (band + 1) / bands
			var points: PackedVector2Array = PackedVector2Array([
				shockwave_point(tip, direction, height, bow, a, outer),
				shockwave_point(tip, direction, height, bow, b, outer),
				shockwave_point(tip, direction, height, bow, b, inner),
				shockwave_point(tip, direction, height, bow, a, inner),
			])
			var polygon: PackedVector2Array = Geometry2D.convex_hull(points)
			if polygon.size() < 4:
				continue
			polygon.resize(polygon.size() - 1)
			draw_colored_polygon(polygon, Color(color, vfx.repulse_band_alpha[band] * strength))
	var line: PackedVector2Array = []
	for segment in SHOCKWAVE_SEGMENTS + 1:
		var along: float = -1.0 + 2.0 * segment / SHOCKWAVE_SEGMENTS
		line.append(shockwave_point(tip, direction, height, bow, along, 0.0))
	var rim: Color = color.lerp(PALETTE.spark_hot, vfx.repulse_edge_light) if edge else color
	draw_polyline(line, Color(rim, strength), vfx.repulse_edge_width, false)


func _draw_lightning_fan(hand: Vector2, chest: Vector2, beams: int, color: Color) -> void:
	for i in beams:
		var spread: float = float(i) - (beams - 1) * 0.5
		var origin: Vector2 = hand + Vector2(0.0, spread * vfx.lightning_finger_gap)
		var arrival: Vector2 = chest + Vector2(0.0, spread * vfx.lightning_target_gap)
		var phase: int = int((_time + i * vfx.lightning_phase_step) / BEAM_REFRESH)
		_draw_beam(origin, arrival, color, phase * 7 + i * 31, 2.5 if i == 0 else 2.0, Vector2(0.0, spread * vfx.lightning_fan_bow))


func _draw_pull_orb(caster_index: int, radius: float, color: Color, progress: float) -> void:
	var hand: Vector2 = views[caster_index].hand_position(false)
	var size: float = snappedf(radius * (1.0 - ease(progress, 0.45)), GRID)
	if size <= 0.0:
		return
	var strength: float = ceilf((1.0 - progress) * FADE_STEPS) / FADE_STEPS
	draw_circle(hand, size, Color(color, 0.22 * strength))
	draw_arc(hand, size, 0.0, TAU, 32, Color(color, 0.8 * strength), GRID)
	draw_circle(hand, size * vfx.pull_orb_core, Color(Color.WHITE, 0.5 * strength))


func _draw_storm_shield(fighter: FighterState, center: Vector2, color: Color) -> void:
	var radii: Vector2 = vfx.storm_shell * (1.0 + fighter.flow_tier * vfx.storm_tier_growth)
	var glow: float = 1.0 + _storm_bolt_flash * vfx.storm_bolt_glow
	var flicker: float = 0.7 + 0.3 * float(int(_time * vfx.storm_flicker_rate) % 3) / 2.0
	_fill_ellipse(center, radii, Color(color, vfx.storm_fill_alpha * glow))
	for band in vfx.storm_shell_alpha.size():
		var inset: Vector2 = Vector2.ONE * vfx.storm_shell_spacing * band
		_draw_ellipse(center, radii - inset, Color(color, minf(vfx.storm_shell_alpha[band] * flicker * glow, 1.0)), GRID)
	for i in vfx.storm_arcs:
		var start: float = _time * vfx.storm_arc_speed * (1.0 if i % 2 == 0 else -1.3) + i * TAU / vfx.storm_arcs
		_storm_arc(center, radii, start, vfx.storm_arc_span, Color(Color.WHITE, 0.85), _beam_seed * 11 + i)
	var floor_y: float = 0.0
	if center.y + radii.y >= floor_y - radii.y * 0.2:
		_beam_rng.seed = _beam_seed * 5 + fighter.index
		for i in vfx.storm_ground_sparks:
			var x: float = center.x + _beam_rng.randf_range(-radii.x, radii.x) * 0.7
			draw_rect(Rect2(Vector2(x, floor_y - GRID).snapped(Vector2(GRID, GRID)), Vector2(GRID, GRID)), Color(color, 0.9))


func _storm_arc(center: Vector2, radii: Vector2, start: float, span: float, color: Color, seed_value: int) -> void:
	_beam_rng.seed = seed_value
	var points: PackedVector2Array = []
	var steps: int = 6
	for k in steps + 1:
		var angle: float = start + span * float(k) / steps
		var wobble: float = _beam_rng.randf_range(-vfx.storm_arc_jitter, vfx.storm_arc_jitter) if k > 0 and k < steps else 0.0
		points.append(center + Vector2(cos(angle) * (radii.x + wobble), sin(angle) * (radii.y + wobble)))
	draw_polyline(points, Color(color, color.a * 0.35), GRID * 2.0)
	draw_polyline(points, color, GRID * 0.5)


func _fill_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points: PackedVector2Array = []
	for i in 32:
		var angle: float = i * TAU / 32.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)


func _draw_beam(from: Vector2, to: Vector2, color: Color, seed_value: int, width: float, bow: Vector2 = Vector2.ZERO) -> void:
	_beam_rng.seed = seed_value
	var points: PackedVector2Array = [from]
	var normal: Vector2 = (to - from).orthogonal().normalized()
	var jitter: float = BEAM_JITTER if bow == Vector2.ZERO else BEAM_JITTER * 0.5
	for i in range(1, BEAM_SEGMENTS):
		var t: float = float(i) / BEAM_SEGMENTS
		points.append(from.lerp(to, t) + bow * sin(PI * t) + normal * _beam_rng.randf_range(-jitter, jitter))
	points.append(to)
	draw_polyline(points, Color(color, color.a * 0.45), width * 3.0)
	draw_polyline(points, Color(Color.WHITE, color.a * 0.9), width)


func _draw_freeze(fighter: FighterState, view: FighterView, center: Vector2) -> void:
	var color: Color = _freeze_color(fighter)
	var strands: int = vfx.freeze_strands
	for i in strands:
		var lift: float = fmod(_time * vfx.freeze_strand_rise + i * 0.37, 1.0)
		var x: float = lerpf(-0.6, 0.6, (i + 0.5) / strands) * vfx.freeze_mote_spread.x
		var strength: float = ceilf(sin(lift * PI) * FADE_STEPS) / FADE_STEPS
		_draw_strand(center + Vector2(x, 24.0 - lift * 56.0), vfx.freeze_strand_height, Color(color.lightened(FREEZE_LIGHTEN), vfx.freeze_strand_alpha * strength), i)
	if reduced:
		return
	for i in vfx.freeze_motes:
		var vibration: Vector2 = Vector2(sin(_time * 31.0 + i * 2.1), cos(_time * 27.0 + i * 1.7)) * vfx.freeze_mote_vibration
		var tint: Color = PALETTE.text if i % 3 == 0 else color
		_draw_mote(center + freeze_mote_offset(i, vfx.freeze_mote_spread) + vibration, Color(tint.lightened(FREEZE_LIGHTEN), 1.0), 1 + i % 2)
	var anchors: Array[Vector2] = [view.hand_position(true), view.hand_position(false), view.head_position()]
	var step: int = int(floorf(_time * vfx.freeze_crackle_rate))
	for j in anchors.size():
		_crackle_rng.seed = step * 97 + j * 13 + fighter.index * 7
		if _crackle_rng.randf() < CRACKLE_CHANCE:
			_draw_crackle(anchors[j], color)


static func freeze_mote_offset(index: int, spread: Vector2) -> Vector2:
	var u: float = fposmod(sin(index * 12.9898) * 43758.5453, 1.0)
	var v: float = fposmod(sin(index * 78.233) * 12543.1, 1.0)
	return Vector2((u * 2.0 - 1.0) * spread.x * 0.5, (v * 2.0 - 1.0) * spread.y * 0.5)


func _draw_mote(at: Vector2, color: Color, cells: int = 1) -> void:
	var size: Vector2 = GRID_CELL * cells
	draw_rect(Rect2(at.snapped(GRID_CELL) - size * 0.5, size), color)


func _draw_strand(at: Vector2, height: float, color: Color, phase: int) -> void:
	var points: PackedVector2Array = []
	for j in STRAND_POINTS:
		var t: float = float(j) / (STRAND_POINTS - 1)
		var sway: float = sin(_time * 5.0 + phase * 1.9 + t * 4.0) * vfx.freeze_strand_sway
		points.append((at + Vector2(sway, (t - 0.5) * height)).snapped(GRID_CELL))
	draw_polyline(points, color, GRID)


func _draw_crackle(anchor: Vector2, color: Color) -> void:
	var angle: float = _crackle_rng.randf() * TAU
	var length: float = vfx.freeze_crackle_length
	var bend: Vector2 = anchor + Vector2(cos(angle), sin(angle)) * length * 0.5 + Vector2(_crackle_rng.randf_range(-3.0, 3.0), _crackle_rng.randf_range(-3.0, 3.0))
	var tip: Vector2 = anchor + Vector2(cos(angle), sin(angle)) * length
	draw_polyline(PackedVector2Array([anchor.snapped(GRID_CELL), bend.snapped(GRID_CELL), tip.snapped(GRID_CELL)]), Color(color.lightened(0.4), 0.85), GRID)


func _draw_freeze_ripple(index: int, progress: float) -> void:
	var fade: float = ceilf((1.0 - progress) * FADE_STEPS) / FADE_STEPS
	for k in RIPPLE_STRANDS:
		var travel: float = clampf(progress * 1.3 - k * 0.15, 0.0, 1.0)
		if travel <= 0.0:
			continue
		var at: Vector2 = _positions[index] + Vector2(_directions[index] * _sizes[index] * travel, 0.0)
		_draw_strand(at, vfx.freeze_strand_height * (0.6 + 0.4 * travel), Color(_colors[index], 0.5 * fade), k)


func _draw_freeze_release(index: int, progress: float) -> void:
	var fade: float = ceilf((1.0 - progress) * FADE_STEPS) / FADE_STEPS
	for m in vfx.freeze_motes:
		var offset: Vector2 = freeze_mote_offset(m, vfx.freeze_mote_spread)
		var outward: Vector2 = offset.normalized() if offset != Vector2.ZERO else Vector2.UP
		_draw_mote(_positions[index] + offset + outward * _sizes[index] * ease(progress, 0.4), Color(_colors[index], 0.8 * fade))


func _draw_ellipse(center: Vector2, radii: Vector2, color: Color, width: float) -> void:
	var points: PackedVector2Array = []
	for i in 33:
		var angle: float = i * TAU / 32.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_polyline(points, color, width)


func _draw_instinct(fighter: FighterState, view: FighterView, center: Vector2) -> void:
	var silver: Color = PALETTE.text.lerp(tier_color(fighter.flow_tier), vfx.instinct_tier_tint)
	var step: float = 1.0 if reduced else (floorf(fmod(_time * vfx.instinct_flicker_rate, 1.0) * FADE_STEPS) + 1.0) / FADE_STEPS
	var radii: Vector2 = vfx.instinct_aura
	_draw_instinct_glow(center, radii, silver)
	var alpha: float = lerpf(vfx.instinct_outline_alpha.x, vfx.instinct_outline_alpha.y, step)
	var samples: int = vfx.instinct_outline_samples
	for sample in samples:
		var angle: float = TAU * float(sample) / samples
		var at: Vector2 = Vector2(sin(angle) * radii.x, -cos(angle) * radii.y)
		if at.y > vfx.instinct_open_bottom * radii.y:
			continue
		if not reduced and at.y < 0.0:
			var flicker: float = absf(sin(angle * vfx.instinct_tongues + _time * vfx.instinct_tongue_rate))
			at.y -= floorf(flicker * vfx.instinct_tongue_height / GRID) * GRID * (-at.y / radii.y)
		draw_rect(Rect2((center + at).snapped(Vector2.ONE * GRID), Vector2.ONE * GRID), Color(silver, alpha))
	if not reduced:
		_draw_instinct_sparks(center, radii, silver)
	var eye: Vector2 = (view.head_position() + Vector2(fighter.facing * 4.0, -2.0)).snapped(Vector2.ONE * GRID)
	draw_rect(Rect2(eye, vfx.instinct_eye_size), Color(silver, 0.8))


func _draw_instinct_glow(center: Vector2, radii: Vector2, silver: Color) -> void:
	draw_set_transform(center, 0.0, Vector2(radii.x / radii.y, 1.0))
	draw_circle(Vector2.ZERO, radii.y, Color(silver, vfx.instinct_glow_alpha.x))
	draw_circle(Vector2.ZERO, radii.y * 0.8, Color(silver, vfx.instinct_glow_alpha.y))
	draw_set_transform(Vector2.ZERO)


func _draw_instinct_sparks(center: Vector2, radii: Vector2, silver: Color) -> void:
	var size: Vector2 = vfx.instinct_spark_size
	for spark in vfx.instinct_sparks:
		var phase: float = fposmod(_time * vfx.instinct_spark_rate + float(spark) * 0.618, 1.0)
		var side: float = -1.0 if spark % 2 == 0 else 1.0
		var lane: float = 0.55 + 0.4 * fposmod(float(spark) * 0.37, 1.0)
		var height: float = lerpf(radii.y * 0.8, -radii.y * 1.05, phase)
		var width: float = radii.x * lane * sqrt(maxf(1.0 - pow(height / (radii.y * 1.1), 2.0), 0.0))
		var fade: float = ceilf((1.0 - phase) * FADE_STEPS) / FADE_STEPS
		var at: Vector2 = (center + Vector2(side * width, height)).snapped(Vector2.ONE * GRID)
		draw_rect(Rect2(at, size), Color(silver, vfx.instinct_outline_alpha.y * fade))


func _draw_flow_hold(view: FighterView, rival: FighterView, color: Color) -> void:
	var palm: Vector2 = view.hand_position(false)
	var held: Vector2 = Geometry2D.get_closest_point_to_segment(palm, rival.active_blade_base(), rival.active_blade_tip())
	var pulse: float = 0.0 if reduced else (floorf(fmod(_time * vfx.flow_hold_pulse_rate, 1.0) * FADE_STEPS) / FADE_STEPS)
	for ring in vfx.flow_hold_rings:
		var radius: float = vfx.flow_hold_radius * (1.0 + float(ring) * 0.6 + pulse * 0.4)
		draw_arc(palm, radius, 0.0, TAU, 16, Color(color, vfx.flow_hold_alpha * (1.0 - float(ring) / vfx.flow_hold_rings)), GRID)
	var jitter: Vector2 = Vector2.ZERO if reduced else Vector2(0.0, sin(_time * 47.0) * GRID)
	draw_line(palm.snapped(Vector2.ONE * GRID), (held + jitter).snapped(Vector2.ONE * GRID), Color(color, vfx.flow_hold_alpha), GRID)
	draw_circle(held, vfx.flow_hold_radius * 0.7, Color(color, vfx.flow_hold_alpha * 0.5))
	if reduced:
		return
	for mote in vfx.flow_hold_motes:
		var phase: float = fposmod(_time * vfx.flow_hold_mote_rate + float(mote) / vfx.flow_hold_motes, 1.0)
		var at: Vector2 = held.lerp(palm, phase) + Vector2(0.0, sin(phase * TAU + mote) * vfx.flow_hold_radius * 0.5)
		draw_rect(Rect2(at.snapped(Vector2.ONE * GRID), Vector2.ONE * GRID), Color(color, 1.0 - phase))


func _draw_singularity(fighter: FighterState) -> void:
	if debris == null:
		return
	var creating: bool = fighter.power != null and fighter.power.kind == PowerData.Kind.SINGULARITY and fighter.power_phase == FighterState.Phase.STARTUP
	if fighter.singularity_ticks <= 0 and not creating:
		return
	var radius: float = debris.singularity_radius(fighter)
	if creating:
		radius *= clampf(float(fighter.power_ticks) / maxf(fighter.power.startup_ticks(), 1.0), 0.0, 1.0)
	var color: Color = tier_color(fighter.flow_tier).lerp(PALETTE.eclipse, vfx.singularity_tier_tint)
	var at: Vector2 = debris.singularity_position(fighter)
	var forming: bool = fighter.singularity_phase == FighterState.SingularityPhase.FORMATION
	_draw_singularity_core(at, radius, color, forming)
	if forming:
		var aim: Vector2 = Vector2(fighter.singularity_aim.x, -fighter.singularity_aim.y)
		var direction: Vector2 = (aim - at).normalized()
		draw_line(at + direction * radius, at + direction * radius * 2.0, Color(color, 0.7), GRID)


func _draw_singularity_core(at: Vector2, radius: float, color: Color, forming: bool) -> void:
	at = at.snapped(Vector2.ONE * GRID)
	var core: float = radius * (0.22 if forming else 0.35)
	draw_circle(at, snappedf(core, GRID), Color(color, 0.8))
	draw_circle(at, GRID, PALETTE.text)
	for side_index in 2:
		var start: float = float(side_index) * PI + 0.3
		draw_arc(at, radius * 0.85, start, start + PI * 0.6, 8, Color(color, 0.65), GRID)
	if reduced:
		return
	for band in 3:
		var phase: float = fposmod(floorf(_time * vfx.singularity_vibration_rate) / vfx.singularity_vibration_rate + float(band) / 3.0, 1.0)
		var offset: Vector2 = Vector2((band % 2 * 2 - 1) * vfx.singularity_distortion * phase, (band - 1) * radius * 0.8)
		draw_line((at + offset - Vector2(radius, 0.0)).snapped(Vector2.ONE * GRID), (at + offset + Vector2(radius, 0.0)).snapped(Vector2.ONE * GRID), Color(color, 0.12), GRID)
