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
		FighterState.DodgeKind.SPIN:
			_step_spin(sim, fighter)


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


static func spin_travel_ticks(config: CombatConfig) -> int:
	return Ticks.from_seconds(config.spin_dodge_duration - config.spin_dodge_recovery)


static func is_spinning_through(config: CombatConfig, fighter: FighterState) -> bool:
	return fighter.state == FighterState.State.DODGING and fighter.dodge_kind == FighterState.DodgeKind.SPIN and fighter.state_ticks <= spin_travel_ticks(config)


func _step_spin(sim: MatchSimulation, fighter: FighterState) -> void:
	var config: CombatConfig = sim.config
	var travel_ticks: int = spin_travel_ticks(config)
	if fighter.state_ticks == Ticks.from_seconds(config.spin_dodge_invulnerable_start):
		fighter.invulnerable_ticks = Ticks.from_seconds(config.spin_dodge_invulnerable_end - config.spin_dodge_invulnerable_start)
	if fighter.state_ticks <= travel_ticks:
		fighter.vx = fighter.dodge_direction * fighter.dodge_travel / Ticks.to_seconds(travel_ticks)
	if fighter.state_ticks == travel_ticks:
		var opponent: FighterState = sim.opponent_of(fighter)
		fighter.vx = 0.0
		if opponent.x != fighter.x:
			fighter.facing = int(signf(opponent.x - fighter.x))
	if fighter.state_ticks >= Ticks.from_seconds(config.spin_dodge_duration):
		finish_to_neutral(sim, fighter)


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
