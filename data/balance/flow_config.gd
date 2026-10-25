class_name FlowConfig
extends Resource

@export var basic_table: InteractionTable

@export_group("Meter")
@export var maximum: float = 100.0
@export var round_start: float = 20.0
@export var regen: float = 2.5
@export var gain_on_hit: float = 7.0
@export var gain_on_hurt: float = 9.0
@export var gain_on_block: float = 4.0
@export var gain_on_parry: float = 10.0
@export var shared_cooldown: float = 1.2
@export var chord_window: float = 0.1

@export_group("Tiers")
@export var tier_floors: PackedInt32Array = PackedInt32Array([1, 4, 7, 10])

@export_group("Airborne")
@export var air_push_multiplier: float = 1.3
@export var air_stagger_multiplier: float = 1.2
@export var air_hold_multiplier: float = 1.6
@export var vertical_reach: float = 260.0

@export_group("Statuses")
@export var focus_evade_cost: float = 30.0
@export var focus_cost_ratio: float = 0.5
@export var heal_lost_ratio: float = 0.35
@export var wrath_dealt: float = 1.2
@export var wrath_taken: float = 0.85
@export var wrath_armor: int = 2
@export var choke_lift: float = 46.0
@export var choke_lift_speed: float = 120.0
@export var drain_return_ratio: float = 0.6
@export var arsenal_launch_speed: float = 900.0
@export var arsenal_damage: float = 6.0
@export var projectile_height: float = 95.0
@export var blade_throw_base: float = 480.0
@export var blade_throw_per_point: float = 20.0
@export var blade_throw_min: float = 400.0
@export var blade_throw_max: float = 580.0
@export var blade_throw_speed: float = 900.0

@export_group("Technique clash")
@export var technique_clash_separation: float = 420.0
@export var technique_clash_stagger: float = 0.4
@export var technique_clash_vigor: float = 12.0


func tier_for(level: int) -> int:
	var tier: int = 0
	for i in tier_floors.size():
		if level >= tier_floors[i]:
			tier = i
	return tier
