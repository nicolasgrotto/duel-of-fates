class_name BoltResolver


static func fire(sim: MatchSimulation, fighter: FighterState, bolt: BoltData) -> void:
	var projectile: Projectile = sim.spawn_projectile(Projectile.Kind.BOLT, fighter, null)
	if projectile == null:
		return
	projectile.bolt = bolt
	projectile.shooter = fighter.index
	projectile.x = fighter.x + fighter.facing * (sim.config.body_width * 0.5 + bolt.muzzle_forward)
	projectile.y = fighter.y + bolt.muzzle_height
	projectile.vx = fighter.facing * bolt.speed
	projectile.damage = bolt.damage
	projectile.size = bolt.size
	projectile.max_distance = bolt.max_range


static func resolve(sim: MatchSimulation, projectile: Projectile, owner: FighterState, target: FighterState) -> void:
	if not target.is_alive():
		return
	if target.state == FighterState.State.DODGING and target.evade_window_ticks > 0:
		_evade(sim, projectile, owner, target)
		return
	if target.is_invulnerable():
		return
	if target.power_kind_active(PowerData.Kind.BARRIER):
		_fizzle(sim, projectile, owner, target).power = target.power
		return
	var facing: bool = projectile.x == target.x or signf(projectile.x - target.x) == target.facing
	if target.state == FighterState.State.BLOCKING and facing:
		if target.parry_ticks != FighterState.NO_PARRY:
			_reflect(sim, projectile, owner, target, target.parry_ticks < target.perfect_parry_ticks)
		else:
			sim.drain_vigor(target, projectile.bolt.guard_vigor)
			_fizzle(sim, projectile, owner, target)
		return
	_hit(sim, projectile, owner, target)


static func flinches(fighter: FighterState) -> bool:
	if not fighter.on_ground:
		return false
	if fighter.state == FighterState.State.IDLE or fighter.state == FighterState.State.WALKING:
		return true
	return fighter.is_attacking() and fighter.move_phase == FighterState.Phase.RECOVERY


static func _evade(sim: MatchSimulation, projectile: Projectile, owner: FighterState, target: FighterState) -> void:
	projectile.evaded = true
	var event: CombatEvent = sim.emit(CombatEvent.Type.EVADE_SUCCESS, owner.index, target.index)
	event.position = Vector2(projectile.x, projectile.y)
	event.from_front = projectile.x == target.x or signf(projectile.x - target.x) == target.facing
	HitResolver.complete_evade(sim, target, event)


static func _fizzle(sim: MatchSimulation, projectile: Projectile, owner: FighterState, target: FighterState) -> CombatEvent:
	projectile.hit_done = true
	var event: CombatEvent = sim.emit(CombatEvent.Type.BOLT_BLOCKED, owner.index, target.index)
	event.position = Vector2(projectile.x, projectile.y)
	return event


static func _reflect(sim: MatchSimulation, projectile: Projectile, owner: FighterState, target: FighterState, perfect: bool) -> void:
	projectile.owner = target.index
	projectile.evaded = false
	projectile.travelled = 0.0
	projectile.flow_level = target.flow_level
	if perfect:
		var chest: Vector2 = Vector2(owner.x, owner.y + sim.config.body_height * 0.5)
		var velocity: Vector2 = (chest - Vector2(projectile.x, projectile.y)).normalized() * projectile.bolt.speed * projectile.bolt.perfect_reflect_speed
		projectile.vx = velocity.x
		projectile.vy = velocity.y
	else:
		projectile.vx = -projectile.vx
		projectile.vy = -projectile.vy
	var event: CombatEvent = sim.emit(CombatEvent.Type.BOLT_REFLECTED, target.index, owner.index)
	event.position = Vector2(projectile.x, projectile.y)
	event.amount = 1.0 if perfect else 0.0


static func _hit(sim: MatchSimulation, projectile: Projectile, owner: FighterState, target: FighterState) -> void:
	projectile.hit_done = true
	var event: CombatEvent = sim.emit(CombatEvent.Type.BOLT_HIT, owner.index, target.index)
	event.position = Vector2(projectile.x, projectile.y)
	event.amount = projectile.damage
	if sim.apply_damage(target, projectile.damage):
		sim.kill(target, owner, null)
		return
	if flinches(target):
		sim.change_state(target, FighterState.State.HIT)
		target.stun_ticks = projectile.bolt.flinch_ticks()
		target.vx = 0.0
