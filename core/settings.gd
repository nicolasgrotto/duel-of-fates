extends Node

const SETTINGS_PATH: String = "user://settings.cfg"
const DIFFICULTY_PATH: String = "res://data/balance/ai/difficulty_%s.tres"
const DIFFICULTIES: Array[StringName] = [&"easy", &"normal", &"hard"]
const LOCALES: Array[String] = ["pt_BR", "en"]
const VOLUME_STEPS: int = 10
const EFFECT_BUSES: Array[StringName] = [&"Effects", &"Blades", &"Ambience", &"Interface"]
const WEB_FEATURE: String = "web"

var locale: String = "pt_BR"
var difficulty: StringName = &"normal"
var reduced_effects: bool = false
var final_blow_replay: bool = true
var show_finishers: bool = true
var hold_to_lock: Array[bool] = [false, false]
var powers: bool = true
var master_volume: int = VOLUME_STEPS
var music_volume: int = 8
var effects_volume: int = VOLUME_STEPS
var fullscreen: bool = false
var vsync: bool = true


func _ready() -> void:
	InputBindings.apply_defaults()
	load_settings()
	apply()


func difficulty_data() -> AiDifficultyData:
	return load(DIFFICULTY_PATH % difficulty) as AiDifficultyData


func apply() -> void:
	TranslationServer.set_locale(locale)
	_set_volume(&"Master", master_volume)
	_set_volume(&"Music", music_volume)
	for bus in EFFECT_BUSES:
		_set_volume(bus, effects_volume)
	if not OS.has_feature(WEB_FEATURE):
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
	var windowed: bool = DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN
	if fullscreen and windowed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif not fullscreen and not windowed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func cycle_locale(step: int) -> void:
	locale = LOCALES[posmod(LOCALES.find(locale) + step, LOCALES.size())]


func _set_volume(bus: StringName, steps: int) -> void:
	var index: int = AudioServer.get_bus_index(bus)
	if index < 0:
		return
	AudioServer.set_bus_mute(index, steps <= 0)
	AudioServer.set_bus_volume_db(index, linear_to_db(float(steps) / VOLUME_STEPS) if steps > 0 else 0.0)


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
	powers = file.get_value("game", "powers", powers)
	master_volume = clampi(file.get_value("audio", "master", master_volume), 0, VOLUME_STEPS)
	music_volume = clampi(file.get_value("audio", "music", music_volume), 0, VOLUME_STEPS)
	effects_volume = clampi(file.get_value("audio", "effects", effects_volume), 0, VOLUME_STEPS)
	fullscreen = file.get_value("video", "fullscreen", fullscreen)
	vsync = file.get_value("video", "vsync", vsync)
	if not LOCALES.has(locale):
		locale = LOCALES[0]
	for slot in hold_to_lock.size():
		hold_to_lock[slot] = file.get_value("accessibility", "hold_to_lock_p%d" % (slot + 1), false)


func save_settings() -> void:
	var file: ConfigFile = ConfigFile.new()
	file.set_value("game", "locale", locale)
	file.set_value("game", "difficulty", String(difficulty))
	file.set_value("game", "final_blow_replay", final_blow_replay)
	file.set_value("game", "show_finishers", show_finishers)
	file.set_value("accessibility", "reduced_effects", reduced_effects)
	file.set_value("game", "powers", powers)
	file.set_value("audio", "master", master_volume)
	file.set_value("audio", "music", music_volume)
	file.set_value("audio", "effects", effects_volume)
	file.set_value("video", "fullscreen", fullscreen)
	file.set_value("video", "vsync", vsync)
	for slot in hold_to_lock.size():
		file.set_value("accessibility", "hold_to_lock_p%d" % (slot + 1), hold_to_lock[slot])
	file.save(SETTINGS_PATH)
