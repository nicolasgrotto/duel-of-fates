class_name AiController
extends FighterController

enum Plan { WAIT, APPROACH, RETREAT, GUARD }

const PERFECT_PARRY_TARGET: int = 2
const PARRY_TARGET: int = 7
const EVADE_TARGET: int = 2
const SPIN_TARGET: int = 4
const DISENGAGE_THINK_TICKS: int = 6
const REACH_MARGIN: float = 20.0

var difficulty: AiDifficultyData
var awakening: AiDifficultyData
var awakened: bool = false
var profile: AiProfileData
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var memory: AiHabitMemory
var decision: String = ""

var _plan: Plan = Plan.WAIT
var _plan_ticks: int = 0
var _think_ticks: int = 0
var _press_command: int = 0
var _press_hold: int = 0
var _press_delay: int = 0
var _after_press_plan: Plan = Plan.WAIT
var _after_press_ticks: int = 0
var _chain_left: int = 0
var _lock_press_ticks: int = 0
var _hold_command: int = 0
var _hold_until_gap: float = 0.0
var _followup_command: int = 0
var _followup_delay: int = 0
var _press_direction: int = 0
var _channel_ticks: int = 0


func _init(difficulty_data: AiDifficultyData, profile_data: AiProfileData, ai_seed: int) -> void:
	difficulty = difficulty_data
	profile = profile_data
	rng.seed = ai_seed
	memory = AiHabitMemory.new(difficulty.habit_window)


func produce(sim: MatchSimulation, fighter_index: int, intent: Intent) -> void:
	intent.clear()
	var me: FighterState = sim.fighters[fighter_index]
	var opponent: FighterState = sim.opponent_of(me)
	if awakening != null and not awakened and me.health < me.max_health * awakening.awaken_below:
		difficulty = awakening
		awakened = true
	if difficulty.habit_weight > 0.0:
		memory.observe(opponent)
	if sim.phase != MatchSimulation.Phase.FIGHT or not me.is_alive():
		_reset_plan()
		return
	if me.state == FighterState.State.BLADE_LOCK:
		_press_in_lock(sim, me, intent)
		return
	_think_ticks -= 1
	if _think_ticks <= 0:
		_think(sim, me, opponent)
		_think_ticks = _reaction_ticks()
	_execute(me, opponent, sim, intent)


func debug_lines() -> PackedStringArray:
	return PackedStringArray([
		"ai %s  plan %s  think %d" % [decision, Plan.keys()[_plan].to_lower(), _think_ticks],
	])


func _reaction_ticks() -> int:
	var seconds: float = difficulty.reaction_time * (1.0 + rng.randf() * difficulty.reaction_jitter)
	return maxi(Ticks.from_seconds(maxf(seconds, difficulty.reaction_floor)), 1)


func _reset_plan() -> void:
	_plan = Plan.WAIT
	_press_command = 0
	_chain_left = 0
	_lock_press_ticks = 0
	_hold_command = 0
	_followup_command = 0
	_press_direction = 0
	_channel_ticks = 0


func _think(sim: MatchSimulation, me: FighterState, opponent: FighterState) -> void:
	if (_chain_left > 0 and me.is_attacking()) or _hold_command != 0 or _channel_ticks > 0:
		return
	if _try_escape(sim, me):
		return
	var gap: float = CombatGeometry.gap(sim.config, me, opponent)
	if rng.randf() < difficulty.error_chance:
		_make_mistake()
		return
	if me.is_airborne():
		_think_in_air(me, opponent)
		return
	if _try_flow_defense(sim, me, opponent):
		return
	if _try_defend(sim, me, opponent, gap):
		return
	if _try_ability(me, opponent, gap):
		return
	if _try_power(sim, me, opponent, gap):
		return
	if _try_technique(sim, me, gap):
		return
	if _try_punish(sim, me, opponent, gap):
		return
	if _try_shove(me, opponent, gap):
		return
	if _try_recover(me, gap):
		return
	if _try_attack(me, gap):
		return
	_position(me, opponent, gap)


func _try_defend(sim: MatchSimulation, me: FighterState, opponent: FighterState, gap: float) -> bool:
	if not opponent.is_attacking() or opponent.move == null or opponent.move_phase != FighterState.Phase.STARTUP:
		return false
	var move: MoveData = opponent.move
	var ticks_to_active: int = move.startup_ticks() - opponent.phase_ticks
	if move.kind == MoveData.Kind.SHOVE:
		return _answer_shove(me, gap, ticks_to_active)
	if gap > move.reach + move.lunge + REACH_MARGIN:
		if gap <= move.reach + move.lunge + REACH_MARGIN * 3.0 and rng.randf() < difficulty.whiff_bait_chance:
			_set_plan(Plan.RETREAT, ticks_to_active + move.active_ticks(), "whiff bait")
			return true
		return false
	var defend_chance: float = difficulty.defend_chance * lerpf(0.6, 1.4, profile.defense)
	defend_chance *= 1.0 + difficulty.habit_weight * memory.light_share()
	if rng.randf() > defend_chance:
		return false
	var guard_ticks: int = ticks_to_active + move.active_ticks() + 4
	if _ability_answers(me, move, ticks_to_active):
		return true
	if move.is_heavy():
		var parry_chance: float = difficulty.parry_chance * lerpf(0.5, 1.5, profile.parry_bias)
		parry_chance += difficulty.habit_weight * memory.heavy_share()
		if rng.randf() < parry_chance:
			var perfect: bool = rng.randf() < difficulty.perfect_parry_chance
			var target: int = PERFECT_PARRY_TARGET if perfect else PARRY_TARGET
			var delay: int = ticks_to_active - 1 - target
			if delay >= 0:
				_schedule(Intent.Command.BLOCK, delay, 0, Plan.GUARD, guard_ticks - delay, "perfect parry" if perfect else "parry")
				return true
		if _try_spin_dodge(sim, me, gap, ticks_to_active):
			return true
		if rng.randf() < profile.dodge_bias * 0.5 and ticks_to_active - 1 - EVADE_TARGET >= 0:
			_schedule(Intent.Command.EVADE, ticks_to_active - 1 - EVADE_TARGET, 0, Plan.WAIT, 0, "evade")
			return true
	_set_plan(Plan.GUARD, guard_ticks, "guard")
	return true


func _try_spin_dodge(sim: MatchSimulation, me: FighterState, gap: float, ticks_to_active: int) -> bool:
	var delay: int = ticks_to_active - 1 - SPIN_TARGET
	if gap > sim.config.spin_dodge_range or delay < 0 or me.vigor < sim.config.spin_dodge_vigor:
		return false
	var behind: float = sim.config.half_width() + me.x * me.facing
	var chance: float = difficulty.spin_dodge_chance * (1.0 if behind <= difficulty.spin_dodge_corner else difficulty.spin_dodge_open_ratio)
	if rng.randf() >= chance:
		return false
	_schedule(Intent.Command.DODGE, delay, 0, Plan.WAIT, 0, "spin dodge")
	_press_direction = 1
	return true


func _ability_answers(me: FighterState, move: MoveData, ticks_to_active: int) -> bool:
	var ability: AbilityData = me.character.ability
	if ability == null or rng.randf() > profile.ability_bias * difficulty.defend_chance * 1.4:
		return false
	match ability.kind:
		AbilityData.Kind.STANCE:
			var window: int = Ticks.from_seconds(ability.stance_duration)
			if ticks_to_active < window - 2:
				_schedule(Intent.Command.SPECIAL, maxi(ticks_to_active - window + 4, 0), 0, Plan.WAIT, 0, "response stance")
				return true
		AbilityData.Kind.DASH:
			if ability.dash_through and move.is_heavy() and ticks_to_active > 3:
				_schedule(Intent.Command.SPECIAL, 0, 0, Plan.WAIT, 0, "dash through")
				return true
			if not ability.dash_through and ticks_to_active > 1:
				_schedule(Intent.Command.SPECIAL, maxi(ticks_to_active - 3, 0), 0, Plan.WAIT, 0, "reflex step")
				return true
		AbilityData.Kind.STRIKE:
			if ability.move.armor_hits > 0 and ticks_to_active > 2:
				_schedule(Intent.Command.SPECIAL, 0, 0, Plan.WAIT, 0, "armored strike")
				return true
	return false


func _try_ability(me: FighterState, opponent: FighterState, gap: float) -> bool:
	var ability: AbilityData = me.character.ability
	if ability == null or rng.randf() > profile.ability_bias * 0.35:
		return false
	var warning: int = Ticks.from_seconds(difficulty.attack_warning)
	match ability.kind:
		AbilityData.Kind.STRIKE:
			var move: MoveData = ability.move
			var reach: float = move.reach + move.lunge
			var minimum: float = 0.0 if move.hits_behind else me.character.heavy.reach * 0.6
			if gap <= reach and gap >= minimum and me.vigor >= move.vigor_cost:
				_schedule(Intent.Command.SPECIAL, warning, 0, Plan.WAIT, 0, "ability strike")
				return true
		AbilityData.Kind.CHARGE:
			if gap > profile.safe_gap * 0.6 and me.vigor >= ability.move.vigor_cost:
				_schedule(Intent.Command.SPECIAL, 0, 0, Plan.APPROACH, Ticks.from_seconds(1.0), "charge")
				_hold_command = Intent.Command.SPECIAL
				_hold_until_gap = ability.move.reach + ability.move.lunge * 0.5
				return true
		AbilityData.Kind.LEAP:
			if gap > 120.0 and gap < 360.0 and me.vigor >= ability.vigor_cost and opponent.is_alive():
				_schedule(Intent.Command.SPECIAL, warning, 0, Plan.WAIT, 0, "leap")
				return true
	return false


func _try_escape(sim: MatchSimulation, me: FighterState) -> bool:
	if me.state != FighterState.State.HIT or rng.randf() > difficulty.power_defense_chance * 0.5:
		return false
	var slot: int = AiPowers.escape_slot(sim, me)
	if slot == AiPowers.NO_SLOT:
		return false
	_schedule_power(me, slot, 0, "escape power")
	return true


func _try_flow_defense(sim: MatchSimulation, me: FighterState, opponent: FighterState) -> bool:
	var hazard: Hazard = AiPowers.hazard_threat(sim, me)
	if hazard != null and rng.randf() < difficulty.power_defense_chance * 1.5:
		if hazard.kind == Hazard.Kind.FRACTURE:
			_schedule(Intent.Command.JUMP, 0, 0, Plan.WAIT, 0, "jump fracture")
		else:
			_set_plan(Plan.RETREAT if absf(hazard.x - me.x) < absf(hazard.x - opponent.x) else Plan.APPROACH, AiPowers.THREAT_TICKS, "leave mark")
		return true
	var projectile: Projectile = AiPowers.projectile_threat(sim, me)
	if projectile != null and rng.randf() < difficulty.power_defense_chance * 1.5:
		if projectile.kind == Projectile.Kind.ROCK and rng.randf() < profile.dodge_bias:
			_schedule(Intent.Command.JUMP, 0, 0, Plan.WAIT, 0, "jump rock")
		else:
			_set_plan(Plan.GUARD, AiPowers.THREAT_TICKS, "guard projectile")
		return true
	var incoming: PowerData = AiPowers.incoming_power(opponent)
	if incoming == null or rng.randf() > difficulty.power_defense_chance:
		return false
	if incoming.kind == PowerData.Kind.FRACTURE:
		_schedule(Intent.Command.JUMP, incoming.startup_ticks() - opponent.power_ticks, 0, Plan.WAIT, 0, "jump fracture")
		return true
	var slot: int = AiPowers.guard_slot(sim, me, incoming)
	if slot != AiPowers.NO_SLOT:
		_schedule_power(me, slot, 0, "guard power")
		return true
	if incoming.guard_blocks:
		_set_plan(Plan.GUARD, incoming.startup_ticks() + Ticks.from_seconds(incoming.max_channel) + 6, "guard power")
		return true
	return false


func _try_power(sim: MatchSimulation, me: FighterState, opponent: FighterState, gap: float) -> bool:
	if rng.randf() > difficulty.power_chance * lerpf(0.4, 1.6, profile.power_bias):
		return false
	var slot: int = AiPowers.offensive_slot(sim, me, opponent, gap, difficulty.save_for_fourth)
	if slot == AiPowers.NO_SLOT:
		return false
	_schedule_power(me, slot, Ticks.from_seconds(difficulty.attack_warning), "power " + String(me.powers[slot].id))
	return true


func _try_technique(sim: MatchSimulation, me: FighterState, gap: float) -> bool:
	if not sim.rules.powers or me.character.technique_forward == null or rng.randf() > profile.technique_bias * 0.4:
		return false
	var options: Array[MoveData] = [me.character.technique_forward, me.character.technique_back]
	var pick: int = rng.randi_range(0, options.size() - 1)
	var technique: MoveData = options[pick]
	if technique == null or me.vigor < technique.vigor_cost:
		return false
	var reach: float = technique.reach + technique.lunge
	if technique.throws_blade:
		reach = sim.config.flow.blade_throw_base
	elif technique.projectile_range > 0.0:
		reach = technique.projectile_range
	if gap > reach or gap < reach * 0.3:
		return false
	_schedule(Intent.Command.SPECIAL, Ticks.from_seconds(difficulty.attack_warning), 0, Plan.WAIT, 0, "technique " + String(technique.id))
	_press_direction = 1 if pick == 0 else -1
	return true


func _schedule_power(me: FighterState, slot: int, delay: int, label: String) -> void:
	var command: int = Intent.Command.POWER
	if slot == FighterState.FOURTH_SLOT:
		command |= Intent.Command.SPECIAL
	_schedule(command, delay, 0, Plan.WAIT, 0, label)
	_press_direction = AiPowers.direction_for(slot)
	_channel_ticks = AiPowers.hold_ticks(me.powers[slot])


func _think_in_air(me: FighterState, opponent: FighterState) -> void:
	if not ActionStarter.can_attack_in_air(me):
		return
	var dx: float = absf(opponent.x - me.x)
	if dx < 120.0 and me.y > opponent.y + 20.0:
		var command: int = Intent.Command.HEAVY if rng.randf() < profile.heavy_ratio or me.vy < 0.0 else Intent.Command.LIGHT
		_schedule(command, 0, 0, Plan.WAIT, 0, "aerial")


func _answer_shove(me: FighterState, gap: float, ticks_to_active: int) -> bool:
	var light: MoveData = me.character.light_chain[0]
	if gap <= light.reach and ticks_to_active > light.startup_ticks() and me.vigor >= light.vigor_cost:
		_schedule(Intent.Command.LIGHT, 0, 0, Plan.WAIT, 0, "beat shove")
	else:
		_set_plan(Plan.RETREAT, ticks_to_active + 4, "avoid shove")
	return true


func _try_punish(sim: MatchSimulation, me: FighterState, opponent: FighterState, gap: float) -> bool:
	var light: MoveData = me.character.light_chain[0]
	var heavy: MoveData = me.character.heavy
	var opening: int = _opening_ticks(sim, opponent)
	if opening <= light.startup_ticks():
		return false
	if gap > light.reach + light.lunge:
		if opponent.state == FighterState.State.STUNNED:
			_set_plan(Plan.APPROACH, Ticks.from_seconds(difficulty.reaction_time), "close in")
			return true
		return false
	if opponent.state == FighterState.State.STAGGERED and opponent.stagger_counterable:
		_schedule(Intent.Command.LIGHT, 0, 0, Plan.WAIT, 0, "counter")
	elif _heavy_fits(me, heavy, opening, gap) and (opponent.state == FighterState.State.STUNNED or difficulty.smart_punish):
		_schedule(Intent.Command.HEAVY, 0, 0, Plan.WAIT, 0, "punish heavy")
	else:
		_schedule(Intent.Command.LIGHT, 0, 0, Plan.WAIT, 0, "punish")
		_chain_left = me.character.light_chain.size() - 1
	return true


func _opening_ticks(sim: MatchSimulation, opponent: FighterState) -> int:
	match opponent.state:
		FighterState.State.STAGGERED, FighterState.State.STUNNED:
			return opponent.stun_ticks
		FighterState.State.ATTACKING, FighterState.State.HEAVY_ATTACK:
			if opponent.move_phase == FighterState.Phase.RECOVERY:
				return opponent.ticks_left_in_move()
		FighterState.State.DODGING:
			if opponent.dodge_kind == FighterState.DodgeKind.EVADE and opponent.evade_window_ticks == 0:
				return Ticks.from_seconds(sim.config.evade_duration) - opponent.state_ticks
	return 0


func _heavy_fits(me: FighterState, heavy: MoveData, opening: int, gap: float) -> bool:
	return me.vigor >= heavy.vigor_cost and opening >= heavy.startup_ticks() + 2 and gap <= heavy.reach + heavy.lunge


func _try_shove(me: FighterState, opponent: FighterState, gap: float) -> bool:
	if opponent.state != FighterState.State.BLOCKING:
		return false
	var shove: MoveData = me.character.shove
	var chance: float = difficulty.shove_chance * lerpf(0.5, 1.5, profile.shove_bias)
	chance += difficulty.habit_weight * memory.guard_share()
	if rng.randf() > chance or me.vigor < shove.vigor_cost:
		return false
	if gap > shove.reach + shove.lunge:
		_set_plan(Plan.APPROACH, Ticks.from_seconds(difficulty.reaction_time), "close to shove")
		return true
	_schedule(Intent.Command.LIGHT, 0, Intent.Command.BLOCK, Plan.WAIT, 0, "shove")
	return true


func _try_recover(me: FighterState, gap: float) -> bool:
	if me.vigor_ratio() >= profile.low_vigor_ratio or gap >= profile.safe_gap:
		return false
	_set_plan(Plan.RETREAT, Ticks.from_seconds(difficulty.reaction_time * 2.0), "recover")
	return true


func _try_attack(me: FighterState, gap: float) -> bool:
	var light: MoveData = me.character.light_chain[0]
	var heavy: MoveData = me.character.heavy
	if gap > light.reach + light.lunge:
		return false
	if rng.randf() > lerpf(0.3, 1.0, profile.aggression):
		return false
	var warning: int = Ticks.from_seconds(difficulty.attack_warning)
	var wants_heavy: bool = rng.randf() < profile.heavy_ratio and me.vigor >= heavy.vigor_cost
	if wants_heavy:
		_schedule(Intent.Command.HEAVY, warning, 0, Plan.WAIT, 0, "heavy")
		var feint_chance: float = profile.feint_bias * (0.5 + difficulty.habit_weight + memory.guard_share())
		if me.character.can_feint and rng.randf() < feint_chance:
			_followup_command = Intent.Command.BLOCK
			_followup_delay = warning + int(heavy.startup_ticks() * 0.5)
			decision = "feint"
	elif me.vigor >= light.vigor_cost:
		_schedule(Intent.Command.LIGHT, warning, 0, Plan.WAIT, 0, "light")
		_chain_left = rng.randi_range(0, me.character.light_chain.size() - 1)
	else:
		_set_plan(Plan.GUARD, Ticks.from_seconds(difficulty.reaction_time), "guard, no vigor")
	return true


func _position(me: FighterState, opponent: FighterState, gap: float) -> void:
	var think_ticks: int = Ticks.from_seconds(difficulty.reaction_time)
	var light: MoveData = me.character.light_chain[0]
	if gap > profile.preferred_gap + light.reach * 0.5:
		if rng.randf() < profile.patience * 0.5:
			_set_plan(Plan.WAIT, think_ticks, "study")
		else:
			_set_plan(Plan.APPROACH, think_ticks, "approach")
	elif gap < profile.preferred_gap * 0.5 and rng.randf() < profile.patience:
		_set_plan(Plan.RETREAT, think_ticks, "space")
	elif opponent.is_free() and rng.randf() < profile.defense * 0.5:
		_set_plan(Plan.GUARD, think_ticks, "anticipate")
	else:
		_set_plan(Plan.WAIT, think_ticks, "wait")


func _make_mistake() -> void:
	var plans: Array[Plan] = [Plan.WAIT, Plan.APPROACH, Plan.RETREAT]
	_set_plan(plans[rng.randi_range(0, plans.size() - 1)], Ticks.from_seconds(difficulty.reaction_time), "mistake")
	if rng.randf() < profile.aggression:
		_schedule(Intent.Command.LIGHT, 0, 0, _plan, _plan_ticks, "mistake swing")


func _set_plan(plan: Plan, ticks: int, label: String) -> void:
	_plan = plan
	_plan_ticks = ticks
	_press_command = 0
	_press_direction = 0
	_chain_left = 0
	decision = label


func _schedule(command: int, delay: int, extra_hold: int, after_plan: Plan, after_ticks: int, label: String) -> void:
	_set_plan(Plan.WAIT, delay, label)
	_press_command = command
	_press_hold = extra_hold
	_press_delay = delay
	_after_press_plan = after_plan
	_after_press_ticks = after_ticks


func _execute(me: FighterState, opponent: FighterState, sim: MatchSimulation, intent: Intent) -> void:
	_execute_holds(me, opponent, sim, intent)
	match _plan:
		Plan.APPROACH:
			intent.move_x = me.facing
		Plan.RETREAT:
			intent.move_x = -me.facing
		Plan.GUARD:
			intent.hold(Intent.Command.BLOCK)
	if _press_command != 0:
		if _press_delay > 0:
			_press_delay -= 1
		else:
			intent.pressed |= _press_command
			intent.held |= _press_command | _press_hold
			if _press_direction != 0:
				intent.move_x = me.facing * _press_direction
				_press_direction = 0
			_press_command = 0
			_plan = _after_press_plan
			_plan_ticks = _after_press_ticks
	_continue_chain(me, intent)
	_plan_ticks -= 1
	if _plan_ticks <= 0 and _press_command == 0:
		_plan = Plan.WAIT


func _execute_holds(me: FighterState, opponent: FighterState, sim: MatchSimulation, intent: Intent) -> void:
	if _channel_ticks > 0 and _press_command == 0:
		_channel_ticks -= 1
		if me.is_casting():
			intent.hold(Intent.Command.POWER)
	if _followup_command != 0 and _press_command == 0:
		_followup_delay -= 1
		if _followup_delay <= 0:
			intent.press(_followup_command)
			_followup_command = 0
	if _hold_command == 0:
		return
	var gap: float = CombatGeometry.gap(sim.config, me, opponent)
	if not me.is_attacking() and _press_command == 0:
		_hold_command = 0
		return
	if gap <= _hold_until_gap or not opponent.is_alive():
		_hold_command = 0
		return
	intent.hold(_hold_command)


func _try_disengage(sim: MatchSimulation, me: FighterState, intent: Intent) -> bool:
	if not BladeLockResolver.can_disengage(sim) or sim.lock_ticks % DISENGAGE_THINK_TICKS != 0:
		return false
	var losing: bool = me.lock_presses < sim.opponent_of(me).lock_presses
	if not losing or me.vigor < BladeLockConfig.DISENGAGE_MOVE.vigor_cost or rng.randf() >= difficulty.disengage_chance:
		return false
	intent.press(Intent.Command.HEAVY)
	decision = "disengage"
	return true


func _continue_chain(me: FighterState, intent: Intent) -> void:
	if _chain_left <= 0 or me.move == null:
		return
	if me.move.kind == MoveData.Kind.LIGHT and me.move_connected and me.move_phase == FighterState.Phase.RECOVERY:
		intent.press(Intent.Command.LIGHT)
		_chain_left -= 1


func _press_in_lock(sim: MatchSimulation, me: FighterState, intent: Intent) -> void:
	if sim.lock_ticks < Ticks.from_seconds(difficulty.lock_reaction):
		return
	if _try_disengage(sim, me, intent):
		return
	_lock_press_ticks -= 1
	if _lock_press_ticks > 0:
		return
	intent.press(Intent.Command.LIGHT)
	var interval: float = Ticks.RATE / difficulty.lock_presses_per_second
	_lock_press_ticks = maxi(roundi(interval * (0.85 + rng.randf() * 0.3)), 1)
