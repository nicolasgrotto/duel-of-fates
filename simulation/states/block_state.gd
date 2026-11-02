class_name BlockState
extends StateLogic


func step(sim: MatchSimulation, fighter: FighterState, intent: Intent) -> void:
	if fighter.sidearm_guard_ticks > 0:
		fighter.sidearm_guard_ticks -= 1
	_guard_walk(sim, fighter, intent)
	_advance_parry_window(sim, fighter)
	var tapped: bool = fighter.buffered_action == FighterState.Action.BLOCK
	if tapped:
		ActionStarter.consume(fighter)
		ActionStarter.open_parry_window(fighter)
	if fighter.stun_ticks > 0:
		fighter.stun_ticks -= 1
		return
	if ActionStarter.try_buffered(sim, fighter, intent, ActionStarter.GUARD_ACTIONS):
		return
	if _try_guard_technique(sim, fighter):
		return
	if not intent.is_held(Intent.Command.BLOCK) and fighter.parry_ticks == FighterState.NO_PARRY:
		sim.change_state(fighter, FighterState.State.IDLE)


func _try_guard_technique(sim: MatchSimulation, fighter: FighterState) -> bool:
	if fighter.buffered_action != FighterState.Action.SPECIAL:
		return false
	var technique: MoveData = ActionStarter.technique_for(sim, fighter, fighter.buffered_direction)
	if technique == null or not technique.from_guard:
		return false
	ActionStarter.consume(fighter)
	return ActionStarter.start_attack(sim, fighter, technique) == ActionStarter.Result.STARTED


func _guard_walk(sim: MatchSimulation, fighter: FighterState, intent: Intent) -> void:
	var ratio: float = fighter.character.block_walk_ratio
	if ratio <= 0.0 or fighter.stun_ticks > 0 or not intent.is_held(Intent.Command.BLOCK):
		decelerate(sim, fighter)
		return
	var target: float = intent.move_x * fighter.walk_speed * ratio
	var rate: float = sim.config.ground_acceleration if intent.move_x != 0 else sim.config.ground_deceleration
	fighter.vx = move_toward(fighter.vx, target, rate * Ticks.DELTA)


func exit(_sim: MatchSimulation, fighter: FighterState) -> void:
	fighter.sidearm_guard_ticks = 0
	fighter.parry_ticks = FighterState.NO_PARRY
	fighter.stun_ticks = 0


func _advance_parry_window(sim: MatchSimulation, fighter: FighterState) -> void:
	if fighter.parry_ticks == FighterState.NO_PARRY:
		return
	fighter.parry_ticks += 1
	if fighter.parry_ticks >= fighter.parry_window_ticks:
		fighter.parry_ticks = FighterState.NO_PARRY
		fighter.parry_lockout_ticks = Ticks.from_seconds(sim.config.parry_lockout)


func debug_lines(_sim: MatchSimulation, fighter: FighterState) -> PackedStringArray:
	return PackedStringArray([
		"parry %d  lockout %d  blockstun %d" % [fighter.parry_ticks, fighter.parry_lockout_ticks, fighter.stun_ticks],
	])
