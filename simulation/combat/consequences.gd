class_name Consequences

const FINISHER_SEED_MIX: int = 31
const FINISHER_TICK_MIX: int = 7


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


static func finisher_for(sim: MatchSimulation, move: MoveData, power: PowerData, deciding: bool) -> Finisher.Kind:
	if not sim.rules.finishers or not deciding:
		return Finisher.Kind.NONE
	if power != null:
		return power.finisher
	if move != null:
		return move.cinematic_finisher
	return Finisher.Kind.NONE


static func family_finisher(sim: MatchSimulation, killer: FighterState, victim: FighterState, move: MoveData, base: Finisher.Kind) -> Finisher.Kind:
	if base == Finisher.Kind.NONE or sim.rules.fixed_finishers or move == null:
		return base
	if move.kind != MoveData.Kind.HEAVY and move.kind != MoveData.Kind.FORWARD_HEAVY:
		return base
	var family: MotionFamily = killer.character.family
	if family == null or family.finisher_pool.is_empty():
		return base
	var options: Array[Finisher.Kind] = [base]
	for value in family.finisher_pool:
		options.append(value as Finisher.Kind)
	options = options.filter(func(kind: Finisher.Kind) -> bool: return Finisher.fits(kind, victim.character.weapon.kind))
	if options.is_empty():
		return base
	return options[posmod(sim.seed_value * FINISHER_SEED_MIX + sim.tick * FINISHER_TICK_MIX + sim.round_number, options.size())]


static func finisher_limb(sim: MatchSimulation, attacker: FighterState, defender: FighterState, move: MoveData, deciding: bool) -> MoveData.Limb:
	if not sim.rules.finishers or move == null or move.is_aerial():
		return MoveData.Limb.NONE
	if not move.is_blade() and move.kind != MoveData.Kind.LOCK_FINISH:
		return MoveData.Limb.NONE
	if move.finisher_limb == MoveData.Limb.NONE:
		return MoveData.Limb.NONE
	if deciding and sim.config.consequences.head_on_deciding_heavy and _takes_head(move):
		return MoveData.Limb.HEAD
	if move.kind != MoveData.Kind.LIGHT or move.finisher_limb == MoveData.Limb.LEG:
		return move.finisher_limb
	var struck: MoveData.Limb = struck_zone(sim.config.consequences, attacker, defender, move)
	if struck == MoveData.Limb.HEAD and not deciding:
		return MoveData.Limb.ARM
	return struck


static func struck_zone(config: ConsequenceConfig, attacker: FighterState, defender: FighterState, move: MoveData) -> MoveData.Limb:
	var height: float = attacker.y + config.cut_heights[move.cut] - defender.y
	if height >= config.head_line:
		return MoveData.Limb.HEAD
	if height < config.leg_line:
		return MoveData.Limb.LEG
	return MoveData.Limb.ARM


static func _takes_head(move: MoveData) -> bool:
	if move.is_heavy():
		return true
	return move.is_technique() and move.technique_style == MoveData.TechniqueStyle.RISING
