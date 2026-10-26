extends TestCase

const TABLE: String = "res://localization/strings.csv"
const CODE_ROOTS: Array[String] = ["res://screens", "res://presentation", "res://ui", "res://modes", "res://core"]
const CHARACTERS_ROOT: String = "res://data/characters"
const POWERS_ROOT: String = "res://data/powers"
const TECHNIQUES_ROOT: String = "res://data/techniques"
const KEY_PATTERN: String = "(?:tr\\(|hint\\([^,]+,\\s*)\"([A-Z][A-Z0-9_]+)\"\\)"

var _keys: Dictionary = {}


func before_each() -> void:
	var file: FileAccess = FileAccess.open(TABLE, FileAccess.READ)
	var header: PackedStringArray = file.get_csv_line()
	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		if row.size() == header.size() and row[0] != "":
			_keys[row[0]] = row


func _assert_key(key: String, context: String) -> void:
	if key == "":
		return
	assert_true(_keys.has(key), "%s missing (%s)" % [key, context])
	if _keys.has(key):
		var row: PackedStringArray = _keys[key]
		assert_true(row[1] != "" and row[2] != "", "%s needs both languages" % key)


func test_character_texts_exist_in_both_languages() -> void:
	for folder in DirAccess.get_directories_at(CHARACTERS_ROOT):
		var path: String = "%s/%s/%s.tres" % [CHARACTERS_ROOT, folder, folder]
		if not ResourceLoader.exists(path):
			continue
		var data: CharacterData = load(path)
		for key in [data.name_key, data.style_key, data.trait_key, data.ability_key, data.variant_key]:
			_assert_key(key, String(data.id))
		for key in data.blade_color_keys:
			_assert_key(key, String(data.id))
		for costume in data.costumes:
			_assert_key(costume.name_key, String(costume.id))
			_assert_key(costume.requirement_key, String(costume.id))


func test_texts_used_by_code_exist() -> void:
	var regex: RegEx = RegEx.create_from_string(KEY_PATTERN)
	for root in CODE_ROOTS:
		for path in _scripts(root):
			var source: String = FileAccess.get_file_as_string(path)
			for found in regex.search_all(source):
				_assert_key(found.get_string(1), path.get_file())


func _scripts(folder: String) -> PackedStringArray:
	var paths: PackedStringArray = []
	for sub in DirAccess.get_directories_at(folder):
		paths.append_array(_scripts(folder.path_join(sub)))
	for file in DirAccess.get_files_at(folder):
		if file.ends_with(".gd"):
			paths.append(folder.path_join(file))
	return paths


func test_move_kinds_and_frame_results_have_names() -> void:
	for kind_name in MoveData.Kind.keys():
		_assert_key("MOVE_KIND_" + kind_name, "move kind")
	for type in TrainingPanel.FRAME_EVENTS:
		_assert_key("FRAME_" + CombatEvent.Type.find_key(type), "frame data")


func test_powers_and_techniques_have_names() -> void:
	for file in DirAccess.get_files_at(POWERS_ROOT):
		if file.ends_with(".tres") and file != "catalog.tres":
			var power: PowerData = load(POWERS_ROOT.path_join(file))
			_assert_key(power.name_key, String(power.id))
			_assert_key(power.description_key, String(power.id))
	for file in DirAccess.get_files_at(TECHNIQUES_ROOT):
		if file.ends_with(".tres"):
			var technique: MoveData = load(TECHNIQUES_ROOT.path_join(file))
			_assert_key(PowerCatalog.technique_key(technique), String(technique.id))


func test_hunts_have_bilingual_briefings_phases_rewards_and_dialogue() -> void:
	for hunt in HuntMode.HUNTS:
		for key in [hunt.title_key, hunt.condition.description_key, hunt.reward_key]:
			_assert_key(key, String(hunt.id))
		for phase in hunt.phases:
			_assert_key(phase.title_key, String(hunt.id))
		for line in hunt.before + hunt.after:
			_assert_key(line.text_key, String(hunt.id))
