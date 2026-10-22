class_name PowerStarter

const NEUTRAL_SLOT: int = 0
const FORWARD_SLOT: int = 1
const BACK_SLOT: int = 2
const ARSENAL_LAUNCH_COOLDOWN: float = 0.25


static func slot_for(fighter: FighterState, direction: int, fourth: bool) -> int:
	if fourth:
		return FighterState.FOURTH_SLOT
	var slot: int = NEUTRAL_SLOT
	if direction > 0:
		slot = FORWARD_SLOT
	elif direction < 0:
		slot = BACK_SLOT
	if fighter.powers[slot] == null:
		slot = NEUTRAL_SLOT
	return slot


static func try_cast(sim: MatchSimulation, fighter: FighterState, direction: int, fourth: bool) -> ActionStarter.Result:
	if not sim.rules.powers:
		return ActionStarter.Result.NOT_POSSIBLE
	var slot: int = slot_for(fighter, direction, fourth)
	var power: PowerData = fighter.powers[slot]
	if power == null:
		return ActionStarter.Result.NOT_POSSIBLE
	if power.kind == PowerData.Kind.ARSENAL and fighter.arsenal_count > 0:
		if fighter.power_cooldowns[slot] > 0:
			return ActionStarter.Result.NOT_POSSIBLE
		PowerEffects.launch_arsenal(sim, fighter, power)
		fighter.power_cooldowns[slot] = Ticks.from_seconds(ARSENAL_LAUNCH_COOLDOWN)
		return ActionStarter.Result.STARTED
	if fighter.rain_ticks > 0:
		return ActionStarter.Result.NOT_POSSIBLE
	var cost: float = power.cost_for(fighter.flow_level)
	var blocked: bool = fighter.power_cooldown > 0 or fighter.power_cooldowns[slot] > 0
	if blocked or fighter.flow_level < power.min_level or fighter.flow < cost:
		var rejected: CombatEvent = sim.emit(CombatEvent.Type.POWER_REJECTED, fighter.index, CombatEvent.NO_FIGHTER)
		rejected.power = power
		return ActionStarter.Result.REJECTED
	var escaping: bool = fighter.state == FighterState.State.HIT or fighter.state == FighterState.State.STAGGERED
	fighter.flow -= cost
	sim.change_state(fighter, FighterState.State.CASTING)
	fighter.power = power
	fighter.power_slot = slot
	fighter.power_phase = FighterState.Phase.STARTUP
	fighter.power_ticks = 0
	fighter.power_escape = escaping
	fighter.spawned = 0
	var event: CombatEvent = sim.emit(CombatEvent.Type.POWER_STARTED, fighter.index, sim.opponent_of(fighter).index)
	event.power = power
	event.amount = fighter.flow_tier
	if power.startup_ticks() == 0:
		PowerEffects.activate(sim, fighter)
	return ActionStarter.Result.STARTED


static func castable_while_hit(fighter: FighterState, direction: int) -> bool:
	var power: PowerData = fighter.powers[slot_for(fighter, direction, false)]
	return power != null and power.castable_when_hit
