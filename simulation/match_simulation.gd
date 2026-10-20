class_name MatchSimulation
extends RefCounted

enum Phase { INTRO, FIGHT, KO, OVER }

const EVENT_POOL_SIZE: int = 32
const NO_WINNER: int = -1

var config: CombatConfig
var rules: MatchRules
var fighters: Array[FighterState] = []
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var seed_value: int = 0

var phase: Phase = Phase.INTRO
var phase_ticks: int = 0
var tick: int = 0
var round_number: int = 0
var round_tick: int = 0
var round_winner: int = NO_WINNER
var match_winner: int = NO_WINNER
var lock_ticks: int = 0
var lock_cooldown_ticks: int = 0

var lock_finish_move: MoveData
var hit_attackers: Array[FighterState] = []
var hit_moves: Array[MoveData] = []
var events: Array[CombatEvent] = []
var event_count: int = 0

var _states: Array[StateLogic] = []
var _neutral_intent: Intent = Intent.new()
var _intents: Array[Intent] = [null, null]


func _init(combat_config: CombatConfig, match_rules: MatchRules, characters: Array[CharacterData], match_seed: int) -> void:
	config = combat_config
	rules = match_rules
	seed_value = match_seed
	rng.seed = match_seed
	lock_finish_move = BladeLockResolver.create_finish_move(config)
	_build_states()
	for i in EVENT_POOL_SIZE:
		events.append(CombatEvent.new())
	for i in characters.size():
		var fighter: FighterState = FighterState.new()
		fighter.setup(i, characters[i], config)
		fighters.append(fighter)


func _build_states() -> void:
	var ground: GroundState = GroundState.new()
	var attack: AttackState = AttackState.new()
	var recoil: RecoilState = RecoilState.new()
	_states.resize(FighterState.State.size())
	_states[FighterState.State.IDLE] = ground
	_states[FighterState.State.WALKING] = ground
	_states[FighterState.State.JUMPING] = AirState.new()
	_states[FighterState.State.ATTACKING] = attack
	_states[FighterState.State.HEAVY_ATTACK] = attack
	_states[FighterState.State.BLOCKING] = BlockState.new()
	_states[FighterState.State.DODGING] = DodgeState.new()
	_states[FighterState.State.BLADE_LOCK] = BladeLockState.new()
	_states[FighterState.State.HIT] = recoil
	_states[FighterState.State.STAGGERED] = recoil
	_states[FighterState.State.STUNNED] = recoil
	_states[FighterState.State.DEAD] = DeadState.new()


func start_match() -> void:
	tick = 0
	round_number = 0
	match_winner = NO_WINNER
	for fighter in fighters:
		fighter.round_wins = 0
	_start_round()


func step(first_intent: Intent, second_intent: Intent) -> void:
	event_count = 0
	tick += 1
	round_tick += 1
	phase_ticks += 1
	_advance_phase()
	var fighting: bool = phase == Phase.FIGHT
	_intents[0] = first_intent if fighting else _neutral_intent
	_intents[1] = second_intent if fighting else _neutral_intent
	for i in fighters.size():
		ActionStarter.update_buffer(self, fighters[i], _intents[i])
	for i in fighters.size():
		_step_fighter(fighters[i], _intents[i])
	BodyResolver.resolve(self)
	_update_facing()
	if fighting:
		ClashResolver.resolve(self)
		HitResolver.resolve(self)
		BladeLockResolver.step(self)
		_check_round_end()
	if lock_cooldown_ticks > 0:
		lock_cooldown_ticks -= 1


func opponent_of(fighter: FighterState) -> FighterState:
	return fighters[1 - fighter.index]


func state_logic(fighter: FighterState) -> StateLogic:
	return _states[fighter.state]


func change_state(fighter: FighterState, new_state: FighterState.State) -> void:
	_states[fighter.state].exit(self, fighter)
	fighter.state = new_state
	fighter.state_ticks = 0
	_states[new_state].enter(self, fighter)


func emit(type: CombatEvent.Type, source: int, target: int) -> CombatEvent:
	if event_count >= events.size():
		events.append(CombatEvent.new())
	var event: CombatEvent = events[event_count]
	event_count += 1
	event.reset()
	event.type = type
	event.source = source
	event.target = target
	return event


func freeze_pair(a: FighterState, b: FighterState, seconds: float) -> int:
	var ticks: int = Ticks.from_seconds(seconds)
	a.freeze_ticks = maxi(a.freeze_ticks, ticks)
	b.freeze_ticks = maxi(b.freeze_ticks, ticks)
	return ticks


func push_apart(a: FighterState, b: FighterState, total_distance: float) -> void:
	var speed: float = config.slide_speed_for(total_distance * 0.5)
	a.vx = CombatGeometry.away_from(b, a) * speed
	b.vx = CombatGeometry.away_from(a, b) * speed


func spend_vigor(fighter: FighterState, amount: float) -> bool:
	if amount <= 0.0:
		return true
	if fighter.vigor < amount:
		reject_action(fighter)
		return false
	drain_vigor(fighter, amount)
	return true


func reject_action(fighter: FighterState) -> void:
	emit(CombatEvent.Type.ACTION_REJECTED, fighter.index, CombatEvent.NO_FIGHTER)


func drain_vigor(fighter: FighterState, amount: float) -> void:
	fighter.vigor = maxf(fighter.vigor - amount, 0.0)
	fighter.regen_delay_ticks = Ticks.from_seconds(config.vigor_regen_delay)
	Consequences.check_exhaustion(self, fighter)


func gain_vigor(fighter: FighterState, amount: float) -> void:
	fighter.vigor = minf(fighter.vigor + amount, fighter.max_vigor)


func block_cost(defender: FighterState, move: MoveData) -> float:
	var cost: float = move.block_vigor_cost * defender.character.block_cost_multiplier / defender.defense_multiplier
	if defender.wound == FighterState.Wound.ARM:
		cost *= config.consequences.wounded_arm_block_multiplier
	return cost


func apply_damage(fighter: FighterState, amount: float) -> bool:
	fighter.ticks_since_damage = 0
	if rules.endless:
		fighter.health = maxf(fighter.health - amount, 1.0)
		return false
	fighter.health = maxf(fighter.health - amount, 0.0)
	return fighter.health <= 0.0


func kill(victim: FighterState, killer: FighterState, move: MoveData) -> void:
	var deciding: bool = killer.round_wins + 1 >= rules.rounds_to_win
	victim.finisher_limb = Consequences.finisher_limb(self, move, deciding)
	victim.finisher_from_front = CombatGeometry.faces(victim, killer)
	change_state(victim, FighterState.State.DEAD)
	var event: CombatEvent = emit(CombatEvent.Type.DEATH, killer.index, victim.index)
	event.move = move
	event.limb = victim.finisher_limb
	event.from_front = victim.finisher_from_front
	event.position = Vector2(victim.x, victim.y + config.body_height * 0.5)


func capture() -> Dictionary:
	var fighter_snapshots: Array[Dictionary] = []
	for fighter in fighters:
		fighter_snapshots.append(fighter.capture())
	return {
		"phase": phase,
		"phase_ticks": phase_ticks,
		"tick": tick,
		"round_number": round_number,
		"round_tick": round_tick,
		"round_winner": round_winner,
		"match_winner": match_winner,
		"lock_ticks": lock_ticks,
		"lock_cooldown_ticks": lock_cooldown_ticks,
		"rng_state": rng.state,
		"fighters": fighter_snapshots,
	}


func restore(snapshot: Dictionary) -> void:
	phase = snapshot["phase"]
	phase_ticks = snapshot["phase_ticks"]
	tick = snapshot["tick"]
	round_number = snapshot["round_number"]
	round_tick = snapshot["round_tick"]
	round_winner = snapshot["round_winner"]
	match_winner = snapshot["match_winner"]
	lock_ticks = snapshot["lock_ticks"]
	lock_cooldown_ticks = snapshot["lock_cooldown_ticks"]
	rng.state = snapshot["rng_state"]
	var fighter_snapshots: Array = snapshot["fighters"]
	for i in fighters.size():
		fighters[i].restore(fighter_snapshots[i])
	event_count = 0


func _start_round() -> void:
	round_number += 1
	round_tick = 0
	round_winner = NO_WINNER
	lock_cooldown_ticks = 0
	lock_ticks = 0
	var half_distance: float = config.round_start_distance * 0.5
	fighters[0].reset_for_round(-half_distance, 1)
	fighters[1].reset_for_round(half_distance, -1)
	_set_phase(Phase.INTRO)
	emit(CombatEvent.Type.ROUND_STARTED, CombatEvent.NO_FIGHTER, CombatEvent.NO_FIGHTER).amount = round_number


func _set_phase(new_phase: Phase) -> void:
	phase = new_phase
	phase_ticks = 0


func _advance_phase() -> void:
	match phase:
		Phase.INTRO:
			if phase_ticks >= Ticks.from_seconds(config.round_intro):
				_set_phase(Phase.FIGHT)
				emit(CombatEvent.Type.FIGHT_STARTED, CombatEvent.NO_FIGHTER, CombatEvent.NO_FIGHTER).amount = round_number
		Phase.KO:
			if phase_ticks >= Ticks.from_seconds(config.ko_duration):
				_after_ko()


func _after_ko() -> void:
	for fighter in fighters:
		if fighter.round_wins >= rules.rounds_to_win:
			match_winner = fighter.index
	if match_winner != NO_WINNER:
		_set_phase(Phase.OVER)
		emit(CombatEvent.Type.MATCH_ENDED, match_winner, 1 - match_winner)
	else:
		_start_round()


func _step_fighter(fighter: FighterState, intent: Intent) -> void:
	if fighter.freeze_ticks > 0:
		fighter.freeze_ticks -= 1
		return
	if fighter.state != FighterState.State.BLADE_LOCK:
		_tick_timers(fighter)
	fighter.state_ticks += 1
	_states[fighter.state].step(self, fighter, intent)
	_integrate(fighter)


func _tick_timers(fighter: FighterState) -> void:
	if fighter.invulnerable_ticks > 0:
		fighter.invulnerable_ticks -= 1
	if fighter.parry_lockout_ticks > 0:
		fighter.parry_lockout_ticks -= 1
	fighter.ticks_since_damage += 1
	_regenerate(fighter)
	Consequences.step_exhaustion(self, fighter)
	if rules.endless and fighter.ticks_since_damage >= Ticks.from_seconds(config.endless_refill_delay):
		fighter.health = fighter.max_health


func _regenerate(fighter: FighterState) -> void:
	if not fighter.is_alive():
		return
	if fighter.regen_delay_ticks > 0:
		fighter.regen_delay_ticks -= 1
		return
	var rate: float = fighter.vigor_regen
	if fighter.state == FighterState.State.BLOCKING:
		rate *= config.block_regen_ratio
	gain_vigor(fighter, rate * Ticks.DELTA)


func _integrate(fighter: FighterState) -> void:
	if fighter.state == FighterState.State.BLADE_LOCK:
		return
	if not fighter.on_ground:
		fighter.vy = maxf(fighter.vy - config.gravity * Ticks.DELTA, -config.max_fall_speed)
	fighter.x += fighter.vx * Ticks.DELTA
	fighter.y += fighter.vy * Ticks.DELTA
	if not fighter.on_ground and fighter.y <= 0.0 and fighter.vy <= 0.0:
		_land(fighter)
	BodyResolver.clamp_to_walls(self, fighter)


func _land(fighter: FighterState) -> void:
	fighter.y = 0.0
	fighter.vy = 0.0
	fighter.on_ground = true
	fighter.jumps_used = 0
	fighter.air_dash_used = false
	fighter.air_attack_used = false
	var landing_cancels: bool = (
		fighter.state == FighterState.State.JUMPING
		or fighter.is_air_dashing()
		or (fighter.is_attacking() and fighter.move != null and fighter.move.is_aerial())
	)
	if landing_cancels:
		change_state(fighter, FighterState.State.IDLE)
	emit(CombatEvent.Type.LAND, fighter.index, CombatEvent.NO_FIGHTER)


func _update_facing() -> void:
	for fighter in fighters:
		if not fighter.on_ground:
			continue
		var turns: bool = fighter.is_free() or (fighter.state == FighterState.State.BLOCKING and fighter.stun_ticks == 0)
		if not turns:
			continue
		var dx: float = opponent_of(fighter).x - fighter.x
		if dx != 0.0:
			fighter.facing = int(signf(dx))


func _check_round_end() -> void:
	var a_dead: bool = not fighters[0].is_alive()
	var b_dead: bool = not fighters[1].is_alive()
	if not (a_dead or b_dead):
		return
	if a_dead != b_dead:
		round_winner = 1 if a_dead else 0
		fighters[round_winner].round_wins += 1
	_set_phase(Phase.KO)
	emit(CombatEvent.Type.ROUND_ENDED, round_winner, CombatEvent.NO_FIGHTER if round_winner == NO_WINNER else 1 - round_winner)
