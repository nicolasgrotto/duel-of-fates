class_name ActionStarter

enum Result { NOT_POSSIBLE, STARTED, REJECTED }

const GROUND_ACTIONS: int = (
	(1 << FighterState.Action.JUMP)
	| (1 << FighterState.Action.BLOCK)
	| (1 << FighterState.Action.LIGHT)
	| (1 << FighterState.Action.HEAVY)
	| (1 << FighterState.Action.SHOVE)
	| (1 << FighterState.Action.EVADE)
	| (1 << FighterState.Action.DODGE)
)
const AIR_ACTIONS: int = (
	(1 << FighterState.Action.JUMP)
	| (1 << FighterState.Action.LIGHT)
	| (1 << FighterState.Action.HEAVY)
	| (1 << FighterState.Action.DODGE)
)
const GUARD_ACTIONS: int = 1 << FighterState.Action.SHOVE
const MAX_JUMPS: int = 2


static func update_buffer(sim: MatchSimulation, fighter: FighterState, intent: Intent) -> void:
	if fighter.freeze_ticks == 0 and fighter.buffer_ticks > 0:
		fighter.buffer_ticks -= 1
		if fighter.buffer_ticks == 0:
			fighter.buffered_action = FighterState.Action.NONE
	var action: FighterState.Action = pressed_action(intent)
	if action != FighterState.Action.NONE:
		fighter.buffered_action = action
		fighter.buffer_ticks = Ticks.from_seconds(sim.config.input_buffer)


static func pressed_action(intent: Intent) -> FighterState.Action:
	if intent.pressed == 0:
		return FighterState.Action.NONE
	if intent.was_pressed(Intent.Command.DODGE):
		return FighterState.Action.DODGE
	if intent.was_pressed(Intent.Command.EVADE):
		return FighterState.Action.EVADE
	if intent.was_pressed(Intent.Command.LIGHT) and intent.is_held(Intent.Command.BLOCK):
		return FighterState.Action.SHOVE
	if intent.was_pressed(Intent.Command.HEAVY):
		return FighterState.Action.HEAVY
	if intent.was_pressed(Intent.Command.LIGHT):
		return FighterState.Action.LIGHT
	if intent.was_pressed(Intent.Command.BLOCK):
		return FighterState.Action.BLOCK
	if intent.was_pressed(Intent.Command.JUMP):
		return FighterState.Action.JUMP
	return FighterState.Action.NONE


static func consume(fighter: FighterState) -> void:
	fighter.buffered_action = FighterState.Action.NONE
	fighter.buffer_ticks = 0


static func try_buffered(sim: MatchSimulation, fighter: FighterState, intent: Intent, allowed: int) -> bool:
	var action: FighterState.Action = fighter.buffered_action
	if action == FighterState.Action.NONE or (allowed & (1 << action)) == 0:
		return false
	var result: Result = _start(sim, fighter, intent, action)
	if result == Result.NOT_POSSIBLE:
		return false
	consume(fighter)
	return result == Result.STARTED


static func _start(sim: MatchSimulation, fighter: FighterState, intent: Intent, action: FighterState.Action) -> Result:
	match action:
		FighterState.Action.JUMP:
			return _start_jump(sim, fighter)
		FighterState.Action.BLOCK:
			return _start_guard(sim, fighter)
		FighterState.Action.LIGHT:
			return _start_light(sim, fighter)
		FighterState.Action.HEAVY:
			return _start_heavy(sim, fighter, intent)
		FighterState.Action.SHOVE:
			return start_attack(sim, fighter, fighter.character.shove) if fighter.on_ground else Result.NOT_POSSIBLE
		FighterState.Action.EVADE:
			return _start_evade(sim, fighter)
		FighterState.Action.DODGE:
			return _start_dodge(sim, fighter, intent)
	return Result.NOT_POSSIBLE


static func start_attack(sim: MatchSimulation, fighter: FighterState, move: MoveData, chain_index: int = 0) -> Result:
	if move == null:
		return Result.NOT_POSSIBLE
	if not sim.spend_vigor(fighter, move.vigor_cost):
		return Result.REJECTED
	var state: FighterState.State = FighterState.State.HEAVY_ATTACK if move.is_heavy() else FighterState.State.ATTACKING
	sim.change_state(fighter, state)
	fighter.move = move
	fighter.chain_index = chain_index
	fighter.move_hit_done = false
	fighter.move_connected = false
	fighter.phase_ticks = 0
	fighter.move_phase = FighterState.Phase.STARTUP
	if move.startup_ticks() == 0:
		fighter.move_phase = FighterState.Phase.ACTIVE if move.active_ticks() > 0 else FighterState.Phase.RECOVERY
	if move.is_aerial():
		fighter.air_attack_used = true
	var event: CombatEvent = sim.emit(CombatEvent.Type.ATTACK_STARTED, fighter.index, sim.opponent_of(fighter).index)
	event.move = move
	event.heavy = move.is_heavy()
	return Result.STARTED


static func _start_light(sim: MatchSimulation, fighter: FighterState) -> Result:
	if fighter.is_airborne():
		return Result.NOT_POSSIBLE if fighter.air_attack_used else start_attack(sim, fighter, fighter.character.aerial_light)
	var opponent: FighterState = sim.opponent_of(fighter)
	if opponent.state == FighterState.State.STAGGERED and opponent.stagger_counterable:
		return start_attack(sim, fighter, fighter.character.counter)
	if fighter.character.light_chain.is_empty():
		return Result.NOT_POSSIBLE
	return start_attack(sim, fighter, fighter.character.light_chain[0], 0)


static func _start_heavy(sim: MatchSimulation, fighter: FighterState, intent: Intent) -> Result:
	if fighter.is_airborne():
		return Result.NOT_POSSIBLE if fighter.air_attack_used else start_attack(sim, fighter, fighter.character.aerial_heavy)
	var forward: bool = intent.move_x != 0 and intent.move_x == fighter.facing
	if forward and fighter.character.forward_heavy != null:
		return start_attack(sim, fighter, fighter.character.forward_heavy)
	return start_attack(sim, fighter, fighter.character.heavy)


static func _start_jump(sim: MatchSimulation, fighter: FighterState) -> Result:
	if fighter.on_ground:
		fighter.vy = fighter.jump_velocity
		fighter.on_ground = false
		fighter.jumps_used = 1
	else:
		var max_jumps: int = 1 if fighter.wound == FighterState.Wound.LEG else MAX_JUMPS
		if fighter.jumps_used >= max_jumps:
			return Result.NOT_POSSIBLE
		fighter.jumps_used += 1
		fighter.vy = fighter.jump_velocity * fighter.character.double_jump_ratio
	if fighter.state != FighterState.State.JUMPING:
		sim.change_state(fighter, FighterState.State.JUMPING)
	sim.emit(CombatEvent.Type.JUMP, fighter.index, CombatEvent.NO_FIGHTER).amount = fighter.jumps_used
	return Result.STARTED


static func _start_guard(sim: MatchSimulation, fighter: FighterState) -> Result:
	if not fighter.on_ground:
		return Result.NOT_POSSIBLE
	sim.change_state(fighter, FighterState.State.BLOCKING)
	open_parry_window(fighter)
	return Result.STARTED


static func open_parry_window(fighter: FighterState) -> void:
	if fighter.parry_lockout_ticks == 0 and fighter.parry_ticks == FighterState.NO_PARRY:
		fighter.parry_ticks = 0


static func _start_dodge(sim: MatchSimulation, fighter: FighterState, intent: Intent) -> Result:
	var config: CombatConfig = sim.config
	var leg_multiplier: float = config.consequences.wounded_leg_dodge_multiplier if fighter.wound == FighterState.Wound.LEG else 1.0
	if fighter.is_airborne():
		if fighter.air_dash_used:
			return Result.NOT_POSSIBLE
		if not sim.spend_vigor(fighter, fighter.character.air_dash_vigor * leg_multiplier):
			return Result.REJECTED
		fighter.air_dash_used = true
		fighter.dodge_kind = FighterState.DodgeKind.AIR
		fighter.dodge_direction = intent.move_x if intent.move_x != 0 else fighter.facing
		fighter.vy = maxf(fighter.vy, config.air_dash_lift)
	else:
		if not sim.spend_vigor(fighter, config.dodge_vigor * leg_multiplier):
			return Result.REJECTED
		fighter.dodge_kind = FighterState.DodgeKind.GROUND
		fighter.dodge_direction = intent.move_x if intent.move_x != 0 else -fighter.facing
		fighter.invulnerable_ticks = Ticks.from_seconds(config.dodge_invulnerable)
	sim.change_state(fighter, FighterState.State.DODGING)
	sim.emit(CombatEvent.Type.DODGE, fighter.index, CombatEvent.NO_FIGHTER).heavy = fighter.is_airborne()
	return Result.STARTED


static func _start_evade(sim: MatchSimulation, fighter: FighterState) -> Result:
	if fighter.is_airborne():
		return Result.NOT_POSSIBLE
	fighter.dodge_kind = FighterState.DodgeKind.EVADE
	fighter.dodge_direction = -fighter.facing
	fighter.evade_succeeded = false
	fighter.evade_window_ticks = maxi(Ticks.from_seconds(sim.config.evade_invulnerable * fighter.agility_multiplier), 1)
	sim.change_state(fighter, FighterState.State.DODGING)
	return Result.STARTED
