class_name EffectsConfig
extends Resource

@export_group("Recipes")
@export var hit_light: EffectRecipe
@export var hit_heavy: EffectRecipe
@export var block: EffectRecipe
@export var guard_break: EffectRecipe
@export var clash: EffectRecipe
@export var parry: EffectRecipe
@export var perfect_parry: EffectRecipe
@export var shove: EffectRecipe
@export var blade_lock_start: EffectRecipe
@export var blade_lock_press: EffectRecipe
@export var blade_lock_end: EffectRecipe
@export var knockout: EffectRecipe
@export var evade: EffectRecipe
@export var power_hit: EffectRecipe
@export var power_blocked: EffectRecipe
@export var hazard: EffectRecipe
@export var technique_clash: EffectRecipe
@export var plunge_impact: EffectRecipe
@export var blade_press_start: EffectRecipe
@export var blade_press_end: EffectRecipe
@export var disengage: EffectRecipe

@export_group("Sparks")
@export var spark_life: float = 0.32
@export var spark_gravity: float = 1400.0
@export var spark_drag: float = 2.5
@export var spark_length: float = 0.022
@export var ring_duration: float = 0.25
@export var blade_contact_snap: float = 40.0

@export_group("Framing")
@export var fighter_screen_ratio: float = 0.27
@export var ground_screen_ratio: float = 0.8
@export var framing_margin: float = 330.0
@export var arena_margin: float = 160.0
@export var follow_speed: float = 6.0
@export var zoom_speed: float = 3.0
@export var jump_follow: float = 0.35

@export_group("Camera")
@export var punch_in_return: float = 0.25
@export var flash_decay: float = 0.18
@export var hit_flash_duration: float = 0.06
@export var reduced_motion_scale: float = 0.25
@export var reduced_spark_scale: float = 0.5

@export_group("Blade")
@export var ignition: float = 0.3
@export var extinguish: float = 0.45
@export var trail_duration: float = 0.12
@export var parry_flare: float = 0.15

@export_group("Fighter intros")
@export var hood_lower_time: float = 0.4
@export var hood_lower_offset: Vector2 = Vector2(-6.0, 18.0)
@export var cloak_fling: Vector2 = Vector2(100.0, -90.0)
@export var cloak_fade_time: float = 0.8

@export_group("Finishers")
@export var finisher_hold: float = 0.35
@export var finisher_slide_time: float = 0.45
@export var finisher_slide_distance: float = 18.0
@export var finisher_topple_speed: float = 2.6
@export var finisher_drop_gravity: float = 900.0
@export var finisher_lower_delay: float = 0.6
@export var finisher_fling_speed: Vector2 = Vector2(380.0, -260.0)
@export var finisher_fling_gravity: float = 1400.0
@export var finisher_fling_spin: float = 7.0
@export var finisher_edge_cooling: float = 1.6
@export var finisher_edge_width: float = 3.0
@export var finisher_smoke_interval: float = 0.18
@export var finisher_streak_time: float = 0.3
@export var finisher_streak_width: float = 6.0
@export var finisher_streak_height: float = 82.0
@export var finisher_cutter_pose: float = 1.1
@export var xray_time: float = 0.6
@export var xray_flicker: float = 14.0
@export var char_time: float = 0.3
@export var blast_time: float = 0.75
@export var blast_distance: float = 300.0
@export var blast_arc: float = 110.0
@export var blast_embers: int = 26
@export var neck_embers: int = 14
@export var ember_speed: float = 260.0
@export var ember_life: float = 0.8
@export var stab_hole_radius: float = 5.0

@export_group("Letterbox")
@export var letterbox_height: float = 0.11
@export var letterbox_speed: float = 4.0
@export var perfect_parry_letterbox: float = 0.35

@export_group("Signature")
@export var desaturation: float = 0.15

@export_group("Flow")
@export var mass_letterbox: float = 1.6
@export var mass_pull_back: float = 0.18
@export var pull_back_speed: float = 2.5

@export_group("Pixel grid")
@export var units_per_pixel: float = 2.0
@export var fade_steps: int = 3
@export var heavy_glint: float = 0.2
@export var lock_spark_interval: float = 0.07
@export var lock_pulse_interval: float = 0.45
@export var lock_pulse_radius: float = 30.0

@export_group("Web")
@export var web_glow: bool = false
@export var web_light_scale: float = 1.6
@export var replay_ticks_per_frame: int = 240
