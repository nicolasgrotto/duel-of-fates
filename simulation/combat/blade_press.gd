class_name BladePress


static func reset(sim: MatchSimulation) -> void:
	sim.contact_streak = 0
	sim.contact_idle_ticks = 0
	sim.contact_parrier = -1


static func observe(sim: MatchSimulation) -> void:
	sim.contact_idle_ticks += 1
	for i in sim.event_count:
		var event: CombatEvent = sim.events[i]
		if _counts(event):
			_contact(sim, event.target if event.type != CombatEvent.Type.CLASH else -1)
		elif _breaks(event):
			reset(sim)
	if sim.contact_streak > 0 and sim.contact_idle_ticks > Ticks.from_seconds(sim.config.blade_lock.press_contact_window):
		reset(sim)
	if sim.contact_streak >= sim.config.blade_lock.press_contacts and sim.contact_idle_ticks == 0:
		_try_open(sim)


static func _counts(event: CombatEvent) -> bool:
	match event.type:
		CombatEvent.Type.CLASH:
			return not event.heavy
		CombatEvent.Type.PARRY, CombatEvent.Type.PERFECT_PARRY:
			return event.move != null and not event.move.is_heavy() and not event.move.is_technique()
	return false


static func _breaks(event: CombatEvent) -> bool:
	match event.type:
		CombatEvent.Type.HIT, CombatEvent.Type.GUARD_BREAK, CombatEvent.Type.SHOVE, CombatEvent.Type.DODGE:
			return true
		CombatEvent.Type.POWER_STARTED, CombatEvent.Type.TECHNIQUE_CLASH, CombatEvent.Type.BLADE_LOCK_STARTED:
			return true
		CombatEvent.Type.ATTACK_STARTED:
			return event.move != null and (event.move.is_heavy() or event.move.is_technique())
	return false


static func _contact(sim: MatchSimulation, parrier: int) -> void:
	sim.contact_streak += 1
	sim.contact_idle_ticks = 0
	sim.contact_parrier = parrier


static func _try_open(sim: MatchSimulation) -> void:
	var a: FighterState = sim.fighters[0]
	var b: FighterState = sim.fighters[1]
	var parrier: int = sim.contact_parrier
	reset(sim)
	var config: CombatConfig = sim.config
	if not sim.rules.blade_lock or sim.lock_cooldown_ticks > 0 or BladeLockResolver.is_active(sim):
		return
	if not (a.is_alive() and b.is_alive() and a.on_ground and b.on_ground):
		return
	if CombatGeometry.gap(config, a, b) > config.blade_lock.press_entry_gap:
		return
	BladeLockResolver.start(sim, a, b, true)
	if parrier >= 0:
		sim.fighters[parrier].lock_presses = config.blade_lock.press_parry_advantage
