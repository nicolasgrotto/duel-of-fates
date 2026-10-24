class_name PowerState
extends StateLogic


func step(sim: MatchSimulation, fighter: FighterState, intent: Intent) -> void:
	fighter.power_ticks += 1
	match fighter.power_phase:
		FighterState.Phase.STARTUP:
			decelerate(sim, fighter)
			if fighter.power_ticks >= fighter.power.startup_ticks():
				PowerEffects.activate(sim, fighter)
		FighterState.Phase.ACTIVE:
			PowerEffects.sustain(sim, fighter, intent)
		FighterState.Phase.RECOVERY:
			decelerate(sim, fighter)
			PowerEffects.recovering(sim, fighter)
			if fighter.power_ticks >= fighter.power.recovery_ticks_at(fighter.flow_tier >= PowerEffects.APEX_TIER):
				finish_to_neutral(sim, fighter)


func exit(sim: MatchSimulation, fighter: FighterState) -> void:
	PowerEffects.release(sim, fighter)
	fighter.power = null
	fighter.power_phase = FighterState.Phase.NONE
	fighter.power_ticks = 0


func debug_lines(_sim: MatchSimulation, fighter: FighterState) -> PackedStringArray:
	if fighter.power == null:
		return PackedStringArray()
	return PackedStringArray([
		"%s  %s %d" % [fighter.power.id, FighterState.Phase.keys()[fighter.power_phase].to_lower(), fighter.power_ticks],
	])
