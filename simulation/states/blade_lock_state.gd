class_name BladeLockState
extends StateLogic


func enter(_sim: MatchSimulation, fighter: FighterState) -> void:
	fighter.lock_presses = 0
	fighter.lock_press_cooldown = 0
	fighter.lock_hold_ticks = 0
	fighter.vx = 0.0


func step(sim: MatchSimulation, fighter: FighterState, intent: Intent) -> void:
	var lock_config: BladeLockConfig = sim.config.blade_lock
	if fighter.lock_press_cooldown > 0:
		fighter.lock_press_cooldown -= 1
	var counts: bool = false
	if intent.was_pressed(Intent.Command.LIGHT):
		counts = true
		fighter.lock_hold_ticks = 0
	elif fighter.hold_to_lock and intent.is_held(Intent.Command.LIGHT):
		fighter.lock_hold_ticks += 1
		if fighter.lock_hold_ticks >= lock_config.hold_interval_ticks():
			fighter.lock_hold_ticks = 0
			counts = true
	else:
		fighter.lock_hold_ticks = 0
	if counts and fighter.lock_press_cooldown == 0:
		fighter.lock_presses += 1
		fighter.lock_press_cooldown = lock_config.press_interval_ticks()
		sim.emit(CombatEvent.Type.BLADE_LOCK_PRESSED, fighter.index, sim.opponent_of(fighter).index).amount = fighter.lock_presses
	ActionStarter.consume(fighter)


func exit(_sim: MatchSimulation, fighter: FighterState) -> void:
	fighter.lock_presses = 0
	fighter.lock_hold_ticks = 0
	fighter.lock_press = false


func debug_lines(sim: MatchSimulation, fighter: FighterState) -> PackedStringArray:
	return PackedStringArray(["%s  presses %d  ticks %d" % ["press" if fighter.lock_press else "lock", fighter.lock_presses, sim.lock_ticks]])
