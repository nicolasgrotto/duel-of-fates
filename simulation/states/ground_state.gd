class_name GroundState
extends StateLogic


func step(sim: MatchSimulation, fighter: FighterState, intent: Intent) -> void:
	if ActionStarter.try_buffered(sim, fighter, intent, ActionStarter.GROUND_ACTIONS):
		return
	if intent.is_held(Intent.Command.BLOCK) and not fighter.blade_out:
		sim.change_state(fighter, FighterState.State.BLOCKING)
		return
	_walk(sim, fighter, intent.move_x)


func _walk(sim: MatchSimulation, fighter: FighterState, direction: int) -> void:
	var config: CombatConfig = sim.config
	var target_speed: float = direction * fighter.walk_speed
	if direction != 0 and direction != fighter.facing:
		target_speed *= config.back_walk_ratio
	var rate: float = config.ground_acceleration if direction != 0 else config.ground_deceleration
	fighter.vx = move_toward(fighter.vx, target_speed, rate * Ticks.DELTA)
	fighter.state = FighterState.State.WALKING if direction != 0 else FighterState.State.IDLE


func debug_lines(_sim: MatchSimulation, fighter: FighterState) -> PackedStringArray:
	return PackedStringArray(["speed %.0f" % fighter.vx])
