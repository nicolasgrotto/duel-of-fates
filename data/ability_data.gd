class_name AbilityData
extends Resource

enum Kind { STRIKE, STANCE, DASH, CHARGE, LEAP }

@export var id: StringName
@export var icon: Texture2D
@export var kind: Kind = Kind.STRIKE
@export var move: MoveData
@export var vigor_cost: float = 0.0

@export_group("Stance")
@export var stance_duration: float = 0.35
@export var stance_recovery: float = 0.3
@export var stance_stagger: float = 0.4
@export var perfect_response: bool = false

@export_group("Dash")
@export var dash_distance: float = 220.0
@export var dash_duration: float = 0.26
@export var dash_invulnerable: float = 0.2
@export var dash_through: bool = true
@export var dash_forward_by_default: bool = true

@export_group("Charge")
@export var charge_level_time: float = 0.35
@export var charge_levels: int = 3
@export var charge_bonus_per_level: float = 0.35
@export var guard_break_level: int = 3

@export_group("Leap")
@export var leap_velocity: Vector2 = Vector2(320.0, 980.0)
@export var dive_when_falling: bool = false

var _stance_move: MoveData


func stance_move() -> MoveData:
	if _stance_move == null:
		_stance_move = MoveData.new()
		_stance_move.id = StringName(String(id) + "_stance")
		_stance_move.kind = MoveData.Kind.STANCE
		_stance_move.startup = 0.0
		_stance_move.active = stance_duration
		_stance_move.recovery = stance_recovery
		_stance_move.damage = 0.0
		_stance_move.vigor_cost = vigor_cost
		_stance_move.reach = 0.0
		_stance_move.lunge = 0.0
		_stance_move.finisher_limb = MoveData.Limb.NONE
	return _stance_move


func charge_level_ticks() -> int:
	return maxi(Ticks.from_seconds(charge_level_time), 1)
