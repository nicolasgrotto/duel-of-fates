extends Control

const TITLE_GAP: float = 12.0
const LIST_GAP: float = 72.0
const FOOTER_MARGIN: float = 36.0
const WEB_FEATURE: String = "web"
const EMBLEM_SPACE: float = 250.0
const EMBLEM_LIFT: float = 178.0

const GROUP_GAP: float = 18.0
const COLUMN_TOP: float = 215.0
const ROOT: StringName = &"root"
const LESSON_PATH: String = "res://data/lessons/%s.tres"
const CHALLENGE_PATH: String = "res://data/challenges/%s.tres"
const GROUPS: Dictionary = {
	&"play": {"title": "MENU_PLAY", "items": [[&"story", "MENU_STORY"], [&"duel", "MENU_DUEL"], [&"battles", "MENU_BATTLES"], [&"special", "MENU_SPECIAL"]]},
	&"duel": {"title": "MENU_DUEL", "parent": &"play", "items": [[&"versus", "MENU_ONE_PLAYER"], [&"two_players", "MENU_TWO_PLAYERS"], [&"spectate", "MENU_CPU_VS_CPU"]]},
	&"battles": {"title": "MENU_BATTLES", "parent": &"play", "items": [[&"arcade", "MENU_ARCADE"], [&"survival", "MENU_SURVIVAL"], [&"hunts", "MENU_HUNTS"]]},
	&"special": {"title": "MENU_SPECIAL", "parent": &"play", "items": [[&"infiltration", "MENU_INFILTRATION"], [&"space", "MENU_SPACE"]]},
	&"learn": {"title": "MENU_LEARN", "items": [[&"tutorial", "MENU_TUTORIAL"], [&"guided", "MENU_GUIDED"], [&"training", "MENU_TRAINING"], [&"parry_challenge", "MENU_PARRY_CHALLENGE"], [&"controls", "MENU_CONTROLS"]]},
	&"extras": {"title": "MENU_EXTRAS", "items": [[&"challenges", "MENU_CHALLENGES"], [&"gallery", "MENU_GALLERY"], [&"story_gallery", "MENU_STORY_GALLERY"], [&"exhibition_duel", "MENU_EXHIBITION_DUEL"], [&"exhibition", "MENU_EXHIBITION_SEQUENCE"]]},
	&"guided": {"title": "MENU_GUIDED", "parent": &"learn", "items": [[&"guided_evade", "LESSON_GUIDED_EVADE"], [&"guided_exhaustion", "LESSON_GUIDED_EXHAUSTION"], [&"guided_lock", "LESSON_GUIDED_LOCK"]]},
	&"challenges": {"title": "MENU_CHALLENGES", "parent": &"extras", "items": [[&"salt_flats_bladework", "CHALLENGE_SALT"], [&"storm_on_deck", "CHALLENGE_STORM"], [&"last_breath", "CHALLENGE_LAST_BREATH"], [&"under_the_eclipse", "CHALLENGE_ECLIPSE"]]},
}

static var _last_group: StringName = ROOT
static var _last_focus: Dictionary = {}

var _list: MenuList
var _emblem: MenuEmblem
var _emblem_space: Control
var _group_label: Label
var _group: StringName = ROOT


func _ready() -> void:
	_emblem = MenuEmblem.new()
	add_child(_emblem)
	var column: VBoxContainer = VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_CENTER_TOP)
	column.grow_horizontal = Control.GROW_DIRECTION_BOTH
	column.offset_top = COLUMN_TOP
	add_child(column)
	_emblem_space = _spacer(EMBLEM_SPACE)
	column.add_child(_emblem_space)
	column.add_child(_label("GAME_TITLE", &"TitleLabel"))
	column.add_child(_spacer(TITLE_GAP))
	column.add_child(_label("GAME_TAGLINE", &"SubtitleLabel"))
	column.add_child(_spacer(LIST_GAP))
	_group_label = _label("", &"HintLabel")
	column.add_child(_group_label)
	column.add_child(_spacer(GROUP_GAP))
	_list = MenuList.new()
	_list.centered = true
	column.add_child(_list)
	_list.chosen.connect(_on_chosen)
	_list.highlighted.connect(_on_highlighted)
	_show_group(_last_group)
	var footer: Label = _label("", &"HintLabel")
	footer.text = ControlHints.line(PackedStringArray([
		"↑ ↓  " + tr("HINT_CHANGE"),
		ControlHints.hint(&"ui_accept", "HINT_CONFIRM"),
		ControlHints.hint(&"ui_cancel", "HINT_BACK"),
	]))
	footer.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	footer.grow_horizontal = Control.GROW_DIRECTION_BOTH
	footer.grow_vertical = Control.GROW_DIRECTION_BEGIN
	footer.offset_bottom = -FOOTER_MARGIN
	add_child(footer)


func _process(_delta: float) -> void:
	var space: Rect2 = _emblem_space.get_global_rect()
	_emblem.cross_point = Vector2(space.get_center().x, space.end.y - EMBLEM_LIFT)


func open(params: Dictionary) -> void:
	if params.has("group"):
		_last_group = params["group"]
		if params.has("focus"):
			_last_focus[_last_group] = params["focus"]
		_show_group(_last_group)


func _show_group(group: StringName) -> void:
	_group = group if group == ROOT or GROUPS.has(group) else ROOT
	_last_group = _group
	_list.clear_items()
	if _group == ROOT:
		_group_label.text = ""
		for id in GROUPS:
			if not GROUPS[id].has("parent"):
				_list.add_item(id, tr(GROUPS[id]["title"]))
		_list.add_item(&"options", tr("MENU_OPTIONS"))
		if not OS.has_feature(WEB_FEATURE):
			_list.add_item(&"quit", tr("MENU_QUIT"))
	else:
		_group_label.text = tr(GROUPS[_group]["title"]).to_upper()
		for item in GROUPS[_group]["items"]:
			_list.add_item(item[0], tr(item[1]))
		_list.add_item(&"back", tr("MENU_BACK"))
	if _last_focus.has(_group):
		_list.select_id(_last_focus[_group])


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") and _group != ROOT:
		_go_back()
		get_viewport().set_input_as_handled()


func _go_back() -> void:
	var group: StringName = _group
	_show_group(GROUPS[group].get("parent", ROOT))
	_list.select_id(group)


func _on_highlighted(id: StringName) -> void:
	_last_focus[_group] = id


func _on_chosen(id: StringName) -> void:
	if GROUPS.has(id):
		_show_group(id)
		return
	match id:
		&"back":
			_go_back()
		&"tutorial", &"guided_evade", &"guided_exhaustion", &"guided_lock":
			LessonMode.new(load(LESSON_PATH % id)).start()
		&"parry_challenge":
			ParryChallengeMode.new().start()
		&"salt_flats_bladework", &"storm_on_deck", &"last_breath", &"under_the_eclipse":
			ChallengeMode.new(load(CHALLENGE_PATH % id)).start()
		&"options":
			SceneRouter.change(&"options", {"focus": &"options"})
		&"versus":
			SceneRouter.change(&"select", {"mode": VersusMode.new()})
		&"training":
			SceneRouter.change(&"select", {"mode": TrainingMode.new()})
		&"two_players":
			SceneRouter.change(&"select", {"mode": TwoPlayerMode.new()})
		&"spectate":
			SceneRouter.change(&"select", {"mode": SpectateMode.new()})
		&"arcade":
			SceneRouter.change(&"select", {"mode": ArcadeMode.new()})
		&"survival":
			SceneRouter.change(&"select", {"mode": SurvivalMode.new()})
		&"hunts":
			SceneRouter.change(&"hunts")
		&"space":
			SceneRouter.change(&"space")
		&"infiltration":
			SceneRouter.change(&"infiltration")
		&"gallery":
			GalleryMode.new().start()
		&"exhibition":
			ExhibitionMode.new().start()
		&"exhibition_duel":
			ExhibitionMode.new(ExhibitionMode.SHOWCASE).start()
		&"story":
			SceneRouter.change(&"story_hub" if not SaveService.campaign.is_empty() else &"story_new")
		&"story_gallery":
			SceneRouter.change(&"story_gallery")
		&"controls":
			SceneRouter.change(&"controls")
		&"quit":
			get_tree().quit()


func _label(text_key: String, variation: StringName) -> Label:
	var label: Label = Label.new()
	label.text = tr(text_key) if text_key != "" else ""
	label.theme_type_variation = variation
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _spacer(height: float) -> Control:
	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0.0, height)
	return spacer
