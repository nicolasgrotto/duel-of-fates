class_name ProjectileSystem

const CATCH_DISTANCE: float = 30.0


static func step(sim: MatchSimulation) -> void:
	for projectile in sim.projectiles:
		if not projectile.active:
			continue
		var owner: FighterState = sim.fighters[projectile.owner]
		_move(sim, projectile, owner)
		if not projectile.active:
			continue
		var target: FighterState = sim.opponent_of(owner)
		if not projectile.hit_done and _touches(sim, projectile, target):
			_collide(sim, projectile, owner, target)


static func drift(sim: MatchSimulation) -> void:
	for projectile in sim.projectiles:
		if projectile.active:
			_move(sim, projectile, sim.fighters[projectile.owner])


static func _move(sim: MatchSimulation, projectile: Projectile, owner: FighterState) -> void:
	if projectile.kind == Projectile.Kind.SINGULARITY:
		projectile.delay_ticks -= 1
		if projectile.delay_ticks <= 0:
			_end(sim, projectile)
			return
	var step: float = projectile.vx * Ticks.DELTA
	if projectile.kind == Projectile.Kind.BLADE and projectile.returning:
		var toward: float = signf(owner.x - projectile.x)
		projectile.vx = toward * absf(projectile.vx)
		projectile.y = move_toward(projectile.y, owner.y + sim.config.flow.projectile_height, 400.0 * Ticks.DELTA)
		step = projectile.vx * Ticks.DELTA
		if absf(owner.x - projectile.x) <= CATCH_DISTANCE:
			_end(sim, projectile)
			return
	projectile.x += step
	if projectile.kind == Projectile.Kind.SINGULARITY or projectile.kind == Projectile.Kind.BOLT:
		projectile.y += projectile.vy * Ticks.DELTA
		projectile.travelled += Vector2(step, projectile.vy * Ticks.DELTA).length()
	else:
		projectile.travelled += absf(step)
	var limit: float = sim.config.half_width()
	var reached: bool = projectile.travelled >= projectile.max_distance or absf(projectile.x) >= limit or ((projectile.kind == Projectile.Kind.SINGULARITY or projectile.kind == Projectile.Kind.BOLT) and projectile.y < -projectile.size)
	if not reached:
		return
	if projectile.kind == Projectile.Kind.BLADE and not projectile.returning:
		projectile.returning = true
		projectile.x = clampf(projectile.x, -limit, limit)
	elif projectile.kind != Projectile.Kind.BLADE:
		_end(sim, projectile)


static func _touches(sim: MatchSimulation, projectile: Projectile, target: FighterState) -> bool:
	var hurtbox: Rect2 = CombatGeometry.hurtbox(sim.config, target)
	var box: Rect2 = Rect2(projectile.x - projectile.size, projectile.y - projectile.size, projectile.size * 2.0, projectile.size * 2.0)
	return CombatGeometry.overlaps(box, hurtbox)


static func _collide(sim: MatchSimulation, projectile: Projectile, owner: FighterState, target: FighterState) -> void:
	if target.arsenal_count > 0 and projectile.kind != Projectile.Kind.BLADE and projectile.kind != Projectile.Kind.SINGULARITY:
		target.arsenal_count -= 1
		var caught: CombatEvent = sim.emit(CombatEvent.Type.POWER_BLOCKED, owner.index, target.index)
		caught.power = projectile.power
		caught.position = Vector2(projectile.x, projectile.y)
		_end(sim, projectile)
		return
	if projectile.kind == Projectile.Kind.BOLT:
		BoltResolver.resolve(sim, projectile, owner, target)
		if projectile.hit_done:
			_end(sim, projectile)
		return
	if projectile.kind == Projectile.Kind.CLEAVE and _perfect_parry(target, projectile):
		_reflect(sim, projectile, target)
		return
	if projectile.move != null:
		_blade_hit(sim, projectile, owner, target)
		if projectile.kind == Projectile.Kind.CLEAVE and projectile.hit_done:
			_end(sim, projectile)
		return
	var impact: PowerImpact = sim.impact
	impact.reset(projectile.power, owner)
	impact.source_x = projectile.x - signf(projectile.vx)
	impact.flow_level = projectile.flow_level
	impact.damage = projectile.damage
	impact.hold = 0.25
	if projectile.kind == Projectile.Kind.SINGULARITY:
		impact.ignore_barrier = true
		impact.ignore_absorption = true
		impact.stagger = projectile.power.stagger
		impact.push = projectile.power.throw_push
	impact.guard_vigor = projectile.power.guard_vigor if projectile.power != null else 8.0
	var result: PowerHit.Result = PowerHit.resolve(sim, owner, target, projectile.power, impact)
	if result == PowerHit.Result.MISSED:
		return
	projectile.hit_done = true
	_end(sim, projectile)


static func _perfect_parry(target: FighterState, projectile: Projectile) -> bool:
	if target.state != FighterState.State.BLOCKING or target.parry_ticks == FighterState.NO_PARRY:
		return false
	if target.parry_ticks >= target.perfect_parry_ticks:
		return false
	var dx: float = projectile.x - target.x
	return dx == 0.0 or signf(dx) == target.facing


static func _reflect(sim: MatchSimulation, projectile: Projectile, target: FighterState) -> void:
	projectile.owner = target.index
	projectile.vx = -projectile.vx
	projectile.travelled = 0.0
	projectile.flow_level = target.flow_level
	target.parry_ticks = FighterState.NO_PARRY
	var event: CombatEvent = sim.emit(CombatEvent.Type.PROJECTILE_REFLECTED, target.index, 1 - target.index)
	event.power = projectile.power
	event.position = Vector2(projectile.x, projectile.y)


static func _blade_hit(sim: MatchSimulation, projectile: Projectile, owner: FighterState, target: FighterState) -> void:
	if target.is_invulnerable() or target.evade_window_ticks > 0 or not target.is_alive():
		return
	projectile.hit_done = true
	var config: CombatConfig = sim.config
	var move: MoveData = projectile.move
	var guarding: bool = target.state == FighterState.State.BLOCKING and signf(projectile.x - target.x) == target.facing
	var event_type: CombatEvent.Type = CombatEvent.Type.BLOCK if guarding else CombatEvent.Type.HIT
	var event: CombatEvent = sim.emit(event_type, owner.index, target.index)
	event.move = move
	event.position = Vector2(projectile.x, projectile.y)
	if guarding:
		sim.drain_vigor(target, sim.block_cost(target, move))
		target.stun_ticks = Ticks.from_seconds(move.blockstun)
		return
	var damage: float = projectile.damage * sim.wrath_scale(owner, target)
	event.amount = damage
	var lethal: bool = sim.apply_damage(target, damage)
	if lethal:
		sim.kill(target, owner, null, null, move)
		return
	sim.change_state(target, FighterState.State.HIT)
	target.stun_ticks = Ticks.from_seconds(move.hitstun)
	target.vx = signf(projectile.vx) * config.slide_speed_for(move.knockback)
	sim.gain_flow(owner, config.flow.gain_on_hit)
	sim.gain_flow(target, config.flow.gain_on_hurt)


static func _end(sim: MatchSimulation, projectile: Projectile) -> void:
	projectile.active = false
	if projectile.kind == Projectile.Kind.BLADE:
		sim.fighters[projectile.owner].blade_out = false
	var event: CombatEvent = sim.emit(CombatEvent.Type.PROJECTILE_ENDED, projectile.owner, CombatEvent.NO_FIGHTER)
	event.power = projectile.power
	event.position = Vector2(projectile.x, projectile.y)
