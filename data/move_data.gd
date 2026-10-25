class_name MoveData
extends Resource

enum Kind { LIGHT, HEAVY, FORWARD_HEAVY, COUNTER, SHOVE, AERIAL_LIGHT, AERIAL_HEAVY, LOCK_FINISH, ABILITY, STANCE, TECHNIQUE, DISENGAGE }
enum Limb { NONE, ARM, LEG, HEAD }
enum Cut { ARC, DESCENDING, RISING, HORIZONTAL, THRUST, SPIN }
enum TechniqueStyle { ARC, DASH, THROW, THRUST, RISING, FLURRY, LUNGE, PLUNGE, WAVE }

@export var id: StringName
@export var icon: Texture2D
@export var kind: Kind = Kind.LIGHT

@export_group("Timing")
@export var startup: float = 0.1
@export var active: float = 0.1
@export var recovery: float = 0.2

@export_group("Effect")
@export var damage: float = 10.0
@export var vigor_cost: float = 8.0
@export var block_vigor_cost: float = 8.0
@export var knockback: float = 40.0
@export var block_push: float = 30.0
@export var hitstun: float = 0.35
@export var blockstun: float = 0.24
@export var lunge: float = 20.0

@export_group("Hitbox")
@export var reach: float = 100.0
@export var hitbox_bottom: float = 40.0
@export var hitbox_top: float = 140.0
@export var blade_reach: float = 60.0

@export_group("Properties")
@export var counts_as_heavy: bool = false
@export var armor_hits: int = 0
@export_range(0.0, 1.0) var armor_damage_ratio: float = 1.0
@export var armor_in_active: bool = false
@export var hits_behind: bool = false
@export var dive_speed: float = 0.0
@export var aerial_technique: bool = false

@export_group("Technique")
@export var multi_hits: int = 1
@export var multi_interval: float = 0.07
@export var airborne_bonus: float = 0.0
@export var launch_speed: float = 0.0
@export var throws_blade: bool = false
@export var projectile_speed: float = 0.0
@export var projectile_range: float = 0.0
@export var projectile_size: float = 0.0
@export var recovery_on_hit: float = -1.0
@export var dash_in_startup: bool = false

@export_group("Consequences")
@export var can_blade_lock: bool = false
@export var wound_limb: Limb = Limb.NONE
@export var finisher_limb: Limb = Limb.ARM
@export var cinematic_finisher: Finisher.Kind = Finisher.Kind.NONE

@export_group("Presentation")
@export var blade_angle_windup: float = -120.0
@export var blade_angle_strike: float = 30.0
@export var technique_style: TechniqueStyle = TechniqueStyle.ARC
@export var cut: Cut = Cut.ARC


func startup_ticks() -> int:
	return Ticks.from_seconds(startup)


func active_ticks() -> int:
	return maxi(Ticks.from_seconds(active), 1) if active > 0.0 else 0


func recovery_ticks() -> int:
	return Ticks.from_seconds(recovery)


func total_ticks() -> int:
	return startup_ticks() + active_ticks() + recovery_ticks()


func is_heavy() -> bool:
	return kind == Kind.HEAVY or kind == Kind.FORWARD_HEAVY or kind == Kind.AERIAL_HEAVY or counts_as_heavy


func is_aerial() -> bool:
	return kind == Kind.AERIAL_LIGHT or kind == Kind.AERIAL_HEAVY or aerial_technique


func is_technique() -> bool:
	return kind == Kind.TECHNIQUE


func is_blade() -> bool:
	return kind != Kind.SHOVE and kind != Kind.LOCK_FINISH and kind != Kind.STANCE


func can_clash() -> bool:
	return is_blade() and not throws_blade and technique_style != TechniqueStyle.WAVE
