class_name PowerImpact
extends RefCounted

var allow_finisher: bool = true
var damage: float = 0.0
var push: float = 0.0
var stagger: float = 0.0
var hold: float = 0.0
var guard_vigor: float = 0.0
var source_x: float = 0.0
var flow_level: int = 4
var table: InteractionTable
var ignore_guard: bool = false
var ignore_barrier: bool = false
var ignore_absorption: bool = false
var ignore_invulnerability: bool = false
var grounded_only: bool = false
var periodic: bool = false
var grants_flow: bool = true
var silent_miss: bool = false
var position: Vector2 = Vector2.ZERO


func reset(power: PowerData, caster: FighterState) -> void:
	allow_finisher = true
	damage = 0.0
	push = 0.0
	stagger = 0.0
	hold = 0.0
	guard_vigor = power.guard_vigor if power != null else 0.0
	source_x = caster.x
	flow_level = caster.flow_level
	table = power.interaction if power != null else null
	ignore_guard = power != null and not power.guard_blocks
	ignore_barrier = false
	ignore_absorption = false
	ignore_invulnerability = power != null and power.ignores_invulnerability
	grounded_only = false
	periodic = false
	grants_flow = true
	silent_miss = false
	position = Vector2(caster.x, caster.y + 90.0)
