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
@export var repulse_palm_offset: float = 30.0
@export var repulse_dust: int = 8
@export var fracture_chunks: int = 5
@export var fracture_dust: int = 3
@export var shove_dust: int = 3

@export_group("Flow cleave")
@export var cleave_height: float = 170.0
@export var cleave_base_width: float = 26.0
@export var cleave_tip_width: float = 3.0
@export var cleave_bow: float = 26.0
@export var cleave_ground_sparks: int = 2

@export_group("Mass telekinesis")
@export var mass_rise: float = 0.2
@export var mass_hold: float = 0.14
@export var mass_descend: float = 0.22
@export var mass_sky_offset: float = 560.0
@export var meteor_height: float = 820.0
@export var meteor_radius: float = 52.0
@export var meteor_pull: float = 260.0
@export var meteor_crack: float = 0.28
@export var rain_chunks: int = 7
@export var rain_dust: int = 4

@export_group("Storm sky")
@export var sky_top: float = -760.0
@export var sky_horizon: float = -190.0
@export var sky_clouds: int = 6
@export var sky_bolt_interval: float = 0.32
@export var sky_bolt_life: float = 0.24
@export var sky_flash: float = 0.35
@export var sky_fade: float = 2.5
