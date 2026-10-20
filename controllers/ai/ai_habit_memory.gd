class_name AiHabitMemory
extends RefCounted

var heavy_starts: float = 0.0
var light_starts: float = 0.0
var guard_ticks: float = 0.0
var observed_ticks: float = 0.0
var _decay: float = 1.0
var _last_state: FighterState.State = FighterState.State.IDLE


func _init(window_seconds: float) -> void:
	_decay = 1.0 - 1.0 / maxf(window_seconds * Ticks.RATE, 1.0)


func observe(opponent: FighterState) -> void:
	heavy_starts *= _decay
	light_starts *= _decay
	guard_ticks *= _decay
	observed_ticks = observed_ticks * _decay + 1.0
	if opponent.state != _last_state:
		if opponent.state == FighterState.State.HEAVY_ATTACK:
			heavy_starts += 1.0
		elif opponent.state == FighterState.State.ATTACKING:
			light_starts += 1.0
	if opponent.state == FighterState.State.BLOCKING:
		guard_ticks += 1.0
	_last_state = opponent.state


func heavy_share() -> float:
	return heavy_starts / (heavy_starts + light_starts + 1.0)


func light_share() -> float:
	return light_starts / (heavy_starts + light_starts + 1.0)


func guard_share() -> float:
	return guard_ticks / maxf(observed_ticks, 1.0)
