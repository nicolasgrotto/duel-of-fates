class_name DodgeState
extends StateLogic


func enter(sim: MatchSimulation, fighter: FighterState) -> void:
	_set_velocity(sim, fighter)


func step(sim: MatchSimulation, fighter: FighterState, _intent: Intent) -> void:
	var config: CombatConfig = sim.config
	match fighter.dodge_kind:
		FighterState.DodgeKind.GROUND:
			_set_velocity(sim, fighter)
			if fighter.state_ticks >= Ticks.from_seconds(config.dodge_duration):
				finish_to_neutral(sim, fighter)
		FighterState.DodgeKind.AIR:
			_set_velocity(sim, fighter)
			if fighter.state_ticks >= Ticks.from_seconds(config.air_dash_duration):
				fighter.vx = fighter.dodge_direction * fighter.walk_speed
				finish_to_neutral(sim, fighter)
		FighterState.DodgeKind.EVADE:
			_step_evade(sim, fighter)
		FighterState.DodgeKind.DASH:
			_set_velocity(sim, fighter)
			if fighter.state_ticks >= Ticks.from_seconds(fighter.character.ability.dash_duration):
				finish_to_neutral(sim, fighter)


func exit(_sim: MatchSimulation, fighter: FighterState) -> void:
	fighter.dodge_kind = FighterState.DodgeKind.NONE
	fighter.evade_window_ticks = 0


func _set_velocity(sim: MatchSimulation, fighter: FighterState) -> void:
	var config: CombatConfig = sim.config
	match fighter.dodge_kind:
		FighterState.DodgeKind.GROUND:
			fighter.vx = fighter.dodge_direction * config.dodge_distance * fighter.agility_multiplier / config.dodge_duration
		FighterState.DodgeKind.AIR:
			fighter.vx = fighter.dodge_direction * config.air_dash_distance * fighter.agility_multiplier / config.air_dash_duration
		FighterState.DodgeKind.DASH:
			var ability: AbilityData = fighter.character.ability
			fighter.vx = fighter.dodge_direction * ability.dash_distance * fighter.agility_multiplier / ability.dash_duration
		FighterState.DodgeKind.EVADE:
			if fighter.evade_window_ticks > 0:
				fighter.vx = fighter.dodge_direction * config.evade_step / Ticks.to_seconds(fighter.evade_window_ticks)


func _step_evade(sim: MatchSimulation, fighter: FighterState) -> void:
	var config: CombatConfig = sim.config
	if fighter.evade_window_ticks > 0:
		fighter.evade_window_ticks -= 1
		if fighter.evade_window_ticks == 0 and not fighter.evade_succeeded:
			fighter.evade_streak = 0
	else:
		decelerate(sim, fighter)
	if fighter.state_ticks >= Ticks.from_seconds(config.evade_duration):
		finish_to_neutral(sim, fighter)


func debug_lines(_sim: MatchSimulation, fighter: FighterState) -> PackedStringArray:
	var kind_name: String = FighterState.DodgeKind.keys()[fighter.dodge_kind]
	return PackedStringArray([
		"%s  invuln %d  evade %d  streak %d" % [kind_name.to_lower(), fighter.invulnerable_ticks, fighter.evade_window_ticks, fighter.evade_streak],
	])
