class_name ClashResolver


static func resolve(sim: MatchSimulation) -> void:
	var a: FighterState = sim.fighters[0]
	var b: FighterState = sim.fighters[1]
	if not _blades_meet(sim, a, b):
		return
	var config: CombatConfig = sim.config
	var gap: float = CombatGeometry.gap(config, a, b)
	if _can_lock(sim, a, b, gap):
		BladeLockResolver.start(sim, a, b)
	elif a.move.is_heavy() or b.move.is_heavy():
		_heavy_clash(sim, a, b)
	else:
		_light_clash(sim, a, b)


static func _blades_meet(sim: MatchSimulation, a: FighterState, b: FighterState) -> bool:
	if not (a.is_active() and b.is_active()):
		return false
	if a.move_hit_done or b.move_hit_done:
		return false
	if not (a.move.can_clash() and b.move.can_clash()):
		return false
	if not (CombatGeometry.faces(a, b) and CombatGeometry.faces(b, a)):
		return false
	var config: CombatConfig = sim.config
	if CombatGeometry.gap(config, a, b) > a.move.blade_reach + b.move.blade_reach:
		return false
	var a_box: Rect2 = CombatGeometry.blade_box(config, a, a.move)
	var b_box: Rect2 = CombatGeometry.blade_box(config, b, b.move)
	return a_box.position.y <= b_box.end.y and b_box.position.y <= a_box.end.y


static func _can_lock(sim: MatchSimulation, a: FighterState, b: FighterState, gap: float) -> bool:
	return (
		sim.rules.blade_lock
		and sim.lock_cooldown_ticks == 0
		and a.move.can_blade_lock
		and b.move.can_blade_lock
		and a.on_ground
		and b.on_ground
		and gap <= sim.config.blade_lock.entry_gap
	)


static func _light_clash(sim: MatchSimulation, a: FighterState, b: FighterState) -> void:
	var event: CombatEvent = _emit(sim, a, b, false)
	for fighter in [a, b]:
		fighter.move_hit_done = true
		fighter.move_connected = true
	sim.push_apart(a, b, sim.config.clash_light_separation)
	event.hitstop_ticks = sim.freeze_pair(a, b, sim.config.hitstop_clash)


static func _heavy_clash(sim: MatchSimulation, a: FighterState, b: FighterState) -> void:
	var event: CombatEvent = _emit(sim, a, b, true)
	var recoil_ticks: int = Ticks.from_seconds(sim.config.clash_heavy_recoil)
	for fighter in [a, b]:
		sim.change_state(fighter, FighterState.State.HIT)
		fighter.stun_ticks = recoil_ticks
	sim.push_apart(a, b, sim.config.clash_heavy_separation)
	event.hitstop_ticks = sim.freeze_pair(a, b, sim.config.hitstop_clash)


static func _emit(sim: MatchSimulation, a: FighterState, b: FighterState, heavy: bool) -> CombatEvent:
	var event: CombatEvent = sim.emit(CombatEvent.Type.CLASH, a.index, b.index)
	event.heavy = heavy
	event.move = a.move
	var height: float = (a.y + b.y + (a.move.hitbox_bottom + a.move.hitbox_top + b.move.hitbox_bottom + b.move.hitbox_top) * 0.5) * 0.5
	event.position = Vector2((a.x + b.x) * 0.5, height)
	return event
