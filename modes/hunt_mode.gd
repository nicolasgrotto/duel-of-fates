class_name HuntMode
extends DuelMode

const HUNTS: Array[HuntData] = [
	preload("res://data/hunts/last_lesson.tres"),
	preload("res://data/hunts/storm_eye.tres"),
	preload("res://data/hunts/weight_of_void.tres"),
]

var hunt: HuntData
var tracker: HuntTracker
var won: bool = false
var duel_won: bool = false
var record: bool = false
var seconds: float = 0.0
var _finished: bool = false
var _unlocks: PackedStringArray = []


func _init(data: HuntData) -> void:
	hunt = data


func steps() -> Array[StringName]:
	return []


func required_resources() -> PackedStringArray:
	return PackedStringArray([CHARACTER_PATH % [hunt.opponent, hunt.opponent]])


func build_setup() -> DuelSetup:
	tracker = HuntTracker.new(hunt)
	_finished = false
	won = false
	duel_won = false
	record = false
	_unlocks.clear()
	var setup: DuelSetup = DuelSetup.new()
	var hero: CharacterData = hunt.player.duplicate() as CharacterData
	hero.flow = hunt.player_flow
	hero.powers = hunt.player_powers.duplicate()
	hero.fourth_power = null
	setup.characters = [hero, character(hunt.opponent)]
	setup.controllers = [DuelSetup.ControllerKind.PLAYER, DuelSetup.ControllerKind.AI]
	setup.hold_to_lock = [Settings.hold_to_lock[0], false]
	setup.difficulty = hunt.difficulty
	setup.arena = hunt.arena
	setup.rules = MatchRules.new()
	setup.rules.rounds_to_win = 1
	setup.rules.fighter_intros = Settings.fighter_intros
	setup.match_seed = _new_seed()
	setup.banner = TranslationServer.translate(hunt.title_key)
	setup.fill_default_looks()
	return setup


func create_objective(_dummy: DummyController) -> DuelObjective:
	return tracker


func create_replay_objective() -> DuelObjective:
	return HuntTracker.new(hunt)


func create_ai(_data: AiDifficultyData, _profile: AiProfileData, ai_seed: int) -> AiController:
	return HuntController.new(tracker, ai_seed)


func finish(winner: int, _sim: MatchSimulation, _duration: float) -> void:
	if _finished:
		return
	_finished = true
	duel_won = winner == 0
	won = duel_won and tracker.condition_met()
	seconds = Ticks.to_seconds(tracker.fight_ticks)
	if not won:
		return
	record = SaveService.record_hunt(hunt.id, seconds)
	for key in hunt.unlocks:
		if SaveService.unlock(key):
			_unlocks.append(TranslationServer.translate("HUNT_UNLOCKED").format({"reward": TranslationServer.translate(hunt.reward_key)}))


func unlock_messages() -> PackedStringArray:
	return _unlocks


func result_title() -> String:
	if not duel_won:
		return TranslationServer.translate("RESULT_DEFEAT")
	return TranslationServer.translate("HUNT_COMPLETED" if won else "HUNT_FAILED")


func result_note() -> String:
	if not won:
		return tracker.progress_line()
	return TranslationServer.translate("CHALLENGE_TIME_RECORD" if record else "CHALLENGE_TIME").format({"time": ChallengeMode.format_time(seconds)})


func result_options() -> Array[StringName]:
	return [&"continue", &"retry", &"hunts"] if won else [&"retry", &"hunts"]


func start_briefing() -> void:
	SceneRouter.change(&"dialogue", {"hunt_mode": self, "encounter": hunt.dialogue_encounter(), "part": &"before"})


func choose(option: StringName) -> void:
	match option:
		&"continue":
			SceneRouter.change(&"dialogue", {"hunt_mode": self, "encounter": hunt.dialogue_encounter(), "part": &"after"})
		&"hunts":
			SceneRouter.change(&"hunts", {"hunt": hunt.id})
		_:
			super.choose(option)
