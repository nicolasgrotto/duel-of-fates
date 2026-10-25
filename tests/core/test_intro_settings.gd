extends TestCase

const SCRIPT: GDScript = preload("res://core/settings.gd")
const PATH: String = "user://test_intro_settings.cfg"


func test_intro_option_round_trips_and_old_settings_default_to_enabled() -> void:
	var settings: Node = SCRIPT.new()
	settings.fighter_intros = false
	settings.save_settings(PATH)
	var copy: Node = SCRIPT.new()
	copy.load_settings(PATH)
	assert_false(copy.fighter_intros)
	settings.fighter_intros = true
	settings.save_settings(PATH)
	copy.load_settings(PATH)
	assert_true(copy.fighter_intros)
	var old: ConfigFile = ConfigFile.new()
	old.set_value("game", "locale", "en")
	old.save(PATH)
	copy.fighter_intros = false
	copy.load_settings(PATH)
	assert_true(copy.fighter_intros)
	DirAccess.remove_absolute(PATH)
	settings.free()
	copy.free()
