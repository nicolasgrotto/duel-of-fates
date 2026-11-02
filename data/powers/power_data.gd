class_name PowerData
extends Resource

const DEFAULT_TIER_VALUES: PackedFloat32Array = [1.0, 1.0, 1.0, 1.0]

enum Path { COMMON, AURORA, ECLIPSE }
enum Kind {
	REPULSE, PULL, THROW, MIND_TWIST, SUPREME_PUSH, FRACTURE,
	BARRIER, HEAL, FOCUS, ABSORPTION, SANCTUARY, MASS_TELEKINESIS, UNUSED_FLOW_CLEAVE,
	LIGHTNING, CHOKE, FREEZE, STORM, WRATH, DRAIN, ARSENAL, HIGHER_INSTINCT, SINGULARITY,
}

@export var id: StringName
@export var name_key: String
@export var description_key: String
@export var icon: Texture2D
@export var path: Path = Path.COMMON
@export var kind: Kind = Kind.REPULSE

@export_group("Cost")
@export var cost: float = 40.0
@export var cost_per_second: float = 0.0
@export var min_level: int = 1
@export var cooldown: float = 0.0
@export var high_cost: bool = false
@export var mark_color: Color = Color.WHITE

@export_group("Timing")
@export var startup: float = 0.3
@export var max_channel: float = 0.0
@export var duration: float = 0.0
@export var recovery: float = 0.35
@export var pulse_interval: float = 0.1
@export var apex_repeat_delay: float = 0.0
@export var cinematic_freeze: float = 0.0
@export var counter_window: float = 0.0
@export var evade_duration: float = 0.0

@export_group("Effect")
@export var reach: float = 320.0
@export var damage: float = 0.0
@export var stagger: float = 0.0
@export var strength: float = 0.0
@export var speed: float = 0.0
@export var escape_damage: float = 0.0
@export var absorb_gain: float = 0.0
@export var tier_values: PackedFloat32Array = DEFAULT_TIER_VALUES
@export var interaction: InteractionTable
@export var guard_vigor: float = 10.0
@export var barrier_drain: float = 0.0
@export var fissure_min_level: int = 0

@export_group("Singularity")
@export var suspension: float = 0.0
@export var formation: float = 0.0
@export var warning: float = 0.0
@export var mark_half_width: float = 0.0
@export var safe_width: float = 0.0
@export var extraction_damage: float = 0.0
@export var extraction_lift: float = 0.0
@export var extraction_hold: float = 0.0
@export var ground_pull: float = 0.0
@export var air_pull: float = 0.0
@export var vertical_pull: float = 0.0
@export var pull_speed: float = 0.0
@export var sphere_height: float = 0.0
@export var target_height: float = 0.0
@export var projectile_size: float = 0.0
@export var throw_range: float = 0.0
@export var throw_push: float = 0.0

@export_group("By Flow level")
@export var level_damage: PackedFloat32Array
@export var level_speed: PackedFloat32Array
@export var level_cost: PackedFloat32Array
@export var level_cooldown: PackedFloat32Array

@export_group("Finisher")
@export var finisher: Finisher.Kind = Finisher.Kind.NONE
@export var execute_below: float = 0.0

@export_group("Defense")
@export var guard_blocks: bool = true
@export var guard_damage_ratio: float = 0.0
@export var ignores_invulnerability: bool = false
@export var castable_when_hit: bool = false


func startup_ticks() -> int:
	return Ticks.from_seconds(startup)


func recovery_ticks() -> int:
	return Ticks.from_seconds(recovery)


func recovery_ticks_at(apex: bool) -> int:
	return Ticks.from_seconds(recovery + (apex_repeat_delay if apex else 0.0))


func is_channeled() -> bool:
	return max_channel > 0.0


func cost_for(level: int) -> float:
	return _by_level(level_cost, level, cost)


func cooldown_for(level: int) -> float:
	return _by_level(level_cooldown, level, cooldown)


func damage_for(level: int) -> float:
	return _by_level(level_damage, level, damage)


func speed_for(level: int) -> float:
	return _by_level(level_speed, level, speed)


func _by_level(values: PackedFloat32Array, level: int, fallback: float) -> float:
	if values.is_empty():
		return fallback
	return values[clampi(level, 1, values.size()) - 1]


func opens_fissures(level: int) -> bool:
	return fissure_min_level > 0 and level >= fissure_min_level


func min_tier(flow: FlowConfig) -> int:
	return flow.tier_for(min_level)


func targeted_reach(tier: int) -> float:
	match kind:
		Kind.PULL:
			return tier_value(tier)
		Kind.REPULSE, Kind.MIND_TWIST, Kind.SUPREME_PUSH, Kind.FREEZE, Kind.CHOKE, Kind.DRAIN, Kind.LIGHTNING:
			return reach
	return 0.0


func tier_value(tier: int) -> float:
	return tier_values[clampi(tier, 0, tier_values.size() - 1)]
