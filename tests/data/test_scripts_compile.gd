extends TestCase

const ROOTS: PackedStringArray = ["res://core", "res://simulation", "res://controllers", "res://data", "res://presentation", "res://screens", "res://modes", "res://ui", "res://arenas"]


func _collect(folder: String, found: PackedStringArray) -> void:
	for file in DirAccess.get_files_at(folder):
		if file.ends_with(".gd"):
			found.append(folder.path_join(file))
	for sub in DirAccess.get_directories_at(folder):
		_collect(folder.path_join(sub), found)


func test_every_game_script_compiles() -> void:
	var scripts: PackedStringArray = []
	for root in ROOTS:
		_collect(root, scripts)
	assert_gt(scripts.size(), 50.0)
	for path in scripts:
		var script: GDScript = load(path) as GDScript
		assert_true(script != null and script.can_instantiate(), path)
