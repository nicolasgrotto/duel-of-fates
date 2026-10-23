class_name ChallengeMode
extends DuelMode

var challenge: ChallengeData
var won: bool = false
var record: bool = false
var seconds: float = 0.0


func _init(challenge_data: ChallengeData) -> void:
	challenge = challenge_data


func steps() -> Array[StringName]:
	return []


func build_setup() -> DuelSetup:
	var setup: DuelSetup = DuelSetup.new()
	setup.characters = [character(challenge.player), character(challenge.opponent)]
	setup.controllers = [DuelSetup.ControllerKind.PLAYER, DuelSetup.ControllerKind.AI]
	setup.hold_to_lock = [Settings.hold_to_lock[0], false]
	setup.difficulty = difficulty(challenge.difficulty)
	setup.rules = MatchRules.new()
	setup.rules.rounds_to_win = 1
	setup.rules.powers = challenge.powers
	setup.rules.start_health = PackedFloat32Array([challenge.start_health, 1.0])
	setup.arena = challenge.arena
	setup.match_seed = _new_seed()
	var best: String = format_time(SaveService.challenge_best[String(challenge.id)]) if SaveService.challenge_best.has(String(challenge.id)) else "—"
	setup.banner = TranslationServer.translate("CHALLENGE_BANNER").format({
		"name": TranslationServer.translate(challenge.title_key).to_upper(), "best": best,
	})
	return _finish_setup(setup)


func finish(winner: int, _sim: MatchSimulation, duration: float) -> void:
	won = winner == 0
	seconds = duration
	record = won and SaveService.record_challenge(challenge.id, duration)


func result_options() -> Array[StringName]:
	return [&"retry", &"menu"]


func result_title() -> String:
	return TranslationServer.translate("CHALLENGE_DONE") if won else ""


func result_note() -> String:
	if not won:
		return TranslationServer.translate(challenge.description_key)
	var key: String = "CHALLENGE_TIME_RECORD" if record else "CHALLENGE_TIME"
	return TranslationServer.translate(key).format({"time": format_time(seconds)})


static func format_time(value: float) -> String:
	var total: int = int(round(value))
	return "%d:%02d" % [total / 60, total % 60]
