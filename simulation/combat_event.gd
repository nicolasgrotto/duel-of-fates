class_name CombatEvent
extends RefCounted

enum Type {
	ATTACK_STARTED,
	HIT,
	BLOCK,
	GUARD_BREAK,
	PARRY,
	PERFECT_PARRY,
	CLASH,
	BLADE_LOCK_STARTED,
	BLADE_LOCK_PRESSED,
	BLADE_LOCK_ENDED,
	SHOVE,
	DODGE,
	EVADE_SUCCESS,
	ACTION_REJECTED,
	EXHAUSTION,
	EXHAUSTION_RECOVERED,
	WOUND,
	JUMP,
	LAND,
	DEATH,
	ROUND_STARTED,
	FIGHT_STARTED,
	ROUND_ENDED,
	MATCH_ENDED,
}

const NO_FIGHTER: int = -1

var type: Type = Type.HIT
var source: int = NO_FIGHTER
var target: int = NO_FIGHTER
var move: MoveData
var amount: float = 0.0
var heavy: bool = false
var position: Vector2 = Vector2.ZERO
var limb: MoveData.Limb = MoveData.Limb.NONE
var from_front: bool = true
var frame_advantage: int = 0
var combo: int = 0
var hitstop_ticks: int = 0


func reset() -> void:
	source = NO_FIGHTER
	target = NO_FIGHTER
	move = null
	amount = 0.0
	heavy = false
	position = Vector2.ZERO
	limb = MoveData.Limb.NONE
	from_front = true
	frame_advantage = 0
	combo = 0
	hitstop_ticks = 0


func type_name() -> StringName:
	return StringName(Type.keys()[type].to_lower())
