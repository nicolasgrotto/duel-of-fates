extends Node

const SETTINGS_PATH: String = "user://settings.cfg"
const DIFFICULTY_PATH: String = "res://data/balance/ai/difficulty_%s.tres"
const DIFFICULTIES: Array[StringName] = [&"easy", &"normal", &"hard"]
const LOCALES: Array[String] = ["pt_BR", "en"]

var locale: String = "pt_BR"
var difficulty: StringName = &"normal"
var reduced_effects: bool = false
var final_blow_replay: bool = true
var show_finishers: bool = true
var hold_to_lock: Array[bool] = [false, false]


func _ready() -> void:
	InputBindings.apply_defaults()
	load_settings()
	TranslationServer.set_locale(locale)


func difficulty_data() -> AiDifficultyData:
	return load(DIFFICULTY_PATH % difficulty) as AiDifficultyData


func cycle_difficulty(step: int) -> void:
	var index: int = DIFFICULTIES.find(difficulty)
	difficulty = DIFFICULTIES[posmod(index + step, DIFFICULTIES.size())]
	save_settings()


func load_settings() -> void:
	var file: ConfigFile = ConfigFile.new()
	if file.load(SETTINGS_PATH) != OK:
		return
	locale = file.get_value("game", "locale", locale)
	difficulty = StringName(file.get_value("game", "difficulty", String(difficulty)))
	if not DIFFICULTIES.has(difficulty):
		difficulty = &"normal"
	final_blow_replay = file.get_value("game", "final_blow_replay", final_blow_replay)
	show_finishers = file.get_value("game", "show_finishers", show_finishers)
	reduced_effects = file.get_value("accessibility", "reduced_effects", reduced_effects)
	for slot in hold_to_lock.size():
		hold_to_lock[slot] = file.get_value("accessibility", "hold_to_lock_p%d" % (slot + 1), false)


func save_settings() -> void:
	var file: ConfigFile = ConfigFile.new()
	file.set_value("game", "locale", locale)
	file.set_value("game", "difficulty", String(difficulty))
	file.set_value("game", "final_blow_replay", final_blow_replay)
	file.set_value("game", "show_finishers", show_finishers)
	file.set_value("accessibility", "reduced_effects", reduced_effects)
	for slot in hold_to_lock.size():
		file.set_value("accessibility", "hold_to_lock_p%d" % (slot + 1), hold_to_lock[slot])
	file.save(SETTINGS_PATH)
