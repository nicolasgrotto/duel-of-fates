class_name Consequences


static func check_exhaustion(sim: MatchSimulation, fighter: FighterState) -> void:
	if not sim.rules.exhaustion or fighter.exhausted:
		return
	if fighter.vigor <= fighter.max_vigor * sim.config.consequences.exhaustion_enter_ratio:
		fighter.exhausted = true
		fighter.exhausted_ticks = 0
		sim.emit(CombatEvent.Type.EXHAUSTION, fighter.index, CombatEvent.NO_FIGHTER)


static func step_exhaustion(sim: MatchSimulation, fighter: FighterState) -> void:
	if not fighter.exhausted:
		return
	var config: ConsequenceConfig = sim.config.consequences
	fighter.exhausted_ticks += 1
	var rested: bool = fighter.exhausted_ticks >= Ticks.from_seconds(config.exhaustion_min_duration)
	if rested and fighter.vigor >= fighter.max_vigor * config.exhaustion_exit_ratio:
		fighter.exhausted = false
		sim.emit(CombatEvent.Type.EXHAUSTION_RECOVERED, fighter.index, CombatEvent.NO_FIGHTER)


static func try_wound(sim: MatchSimulation, attacker: FighterState, defender: FighterState, move: MoveData) -> void:
	if not sim.rules.wounds or move.wound_limb == MoveData.Limb.NONE:
		return
	if not defender.exhausted or defender.wounded_this_round:
		return
	defender.wound = FighterState.Wound.ARM if move.wound_limb == MoveData.Limb.ARM else FighterState.Wound.LEG
	defender.wounded_this_round = true
	var event: CombatEvent = sim.emit(CombatEvent.Type.WOUND, attacker.index, defender.index)
	event.move = move
	event.limb = move.wound_limb


static func finisher_limb(sim: MatchSimulation, move: MoveData, deciding: bool) -> MoveData.Limb:
	if not sim.rules.finishers or move == null or move.is_aerial():
		return MoveData.Limb.NONE
	if not move.is_blade() and move.kind != MoveData.Kind.LOCK_FINISH:
		return MoveData.Limb.NONE
	if move.finisher_limb == MoveData.Limb.NONE:
		return MoveData.Limb.NONE
	if deciding and sim.rng.randf() < sim.config.consequences.head_finisher_chance:
		return MoveData.Limb.HEAD
	return move.finisher_limb
