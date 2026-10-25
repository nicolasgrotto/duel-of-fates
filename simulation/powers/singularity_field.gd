extends RefCounted


static func start(sim: MatchSimulation, caster: FighterState, power: PowerData) -> void:
	var target: FighterState = sim.opponent_of(caster)
	caster.singularity_power = power
	caster.singularity_ticks = Ticks.from_seconds(power.duration)
	caster.singularity_elapsed = 0
	caster.singularity_phase = FighterState.SingularityPhase.SUSPENSION
	caster.singularity_wave = 0
	caster.singularity_mass = 0
	caster.singularity_center = Vector2((caster.x + target.x) * 0.5, power.sphere_height)
	caster.singularity_aim = Vector2(target.x, target.y + power.target_height)


static func step(sim: MatchSimulation) -> void:
	for caster in sim.fighters:
		if caster.singularity_ticks <= 0:
			continue
		if not caster.is_alive():
			_cancel(sim, caster)
			continue
		var power: PowerData = caster.singularity_power
		caster.singularity_elapsed += 1
		caster.singularity_ticks -= 1
		var elapsed: int = caster.singularity_elapsed
		var suspension: int = Ticks.from_seconds(power.suspension)
		var formation: int = Ticks.from_seconds(power.duration - power.formation)
		if elapsed < suspension:
			continue
		if elapsed < formation:
			caster.singularity_phase = FighterState.SingularityPhase.EXTRACTION
			if (elapsed - suspension) % maxi(Ticks.from_seconds(power.pulse_interval), 1) == 0:
				_wave(sim, caster, power)
		elif caster.singularity_phase != FighterState.SingularityPhase.FORMATION:
			caster.singularity_phase = FighterState.SingularityPhase.FORMATION
			var target: FighterState = sim.opponent_of(caster)
			caster.singularity_aim = Vector2(target.x, target.y + power.target_height)
		if caster.singularity_ticks == 0:
			_launch(sim, caster, power)


static func pull(sim: MatchSimulation, target: FighterState) -> void:
	var caster: FighterState = sim.opponent_of(target)
	if caster.singularity_ticks <= 0 or not caster.is_alive() or not target.is_alive():
		return
	if target.is_invulnerable() or target.evade_window_ticks > 0 or target.state == FighterState.State.BLADE_LOCK or target.held_by_choke:
		return
	var power: PowerData = caster.singularity_power
	var delta: Vector2 = caster.singularity_center - Vector2(target.x, target.y + power.target_height)
	if absf(delta.x) > power.reach:
		return
	if target.on_ground:
		target.x += signf(delta.x) * minf(power.ground_pull * Ticks.DELTA, absf(delta.x))
	else:
		target.vx = move_toward(target.vx, signf(delta.x) * power.pull_speed, power.air_pull * Ticks.DELTA)
		target.vy = move_toward(target.vy, signf(delta.y) * power.pull_speed, power.vertical_pull * Ticks.DELTA)


static func _wave(sim: MatchSimulation, caster: FighterState, power: PowerData) -> void:
	var target: FighterState = sim.opponent_of(caster)
	var limit: float = sim.config.half_width() - power.mark_half_width
	var first: float = clampf(target.x, -limit, limit)
	var second: float = clampf(caster.singularity_center.x + sim.rng.randf_range(-power.reach, power.reach), -limit, limit)
	var spacing: float = power.mark_half_width * 2.0 + power.safe_width
	if absf(first - second) < spacing:
		second = first + (spacing if first <= 0.0 else -spacing)
	second = clampf(second, -limit, limit)
	var group: int = sim.next_hazard_group()
	sim.spawn_hazard(Hazard.Kind.EXTRACTION, caster, first, power.mark_half_width, power.warning, group, power.extraction_damage * caster.flow_potency, power)
	sim.spawn_hazard(Hazard.Kind.EXTRACTION, caster, second, power.mark_half_width, power.warning, group, power.extraction_damage * caster.flow_potency, power)
	caster.singularity_wave += 1


static func _launch(sim: MatchSimulation, caster: FighterState, power: PowerData) -> void:
	caster.singularity_phase = FighterState.SingularityPhase.THROW
	caster.singularity_throw_ticks = power.recovery_ticks()
	var projectile: Projectile = sim.spawn_projectile(Projectile.Kind.SINGULARITY, caster, power)
	if projectile == null:
		return
	var direction: Vector2 = (caster.singularity_aim - caster.singularity_center).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.UP
	projectile.x = caster.singularity_center.x
	projectile.y = caster.singularity_center.y
	projectile.vx = direction.x * power.speed
	projectile.vy = direction.y * power.speed
	projectile.delay_ticks = Ticks.from_seconds(power.throw_range / power.speed)
	projectile.damage = power.damage_for(caster.flow_level) * caster.flow_potency
	projectile.size = power.projectile_size
	projectile.max_distance = power.throw_range


static func _cancel(sim: MatchSimulation, caster: FighterState) -> void:
	caster.singularity_ticks = 0
	caster.singularity_phase = FighterState.SingularityPhase.NONE
	for hazard in sim.hazards:
		if hazard.active and hazard.owner == caster.index and hazard.kind == Hazard.Kind.EXTRACTION:
			hazard.active = false
