class_name AirState
extends StateLogic


func step(sim: MatchSimulation, fighter: FighterState, intent: Intent) -> void:
	if ActionStarter.try_buffered(sim, fighter, intent, ActionStarter.AIR_ACTIONS):
		return
	if intent.move_x != 0:
		var target_speed: float = intent.move_x * fighter.walk_speed
		fighter.vx = move_toward(fighter.vx, target_speed, sim.config.air_acceleration * Ticks.DELTA)


func debug_lines(_sim: MatchSimulation, fighter: FighterState) -> PackedStringArray:
	return PackedStringArray([
		"jumps %d  dash %s  aerial %s" % [fighter.jumps_used, fighter.air_dash_used, fighter.air_attack_used],
	])
