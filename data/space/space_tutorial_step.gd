class_name SpaceTutorialStep
extends Resource

enum Action { THRUST, TURN, REVERSE, FIRE, BOOST, MISSILE, DESTROY }

@export var title_key: String
@export var action: Action = Action.THRUST
@export var count: int = 1
@export var hint_actions: PackedStringArray
