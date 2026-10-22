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
	if not attacker.is_active() or attacker.move_hit_done or attacker.move.kind == MoveData.Kind.STANCE:
		return false
	if not defender.is_alive() or defender.is_invulnerable() or defender.state == FighterState.State.BLADE_LOCK:
		return false
	if defender.power_kind_active(PowerData.Kind.STORM):
		return false
	var config: CombatConfig = sim.config
	var hurtbox: Rect2 = CombatGeometry.hurtbox(config, defender)
	if CombatGeometry.overlaps(CombatGeometry.hitbox(config, attacker, attacker.move), hurtbox):
		return true
	return attacker.move.hits_behind and CombatGeometry.overlaps(CombatGeometry.hitbox_behind(config, attacker, attacker.move), hurtbox)


static func _apply(sim: MatchSimulation, attacker: FighterState, defender: FighterState, move: MoveData) -> void:
	attacker.move_hit_done = true
	if defender.state == FighterState.State.DODGING and defender.evade_window_ticks > 0:
		_evade(sim, attacker, defender, move)
	elif _focus_evades(sim, defender, move):
		defender.flow -= sim.config.flow.focus_evade_cost
		_evade(sim, attacker, defender, move)
	elif defender.power_kind_active(PowerData.Kind.BARRIER) and move.is_blade():
		_barrier(sim, attacker, defender, move)
	elif move.kind == MoveData.Kind.SHOVE:
		_shove(sim, attacker, defender, move)
	elif _in_stance(defender) and CombatGeometry.faces(defender, attacker):
		_respond(sim, attacker, defender, move)
	elif defender.state == FighterState.State.BLOCKING and CombatGeometry.faces(defender, attacker):
		if defender.parry_ticks == FighterState.NO_PARRY:
			_block(sim, attacker, defender, move)
		elif defender.parry_ticks < defender.perfect_parry_ticks and move.is_heavy():
			_perfect_parry(sim, attacker, defender, move)
		else:
			_parry(sim, attacker, defender, move)
	else:
		_hit(sim, attacker, defender, move)


static func _focus_evades(sim: MatchSimulation, defender: FighterState, move: MoveData) -> bool:
	if not sim.rules.focus_evade or defender.focus_ticks <= 0 or not move.is_blade():
		return false
	return defender.state == FighterState.State.IDLE and defender.input_idle and defender.flow >= sim.config.flow.focus_evade_cost


static func _barrier(sim: MatchSimulation, attacker: FighterState, defender: FighterState, move: MoveData) -> void:
	var event: CombatEvent = _event(sim, CombatEvent.Type.POWER_BLOCKED, attacker, defender, move)
	event.power = defender.power
	attacker.move_connected = true
	if attacker.is_attacking() and attacker.move == move:
		attacker.move_phase = FighterState.Phase.RECOVERY
		attacker.phase_ticks = 0
	event.hitstop_ticks = sim.freeze_pair(attacker, defender, sim.config.hitstop_block)


static func _guard_stagger(sim: MatchSimulation, defender: FighterState, move: MoveData) -> void:
	if move.stagger_on_guard <= 0.0 or not defender.is_alive():
		return
	_recoil(sim, defender, FighterState.State.STAGGERED, move.stagger_on_guard)


static func _in_stance(fighter: FighterState) -> bool:
	return fighter.is_active() and fighter.move.kind == MoveData.Kind.STANCE


static func _respond(sim: MatchSimulation, attacker: FighterState, defender: FighterState, move: MoveData) -> void:
	var config: CombatConfig = sim.config
	var ability: AbilityData = defender.character.ability
	var type: CombatEvent.Type = CombatEvent.Type.PERFECT_PARRY if ability.perfect_response else CombatEvent.Type.RESPONSE
	var event: CombatEvent = _event(sim, type, attacker, defender, move)
	if ability.perfect_response:
		sim.drain_vigor(attacker, sim.block_cost(defender, move) * 2.0)
		sim.gain_vigor(defender, config.perfect_parry_vigor_gain)
	_recoil(sim, attacker, FighterState.State.STAGGERED, ability.stance_stagger)
	attacker.stagger_counterable = ability.perfect_response
	ActionStarter.start_attack(sim, defender, ability.move)
	event.hitstop_ticks = sim.freeze_pair(attacker, defender, config.hitstop_perfect_parry if ability.perfect_response else config.hitstop_parry)
	event.frame_advantage = attacker.stun_ticks


static func _knockback(sim: MatchSimulation, attacker: FighterState, distance: float) -> float:
	return sim.config.slide_speed_for(distance * attacker.character.knockback_multiplier)


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
	defender.vx = CombatGeometry.away_from(attacker, defender) * _knockback(sim, attacker, move.knockback)
	event.frame_advantage = defender.stun_ticks - attacker.ticks_left_in_move()


static func _block(sim: MatchSimulation, attacker: FighterState, defender: FighterState, move: MoveData) -> void:
	var config: CombatConfig = sim.config
	var cost: float = sim.block_cost(defender, move)
	if move.kind == MoveData.Kind.LIGHT:
		cost += attacker.character.light_block_drain
	attacker.move_connected = true
	if defender.vigor < cost or _breaks_guard(attacker, move):
		sim.drain_vigor(defender, defender.vigor)
		var break_event: CombatEvent = _event(sim, CombatEvent.Type.GUARD_BREAK, attacker, defender, move)
		_recoil(sim, defender, FighterState.State.STUNNED, defender.character.guard_break_stun)
		break_event.hitstop_ticks = sim.freeze_pair(attacker, defender, config.hitstop_guard_break)
		break_event.frame_advantage = defender.stun_ticks - attacker.ticks_left_in_move()
		return
	sim.drain_vigor(defender, cost)
	sim.gain_flow(defender, config.flow.gain_on_block)
	var event: CombatEvent = _event(sim, CombatEvent.Type.BLOCK, attacker, defender, move)
	event.amount = cost
	defender.stun_ticks = Ticks.from_seconds(move.blockstun)
	if not defender.character.block_push_immune:
		var push: float = move.block_push / defender.defense_multiplier
		defender.vx = CombatGeometry.away_from(attacker, defender) * _knockback(sim, attacker, push)
	event.hitstop_ticks = sim.freeze_pair(attacker, defender, config.hitstop_block)
	event.frame_advantage = defender.stun_ticks - attacker.ticks_left_in_move()
	_guard_stagger(sim, defender, move)


static func _breaks_guard(attacker: FighterState, move: MoveData) -> bool:
	var ability: AbilityData = attacker.character.ability
	if ability == null or ability.kind != AbilityData.Kind.CHARGE or move != ability.move or attacker.move != move:
		return false
	return attacker.charge_level >= ability.guard_break_level


static func _damage(sim: MatchSimulation, attacker: FighterState, defender: FighterState, move: MoveData) -> float:
	var config: CombatConfig = sim.config
	var damage: float = move.damage * attacker.blade_multiplier
	var character: CharacterData = attacker.character
	if character.sweet_spot and move.reach > 0.0:
		var ratio: float = CombatGeometry.gap(config, attacker, defender) / move.reach
		if ratio >= config.sweet_spot_tip_ratio:
			damage *= config.sweet_spot_tip_multiplier
		elif ratio <= config.sweet_spot_close_ratio:
			damage *= config.sweet_spot_close_multiplier
	if character.punish_bonus > 0.0 and _is_open(defender):
		damage *= 1.0 + character.punish_bonus
	var ability: AbilityData = character.ability
	if ability != null and ability.kind == AbilityData.Kind.CHARGE and move == ability.move and attacker.move == move:
		damage *= 1.0 + ability.charge_bonus_per_level * (maxi(attacker.charge_level, 1) - 1)
	if defender.exhausted and sim.rules.exhaustion and move.is_blade():
		damage *= config.consequences.exhausted_damage_multiplier
	if move.airborne_bonus > 0.0 and defender.is_airborne():
		damage *= 1.0 + move.airborne_bonus
	return damage * sim.wrath_scale(attacker, defender)


static func _is_open(fighter: FighterState) -> bool:
	if fighter.state == FighterState.State.STAGGERED or fighter.state == FighterState.State.STUNNED:
		return true
	return fighter.is_attacking() and fighter.move_phase == FighterState.Phase.RECOVERY


static func _armor_absorbs(defender: FighterState) -> bool:
	if defender.wrath_ticks > 0 and defender.wrath_armor > 0:
		return true
	if not defender.is_attacking() or defender.move == null:
		return false
	var move: MoveData = defender.move
	if defender.armor_used >= move.armor_hits:
		return false
	return defender.move_phase == FighterState.Phase.STARTUP or (defender.move_phase == FighterState.Phase.ACTIVE and move.armor_in_active)


static func _absorb(sim: MatchSimulation, attacker: FighterState, defender: FighterState, move: MoveData, damage: float) -> void:
	var ratio: float = 1.0
	if defender.wrath_ticks > 0 and defender.wrath_armor > 0:
		defender.wrath_armor -= 1
	else:
		defender.armor_used += 1
		ratio = defender.move.armor_damage_ratio
	var absorbed: float = damage * ratio
	var event: CombatEvent = _event(sim, CombatEvent.Type.ARMOR_ABSORBED, attacker, defender, move)
	event.amount = absorbed
	attacker.move_connected = true
	var lethal: bool = sim.apply_damage(defender, absorbed)
	event.hitstop_ticks = sim.freeze_pair(attacker, defender, sim.config.hitstop_light)
	if lethal:
		sim.kill(defender, attacker, move)


static func _parry(sim: MatchSimulation, attacker: FighterState, defender: FighterState, move: MoveData) -> void:
	var config: CombatConfig = sim.config
	sim.drain_vigor(attacker, sim.block_cost(defender, move))
	var event: CombatEvent = _event(sim, CombatEvent.Type.PARRY, attacker, defender, move)
	attacker.move_connected = true
	attacker.move_phase = FighterState.Phase.RECOVERY
	attacker.phase_ticks = 0
	defender.parry_ticks = FighterState.NO_PARRY
	defender.stun_ticks = 0
	sim.gain_flow(defender, config.flow.gain_on_parry)
	event.hitstop_ticks = sim.freeze_pair(attacker, defender, config.hitstop_parry)
	event.frame_advantage = -attacker.ticks_left_in_move()
	_guard_stagger(sim, defender, move)


static func _perfect_parry(sim: MatchSimulation, attacker: FighterState, defender: FighterState, move: MoveData) -> void:
	var config: CombatConfig = sim.config
	sim.drain_vigor(attacker, sim.block_cost(defender, move) * 2.0)
	sim.gain_vigor(defender, config.perfect_parry_vigor_gain)
	var event: CombatEvent = _event(sim, CombatEvent.Type.PERFECT_PARRY, attacker, defender, move)
	defender.parry_ticks = FighterState.NO_PARRY
	defender.stun_ticks = 0
	_recoil(sim, attacker, FighterState.State.STAGGERED, config.perfect_parry_stagger)
	attacker.stagger_counterable = true
	sim.gain_flow(defender, config.flow.gain_on_parry)
	event.hitstop_ticks = sim.freeze_pair(attacker, defender, config.hitstop_perfect_parry)
	event.frame_advantage = attacker.stun_ticks


static func _hit(sim: MatchSimulation, attacker: FighterState, defender: FighterState, move: MoveData) -> void:
	var config: CombatConfig = sim.config
	var damage: float = _damage(sim, attacker, defender, move)
	if _armor_absorbs(defender):
		_absorb(sim, attacker, defender, move, damage)
		return
	if defender.sanctuary_hp >= damage:
		var shielded: CombatEvent = _event(sim, CombatEvent.Type.POWER_ABSORBED, attacker, defender, move)
		shielded.amount = damage
		attacker.move_connected = true
		sim.apply_damage(defender, damage)
		shielded.hitstop_ticks = sim.freeze_pair(attacker, defender, config.hitstop_block)
		return
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
	defender.vx = CombatGeometry.away_from(attacker, defender) * _knockback(sim, attacker, move.knockback)
	if move.launch_speed > 0.0 and defender.is_airborne():
		defender.vy = move.launch_speed
	if move.recovery_on_hit >= 0.0 and attacker.move == move:
		attacker.recovery_cut = Ticks.from_seconds(move.recovery_on_hit)
	sim.gain_flow(attacker, config.flow.gain_on_hit)
	sim.gain_flow(defender, config.flow.gain_on_hurt)
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
