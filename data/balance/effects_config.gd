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
