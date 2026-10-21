class_name AttackState
extends StateLogic


func step(sim: MatchSimulation, fighter: FighterState, intent: Intent) -> void:
	var move: MoveData = fighter.move
	match fighter.move_phase:
		FighterState.Phase.STARTUP:
			decelerate(sim, fighter)
			if _try_feint(sim, fighter, move):
				return
			if fighter.phase_ticks + 1 >= move.startup_ticks() and _holds_charge(fighter, move, intent):
				return
			fighter.phase_ticks += 1
			if fighter.phase_ticks >= move.startup_ticks():
				_enter_active(fighter, move)
			return
	fighter.phase_ticks += 1
	match fighter.move_phase:
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
	if move.dive_speed > 0.0 and fighter.is_airborne():
		fighter.vy = -move.dive_speed


func _holds_charge(fighter: FighterState, move: MoveData, intent: Intent) -> bool:
	var ability: AbilityData = fighter.character.ability
	if ability == null or ability.kind != AbilityData.Kind.CHARGE or move != ability.move:
		return false
	var full: int = ability.charge_level_ticks() * (ability.charge_levels - 1)
	if not intent.is_held(Intent.Command.SPECIAL) or fighter.charge_ticks >= full:
		return false
	fighter.charge_ticks += 1
	fighter.charge_level = mini(1 + fighter.charge_ticks / ability.charge_level_ticks(), ability.charge_levels)
	return true


func _try_feint(sim: MatchSimulation, fighter: FighterState, move: MoveData) -> bool:
	if not fighter.character.can_feint or fighter.buffered_action != FighterState.Action.BLOCK:
		return false
	if move.kind != MoveData.Kind.HEAVY and move.kind != MoveData.Kind.FORWARD_HEAVY:
		return false
	ActionStarter.consume(fighter)
	if not sim.spend_vigor(fighter, sim.config.feint_vigor):
		return false
	sim.change_state(fighter, FighterState.State.BLOCKING)
	sim.emit(CombatEvent.Type.FEINT, fighter.index, sim.opponent_of(fighter).index).move = move
	return true


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
