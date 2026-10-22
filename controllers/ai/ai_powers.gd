class_name AiPowers
extends RefCounted

const NO_SLOT: int = -1
const FAR_GAP: float = 180.0
const DEFAULT_REACH: float = 420.0
const HEAL_BELOW: float = 0.6
const DRAIN_ABOVE: float = 30.0
const THREAT_MARGIN: float = 40.0
const THREAT_TICKS: int = 18
const DIRECTIONS: Array[int] = [0, 1, -1, 0]
const ZONE_KINDS: Array[PowerData.Kind] = [PowerData.Kind.FRACTURE, PowerData.Kind.STORM, PowerData.Kind.MASS_TELEKINESIS]
const RANGED_KINDS: Array[PowerData.Kind] = [PowerData.Kind.THROW, PowerData.Kind.FLOW_CLEAVE]
const CLOSE_KINDS: Array[PowerData.Kind] = [
	PowerData.Kind.LIGHTNING, PowerData.Kind.FREEZE, PowerData.Kind.CHOKE, PowerData.Kind.MIND_TWIST, PowerData.Kind.PULL,
]
const SELF_KINDS: Array[PowerData.Kind] = [
	PowerData.Kind.FOCUS, PowerData.Kind.WRATH, PowerData.Kind.SANCTUARY, PowerData.Kind.ARSENAL,
]
const GUARD_KINDS: Array[PowerData.Kind] = [PowerData.Kind.ABSORPTION, PowerData.Kind.BARRIER]


static func is_ready(sim: MatchSimulation, me: FighterState, slot: int) -> bool:
	var power: PowerData = me.powers[slot]
	if power == null or not sim.rules.powers:
		return false
	if me.power_cooldown > 0 or me.power_cooldowns[slot] > 0 or me.flow_level < power.min_level:
		return false
	return me.flow >= power.cost_for(me.flow_level)


static func direction_for(slot: int) -> int:
	return DIRECTIONS[slot]


static func hold_ticks(power: PowerData) -> int:
	return Ticks.from_seconds(power.max_channel) if power.is_channeled() else 0


static func offensive_slot(sim: MatchSimulation, me: FighterState, opponent: FighterState, gap: float) -> int:
	for slot in FighterState.POWER_SLOTS:
		if is_ready(sim, me, slot) and _wants(me, opponent, gap, me.powers[slot]):
			return slot
	return NO_SLOT


static func escape_slot(sim: MatchSimulation, me: FighterState) -> int:
	for slot in FighterState.POWER_SLOTS:
		var power: PowerData = me.powers[slot]
		if power != null and power.castable_when_hit and is_ready(sim, me, slot):
			return slot
	return NO_SLOT


static func guard_slot(sim: MatchSimulation, me: FighterState, incoming: PowerData) -> int:
	for slot in FighterState.POWER_SLOTS:
		var power: PowerData = me.powers[slot]
		if power == null or not GUARD_KINDS.has(power.kind) or not is_ready(sim, me, slot):
			continue
		if power.kind == PowerData.Kind.ABSORPTION and incoming.kind == PowerData.Kind.STORM:
			continue
		return slot
	return NO_SLOT


static func incoming_power(opponent: FighterState) -> PowerData:
	if opponent.state != FighterState.State.CASTING or opponent.power_phase != FighterState.Phase.STARTUP:
		return null
	return opponent.power


static func hazard_threat(sim: MatchSimulation, me: FighterState) -> Hazard:
	for hazard in sim.hazards:
		if not hazard.active or hazard.owner == me.index or hazard.delay_ticks > THREAT_TICKS:
			continue
		if absf(hazard.x - me.x) <= hazard.half_width + THREAT_MARGIN:
			return hazard
	return null


static func projectile_threat(sim: MatchSimulation, me: FighterState) -> Projectile:
	for projectile in sim.projectiles:
		if not projectile.active or projectile.owner == me.index:
			continue
		var closing: bool = signf(me.x - projectile.x) == signf(projectile.vx)
		if closing and absf(me.x - projectile.x) < absf(projectile.vx) * Ticks.to_seconds(THREAT_TICKS) + THREAT_MARGIN:
			return projectile
	return null


static func _wants(me: FighterState, opponent: FighterState, gap: float, power: PowerData) -> bool:
	var reach: float = power.reach if power.reach > 0.0 else DEFAULT_REACH
	if ZONE_KINDS.has(power.kind):
		return gap > FAR_GAP and not opponent.is_airborne()
	if RANGED_KINDS.has(power.kind):
		return gap > FAR_GAP
	if CLOSE_KINDS.has(power.kind):
		return gap <= reach and opponent.state != FighterState.State.HELD
	if SELF_KINDS.has(power.kind):
		if power.kind == PowerData.Kind.ARSENAL and me.arsenal_count > 0:
			return gap > FAR_GAP
		return gap > FAR_GAP and not _status_active(me, power.kind)
	match power.kind:
		PowerData.Kind.REPULSE:
			return gap <= reach * 0.6 and (opponent.is_attacking() or me.vigor_ratio() < 0.4)
		PowerData.Kind.SUPREME_PUSH:
			return gap <= reach * 0.5 and opponent.is_attacking()
		PowerData.Kind.HEAL:
			return gap > FAR_GAP and me.health_ratio() < HEAL_BELOW and me.heal_ticks == 0
		PowerData.Kind.DRAIN:
			return gap <= reach and opponent.flow > DRAIN_ABOVE
	return false


static func _status_active(me: FighterState, kind: PowerData.Kind) -> bool:
	match kind:
		PowerData.Kind.FOCUS:
			return me.focus_ticks > 0
		PowerData.Kind.WRATH:
			return me.wrath_ticks > 0
		PowerData.Kind.SANCTUARY:
			return me.sanctuary_ticks > 0
	return false
