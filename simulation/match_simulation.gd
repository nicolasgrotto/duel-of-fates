class_name MatchSimulation
extends RefCounted

const SINGULARITY = preload("res://simulation/powers/singularity_field.gd")

enum Phase { INTRO, FIGHT, KO, OVER }

const EVENT_POOL_SIZE: int = 32
const PROJECTILE_POOL_SIZE: int = 16
const HAZARD_POOL_SIZE: int = 48
const GROUP_MEMORY: int = 16
const NO_WINNER: int = -1
const INTRO_ATTACKS: int = Intent.Command.LIGHT | Intent.Command.HEAVY | Intent.Command.SPECIAL | Intent.Command.POWER

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
var cinematic_ticks: int = 0
var cinematic_ko: bool = false
var long_cinematic: bool = false
var contact_streak: int = 0
var contact_idle_ticks: int = 0
var contact_parrier: int = -1

var lock_finish_move: MoveData
var hit_attackers: Array[FighterState] = []
var hit_moves: Array[MoveData] = []
var events: Array[CombatEvent] = []
var event_count: int = 0
var projectiles: Array[Projectile] = []
var hazards: Array[Hazard] = []
var impact: PowerImpact = PowerImpact.new()
var basic_table: InteractionTable
var hazard_group_counter: int = 0
var hazard_groups_hit: Array[PackedInt32Array] = [PackedInt32Array(), PackedInt32Array()]

var _states: Array[StateLogic] = []
var _neutral_intent: Intent = Intent.new()
var _intents: Array[Intent] = [null, null]
var _twisted: Array[Intent] = [Intent.new(), Intent.new()]


func _init(combat_config: CombatConfig, match_rules: MatchRules, characters: Array[CharacterData], match_seed: int) -> void:
	config = combat_config
	rules = match_rules
	seed_value = match_seed
	rng.seed = match_seed
	lock_finish_move = BladeLockResolver.create_finish_move(config)
	basic_table = config.flow.basic_table
	_build_states()
	for i in EVENT_POOL_SIZE:
		events.append(CombatEvent.new())
	for i in PROJECTILE_POOL_SIZE:
		projectiles.append(Projectile.new())
	for i in HAZARD_POOL_SIZE:
		hazards.append(Hazard.new())
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
	var power_state: PowerState = PowerState.new()
	_states[FighterState.State.CASTING] = power_state
	_states[FighterState.State.CHANNELING] = power_state
	_states[FighterState.State.HELD] = HeldState.new()


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
	if cinematic_ticks > 0:
		cinematic_ticks -= 1
		return
	round_tick += 1
	var was_intro: bool = phase == Phase.INTRO
	phase_ticks += 1
	if was_intro and plays_fighter_intros() and (first_intent.skip_intro or second_intent.skip_intro or ((first_intent.pressed | second_intent.pressed) & INTRO_ATTACKS) != 0):
		phase_ticks = maxi(phase_ticks, intro_title_tick())
	_advance_phase()
	var fighting: bool = phase == Phase.FIGHT
	_intents[0] = first_intent if fighting and not was_intro else _neutral_intent
	_intents[1] = second_intent if fighting and not was_intro else _neutral_intent
	for i in fighters.size():
		fighters[i].input_idle = _intents[i].held == 0 and _intents[i].move_x == 0
		if fighters[i].twisted_ticks > 0:
			_twisted[i].copy_from(_intents[i])
			_twisted[i].move_x = -_intents[i].move_x
			_intents[i] = _twisted[i]
	for i in fighters.size():
		ActionStarter.update_buffer(self, fighters[i], _intents[i])
	for i in fighters.size():
		_step_fighter(fighters[i], _intents[i])
	BodyResolver.resolve(self)
	_update_facing()
	if fighting:
		ClashResolver.resolve(self)
		HitResolver.resolve(self)
		ProjectileSystem.step(self)
		HazardSystem.step(self)
		SINGULARITY.step(self)
		BladeLockResolver.step(self)
		BladePress.observe(self)
		_check_round_end()
	elif phase == Phase.KO or phase == Phase.OVER:
		ProjectileSystem.drift(self)
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
	if fighter.focus_ticks > 0:
		amount *= config.flow.focus_cost_ratio
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
	if defender.focus_ticks > 0:
		cost *= config.flow.focus_cost_ratio
	return cost


func gain_flow(fighter: FighterState, amount: float) -> void:
	if not rules.powers:
		return
	fighter.flow = clampf(fighter.flow + amount * fighter.flow_potency, 0.0, config.flow.maximum)


func wrath_scale(attacker: FighterState, defender: FighterState) -> float:
	var scale: float = 1.0
	if attacker.wrath_ticks > 0:
		scale *= config.flow.wrath_dealt
	if defender.wrath_ticks > 0:
		scale *= config.flow.wrath_taken
	return scale


func spawn_projectile(kind: Projectile.Kind, owner: FighterState, power: PowerData) -> Projectile:
	for projectile in projectiles:
		if projectile.active:
			continue
		projectile.active = true
		projectile.kind = kind
		projectile.owner = owner.index
		projectile.x = owner.x + owner.facing * config.body_width
		projectile.y = owner.y + config.flow.projectile_height
		projectile.vx = 0.0
		projectile.vy = 0.0
		projectile.travelled = 0.0
		projectile.returning = false
		projectile.hit_done = false
		projectile.flow_level = owner.flow_level
		projectile.tier = owner.flow_tier
		projectile.delay_ticks = 0
		projectile.power = power
		projectile.move = null
		projectile.bolt = null
		var event: CombatEvent = emit(CombatEvent.Type.PROJECTILE_SPAWNED, owner.index, CombatEvent.NO_FIGHTER)
		event.power = power
		event.amount = kind
		return projectile
	return null


func spawn_hazard(kind: Hazard.Kind, owner: FighterState, at_x: float, half_width: float, delay: float, group: int, damage: float, power: PowerData) -> void:
	for hazard in hazards:
		if hazard.active:
			continue
		hazard.active = true
		hazard.kind = kind
		hazard.owner = owner.index
		hazard.x = at_x
		hazard.half_width = half_width
		hazard.delay_ticks = maxi(Ticks.from_seconds(delay), 1)
		hazard.total_delay = hazard.delay_ticks
		hazard.group = group
		hazard.damage = damage
		hazard.flow_level = owner.flow_level
		hazard.power = power
		var event: CombatEvent = emit(CombatEvent.Type.HAZARD_MARKED, owner.index, CombatEvent.NO_FIGHTER)
		event.power = power
		event.position = Vector2(at_x, 0.0)
		event.amount = kind
		return


func next_hazard_group() -> int:
	hazard_group_counter += 1
	return hazard_group_counter


func skip_hazard_groups(count: int) -> void:
	hazard_group_counter += count


func hazard_group_hit(group: int, fighter_index: int) -> bool:
	return hazard_groups_hit[fighter_index].has(group)


func mark_hazard_group(group: int, fighter_index: int) -> void:
	var memory: PackedInt32Array = hazard_groups_hit[fighter_index]
	memory.append(group)
	if memory.size() > GROUP_MEMORY:
		memory.remove_at(0)
	hazard_groups_hit[fighter_index] = memory


func apply_damage(fighter: FighterState, amount: float, power_damage: bool = false) -> bool:
	if fighter.sanctuary_hp > 0.0:
		var absorbed: float = minf(fighter.sanctuary_hp, amount)
		fighter.sanctuary_hp -= absorbed
		amount -= absorbed
		if fighter.sanctuary_hp <= 0.0:
			fighter.sanctuary_ticks = 0
	if amount <= 0.0:
		return false
	if power_damage:
		fighter.instinct_ticks = 0
		fighter.instinct_counter_ticks = 0
		fighter.instinct_evade_ticks = 0
	fighter.heal_ticks = 0
	fighter.ticks_since_damage = 0
	if rules.endless and not rules.endless_finishers:
		fighter.health = maxf(fighter.health - amount, 1.0)
		return false
	fighter.health = maxf(fighter.health - amount, 0.0)
	return fighter.health <= 0.0


func kill(victim: FighterState, killer: FighterState, move: MoveData, power: PowerData = null, thrown: MoveData = null) -> void:
	var deciding: bool = is_deciding(killer)
	victim.finisher_kind = Consequences.finisher_for(self, move if thrown == null else thrown, power, deciding)
	if victim.finisher_kind == Finisher.Kind.TWIN_BLADES and victim.character.weapon.kind != WeaponData.Kind.SINGLE:
		victim.finisher_kind = Finisher.Kind.EXECUTION
	victim.finisher_limb = Consequences.finisher_limb(self, killer, victim, move, deciding) if victim.finisher_kind == Finisher.Kind.NONE else MoveData.Limb.NONE
	victim.finisher_from_front = CombatGeometry.faces(victim, killer)
	cinematic_ko = victim.finisher_kind != Finisher.Kind.NONE
	long_cinematic = Finisher.is_long(victim.finisher_kind)
	if victim.finisher_kind == Finisher.Kind.DASH_THROUGH:
		_pass_behind(killer, victim)
	elif Finisher.passes_behind(victim.finisher_kind):
		_pass_behind(killer, victim)
		victim.vx = 0.0
		killer.facing = int(signf(victim.x - killer.x)) if victim.x != killer.x else killer.facing
	elif Finisher.is_staged(victim.finisher_kind):
		_hold_in_front(killer, victim)
	change_state(victim, FighterState.State.DEAD)
	var event: CombatEvent = emit(CombatEvent.Type.DEATH, killer.index, victim.index)
	event.move = move if thrown == null else thrown
	event.power = power
	event.finisher = victim.finisher_kind
	event.limb = victim.finisher_limb
	event.from_front = victim.finisher_from_front
	event.position = Vector2(victim.x, victim.y + config.body_height * 0.5)


func cinematic_seconds() -> float:
	if not cinematic_ko:
		return 0.0
	return config.consequences.long_cinematic_ko_time if long_cinematic else config.consequences.cinematic_ko_time


func intro_seconds() -> float:
	if not rules.round_intro:
		return 0.0
	return config.match_intro if plays_fighter_intros() else config.round_intro


func plays_fighter_intros() -> bool:
	return rules.fighter_intros and round_number == 1


func intro_title_tick() -> int:
	return maxi(Ticks.from_seconds(config.match_intro - config.match_intro_title), 0) if plays_fighter_intros() else 0


func is_deciding(killer: FighterState) -> bool:
	return rules.endless_finishers or killer.round_wins + 1 >= rules.rounds_to_win


func _pass_behind(killer: FighterState, victim: FighterState) -> void:
	var side: int = killer.facing
	var limit: float = config.half_width() - config.body_width * 0.5
	killer.x = clampf(victim.x + side * (config.body_width + config.consequences.dash_through_clearance), -limit, limit)
	killer.vx = 0.0


func _hold_in_front(killer: FighterState, victim: FighterState) -> void:
	killer.vx = 0.0
	victim.vx = 0.0
	var minimum: float = config.body_width + config.consequences.execution_clearance
	if absf(killer.x - victim.x) >= minimum:
		return
	var side: float = signf(killer.x - victim.x) if killer.x != victim.x else -float(killer.facing)
	var limit: float = config.half_width() - config.body_width * 0.5
	killer.x = clampf(victim.x + side * minimum, -limit, limit)


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
		"cinematic_ticks": cinematic_ticks,
		"cinematic_ko": cinematic_ko,
		"long_cinematic": long_cinematic,
		"contact_streak": contact_streak,
		"contact_idle_ticks": contact_idle_ticks,
		"contact_parrier": contact_parrier,
		"rng_state": rng.state,
		"fighters": fighter_snapshots,
		"projectiles": projectiles.map(func(item: Projectile) -> Dictionary: return item.capture()),
		"hazards": hazards.map(func(item: Hazard) -> Dictionary: return item.capture()),
		"hazard_group_counter": hazard_group_counter,
		"hazard_groups_hit": [hazard_groups_hit[0].duplicate(), hazard_groups_hit[1].duplicate()],
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
	cinematic_ticks = snapshot["cinematic_ticks"]
	cinematic_ko = snapshot["cinematic_ko"]
	long_cinematic = snapshot["long_cinematic"]
	contact_streak = snapshot["contact_streak"]
	contact_idle_ticks = snapshot["contact_idle_ticks"]
	contact_parrier = snapshot["contact_parrier"]
	rng.state = snapshot["rng_state"]
	var fighter_snapshots: Array = snapshot["fighters"]
	for i in fighters.size():
		fighters[i].restore(fighter_snapshots[i])
	var projectile_snapshots: Array = snapshot["projectiles"]
	for i in projectiles.size():
		projectiles[i].restore(projectile_snapshots[i])
	var hazard_snapshots: Array = snapshot["hazards"]
	for i in hazards.size():
		hazards[i].restore(hazard_snapshots[i])
	hazard_group_counter = snapshot["hazard_group_counter"]
	var groups: Array = snapshot["hazard_groups_hit"]
	hazard_groups_hit = [PackedInt32Array(groups[0]), PackedInt32Array(groups[1])]
	event_count = 0


func _start_round() -> void:
	round_number += 1
	round_tick = 0
	round_winner = NO_WINNER
	lock_cooldown_ticks = 0
	lock_ticks = 0
	restage()
	_set_phase(Phase.INTRO)
	emit(CombatEvent.Type.ROUND_STARTED, CombatEvent.NO_FIGHTER, CombatEvent.NO_FIGHTER).amount = round_number


func restage() -> void:
	cinematic_ticks = 0
	cinematic_ko = false
	long_cinematic = false
	BladePress.reset(self)
	var half_distance: float = config.round_start_distance * 0.5
	fighters[0].reset_for_round(-half_distance, 1)
	fighters[1].reset_for_round(half_distance, -1)
	for i in fighters.size():
		if i < rules.start_health.size() and rules.start_health[i] < 1.0:
			fighters[i].health = maxf(fighters[i].max_health * rules.start_health[i], 1.0)
	for fighter in fighters:
		fighter.flow = config.flow.round_start if rules.powers else 0.0
	for projectile in projectiles:
		projectile.active = false
	for hazard in hazards:
		hazard.active = false
	hazard_groups_hit = [PackedInt32Array(), PackedInt32Array()]


func _set_phase(new_phase: Phase) -> void:
	phase = new_phase
	phase_ticks = 0


func _advance_phase() -> void:
	match phase:
		Phase.INTRO:
			if phase_ticks >= Ticks.from_seconds(intro_seconds()):
				_set_phase(Phase.FIGHT)
				emit(CombatEvent.Type.FIGHT_STARTED, CombatEvent.NO_FIGHTER, CombatEvent.NO_FIGHTER).amount = round_number
		Phase.KO:
			if phase_ticks >= Ticks.from_seconds(config.ko_duration + cinematic_seconds()):
				_after_ko()


func _after_ko() -> void:
	if rules.endless:
		_start_round()
		return
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
	FlowStatuses.step(self, fighter)
	if rules.endless and not rules.endless_finishers and fighter.ticks_since_damage >= Ticks.from_seconds(config.endless_refill_delay):
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
	SINGULARITY.pull(self, fighter)
	var suspended: bool = fighter.state == FighterState.State.HELD and fighter.held_by_choke
	if not fighter.on_ground and not suspended:
		fighter.vy = maxf(fighter.vy - config.gravity * Ticks.DELTA, -config.max_fall_speed)
	fighter.x += fighter.vx * Ticks.DELTA
	fighter.y += fighter.vy * Ticks.DELTA
	if not fighter.on_ground and fighter.y <= 0.0 and fighter.vy <= 0.0 and not suspended:
		_land(fighter)
	BodyResolver.clamp_to_walls(self, fighter)


func _land(fighter: FighterState) -> void:
	fighter.y = 0.0
	fighter.vy = 0.0
	fighter.on_ground = true
	fighter.jumps_used = 0
	fighter.air_dash_used = false
	fighter.air_attacks = 0
	fighter.last_wall = 0
	fighter.leap_dive = false
	if fighter.is_attacking() and fighter.move != null and fighter.move.aerial_technique and fighter.move_phase != FighterState.Phase.RECOVERY:
		fighter.move_phase = FighterState.Phase.RECOVERY
		fighter.phase_ticks = 0
		fighter.vx = 0.0
	var landing_cancels: bool = (
		fighter.state == FighterState.State.JUMPING
		or fighter.is_air_dashing()
		or (fighter.is_attacking() and fighter.move != null and fighter.move.is_aerial() and not fighter.move.aerial_technique)
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
		if not rules.endless:
			fighters[round_winner].round_wins += 1
	_set_phase(Phase.KO)
	emit(CombatEvent.Type.ROUND_ENDED, round_winner, CombatEvent.NO_FIGHTER if round_winner == NO_WINNER else 1 - round_winner)
