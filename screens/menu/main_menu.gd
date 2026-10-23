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
const GROUPS: Dictionary = {
	&"play": {"title": "MENU_PLAY", "items": [[&"duel", "MENU_DUEL"], [&"two_players", "MENU_TWO_PLAYERS"]]},
	&"learn": {"title": "MENU_LEARN", "items": [[&"training", "MENU_TRAINING"], [&"controls", "MENU_CONTROLS"]]},
	&"extras": {"title": "MENU_EXTRAS", "items": [[&"gallery", "MENU_GALLERY"]]},
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
		var group: StringName = _group
		_show_group(ROOT)
		_list.select_id(group)
		get_viewport().set_input_as_handled()


func _on_highlighted(id: StringName) -> void:
	_last_focus[_group] = id


func _on_chosen(id: StringName) -> void:
	if GROUPS.has(id):
		_show_group(id)
		return
	match id:
		&"back":
			var group: StringName = _group
			_show_group(ROOT)
			_list.select_id(group)
		&"options":
			SceneRouter.change(&"options", {"focus": &"options"})
		&"duel":
			SceneRouter.change(&"select", {"mode": VersusMode.new()})
		&"training":
			SceneRouter.change(&"select", {"mode": TrainingMode.new()})
		&"two_players":
			SceneRouter.change(&"select", {"mode": TwoPlayerMode.new()})
		&"gallery":
			GalleryMode.new().start()
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
