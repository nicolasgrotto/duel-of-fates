class_name AttackState
extends StateLogic


func step(sim: MatchSimulation, fighter: FighterState, intent: Intent) -> void:
	var move: MoveData = fighter.move
	if _try_burst_cancel(sim, fighter, intent):
		return
	match fighter.move_phase:
		FighterState.Phase.STARTUP:
			if move.dash_in_startup and fighter.on_ground:
				var startup: float = Ticks.to_seconds(fighter.move_startup_ticks()) if fighter.draws_sidearm() else move.startup
				fighter.vx = fighter.facing * move.lunge * fighter.agility_multiplier / maxf(startup, Ticks.DELTA)
			else:
				decelerate(sim, fighter)
			if _try_feint(sim, fighter, move):
				return
			if fighter.phase_ticks + 1 >= fighter.move_startup_ticks() and _holds_charge(fighter, move, intent):
				return
			fighter.phase_ticks += 1
			if fighter.draws_sidearm():
				fighter.sidearm_out = fighter.phase_ticks >= fighter.carried_blaster().draw_ticks()
			if fighter.phase_ticks >= fighter.move_startup_ticks():
				_enter_active(sim, fighter, move)
			return
	fighter.phase_ticks += 1
	match fighter.move_phase:
		FighterState.Phase.ACTIVE:
			_continue_burst(sim, fighter, move)
			_rearm_multi_hit(fighter, move)
			if fighter.phase_ticks >= move.active_ticks():
				fighter.move_phase = FighterState.Phase.RECOVERY
				fighter.phase_ticks = 0
		FighterState.Phase.RECOVERY:
			decelerate(sim, fighter)
			_continue_burst(sim, fighter, move)
			if fighter.draws_sidearm() and fighter.phase_ticks >= move.recovery_ticks():
				fighter.sidearm_out = false
			if _try_chain(sim, fighter):
				return
			var recovery: int = fighter.recovery_cut if fighter.recovery_cut >= 0 else fighter.move_recovery_ticks()
			if fighter.phase_ticks >= recovery:
				finish_to_neutral(sim, fighter)


func exit(_sim: MatchSimulation, fighter: FighterState) -> void:
	fighter.clear_move()


func _rearm_multi_hit(fighter: FighterState, move: MoveData) -> void:
	if move.multi_hits <= 1:
		return
	var interval: int = maxi(Ticks.from_seconds(move.multi_interval), 1)
	if fighter.phase_ticks % interval == 0 and int(fighter.phase_ticks / float(interval)) < move.multi_hits:
		fighter.move_hit_done = false


func _throw_blade(sim: MatchSimulation, fighter: FighterState, move: MoveData) -> void:
	var flow: FlowConfig = sim.config.flow
	var projectile: Projectile = sim.spawn_projectile(Projectile.Kind.BLADE, fighter, null)
	fighter.move_hit_done = true
	if projectile == null:
		return
	var reach: float = flow.blade_throw_base + (fighter.character.blade - sim.config.attribute_neutral) * flow.blade_throw_per_point
	projectile.max_distance = clampf(reach, flow.blade_throw_min, flow.blade_throw_max)
	projectile.vx = fighter.facing * flow.blade_throw_speed
	projectile.damage = move.damage * fighter.blade_multiplier
	projectile.move = move
	projectile.size = 22.0
	fighter.blade_out = true


func _enter_active(sim: MatchSimulation, fighter: FighterState, move: MoveData) -> void:
	fighter.move_phase = FighterState.Phase.ACTIVE
	fighter.phase_ticks = 0
	if move.throws_blade:
		_throw_blade(sim, fighter, move)
	elif move.technique_style == MoveData.TechniqueStyle.WAVE:
		_project_wave(sim, fighter, move)
	if fighter.move_bolt() != null:
		_start_burst(sim, fighter, move)
	if move.dash_in_startup:
		fighter.vx = 0.0
	elif fighter.on_ground and move.lunge != 0.0 and move.active > 0.0:
		fighter.vx = fighter.facing * move.lunge * fighter.agility_multiplier / move.active
	if move.dive_speed > 0.0 and fighter.is_airborne():
		fighter.vy = -move.dive_speed


func _start_burst(sim: MatchSimulation, fighter: FighterState, move: MoveData) -> void:
	if move.reach <= 0.0:
		fighter.move_hit_done = true
	var bolt: BoltData = fighter.move_bolt()
	BoltResolver.fire(sim, fighter, bolt)
	fighter.bolts_left = (move.shot_count if fighter.draws_sidearm() else bolt.count) - 1
	fighter.bolt_ticks = _bolt_interval(fighter, move)


func _continue_burst(sim: MatchSimulation, fighter: FighterState, move: MoveData) -> void:
	if fighter.bolts_left <= 0:
		return
	fighter.bolt_ticks -= 1
	if fighter.bolt_ticks > 0:
		return
	BoltResolver.fire(sim, fighter, fighter.move_bolt())
	fighter.bolts_left -= 1
	fighter.bolt_ticks = _bolt_interval(fighter, move)


func _bolt_interval(fighter: FighterState, move: MoveData) -> int:
	return maxi(Ticks.from_seconds(move.shot_interval), 1) if fighter.draws_sidearm() else move.bolt.interval_ticks()


func _try_burst_cancel(sim: MatchSimulation, fighter: FighterState, intent: Intent) -> bool:
	if not fighter.draws_sidearm() or not fighter.move.burst_cancellable or fighter.move_phase == FighterState.Phase.STARTUP:
		return false
	var guard_ticks: int = fighter.carried_blaster().holster_ticks()
	var allowed: int = (1 << FighterState.Action.BLOCK) | (1 << FighterState.Action.EVADE)
	if not ActionStarter.try_buffered(sim, fighter, intent, allowed):
		return false
	if fighter.state == FighterState.State.BLOCKING:
		fighter.sidearm_guard_ticks = guard_ticks
	return true


func _holds_charge(fighter: FighterState, move: MoveData, intent: Intent) -> bool:
	var ability: AbilityData = fighter.character.ability
	if ability == null or ability.kind != AbilityData.Kind.CHARGE or move != ability.move:
		return false
	var full: int = ability.charge_level_ticks() * (ability.charge_levels - 1)
	if not intent.is_held(Intent.Command.SPECIAL) or fighter.charge_ticks >= full:
		return false
	fighter.charge_ticks += 1
	fighter.charge_level = mini(1 + floori(float(fighter.charge_ticks) / ability.charge_level_ticks()), ability.charge_levels)
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
	if _try_follow_up(sim, fighter, move):
		return true
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


func _try_follow_up(sim: MatchSimulation, fighter: FighterState, move: MoveData) -> bool:
	if move.follow_up == null:
		return false
	if not move.follow_up_auto:
		if fighter.buffered_action != FighterState.Action.SPECIAL:
			return false
		ActionStarter.consume(fighter)
	return ActionStarter.start_attack(sim, fighter, move.follow_up, fighter.chain_index + 1) == ActionStarter.Result.STARTED


func debug_lines(_sim: MatchSimulation, fighter: FighterState) -> PackedStringArray:
	if fighter.move == null:
		return PackedStringArray()
	var phase_name: String = FighterState.Phase.keys()[fighter.move_phase]
	return PackedStringArray([
		"%s  %s %d" % [fighter.move.id, phase_name.to_lower(), fighter.phase_ticks],
		"chain %d  connected %s  hit %s" % [fighter.chain_index, fighter.move_connected, fighter.move_hit_done],
	])


func _project_wave(sim: MatchSimulation, fighter: FighterState, move: MoveData) -> void:
	fighter.move_hit_done = true
	var projectile: Projectile = sim.spawn_projectile(Projectile.Kind.CLEAVE, fighter, null)
	if projectile == null:
		return
	projectile.move = move
	projectile.damage = move.damage * fighter.blade_multiplier
	projectile.vx = fighter.facing * move.projectile_speed
	projectile.max_distance = move.projectile_range
	projectile.tier = fighter.flow_tier
	projectile.size = move.projectile_size * move.projectile_scale(fighter.flow_tier)
