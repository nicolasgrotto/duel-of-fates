class_name FighterState
extends RefCounted

enum State {
	IDLE,
	WALKING,
	JUMPING,
	ATTACKING,
	HEAVY_ATTACK,
	BLOCKING,
	DODGING,
	BLADE_LOCK,
	HIT,
	STAGGERED,
	STUNNED,
	DEAD,
	CASTING,
	CHANNELING,
	HELD,
}
enum Phase { NONE, STARTUP, ACTIVE, RECOVERY }
enum DodgeKind { NONE, GROUND, AIR, EVADE, DASH, SPIN }
enum Action { NONE, JUMP, BLOCK, LIGHT, HEAVY, SHOVE, EVADE, DODGE, SPECIAL, POWER, FOURTH }
enum SingularityPhase { NONE, SUSPENSION, EXTRACTION, FORMATION, THROW }
enum InstinctMotion { LEAN, STEP_BACK, TURN, SLIDE }
enum Wound { NONE, ARM, LEG }

const NO_PARRY: int = -1
const POWER_SLOTS: int = 4
const FOURTH_SLOT: int = 3

var index: int = 0
var character: CharacterData
var hold_to_lock: bool = false

var max_health: float = 100.0
var max_vigor: float = 100.0
var walk_speed: float = 260.0
var jump_velocity: float = 820.0
var vigor_regen: float = 25.0
var blade_multiplier: float = 1.0
var defense_multiplier: float = 1.0
var agility_multiplier: float = 1.0
var guard_reserve: float = 0.0
var perfect_parry_ticks: int = 5
var parry_window_ticks: int = 12

var health: float = 100.0
var vigor: float = 100.0
var regen_delay_ticks: int = 0

var x: float = 0.0
var y: float = 0.0
var vx: float = 0.0
var vy: float = 0.0
var facing: int = 1
var on_ground: bool = true

var state: State = State.IDLE
var state_ticks: int = 0
var stun_ticks: int = 0
var bolt_immunity_ticks: int = 0
var freeze_ticks: int = 0

var move: MoveData
var move_phase: Phase = Phase.NONE
var phase_ticks: int = 0
var move_hit_done: bool = false
var move_connected: bool = false
var chain_index: int = 0
var bolts_left: int = 0
var bolt_ticks: int = 0
var sidearm_out: bool = false
var sidearm_guard_ticks: int = 0

var dodge_kind: DodgeKind = DodgeKind.NONE
var dodge_direction: int = 0
var dodge_travel: float = 0.0
var invulnerable_ticks: int = 0
var evade_window_ticks: int = 0
var evade_succeeded: bool = false
var evade_streak: int = 0

var parry_ticks: int = NO_PARRY
var parry_lockout_ticks: int = 0

var buffered_action: Action = Action.NONE
var buffered_direction: int = 0
var buffer_ticks: int = 0
var chord_command: int = 0
var chord_ticks: int = 0
var chord_direction: int = 0
var input_idle: bool = true

var jumps_used: int = 0
var air_dash_used: bool = false
var air_attacks: int = 0
var last_wall: int = 0
var leap_dive: bool = false

var exhausted: bool = false
var exhausted_ticks: int = 0
var wound: Wound = Wound.NONE
var wounded_this_round: bool = false

var lock_presses: int = 0
var lock_press_cooldown: int = 0
var lock_hold_ticks: int = 0
var lock_press: bool = false

var stagger_counterable: bool = false
var armor_used: int = 0
var charge_ticks: int = 0
var charge_level: int = 0
var combo_taken: int = 0
var ticks_since_damage: int = 0
var round_wins: int = 0

var recovery_cut: int = -1
var multi_hit_ticks: int = 0

var powers: Array[PowerData] = [null, null, null, null]
var flow: float = 0.0
var flow_level: int = 4
var flow_tier: int = 1
var flow_potency: float = 1.0
var power: PowerData
var power_phase: Phase = Phase.NONE
var power_ticks: int = 0
var power_slot: int = 0
var power_escape: bool = false
var power_cooldown: int = 0
var power_cooldowns: PackedInt32Array = PackedInt32Array([0, 0, 0, 0])
var pulse_ticks: int = 0
var spawned: int = 0
var heal_ticks: int = 0
var heal_per_tick: float = 0.0
var singularity_ticks: int = 0
var singularity_elapsed: int = 0
var singularity_phase: SingularityPhase = SingularityPhase.NONE
var singularity_wave: int = 0
var singularity_mass: int = 0
var singularity_throw_ticks: int = 0
var singularity_center: Vector2 = Vector2.ZERO
var singularity_aim: Vector2 = Vector2.ZERO
var singularity_power: PowerData
var instinct_ticks: int = 0
var instinct_counter_ticks: int = 0
var instinct_evade_ticks: int = 0
var instinct_motion: InstinctMotion = InstinctMotion.LEAN
var instinct_power: PowerData
var focus_ticks: int = 0
var wrath_ticks: int = 0
var wrath_armor: int = 0
var sanctuary_ticks: int = 0
var sanctuary_hp: float = 0.0
var twisted_ticks: int = 0
var held_ticks: int = 0
var held_by_choke: bool = false
var arsenal_count: int = 0
var arsenal_ticks: int = 0
var rain_ticks: int = 0
var blade_out: bool = false

var finisher_limb: MoveData.Limb = MoveData.Limb.NONE
var finisher_from_front: bool = true
var finisher_kind: Finisher.Kind = Finisher.Kind.NONE


func setup(fighter_index: int, data: CharacterData, config: CombatConfig) -> void:
	index = fighter_index
	character = data
	max_health = config.health_base * config.attribute_multiplier(data.health)
	max_vigor = config.vigor_base * config.attribute_multiplier(data.vigor)
	vigor_regen = config.vigor_regen * config.attribute_multiplier(data.vigor)
	blade_multiplier = config.attribute_multiplier(data.blade) * data.blade_damage_multiplier
	defense_multiplier = config.attribute_multiplier(data.defense)
	agility_multiplier = config.attribute_multiplier(data.agility)
	guard_reserve = maxf(data.defense - config.attribute_neutral, 0) * config.defense_reserve_per_point
	walk_speed = config.walk_speed * agility_multiplier
	jump_velocity = config.jump_velocity * agility_multiplier
	if data.max_health_override > 0.0:
		max_health = data.max_health_override
	var base_perfect: float = data.perfect_parry_window if data.perfect_parry_window > 0.0 else config.perfect_parry_window
	var perfect_window: float = base_perfect + (config.attribute_multiplier(data.blade) - 1.0) * config.perfect_parry_blade_bonus
	perfect_parry_ticks = Ticks.from_seconds(perfect_window)
	parry_window_ticks = Ticks.from_seconds(data.parry_window if data.parry_window > 0.0 else config.parry_window)
	flow_level = data.flow
	flow_potency = config.attribute_multiplier(data.flow)
	flow_tier = config.flow.tier_for(data.flow)
	for slot in POWER_SLOTS:
		powers[slot] = null
	for slot in mini(data.powers.size(), FOURTH_SLOT):
		powers[slot] = data.powers[slot]
	powers[FOURTH_SLOT] = data.fourth_power


func equip_powers(chosen: Array[PowerData]) -> void:
	for slot in mini(chosen.size(), FOURTH_SLOT):
		powers[slot] = chosen[slot]


func set_flow_level(level: int, config: CombatConfig) -> void:
	flow_level = level
	flow_potency = config.attribute_multiplier(level)
	flow_tier = config.flow.tier_for(level)


func is_casting() -> bool:
	return state == State.CASTING or state == State.CHANNELING


func power_kind_active(kind: PowerData.Kind) -> bool:
	return state == State.CHANNELING and power != null and power.kind == kind


func is_airborne() -> bool:
	return not on_ground


func is_attacking() -> bool:
	return state == State.ATTACKING or state == State.HEAVY_ATTACK


func is_active() -> bool:
	return is_attacking() and move_phase == Phase.ACTIVE


func is_free() -> bool:
	return state == State.IDLE or state == State.WALKING


func is_alive() -> bool:
	return state != State.DEAD


func is_air_dashing() -> bool:
	return state == State.DODGING and dodge_kind == DodgeKind.AIR


func is_invulnerable() -> bool:
	return invulnerable_ticks > 0


func vigor_ratio() -> float:
	return vigor / max_vigor if max_vigor > 0.0 else 0.0


func health_ratio() -> float:
	return health / max_health if max_health > 0.0 else 0.0


func ticks_left_in_move() -> int:
	if move == null:
		return 0
	match move_phase:
		Phase.STARTUP:
			return move_startup_ticks() + move.active_ticks() + move_recovery_ticks() - phase_ticks
		Phase.ACTIVE:
			return move.active_ticks() + move_recovery_ticks() - phase_ticks
		Phase.RECOVERY:
			return move_recovery_ticks() - phase_ticks
	return 0


func carried_blaster() -> BlasterData:
	return character.weapon.blaster if character.weapon.sidearm == WeaponData.Sidearm.HOLSTER else null


func draws_sidearm() -> bool:
	return move != null and move.draws_sidearm and carried_blaster() != null


func move_startup_ticks() -> int:
	return move.startup_ticks() + (carried_blaster().draw_ticks() if draws_sidearm() else 0)


func move_recovery_ticks() -> int:
	return move.recovery_ticks() + (carried_blaster().holster_ticks() if draws_sidearm() else 0)


func move_shot_count() -> int:
	var blaster: BlasterData = carried_blaster()
	return blaster.shot_count if blaster != null and blaster.shot_count > 0 else move.shot_count


func vigor_cost_of(attack: MoveData) -> float:
	var blaster: BlasterData = carried_blaster()
	return attack.vigor_cost * blaster.vigor_multiplier if attack.draws_sidearm and blaster != null else attack.vigor_cost


func move_bolt() -> BoltData:
	if draws_sidearm():
		return carried_blaster().bolt
	return move.bolt if move != null else null


func sidearm_guard_multiplier() -> float:
	var blaster: BlasterData = carried_blaster()
	return blaster.guard_cost_multiplier if blaster != null and (sidearm_out or sidearm_guard_ticks > 0) else 1.0


func reset_for_round(start_x: float, start_facing: int) -> void:
	health = max_health
	vigor = max_vigor
	regen_delay_ticks = 0
	x = start_x
	y = 0.0
	vx = 0.0
	vy = 0.0
	facing = start_facing
	on_ground = true
	state = State.IDLE
	state_ticks = 0
	stun_ticks = 0
	bolt_immunity_ticks = 0
	freeze_ticks = 0
	clear_move()
	sidearm_guard_ticks = 0
	chain_index = 0
	dodge_kind = DodgeKind.NONE
	invulnerable_ticks = 0
	evade_window_ticks = 0
	evade_streak = 0
	parry_ticks = NO_PARRY
	parry_lockout_ticks = 0
	buffered_action = Action.NONE
	buffer_ticks = 0
	jumps_used = 0
	air_dash_used = false
	air_attacks = 0
	last_wall = 0
	leap_dive = false
	exhausted = false
	exhausted_ticks = 0
	wound = Wound.NONE
	wounded_this_round = false
	lock_presses = 0
	lock_press_cooldown = 0
	lock_hold_ticks = 0
	stagger_counterable = false
	combo_taken = 0
	ticks_since_damage = 0
	finisher_limb = MoveData.Limb.NONE
	finisher_from_front = true
	finisher_kind = Finisher.Kind.NONE
	buffered_direction = 0
	chord_command = 0
	chord_ticks = 0
	recovery_cut = -1
	multi_hit_ticks = 0
	power = null
	power_phase = Phase.NONE
	power_ticks = 0
	power_cooldown = 0
	power_cooldowns = PackedInt32Array([0, 0, 0, 0])
	pulse_ticks = 0
	spawned = 0
	heal_ticks = 0
	heal_per_tick = 0.0
	singularity_ticks = 0
	singularity_elapsed = 0
	singularity_phase = SingularityPhase.NONE
	singularity_wave = 0
	singularity_mass = 0
	singularity_throw_ticks = 0
	singularity_center = Vector2.ZERO
	singularity_aim = Vector2.ZERO
	singularity_power = null
	instinct_ticks = 0
	instinct_counter_ticks = 0
	instinct_evade_ticks = 0
	instinct_motion = InstinctMotion.LEAN
	instinct_power = null
	focus_ticks = 0
	wrath_ticks = 0
	wrath_armor = 0
	sanctuary_ticks = 0
	sanctuary_hp = 0.0
	twisted_ticks = 0
	held_ticks = 0
	held_by_choke = false
	arsenal_count = 0
	arsenal_ticks = 0
	rain_ticks = 0
	blade_out = false


func clear_move() -> void:
	sidearm_out = false
	move = null
	move_phase = Phase.NONE
	phase_ticks = 0
	move_hit_done = false
	move_connected = false
	armor_used = 0
	charge_ticks = 0
	charge_level = 0
	recovery_cut = -1
	multi_hit_ticks = 0
	bolts_left = 0
	bolt_ticks = 0


func capture() -> Dictionary:
	var snapshot: Dictionary = {}
	for property in get_property_list():
		if property["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
			var value: Variant = get(property["name"])
			if value is Array or value is PackedInt32Array:
				value = value.duplicate()
			snapshot[property["name"]] = value
	return snapshot


func restore(snapshot: Dictionary) -> void:
	for key in snapshot:
		var value: Variant = snapshot[key]
		if value is Array or value is PackedInt32Array:
			value = value.duplicate()
		set(key, value)
