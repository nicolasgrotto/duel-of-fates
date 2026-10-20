class_name BlockState
extends StateLogic


func step(sim: MatchSimulation, fighter: FighterState, intent: Intent) -> void:
	decelerate(sim, fighter)
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
	if not intent.is_held(Intent.Command.BLOCK) and fighter.parry_ticks == FighterState.NO_PARRY:
		sim.change_state(fighter, FighterState.State.IDLE)


func exit(_sim: MatchSimulation, fighter: FighterState) -> void:
	fighter.parry_ticks = FighterState.NO_PARRY
	fighter.stun_ticks = 0


func _advance_parry_window(sim: MatchSimulation, fighter: FighterState) -> void:
	if fighter.parry_ticks == FighterState.NO_PARRY:
		return
	fighter.parry_ticks += 1
	if fighter.parry_ticks >= Ticks.from_seconds(sim.config.parry_window):
		fighter.parry_ticks = FighterState.NO_PARRY
		fighter.parry_lockout_ticks = Ticks.from_seconds(sim.config.parry_lockout)


func debug_lines(_sim: MatchSimulation, fighter: FighterState) -> PackedStringArray:
	return PackedStringArray([
		"parry %d  lockout %d  blockstun %d" % [fighter.parry_ticks, fighter.parry_lockout_ticks, fighter.stun_ticks],
	])
