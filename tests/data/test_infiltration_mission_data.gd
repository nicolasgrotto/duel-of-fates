extends TestCase

const CONFIG: InfiltrationConfig = preload("res://data/balance/infiltration_config.tres")


func test_all_mission_layouts_have_valid_points_routes_and_text_in_both_languages() -> void:
	assert_eq(InfiltrationMode.MISSIONS.size(), 5)
	var ids: Dictionary = {}
	var layouts: Dictionary = {}
	var saved_locale: String = TranslationServer.get_locale()
	for mission in InfiltrationMode.MISSIONS:
		assert_false(ids.has(mission.id))
		ids[mission.id] = true
		layouts[hash(mission.map.rows)] = true
		for locale in ["pt_BR", "en"]:
			TranslationServer.set_locale(locale)
			assert_true(TranslationServer.translate(mission.title_key) != mission.title_key)
			assert_true(TranslationServer.translate(mission.briefing_key) != mission.briefing_key)
		var map: InfiltrationMapData = mission.map
		var points: PackedVector2Array = [map.player_spawn, mission.extraction]
		points.append_array(mission.terminals)
		points.append_array(mission.prisoner_spawns)
		for panel in map.panels:
			points.append(panel.position)
		for placement in map.enemies:
			points.append(placement.position)
			points.append_array(placement.route)
		for row in map.rows:
			assert_eq(row.length(), map.width())
		for point in points:
			assert_eq(InfiltrationGeometry.wall_fraction(map, point, point, CONFIG.body_radius), INF)
	assert_eq(layouts.size(), 5)
	TranslationServer.set_locale(saved_locale)
