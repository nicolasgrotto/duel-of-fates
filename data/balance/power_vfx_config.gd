class_name PowerVfxConfig
extends Resource

@export_group("Debris")
@export var plunge_dust: int = 6
@export var plunge_chunks: int = 3
@export var dust_life: float = 0.6
@export var dust_rise: float = 40.0
@export var dust_size: float = 10.0
@export var chunk_gravity: float = 1500.0
@export var chunk_life: float = 0.9
@export var chunk_bounce: float = 0.35

@export_group("Throw")
@export var dual_throw_delay: float = 0.06
@export var dual_throw_arc: float = 26.0
@export var thrown_blade_spin: float = 22.0
@export var throw_rise_height: float = 46.0
@export var throw_rise_dust: int = 4
@export var throw_impact_chunks: int = 6

@export_group("Repulse and fracture")
@export var repulse_wave_time: float = 0.38
@export var repulse_travel_share: float = 0.8
@export var repulse_start_height: float = 72.0
@export var repulse_end_height: float = 156.0
@export var repulse_tier_height: float = 8.0
@export var repulse_width: float = 12.0
@export var repulse_tier_width: float = 2.0
@export var repulse_bow_ratio: float = 0.22
@export var repulse_edge_width: float = 2.0
@export var repulse_edge_light: float = 0.6
@export var repulse_band_alpha: PackedFloat32Array = PackedFloat32Array([0.34, 0.2, 0.1])
@export var repulse_echo_tier: int = 2
@export var repulse_echo_spacing: float = 18.0
@export var repulse_echo_alpha: float = 0.28
@export var repulse_ground_streaks: int = 3
@export var repulse_streak_length: float = 26.0
@export var repulse_streak_gap: float = 6.0
@export var repulse_streak_alpha: float = 0.24
@export var repulse_reduced_alpha: float = 0.7
@export var pull_orb_radius: float = 46.0
@export var pull_orb_time: float = 0.22
@export var pull_orb_core: float = 0.35
@export var pull_orb_tier_growth: float = 0.12
@export var repulse_dust: int = 8
@export var repulse_reduced_dust: int = 2
@export var fracture_chunks: int = 5
@export var fracture_dust: int = 3
@export var shove_dust: int = 3

@export_group("Lightning")
@export var lightning_finger_gap: float = 4.0
@export var lightning_target_gap: float = 26.0
@export var lightning_fan_bow: float = 14.0
@export var lightning_phase_step: float = 0.017

@export_group("Projected cut")
@export var cleave_height: float = 170.0
@export var cleave_base_width: float = 26.0
@export var cleave_tip_width: float = 3.0
@export var cleave_bow: float = 26.0
@export var cleave_ground_sparks: int = 2

@export_group("Mass telekinesis")
@export var mass_rise: float = 0.45
@export var mass_hold: float = 0.6
@export var mass_descend: float = 0.45
@export var mass_sky_offset: float = 560.0
@export var meteor_height: float = 820.0
@export var meteor_radius: float = 52.0
@export var meteor_pull: float = 260.0
@export var meteor_crack: float = 0.95
@export var rain_chunks: int = 7
@export var rain_dust: int = 4

@export_group("Storm shield")
@export var storm_shell: Vector2 = Vector2(44.0, 86.0)
@export var storm_tier_growth: float = 0.08
@export var storm_fill_alpha: float = 0.06
@export var storm_shell_alpha: PackedFloat32Array = PackedFloat32Array([0.5, 0.26, 0.12])
@export var storm_shell_spacing: float = 6.0
@export var storm_flicker_rate: float = 14.0
@export var storm_arcs: int = 5
@export var storm_arc_span: float = 0.7
@export var storm_arc_speed: float = 3.2
@export var storm_arc_jitter: float = 5.0
@export var storm_ground_sparks: int = 3
@export var storm_bolt_glow: float = 0.5

@export_group("Storm sky")
@export var sky_top: float = -760.0
@export var sky_horizon: float = -190.0
@export var sky_clouds: int = 6
@export var sky_bolt_interval: float = 0.32
@export var sky_bolt_life: float = 0.24
@export var sky_flash: float = 0.35
@export var sky_fade: float = 2.5


@export_group("Higher instinct")
@export var instinct_letterbox: float = 0.3
@export var instinct_tier_tint: float = 0.18
@export var instinct_aura: Vector2 = Vector2(34.0, 84.0)
@export var instinct_aura_width: float = 2.0
@export var instinct_aura_alpha: float = 0.36
@export var instinct_flicker_rate: float = 8.0
@export var instinct_points: int = 4
@export var instinct_eye_size: Vector2 = Vector2(4.0, 2.0)
@export var instinct_lean: float = 24.0
@export var instinct_shift: float = 12.0
@export var instinct_step: float = 14.0
@export var instinct_slide: float = 20.0
