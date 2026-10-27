class_name InfiltrationEvent
extends RefCounted

enum Type { SWING_STARTED, SWING_HIT, SHOT_FIRED, BOLT_BLOCKED, BOLT_REFLECTED, BOLT_HIT, FOOTSTEP, DEFEATED, TARGET_DISABLED, TARGET_RESTORED }

var type: Type = Type.SWING_STARTED
var source: int = 0
var target: int = -1
var position: Vector2 = Vector2.ZERO
var amount: float = 0.0
