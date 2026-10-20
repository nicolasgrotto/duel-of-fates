class_name HitResolver


static func resolve(sim: MatchSimulation) -> void:
	sim.hit_attackers.clear()
	sim.hit_moves.clear()
	for attacker in sim.fighters:
		if _connects(sim, attacker, sim.opponent_of(attacker)):
			sim.hit_attackers.append(attacker)
			sim.hit_moves.append(attacker.move)
	for i in sim.hit_attackers.size():
		_apply(sim, sim.hit_attackers[i], sim.opponent_of(sim.hit_attackers[i]), sim.hit_moves[i])


static func _connects(sim: MatchSimulation, attacker: FighterState, defender: FighterState) -> bool:
	if not attacker.is_active() or attacker.move_hit_done:
		return false
	if not defender.is_alive() or defender.is_invulnerable() or defender.state == FighterState.State.BLADE_LOCK:
		return false
	var config: CombatConfig = sim.config
	return CombatGeometry.overlaps(CombatGeometry.hitbox(config, attacker, attacker.move), CombatGeometry.hurtbox(config, defender))


static func _apply(sim: MatchSimulation, attacker: FighterState, defender: FighterState, move: MoveData) -> void:
	attacker.move_hit_done = true
	if defender.state == FighterState.State.DODGING and defender.evade_window_ticks > 0:
		_evade(sim, attacker, defender, move)
	elif move.kind == MoveData.Kind.SHOVE:
		_shove(sim, attacker, defender, move)
	elif defender.state == FighterState.State.BLOCKING and CombatGeometry.faces(defender, attacker):
		if defender.parry_ticks == FighterState.NO_PARRY:
			_block(sim, attacker, defender, move)
		elif defender.parry_ticks < defender.perfect_parry_ticks and move.is_heavy():
			_perfect_parry(sim, attacker, defender, move)
		else:
			_parry(sim, attacker, defender, move)
	else:
		_hit(sim, attacker, defender, move)


static func _contact_point(sim: MatchSimulation, attacker: FighterState, defender: FighterState, move: MoveData) -> Vector2:
	var height: float = attacker.y + (move.hitbox_bottom + move.hitbox_top) * 0.5
	var front: float = defender.x - attacker.facing * sim.config.body_width * 0.5
	return Vector2(front, clampf(height, defender.y, defender.y + sim.config.body_height))


static func _event(sim: MatchSimulation, type: CombatEvent.Type, attacker: FighterState, defender: FighterState, move: MoveData) -> CombatEvent:
	var event: CombatEvent = sim.emit(type, attacker.index, defender.index)
	event.move = move
	event.heavy = move.is_heavy()
	event.position = _contact_point(sim, attacker, defender, move)
	event.from_front = CombatGeometry.faces(defender, attacker)
	return event


static func _evade(sim: MatchSimulation, attacker: FighterState, defender: FighterState, move: MoveData) -> void:
	defender.evade_succeeded = true
	defender.evade_streak += 1
	var event: CombatEvent = _event(sim, CombatEvent.Type.EVADE_SUCCESS, attacker, defender, move)
	event.amount = defender.evade_streak
	event.frame_advantage = -attacker.ticks_left_in_move()
	sim.change_state(defender, FighterState.State.IDLE)


static func _shove(sim: MatchSimulation, attacker: FighterState, defender: FighterState, move: MoveData) -> void:
	var config: CombatConfig = sim.config
	attacker.move_connected = true
	var event: CombatEvent = _event(sim, CombatEvent.Type.SHOVE, attacker, defender, move)
	sim.drain_vigor(defender, config.shove_vigor_loss)
	_recoil(sim, defender, FighterState.State.STAGGERED, config.shove_stagger)
	defender.vx = CombatGeometry.away_from(attacker, defender) * config.slide_speed_for(move.knockback)
	event.frame_advantage = defender.stun_ticks - attacker.ticks_left_in_move()


static func _block(sim: MatchSimulation, attacker: FighterState, defender: FighterState, move: MoveData) -> void:
	var config: CombatConfig = sim.config
	var cost: float = sim.block_cost(defender, move)
	attacker.move_connected = true
	if defender.vigor < cost:
		sim.drain_vigor(defender, defender.vigor)
		var break_event: CombatEvent = _event(sim, CombatEvent.Type.GUARD_BREAK, attacker, defender, move)
		_recoil(sim, defender, FighterState.State.STUNNED, defender.character.guard_break_stun)
		break_event.hitstop_ticks = sim.freeze_pair(attacker, defender, config.hitstop_guard_break)
		break_event.frame_advantage = defender.stun_ticks - attacker.ticks_left_in_move()
		return
	sim.drain_vigor(defender, cost)
	var event: CombatEvent = _event(sim, CombatEvent.Type.BLOCK, attacker, defender, move)
	event.amount = cost
	defender.stun_ticks = Ticks.from_seconds(move.blockstun)
	var push: float = move.block_push / defender.defense_multiplier
	defender.vx = CombatGeometry.away_from(attacker, defender) * config.slide_speed_for(push)
	event.hitstop_ticks = sim.freeze_pair(attacker, defender, config.hitstop_block)
	event.frame_advantage = defender.stun_ticks - attacker.ticks_left_in_move()


static func _parry(sim: MatchSimulation, attacker: FighterState, defender: FighterState, move: MoveData) -> void:
	var config: CombatConfig = sim.config
	sim.drain_vigor(attacker, sim.block_cost(defender, move))
	var event: CombatEvent = _event(sim, CombatEvent.Type.PARRY, attacker, defender, move)
	attacker.move_connected = true
	attacker.move_phase = FighterState.Phase.RECOVERY
	attacker.phase_ticks = 0
	defender.parry_ticks = FighterState.NO_PARRY
	defender.stun_ticks = 0
	event.hitstop_ticks = sim.freeze_pair(attacker, defender, config.hitstop_parry)
	event.frame_advantage = -attacker.ticks_left_in_move()


static func _perfect_parry(sim: MatchSimulation, attacker: FighterState, defender: FighterState, move: MoveData) -> void:
	var config: CombatConfig = sim.config
	sim.drain_vigor(attacker, sim.block_cost(defender, move) * 2.0)
	sim.gain_vigor(defender, config.perfect_parry_vigor_gain)
	var event: CombatEvent = _event(sim, CombatEvent.Type.PERFECT_PARRY, attacker, defender, move)
	defender.parry_ticks = FighterState.NO_PARRY
	defender.stun_ticks = 0
	_recoil(sim, attacker, FighterState.State.STAGGERED, config.perfect_parry_stagger)
	attacker.stagger_counterable = true
	event.hitstop_ticks = sim.freeze_pair(attacker, defender, config.hitstop_perfect_parry)
	event.frame_advantage = attacker.stun_ticks


static func _hit(sim: MatchSimulation, attacker: FighterState, defender: FighterState, move: MoveData) -> void:
	var config: CombatConfig = sim.config
	var damage: float = move.damage * attacker.blade_multiplier
	if defender.exhausted and sim.rules.exhaustion and move.is_blade():
		damage *= config.consequences.exhausted_damage_multiplier
	var combo: int = defender.combo_taken + 1 if _is_recoiling(defender) else 1
	attacker.move_connected = true
	var event: CombatEvent = _event(sim, CombatEvent.Type.HIT, attacker, defender, move)
	var lethal: bool = sim.apply_damage(defender, damage)
	event.amount = damage
	if attacker.character.vigor_on_hit > 0.0:
		sim.gain_vigor(attacker, attacker.character.vigor_on_hit)
	_recoil(sim, defender, FighterState.State.HIT, move.hitstun)
	defender.combo_taken = combo
	event.combo = combo
	defender.vx = CombatGeometry.away_from(attacker, defender) * config.slide_speed_for(move.knockback)
	if not lethal:
		Consequences.try_wound(sim, attacker, defender, move)
	var hitstop: float = config.hitstop_heavy if move.is_heavy() else config.hitstop_light
	event.hitstop_ticks = sim.freeze_pair(attacker, defender, hitstop)
	event.frame_advantage = defender.stun_ticks - attacker.ticks_left_in_move()
	if lethal:
		sim.kill(defender, attacker, move)


static func _recoil(sim: MatchSimulation, fighter: FighterState, state: FighterState.State, seconds: float) -> void:
	sim.change_state(fighter, state)
	fighter.stun_ticks = maxi(Ticks.from_seconds(seconds), 1)


static func _is_recoiling(fighter: FighterState) -> bool:
	return fighter.state == FighterState.State.HIT or fighter.state == FighterState.State.STAGGERED or fighter.state == FighterState.State.STUNNED
