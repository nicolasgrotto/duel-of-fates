class_name SpaceEvent
extends RefCounted

enum Type { BOOST_STARTED, WEAPON_PRIMED, SHOT_FIRED, SHIELD_HIT, HULL_HIT, SHIP_DESTROYED, SHIP_RESTORED, ACTION_REFUSED, SHOT_EVADED }
enum Refusal { NO_SECONDARY, POOL_FULL }

var type: Type = Type.SHOT_FIRED
var source: int = 0
var target: int = -1
var position: Vector2 = Vector2.ZERO
var amount: float = 0.0
