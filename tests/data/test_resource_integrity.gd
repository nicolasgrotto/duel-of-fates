extends TestCase

const ROOTS: PackedStringArray = ["res://core", "res://simulation", "res://controllers", "res://data", "res://presentation", "res://modes", "res://screens", "res://ui"]
const CONFIG: InfiltrationConfig = preload("res://data/balance/infiltration_config.tres")
const FRAGILE_EXPORT: String = "@export[^:\\n]*:\\s*Packed\\w+Array\\s*=\\s*(\\[|Packed\\w+Array\\()"
const MIN_ENEMIES_WITH_PATROL: int = 2
const CHARACTERS: String = "res://data/characters"
const PATROL_MAP: InfiltrationMapData = preload("res://data/infiltration/patrol_map.tres")


func _scripts(folder: String, found: PackedStringArray) -> void:
	for file in DirAccess.get_files_at(folder):
		if file.ends_with(".gd"):
			found.append(folder.path_join(file))
	for sub in DirAccess.get_directories_at(folder):
		_scripts(folder.path_join(sub), found)


func _resources(folder: String, found: PackedStringArray) -> void:
	for file in DirAccess.get_files_at(folder):
		if file.ends_with(".tres"):
			found.append(folder.path_join(file))
	for sub in DirAccess.get_directories_at(folder):
		_resources(folder.path_join(sub), found)


func test_no_exported_packed_array_uses_a_default_the_editor_save_destroys() -> void:
	var pattern: RegEx = RegEx.create_from_string(FRAGILE_EXPORT)
	var scripts: PackedStringArray = []
	for root in ROOTS:
		_scripts(root, scripts)
	assert_gt(scripts.size(), 50.0)
	for path in scripts:
		assert_true(pattern.search(FileAccess.get_file_as_string(path)) == null, path)


func test_no_resource_keeps_a_null_written_by_a_stale_editor_save() -> void:
	var resources: PackedStringArray = []
	_resources("res://data", resources)
	var pattern: RegEx = RegEx.create_from_string("(?m)^\\w+ = null$")
	assert_gt(resources.size(), 50.0)
	for path in resources:
		assert_true(pattern.search(FileAccess.get_file_as_string(path)) == null, path)


func test_infiltration_maps_keep_their_layout_and_free_points() -> void:
	var maps: Array[InfiltrationMapData] = [PATROL_MAP]
	for mission in InfiltrationMode.MISSIONS:
		maps.append(mission.map)
		assert_true(mission.objective_count() > 0, String(mission.id))
		assert_eq(_is_free(mission.map, mission.extraction), true, String(mission.id))
		for point in mission.terminals:
			assert_eq(_is_free(mission.map, point), true, String(mission.id))
		for point in mission.prisoner_spawns:
			assert_eq(_is_free(mission.map, point), true, String(mission.id))
	for map in maps:
		assert_true(map.rows.size() > 0, String(map.id))
		assert_true(map.world_size().x > 0.0, String(map.id))
		for row in map.rows:
			assert_eq(row.length(), map.width(), String(map.id))
		assert_eq(_is_free(map, map.player_spawn), true, String(map.id))
		for panel in map.panels:
			assert_eq(_is_free(map, panel.position), true, String(map.id))
		for placement in map.enemies:
			assert_eq(_is_free(map, placement.position), true, String(map.id))
			for waypoint in placement.route:
				assert_eq(_is_free(map, waypoint), true, String(map.id))


func test_maps_with_patrols_keep_their_routes() -> void:
	var maps: Array[InfiltrationMapData] = [PATROL_MAP]
	for mission in InfiltrationMode.MISSIONS:
		maps.append(mission.map)
	for map in maps:
		var routes: int = 0
		for placement in map.enemies:
			routes += 1 if placement.route.size() > 0 else 0
		if map.enemies.size() > MIN_ENEMIES_WITH_PATROL:
			assert_gt(float(routes), 0.0, String(map.id))


func test_characters_keep_one_name_key_per_blade_color() -> void:
	for id in DirAccess.get_directories_at(CHARACTERS):
		var path: String = CHARACTERS.path_join(id).path_join(id + ".tres")
		if not ResourceLoader.exists(path):
			continue
		var data: CharacterData = load(path) as CharacterData
		assert_eq(data.blade_color_keys.size(), data.blade_colors.size(), id)


func _is_free(map: InfiltrationMapData, point: Vector2) -> bool:
	return InfiltrationGeometry.wall_fraction(map, point, point, CONFIG.body_radius) == INF
