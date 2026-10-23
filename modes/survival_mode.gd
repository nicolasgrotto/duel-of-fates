class_name SurvivalMode
extends DuelMode

var wins: int = 0
var health: float = 1.0
var won_last: bool = false
var record: bool = false
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _init() -> void:
	_rng.randomize()


func steps() -> Array[StringName]:
	return [&"player"]


func is_boss_fight() -> bool:
	return wins > 0 and wins % MODES.survival_boss_every == 0


func player() -> CharacterData:
	return selection.characters[0] if selection.characters[0] != null else GUARDIAN


func build_setup() -> DuelSetup:
	var setup: DuelSetup = DuelSetup.new()
	var opponent: CharacterData = _pick_opponent(player().id)
	setup.characters = [player(), opponent]
	setup.controllers = [DuelSetup.ControllerKind.PLAYER, DuelSetup.ControllerKind.AI]
	setup.hold_to_lock = [Settings.hold_to_lock[0], false]
	setup.difficulty = difficulty(fight_difficulty())
	if is_boss_fight():
		setup.awakening = [null, BOSS_DIFFICULTY]
	setup.rules = MatchRules.new()
	setup.rules.powers = Settings.powers
	setup.rules.rounds_to_win = 1
	setup.rules.start_health = PackedFloat32Array([health, 1.0])
	setup.arena = ARENAS[wins % ARENAS.size()]
	setup.match_seed = _new_seed()
	setup.banner = TranslationServer.translate("SURVIVAL_BANNER").format({"wins": wins, "best": SaveService.survival_best})
	return _finish_setup(setup)


func fight_difficulty() -> StringName:
	if is_boss_fight() or wins >= MODES.survival_normal_wins:
		return &"hard"
	return &"easy" if wins < MODES.survival_easy_wins else &"normal"


func _pick_opponent(player_id: StringName) -> CharacterData:
	if is_boss_fight():
		return load(BOSS_PATH) as CharacterData
	var pool: Array[StringName] = CAST.duplicate()
	pool.erase(player_id)
	return character(pool[_rng.randi_range(0, pool.size() - 1)])


func finish(winner: int, sim: MatchSimulation) -> void:
	won_last = winner == 0
	if won_last:
		wins += 1
		health = minf(sim.fighters[0].health_ratio() + MODES.survival_heal_ratio, 1.0)
	else:
		record = SaveService.record_survival(wins)


func result_options() -> Array[StringName]:
	return [&"next", &"menu"] if won_last else [&"retry", &"menu"]


func result_title() -> String:
	return "" if won_last else TranslationServer.translate("SURVIVAL_OVER")


func result_note() -> String:
	var key: String = "SURVIVAL_WINS_RECORD" if record else "SURVIVAL_WINS"
	return TranslationServer.translate(key).format({"wins": wins})


func choose(option: StringName) -> void:
	if option == &"retry":
		wins = 0
		health = 1.0
		record = false
	super.choose(option)
