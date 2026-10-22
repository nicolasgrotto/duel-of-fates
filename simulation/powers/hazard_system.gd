class_name HazardSystem

const APEX_TIER: int = 3
const ROCK_STAGGER: float = 0.3
const FRACTURE_STAGGER: float = 0.45
const BOLT_HOLD: float = 0.25


static func step(sim: MatchSimulation) -> void:
	for hazard in sim.hazards:
		if not hazard.active:
			continue
		hazard.delay_ticks -= 1
		if hazard.delay_ticks > 0:
			continue
		hazard.active = false
		_trigger(sim, hazard)


static func _trigger(sim: MatchSimulation, hazard: Hazard) -> void:
	var owner: FighterState = sim.fighters[hazard.owner]
	var target: FighterState = sim.opponent_of(owner)
	var event: CombatEvent = sim.emit(CombatEvent.Type.HAZARD_TRIGGERED, hazard.owner, CombatEvent.NO_FIGHTER)
	event.power = hazard.power
	event.position = Vector2(hazard.x, 0.0)
	event.amount = hazard.kind
	if hazard.kind == Hazard.Kind.BOLT and owner.flow_tier >= APEX_TIER:
		PowerEffects.apex_fissures(sim, owner, hazard.x, hazard.power)
	if absf(target.x - hazard.x) > hazard.half_width + sim.config.body_width * 0.5:
		return
	if sim.hazard_group_hit(hazard.group, target.index):
		return
	var impact: PowerImpact = sim.impact
	impact.reset(hazard.power, owner)
	impact.source_x = hazard.x
	impact.flow_level = hazard.flow_level
	impact.damage = hazard.damage
	match hazard.kind:
		Hazard.Kind.FRACTURE:
			impact.grounded_only = true
			impact.ignore_guard = true
			impact.ignore_absorption = true
			impact.ignore_barrier = true
			impact.ignore_invulnerability = true
			impact.stagger = FRACTURE_STAGGER
		Hazard.Kind.BOLT:
			impact.ignore_guard = true
			impact.ignore_absorption = true
			impact.hold = BOLT_HOLD
		Hazard.Kind.ROCK_DROP:
			impact.push = hazard.power.strength
			impact.stagger = ROCK_STAGGER
	if PowerHit.resolve(sim, owner, target, hazard.power, impact) != PowerHit.Result.MISSED:
		sim.mark_hazard_group(hazard.group, target.index)
