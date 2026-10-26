class_name CombatConfig
extends Resource

@export var blade_lock: BladeLockConfig
@export var consequences: ConsequenceConfig
@export var flow: FlowConfig

@export_group("Arena")
@export var arena_width: float = 1200.0
@export var body_width: float = 46.0
@export var body_height: float = 150.0
@export var round_start_distance: float = 440.0

@export_group("Attributes")
@export var attribute_neutral: int = 4
@export var attribute_step: float = 0.08
@export var health_base: float = 100.0
@export var vigor_base: float = 100.0

@export_group("Movement")
@export var walk_speed: float = 260.0
@export var back_walk_ratio: float = 0.72
@export var ground_acceleration: float = 2200.0
@export var ground_deceleration: float = 2800.0
@export var air_acceleration: float = 900.0
@export var gravity: float = 2400.0
@export var max_fall_speed: float = 1400.0
@export var jump_velocity: float = 820.0

@export_group("Input")
@export var input_buffer: float = 0.15

@export_group("Vigor")
@export var vigor_regen: float = 25.0
@export var vigor_regen_delay: float = 0.6
@export var block_regen_ratio: float = 0.4
@export var defense_reserve_per_point: float = 4.0

@export_group("Parry")
@export var perfect_parry_window: float = 0.08
@export var parry_window: float = 0.20
@export var perfect_parry_blade_bonus: float = 0.05
@export var parry_lockout: float = 0.4
@export var perfect_parry_vigor_gain: float = 15.0
@export var perfect_parry_stagger: float = 0.5

@export_group("Shove")
@export var shove_vigor_loss: float = 20.0
@export var shove_stagger: float = 0.35

@export_group("Dodge")
@export var dodge_vigor: float = 20.0
@export var dodge_duration: float = 0.28
@export var dodge_invulnerable: float = 0.18
@export var dodge_distance: float = 170.0
@export var air_dash_duration: float = 0.18
@export var air_dash_distance: float = 190.0
@export var air_dash_lift: float = 280.0
@export var evade_invulnerable: float = 0.066
@export var evade_duration: float = 0.4
@export var evade_step: float = 14.0
@export var spin_dodge_range: float = 60.0
@export var spin_dodge_vigor: float = 28.0
@export var spin_dodge_duration: float = 0.34
@export var spin_dodge_invulnerable_start: float = 0.04
@export var spin_dodge_invulnerable_end: float = 0.14
@export var spin_dodge_recovery: float = 0.16
@export var spin_dodge_clearance: float = 8.0

@export_group("Traits")
@export var sweet_spot_tip_ratio: float = 0.667
@export var sweet_spot_tip_multiplier: float = 1.5
@export var sweet_spot_close_ratio: float = 0.25
@export var sweet_spot_close_multiplier: float = 0.6
@export var feint_vigor: float = 12.0
@export var wall_jump_speed: float = 380.0
@export var wall_contact: float = 6.0

@export_group("Clash")
@export var clash_window: float = 0.067
@export var heavy_clash_window: float = 0.15
@export var clash_light_separation: float = 120.0
@export var clash_heavy_separation: float = 280.0
@export var clash_heavy_recoil: float = 0.25

@export_group("Hit stop")
@export var hitstop_light: float = 0.04
@export var hitstop_heavy: float = 0.08
@export var hitstop_block: float = 0.03
@export var hitstop_parry: float = 0.07
@export var hitstop_perfect_parry: float = 0.10
@export var hitstop_guard_break: float = 0.10
@export var hitstop_clash: float = 0.10

@export_group("Slow motion")
@export var knockout_slow_motion_scale: float = 0.3
@export var knockout_slow_motion: float = 0.8
@export var perfect_parry_slow_motion_scale: float = 0.5
@export var perfect_parry_slow_motion: float = 0.25

@export_group("Replay")
@export var replay_speed: float = 0.45
@export var replay_length: float = 3.5
@export var replay_tail: float = 1.0
@export var replay_blade_return_limit: float = 3.0

@export_group("Match")
@export var round_intro: float = 1.6
@export var match_intro: float = 3.6
@export var match_intro_title: float = 1.0
@export var ko_duration: float = 2.6
@export var endless_refill_delay: float = 1.5


func attribute_multiplier(rating: int) -> float:
	return 1.0 + float(rating - attribute_neutral) * attribute_step


func half_width() -> float:
	return arena_width * 0.5


func slide_speed_for(distance: float) -> float:
	return sqrt(2.0 * ground_deceleration * maxf(distance, 0.0))
