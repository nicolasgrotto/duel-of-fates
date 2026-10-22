class_name FlowStatuses


static func step(sim: MatchSimulation, fighter: FighterState) -> void:
	if not fighter.is_alive():
		return
	if sim.rules.powers and not fighter.is_casting():
		sim.gain_flow(fighter, sim.config.flow.regen * Ticks.DELTA)
	if fighter.power_cooldown > 0:
		fighter.power_cooldown -= 1
	for slot in FighterState.POWER_SLOTS:
		if fighter.power_cooldowns[slot] > 0:
			fighter.power_cooldowns[slot] -= 1
	_heal(fighter)
	fighter.focus_ticks = maxi(fighter.focus_ticks - 1, 0)
	fighter.twisted_ticks = maxi(fighter.twisted_ticks - 1, 0)
	fighter.rain_ticks = maxi(fighter.rain_ticks - 1, 0)
	if fighter.wrath_ticks > 0:
		fighter.wrath_ticks -= 1
		if fighter.wrath_ticks == 0:
			fighter.wrath_armor = 0
	if fighter.sanctuary_ticks > 0:
		fighter.sanctuary_ticks -= 1
		if fighter.sanctuary_ticks == 0:
			fighter.sanctuary_hp = 0.0
	if fighter.arsenal_ticks > 0:
		fighter.arsenal_ticks -= 1
		if fighter.arsenal_ticks == 0:
			fighter.arsenal_count = 0


static func _heal(fighter: FighterState) -> void:
	if fighter.heal_ticks <= 0:
		return
	fighter.health = minf(fighter.health + fighter.heal_per_tick, fighter.max_health)
	fighter.heal_ticks -= 1
	if fighter.heal_ticks == 0:
		fighter.wound = FighterState.Wound.NONE
