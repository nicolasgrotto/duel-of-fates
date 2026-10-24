class_name LessonStep
extends Resource

enum Goal {
	WALK, LIGHT_HIT, CHAIN_HIT, HEAVY_HIT, BLOCK, PARRY_HEAVY, COUNTER, SHOVE, GUARD_BREAK, WOUND, LOCK_WIN,
	ABILITY, EVADE, EVADE_STREAK, EVADE_PUNISH, EXHAUST, RECOVER, SPIN_DODGE,
}

@export var text_key: String
@export var goal: Goal = Goal.WALK
@export var count: int = 1
@export var dummy: DummyController.Behavior = DummyController.Behavior.STAND
