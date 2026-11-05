extends Node

const SETTINGS_PATH: String = "user://settings.cfg"
const DIFFICULTY_PATH: String = "res://data/balance/ai/difficulty_%s.tres"
const DIFFICULTIES: Array[StringName] = [&"easy", &"normal", &"hard"]
const LOCALES: Array[String] = ["pt_BR", "en"]
const VOLUME_STEPS: int = 10
const EFFECT_BUSES: Array[StringName] = [&"Effects", &"Blades", &"Ambience", &"Interface"]
const HEADLESS_DISPLAY: String = "headless"
const WEB_FEATURE: String = "web"

var locale: String = "pt_BR"
var difficulty: StringName = &"normal"
var reduced_effects: bool = false
var final_blow_replay: bool = true
var fighter_intros: bool = true
var show_finishers: bool = true
var hold_to_lock: Array[bool] = [false, false]
var powers: bool = true
var master_volume: int = VOLUME_STEPS
var music_volume: int = 8
var effects_volume: int = VOLUME_STEPS
var fullscreen: bool = false
var vsync: bool = true
var vibration: bool = true
var key_preset: StringName = &"default"
var custom_keys: Dictionary = {}
var custom_buttons: Dictionary = {}
var blaster_ops_keys: Dictionary = {}
var blaster_ops_buttons: Dictionary = {}


func _ready() -> void:
	InputBindings.apply_defaults()
	load_settings()
	apply()


func difficulty_data() -> AiDifficultyData:
	return load(DIFFICULTY_PATH % difficulty) as AiDifficultyData


func apply() -> void:
	TranslationServer.set_locale(locale)
	InputBindings.apply_keyboard(custom_keys if key_preset == &"custom" and not custom_keys.is_empty() else InputBindings.preset_keys(key_preset))
	InputBindings.apply_buttons(custom_buttons if not custom_buttons.is_empty() else InputBindings.default_buttons())
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
	_fit_window()


static func fitted_window_size(window: Vector2i, room: Vector2i) -> Vector2i:
	if window.x <= room.x and window.y <= room.y:
		return window
	var ratio: float = minf(float(room.x) / window.x, float(room.y) / window.y)
	return Vector2i(floori(window.x * ratio), floori(window.y * ratio))


func _load_operations_keys(file: ConfigFile) -> Dictionary:
	var layout: int = file.get_value("blaster_ops", "operations_layout", 0)
	var saved: Dictionary = file.get_value("blaster_ops", "keys", {})
	if layout < 1:
		return {}
	return saved if layout >= BlasterOpsBindings.LAYOUT_VERSION else BlasterOpsBindings.migrate_keys(saved)


func _fit_window() -> void:
	if OS.has_feature(WEB_FEATURE) or DisplayServer.get_name() == HEADLESS_DISPLAY or Engine.is_embedded_in_editor():
		return
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
		return
	var usable: Rect2i = DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	var inner: Vector2i = DisplayServer.window_get_size()
	var decorations: Vector2i = DisplayServer.window_get_size_with_decorations() - inner
	var fitted: Vector2i = fitted_window_size(inner, usable.size - decorations)
	if fitted != inner:
		DisplayServer.window_set_size(fitted)
		DisplayServer.window_set_position(usable.position + decorations)


func cycle_key_preset(step: int) -> void:
	var presets: Array[StringName] = InputBindings.PRESETS.duplicate()
	if custom_keys.is_empty():
		presets.erase(&"custom")
	key_preset = presets[posmod(presets.find(key_preset) + step, presets.size())]


func set_custom_keys(keys: Dictionary) -> void:
	custom_keys = keys
	key_preset = &"custom"


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


func load_settings(path: String = SETTINGS_PATH) -> void:
	var file: ConfigFile = ConfigFile.new()
	if file.load(path) != OK:
		return
	locale = file.get_value("game", "locale", locale)
	difficulty = StringName(file.get_value("game", "difficulty", String(difficulty)))
	if not DIFFICULTIES.has(difficulty):
		difficulty = &"normal"
	final_blow_replay = file.get_value("game", "final_blow_replay", final_blow_replay)
	fighter_intros = file.get_value("game", "fighter_intros", true)
	show_finishers = file.get_value("game", "show_finishers", show_finishers)
	reduced_effects = file.get_value("accessibility", "reduced_effects", reduced_effects)
	powers = file.get_value("game", "powers", powers)
	master_volume = clampi(file.get_value("audio", "master", master_volume), 0, VOLUME_STEPS)
	music_volume = clampi(file.get_value("audio", "music", music_volume), 0, VOLUME_STEPS)
	effects_volume = clampi(file.get_value("audio", "effects", effects_volume), 0, VOLUME_STEPS)
	fullscreen = file.get_value("video", "fullscreen", fullscreen)
	vsync = file.get_value("video", "vsync", vsync)
	vibration = file.get_value("input", "vibration", vibration)
	key_preset = StringName(file.get_value("input", "key_preset", String(key_preset)))
	custom_keys = file.get_value("input", "custom_keys", {})
	custom_buttons = file.get_value("input", "custom_buttons", {})
	blaster_ops_keys = _load_operations_keys(file)
	blaster_ops_buttons = file.get_value("blaster_ops", "buttons", {})
	if not InputBindings.PRESETS.has(key_preset):
		key_preset = &"default"
	if not LOCALES.has(locale):
		locale = LOCALES[0]
	for slot in hold_to_lock.size():
		hold_to_lock[slot] = file.get_value("accessibility", "hold_to_lock_p%d" % (slot + 1), false)


func save_settings(path: String = SETTINGS_PATH) -> void:
	var file: ConfigFile = ConfigFile.new()
	file.set_value("game", "locale", locale)
	file.set_value("game", "difficulty", String(difficulty))
	file.set_value("game", "final_blow_replay", final_blow_replay)
	file.set_value("game", "fighter_intros", fighter_intros)
	file.set_value("game", "show_finishers", show_finishers)
	file.set_value("accessibility", "reduced_effects", reduced_effects)
	file.set_value("game", "powers", powers)
	file.set_value("audio", "master", master_volume)
	file.set_value("audio", "music", music_volume)
	file.set_value("audio", "effects", effects_volume)
	file.set_value("video", "fullscreen", fullscreen)
	file.set_value("video", "vsync", vsync)
	file.set_value("input", "vibration", vibration)
	file.set_value("input", "key_preset", String(key_preset))
	file.set_value("input", "custom_keys", custom_keys)
	file.set_value("input", "custom_buttons", custom_buttons)
	file.set_value("blaster_ops", "keys", blaster_ops_keys)
	file.set_value("blaster_ops", "operations_layout", BlasterOpsBindings.LAYOUT_VERSION)
	file.set_value("blaster_ops", "buttons", blaster_ops_buttons)
	for slot in hold_to_lock.size():
		file.set_value("accessibility", "hold_to_lock_p%d" % (slot + 1), hold_to_lock[slot])
	file.save(path)
