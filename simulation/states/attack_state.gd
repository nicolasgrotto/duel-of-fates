class_name AttackState
extends StateLogic


func step(sim: MatchSimulation, fighter: FighterState, _intent: Intent) -> void:
	var move: MoveData = fighter.move
	fighter.phase_ticks += 1
	match fighter.move_phase:
		FighterState.Phase.STARTUP:
			decelerate(sim, fighter)
			if fighter.phase_ticks >= move.startup_ticks():
				_enter_active(fighter, move)
		FighterState.Phase.ACTIVE:
			if fighter.phase_ticks >= move.active_ticks():
				fighter.move_phase = FighterState.Phase.RECOVERY
				fighter.phase_ticks = 0
		FighterState.Phase.RECOVERY:
			decelerate(sim, fighter)
			if _try_chain(sim, fighter):
				return
			if fighter.phase_ticks >= move.recovery_ticks():
				finish_to_neutral(sim, fighter)


func exit(_sim: MatchSimulation, fighter: FighterState) -> void:
	fighter.clear_move()


func _enter_active(fighter: FighterState, move: MoveData) -> void:
	fighter.move_phase = FighterState.Phase.ACTIVE
	fighter.phase_ticks = 0
	if fighter.on_ground and move.lunge > 0.0 and move.active > 0.0:
		fighter.vx = fighter.facing * move.lunge * fighter.agility_multiplier / move.active


func _try_chain(sim: MatchSimulation, fighter: FighterState) -> bool:
	var move: MoveData = fighter.move
	if move.kind != MoveData.Kind.LIGHT or not fighter.move_connected:
		return false
	if fighter.buffered_action != FighterState.Action.LIGHT:
		return false
	var next_index: int = fighter.chain_index + 1
	var chain: Array[MoveData] = fighter.character.light_chain
	if next_index >= chain.size():
		return false
	ActionStarter.consume(fighter)
	ActionStarter.start_attack(sim, fighter, chain[next_index], next_index)
	return true


func debug_lines(_sim: MatchSimulation, fighter: FighterState) -> PackedStringArray:
	if fighter.move == null:
		return PackedStringArray()
	var phase_name: String = FighterState.Phase.keys()[fighter.move_phase]
	return PackedStringArray([
		"%s  %s %d" % [fighter.move.id, phase_name.to_lower(), fighter.phase_ticks],
		"chain %d  connected %s  hit %s" % [fighter.chain_index, fighter.move_connected, fighter.move_hit_done],
	])
