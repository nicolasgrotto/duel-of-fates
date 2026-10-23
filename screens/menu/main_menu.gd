extends Control

const TITLE_GAP: float = 12.0
const LIST_GAP: float = 72.0
const FOOTER_MARGIN: float = 36.0
const EMBLEM_SPACE: float = 250.0
const EMBLEM_LIFT: float = 178.0

var _list: MenuList
var _emblem: MenuEmblem
var _emblem_space: Control


func _ready() -> void:
	_emblem = MenuEmblem.new()
	add_child(_emblem)
	var column: VBoxContainer = VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_CENTER)
	column.grow_horizontal = Control.GROW_DIRECTION_BOTH
	column.grow_vertical = Control.GROW_DIRECTION_BOTH
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(column)
	_emblem_space = _spacer(EMBLEM_SPACE)
	column.add_child(_emblem_space)
	column.add_child(_label("GAME_TITLE", &"TitleLabel"))
	column.add_child(_spacer(TITLE_GAP))
	column.add_child(_label("GAME_TAGLINE", &"SubtitleLabel"))
	column.add_child(_spacer(LIST_GAP))
	_list = MenuList.new()
	_list.centered = true
	column.add_child(_list)
	_list.add_item(&"duel", tr("MENU_DUEL"))
	_list.add_item(&"training", tr("MENU_TRAINING"))
	_list.add_item(&"gallery", tr("MENU_GALLERY"))
	_list.add_item(&"difficulty", "")
	_list.add_item(&"quit", tr("MENU_QUIT"))
	_list.chosen.connect(_on_chosen)
	_list.adjusted.connect(_on_adjusted)
	_refresh_difficulty()
	var footer: Label = _label("", &"HintLabel")
	footer.text = ControlHints.line(PackedStringArray([
		"↑ ↓  " + tr("HINT_CHANGE"),
		ControlHints.hint(&"ui_accept", "HINT_CONFIRM"),
	]))
	footer.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	footer.grow_horizontal = Control.GROW_DIRECTION_BOTH
	footer.grow_vertical = Control.GROW_DIRECTION_BEGIN
	footer.offset_bottom = -FOOTER_MARGIN
	add_child(footer)


func _process(_delta: float) -> void:
	var space: Rect2 = _emblem_space.get_global_rect()
	_emblem.cross_point = Vector2(space.get_center().x, space.end.y - EMBLEM_LIFT)


func _on_chosen(id: StringName) -> void:
	match id:
		&"duel":
			SceneRouter.change(&"select", {"mode": VersusMode.new()})
		&"training":
			SceneRouter.change(&"select", {"mode": TrainingMode.new()})
		&"gallery":
			GalleryMode.new().start()
		&"difficulty":
			_on_adjusted(id, 1)
		&"quit":
			get_tree().quit()


func _on_adjusted(id: StringName, step: int) -> void:
	if id == &"difficulty":
		Settings.cycle_difficulty(step)
		_refresh_difficulty()


func _refresh_difficulty() -> void:
	var name_key: String = Settings.difficulty_data().name_key
	_list.set_item_text(&"difficulty", tr("MENU_DIFFICULTY").format({"value": tr(name_key)}))


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
