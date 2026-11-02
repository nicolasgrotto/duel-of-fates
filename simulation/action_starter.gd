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
	| (1 << FighterState.Action.SPECIAL)
	| (1 << FighterState.Action.POWER)
	| (1 << FighterState.Action.FOURTH)
)
const AIR_ACTIONS: int = (
	(1 << FighterState.Action.JUMP)
	| (1 << FighterState.Action.LIGHT)
	| (1 << FighterState.Action.HEAVY)
	| (1 << FighterState.Action.DODGE)
	| (1 << FighterState.Action.SPECIAL)
)
const BLADE_ACTIONS: int = (
	(1 << FighterState.Action.LIGHT)
	| (1 << FighterState.Action.HEAVY)
	| (1 << FighterState.Action.SHOVE)
	| (1 << FighterState.Action.BLOCK)
	| (1 << FighterState.Action.SPECIAL)
)
const RAIN_BLOCKED_ACTIONS: int = (
	(1 << FighterState.Action.LIGHT)
	| (1 << FighterState.Action.HEAVY)
	| (1 << FighterState.Action.SHOVE)
	| (1 << FighterState.Action.SPECIAL)
	| (1 << FighterState.Action.POWER)
	| (1 << FighterState.Action.FOURTH)
)
const GUARD_ACTIONS: int = 1 << FighterState.Action.SHOVE
const MAX_JUMPS: int = 2


static func update_buffer(sim: MatchSimulation, fighter: FighterState, intent: Intent) -> void:
	if fighter.freeze_ticks == 0 and fighter.buffer_ticks > 0:
		fighter.buffer_ticks -= 1
		if fighter.buffer_ticks == 0:
			fighter.buffered_action = FighterState.Action.NONE
	var direction: int = relative_direction(fighter, intent)
	if _uses_chord(sim, fighter) and _resolve_chord(sim, fighter, intent, direction):
		return
	var action: FighterState.Action = pressed_action(intent)
	if action != FighterState.Action.NONE:
		_buffer(sim, fighter, action, direction)


static func relative_direction(fighter: FighterState, intent: Intent) -> int:
	return intent.move_x * fighter.facing


static func _buffer(sim: MatchSimulation, fighter: FighterState, action: FighterState.Action, direction: int) -> void:
	fighter.buffered_action = action
	fighter.buffered_direction = direction
	fighter.buffer_ticks = Ticks.from_seconds(sim.config.input_buffer)


static func _uses_chord(sim: MatchSimulation, fighter: FighterState) -> bool:
	return sim.rules.powers and fighter.powers[FighterState.FOURTH_SLOT] != null


static func _resolve_chord(sim: MatchSimulation, fighter: FighterState, intent: Intent, direction: int) -> bool:
	var power_pressed: bool = intent.was_pressed(Intent.Command.POWER)
	var special_pressed: bool = intent.was_pressed(Intent.Command.SPECIAL)
	if fighter.chord_command != 0:
		var completes: bool = (fighter.chord_command == Intent.Command.POWER and special_pressed) or (fighter.chord_command == Intent.Command.SPECIAL and power_pressed)
		if completes:
			fighter.chord_command = 0
			_buffer(sim, fighter, FighterState.Action.FOURTH, direction)
			return true
		fighter.chord_ticks -= 1
		if fighter.chord_ticks <= 0:
			var waited: FighterState.Action = FighterState.Action.POWER if fighter.chord_command == Intent.Command.POWER else FighterState.Action.SPECIAL
			fighter.chord_command = 0
			_buffer(sim, fighter, waited, fighter.chord_direction)
		return false
	if power_pressed and special_pressed:
		_buffer(sim, fighter, FighterState.Action.FOURTH, direction)
		return true
	if power_pressed or special_pressed:
		fighter.chord_command = Intent.Command.POWER if power_pressed else Intent.Command.SPECIAL
		fighter.chord_ticks = maxi(Ticks.from_seconds(sim.config.flow.chord_window), 1)
		fighter.chord_direction = direction
		var other: int = intent.pressed & ~(Intent.Command.POWER | Intent.Command.SPECIAL)
		return other == 0
	return false


static func pressed_action(intent: Intent) -> FighterState.Action:
	if intent.pressed == 0:
		return FighterState.Action.NONE
	if intent.was_pressed(Intent.Command.DODGE):
		return FighterState.Action.DODGE
	if intent.was_pressed(Intent.Command.EVADE):
		return FighterState.Action.EVADE
	if intent.was_pressed(Intent.Command.LIGHT) and intent.is_held(Intent.Command.BLOCK):
		return FighterState.Action.SHOVE
	if intent.was_pressed(Intent.Command.SPECIAL):
		return FighterState.Action.SPECIAL
	if intent.was_pressed(Intent.Command.POWER):
		return FighterState.Action.POWER
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
	if fighter.blade_out and (BLADE_ACTIONS & (1 << action)) != 0:
		return false
	if (fighter.rain_ticks > 0 or fighter.singularity_ticks > 0) and (RAIN_BLOCKED_ACTIONS & (1 << action)) != 0:
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
		FighterState.Action.SPECIAL:
			return _start_special(sim, fighter, intent)
		FighterState.Action.POWER:
			return PowerStarter.try_cast(sim, fighter, fighter.buffered_direction, false)
		FighterState.Action.FOURTH:
			return PowerStarter.try_cast(sim, fighter, fighter.buffered_direction, true)
	return Result.NOT_POSSIBLE


static func start_attack(sim: MatchSimulation, fighter: FighterState, move: MoveData, chain_index: int = 0) -> Result:
	if move == null:
		return Result.NOT_POSSIBLE
	if move.draws_sidearm and (fighter.carried_blaster() == null or fighter.is_airborne()):
		return Result.NOT_POSSIBLE
	if not sim.spend_vigor(fighter, move.vigor_cost):
		return Result.REJECTED
	var state: FighterState.State = FighterState.State.HEAVY_ATTACK if move.is_heavy() else FighterState.State.ATTACKING
	sim.change_state(fighter, state)
	fighter.move = move
	fighter.chain_index = chain_index
	fighter.move_hit_done = false
	fighter.move_connected = false
	fighter.armor_used = 0
	fighter.charge_ticks = 0
	fighter.charge_level = 1
	fighter.phase_ticks = 0
	fighter.move_phase = FighterState.Phase.STARTUP
	if move.startup_ticks() == 0:
		fighter.move_phase = FighterState.Phase.ACTIVE if move.active_ticks() > 0 else FighterState.Phase.RECOVERY
	if move.is_aerial() or fighter.is_airborne():
		fighter.air_attacks += 1
	var event: CombatEvent = sim.emit(CombatEvent.Type.ATTACK_STARTED, fighter.index, sim.opponent_of(fighter).index)
	event.move = move
	event.heavy = move.is_heavy()
	return Result.STARTED


static func _start_light(sim: MatchSimulation, fighter: FighterState) -> Result:
	if fighter.is_airborne():
		return start_attack(sim, fighter, fighter.character.aerial_light) if can_attack_in_air(fighter) else Result.NOT_POSSIBLE
	if fighter.instinct_counter_ticks > 0:
		fighter.instinct_counter_ticks = 0
		fighter.instinct_evade_ticks = 0
		return start_attack(sim, fighter, fighter.character.counter)
	var opponent: FighterState = sim.opponent_of(fighter)
	if opponent.state == FighterState.State.STAGGERED and opponent.stagger_counterable:
		return start_attack(sim, fighter, fighter.character.counter)
	if fighter.character.light_chain.is_empty():
		return Result.NOT_POSSIBLE
	return start_attack(sim, fighter, fighter.character.light_chain[0], 0)


static func _start_heavy(sim: MatchSimulation, fighter: FighterState, intent: Intent) -> Result:
	if fighter.is_airborne():
		return start_attack(sim, fighter, fighter.character.aerial_heavy) if can_attack_in_air(fighter) else Result.NOT_POSSIBLE
	var forward: bool = intent.move_x != 0 and intent.move_x == fighter.facing
	if forward and fighter.character.forward_heavy != null:
		return start_attack(sim, fighter, fighter.character.forward_heavy)
	return start_attack(sim, fighter, fighter.character.heavy)


static func can_attack_in_air(fighter: FighterState) -> bool:
	return fighter.air_attacks < fighter.character.aerials_per_jump


static func _start_jump(sim: MatchSimulation, fighter: FighterState) -> Result:
	var wall: int = _touching_wall(sim, fighter)
	if fighter.is_airborne() and wall != 0 and fighter.character.wall_jump and wall != fighter.last_wall:
		fighter.last_wall = wall
		fighter.vx = -wall * sim.config.wall_jump_speed * fighter.agility_multiplier
		fighter.vy = fighter.jump_velocity
		sim.emit(CombatEvent.Type.JUMP, fighter.index, CombatEvent.NO_FIGHTER).amount = 3.0
		return Result.STARTED
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


static func _touching_wall(sim: MatchSimulation, fighter: FighterState) -> int:
	var limit: float = sim.config.half_width() - sim.config.body_width * 0.5 - sim.config.wall_contact
	if fighter.x >= limit:
		return 1
	if fighter.x <= -limit:
		return -1
	return 0


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
	elif _spin_dodge_travel(sim, fighter, intent) > 0.0:
		if not sim.spend_vigor(fighter, config.spin_dodge_vigor * leg_multiplier):
			return Result.REJECTED
		fighter.dodge_kind = FighterState.DodgeKind.SPIN
		fighter.dodge_direction = fighter.facing
		fighter.dodge_travel = _spin_dodge_travel(sim, fighter, intent)
		fighter.invulnerable_ticks = 0
	else:
		if not sim.spend_vigor(fighter, config.dodge_vigor * leg_multiplier):
			return Result.REJECTED
		fighter.dodge_kind = FighterState.DodgeKind.GROUND
		fighter.dodge_direction = intent.move_x if intent.move_x != 0 else -fighter.facing
		fighter.invulnerable_ticks = Ticks.from_seconds(config.dodge_invulnerable)
	sim.change_state(fighter, FighterState.State.DODGING)
	var event: CombatEvent = sim.emit(CombatEvent.Type.DODGE, fighter.index, CombatEvent.NO_FIGHTER)
	event.heavy = fighter.is_airborne()
	event.amount = fighter.dodge_kind
	return Result.STARTED


static func _spin_dodge_travel(sim: MatchSimulation, fighter: FighterState, intent: Intent) -> float:
	if intent.move_x != fighter.facing:
		return 0.0
	var config: CombatConfig = sim.config
	var opponent: FighterState = sim.opponent_of(fighter)
	if not opponent.is_alive() or CombatGeometry.gap(config, fighter, opponent) > config.spin_dodge_range:
		return 0.0
	var landing: float = opponent.x + fighter.facing * (config.body_width + config.spin_dodge_clearance)
	if absf(landing) > config.half_width() - config.body_width * 0.5:
		return 0.0
	return absf(landing - fighter.x)


static func _start_evade(sim: MatchSimulation, fighter: FighterState) -> Result:
	if fighter.is_airborne():
		return Result.NOT_POSSIBLE
	fighter.dodge_kind = FighterState.DodgeKind.EVADE
	fighter.dodge_direction = -fighter.facing
	fighter.evade_succeeded = false
	fighter.evade_window_ticks = maxi(Ticks.from_seconds(sim.config.evade_invulnerable * fighter.agility_multiplier), 1)
	sim.change_state(fighter, FighterState.State.DODGING)
	return Result.STARTED


static func _start_special(sim: MatchSimulation, fighter: FighterState, intent: Intent) -> Result:
	var technique: MoveData = technique_for(sim, fighter, fighter.buffered_direction)
	if technique != null:
		if fighter.is_airborne() and not can_attack_in_air(fighter):
			return Result.NOT_POSSIBLE
		return start_attack(sim, fighter, technique)
	if fighter.buffered_direction != 0 and not fighter.character.directional_ability_fallback:
		return Result.NOT_POSSIBLE
	return _start_ability(sim, fighter, intent)


static func technique_for(sim: MatchSimulation, fighter: FighterState, direction: int) -> MoveData:
	if not sim.rules.powers:
		return null
	var character: CharacterData = fighter.character
	if fighter.is_airborne():
		return character.technique_air
	if direction > 0:
		return character.technique_forward
	if direction < 0:
		return character.technique_back
	return null


static func _start_ability(sim: MatchSimulation, fighter: FighterState, intent: Intent) -> Result:
	var ability: AbilityData = fighter.character.ability
	if ability == null or fighter.is_airborne():
		return Result.NOT_POSSIBLE
	match ability.kind:
		AbilityData.Kind.STRIKE, AbilityData.Kind.CHARGE:
			return start_attack(sim, fighter, ability.move)
		AbilityData.Kind.STANCE:
			return start_attack(sim, fighter, ability.stance_move())
		AbilityData.Kind.DASH:
			return _start_dash(sim, fighter, intent, ability)
		AbilityData.Kind.LEAP:
			return _start_leap(sim, fighter, ability)
	return Result.NOT_POSSIBLE


static func _start_dash(sim: MatchSimulation, fighter: FighterState, intent: Intent, ability: AbilityData) -> Result:
	if not sim.spend_vigor(fighter, ability.vigor_cost):
		return Result.REJECTED
	var default_direction: int = fighter.facing if ability.dash_forward_by_default else -fighter.facing
	fighter.dodge_kind = FighterState.DodgeKind.DASH
	fighter.dodge_direction = intent.move_x if intent.move_x != 0 else default_direction
	fighter.invulnerable_ticks = Ticks.from_seconds(ability.dash_invulnerable)
	sim.change_state(fighter, FighterState.State.DODGING)
	sim.emit(CombatEvent.Type.DODGE, fighter.index, CombatEvent.NO_FIGHTER)
	return Result.STARTED


static func _start_leap(sim: MatchSimulation, fighter: FighterState, ability: AbilityData) -> Result:
	if not sim.spend_vigor(fighter, ability.vigor_cost):
		return Result.REJECTED
	fighter.vx = fighter.facing * ability.leap_velocity.x * fighter.agility_multiplier
	fighter.vy = ability.leap_velocity.y
	fighter.on_ground = false
	fighter.jumps_used = 1
	fighter.leap_dive = ability.dive_when_falling
	sim.change_state(fighter, FighterState.State.JUMPING)
	sim.emit(CombatEvent.Type.JUMP, fighter.index, CombatEvent.NO_FIGHTER).amount = 1.0
	return Result.STARTED
