class_name PowerHit

enum Result { MISSED, RESISTED, ABSORBED, BLOCKED, HIT }

const ABSORB_FULL_BELOW: int = 2


static func resolve(sim: MatchSimulation, caster: FighterState, target: FighterState, power: PowerData, impact: PowerImpact) -> Result:
	if not target.is_alive() or target.state == FighterState.State.BLADE_LOCK:
		return Result.MISSED
	if impact.grounded_only and target.is_airborne():
		return Result.MISSED
	if not impact.ignore_invulnerability and (target.is_invulnerable() or target.evade_window_ticks > 0):
		return Result.MISSED
	if target.power_kind_active(PowerData.Kind.STORM):
		return Result.MISSED
	var table: InteractionTable = impact.table if impact.table != null else sim.basic_table
	var band: InteractionBand = table.band_for(impact.flow_level - target.flow_level)
	if band.resisted:
		var resisted: CombatEvent = _event(sim, CombatEvent.Type.POWER_RESISTED, caster, target, power, impact)
		resisted.amount = target.flow_tier
		return Result.RESISTED
	var scale: float = band.scale
	if not impact.ignore_absorption and target.power_kind_active(PowerData.Kind.ABSORPTION):
		var absorbed: CombatEvent = _event(sim, CombatEvent.Type.POWER_ABSORBED, caster, target, power, impact)
		sim.gain_flow(target, power.absorb_gain if power != null else 0.0)
		absorbed.amount = power.absorb_gain if power != null else 0.0
		if impact.flow_level - target.flow_level < ABSORB_FULL_BELOW:
			return Result.ABSORBED
		scale *= 0.5
	if not impact.ignore_barrier and target.power_kind_active(PowerData.Kind.BARRIER):
		_hold_with_barrier(sim, caster, target, power, impact)
		return Result.BLOCKED
	var direction: int = 1 if target.x >= impact.source_x else -1
	if _guards(target, impact, band):
		_guard(sim, caster, target, power, impact, band, scale, direction)
		return Result.BLOCKED
	_hit(sim, caster, target, power, impact, band, scale, direction)
	return Result.HIT


static func _guards(target: FighterState, impact: PowerImpact, band: InteractionBand) -> bool:
	if impact.ignore_guard or band.pierces_guard or target.state != FighterState.State.BLOCKING or target.is_airborne():
		return false
	var dx: float = impact.source_x - target.x
	return dx == 0.0 or signf(dx) == target.facing


static func _hold_with_barrier(sim: MatchSimulation, caster: FighterState, target: FighterState, power: PowerData, impact: PowerImpact) -> void:
	var drain: float = power.barrier_drain if power != null and power.barrier_drain > 0.0 else (power.cost * 0.5 if power != null else 10.0)
	target.flow = maxf(target.flow - drain, 0.0)
	var event: CombatEvent = _event(sim, CombatEvent.Type.POWER_BLOCKED, caster, target, power, impact)
	event.amount = drain
	if impact.push > 0.0:
		target.vx = signf(target.x - impact.source_x) * impact.push * 0.5
	if target.flow <= 0.0:
		PowerEffects.end_channel(sim, target)


static func _guard(sim: MatchSimulation, caster: FighterState, target: FighterState, power: PowerData, impact: PowerImpact, band: InteractionBand, scale: float, direction: int) -> void:
	var ratio: float = maxf(band.guard_damage_ratio, power.guard_damage_ratio if power != null else 0.0)
	var damage: float = impact.damage * scale * ratio * sim.wrath_scale(caster, target)
	var event: CombatEvent = _event(sim, CombatEvent.Type.POWER_BLOCKED, caster, target, power, impact)
	event.amount = damage
	if damage > 0.0 and sim.apply_damage(target, damage, true):
		sim.kill(target, caster, null, power if impact.allow_finisher else null)
		return
	sim.drain_vigor(target, impact.guard_vigor * band.guard_vigor_ratio)
	target.vx = direction * absf(impact.push) * band.guard_slide_ratio * signf(impact.push if impact.push != 0.0 else 1.0)
	sim.gain_flow(target, sim.config.flow.gain_on_block)


static func _hit(sim: MatchSimulation, caster: FighterState, target: FighterState, power: PowerData, impact: PowerImpact, band: InteractionBand, scale: float, direction: int) -> void:
	var flow: FlowConfig = sim.config.flow
	var airborne: bool = target.is_airborne()
	var damage: float = impact.damage * scale
	if not impact.periodic:
		damage *= sim.wrath_scale(caster, target)
	var stagger: float = impact.stagger * scale * (flow.air_stagger_multiplier if airborne else 1.0)
	var hold: float = impact.hold * (flow.air_hold_multiplier if airborne else 1.0)
	var push: float = impact.push * (flow.air_push_multiplier if airborne else 1.0) if band.moves_target else 0.0
	var event: CombatEvent = _event(sim, CombatEvent.Type.POWER_HIT, caster, target, power, impact)
	event.amount = damage
	event.heavy = stagger > 0.0
	var lethal: bool = damage > 0.0 and sim.apply_damage(target, damage, true)
	if damage > 0.0 and not impact.periodic and impact.grants_flow:
		sim.gain_flow(target, flow.gain_on_hurt)
		sim.gain_flow(caster, flow.gain_on_hit)
	if lethal or (impact.allow_finisher and _executes(sim, caster, target, power)):
		if not lethal:
			sim.apply_damage(target, target.health, true)
		sim.kill(target, caster, null, power if impact.allow_finisher else null)
		return
	if stagger > 0.0:
		_recoil(sim, target, FighterState.State.STAGGERED, stagger)
	elif hold > 0.0 and target.state != FighterState.State.HELD:
		_recoil(sim, target, FighterState.State.HIT, hold)
	if push != 0.0:
		target.vx = direction * push


static func _executes(sim: MatchSimulation, caster: FighterState, target: FighterState, power: PowerData) -> bool:
	if power == null or power.execute_below <= 0.0 or target.health > power.execute_below or (sim.rules.endless and not sim.rules.endless_finishers):
		return false
	return Consequences.finisher_for(sim, null, power, sim.is_deciding(caster)) != Finisher.Kind.NONE


static func _recoil(sim: MatchSimulation, fighter: FighterState, state: FighterState.State, seconds: float) -> void:
	sim.change_state(fighter, state)
	fighter.stun_ticks = maxi(Ticks.from_seconds(seconds), 1)


static func _event(sim: MatchSimulation, type: CombatEvent.Type, caster: FighterState, target: FighterState, power: PowerData, impact: PowerImpact) -> CombatEvent:
	var event: CombatEvent = sim.emit(type, caster.index, target.index)
	event.power = power
	event.position = Vector2(target.x, target.y + sim.config.body_height * 0.6)
	return event
