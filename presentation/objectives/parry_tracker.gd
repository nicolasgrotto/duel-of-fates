class_name ParryTracker
extends DuelObjective

var points: int = 0
var player: int = 0
var duration: float = 45.0
var record: bool = false
var _start_tick: int = -1
var _left: float = 0.0


func _init(seconds: float) -> void:
	duration = seconds
	_left = seconds


func on_tick(sim: MatchSimulation) -> void:
	if done or sim.phase != MatchSimulation.Phase.FIGHT:
		return
	if _start_tick < 0:
		_start_tick = sim.tick
	_left = maxf(duration - Ticks.to_seconds(sim.tick - _start_tick), 0.0)
	if _left <= 0.0:
		_finish()


func on_event(event: CombatEvent, _sim: MatchSimulation) -> void:
	if done or event.target != player or not event.heavy:
		return
	match event.type:
		CombatEvent.Type.PARRY:
			points += 1
		CombatEvent.Type.PERFECT_PARRY:
			points += 2


func instruction() -> String:
	return format_keys(TranslationServer.translate("PARRY_CHALLENGE_HINT"))


func progress_line() -> String:
	return TranslationServer.translate("PARRY_CHALLENGE_LINE").format({"time": ceili(_left), "points": points})


func result_title() -> String:
	return TranslationServer.translate("PARRY_CHALLENGE_DONE")


func result_note() -> String:
	return TranslationServer.translate("PARRY_CHALLENGE_RECORD" if record else "PARRY_CHALLENGE_POINTS").format({"points": points})
