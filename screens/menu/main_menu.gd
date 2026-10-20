extends Control

const TITLE_GAP: float = 12.0
const LIST_GAP: float = 72.0
const FOOTER_MARGIN: float = 36.0

var _list: MenuList


func _ready() -> void:
	var column: VBoxContainer = VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_CENTER)
	column.grow_horizontal = Control.GROW_DIRECTION_BOTH
	column.grow_vertical = Control.GROW_DIRECTION_BOTH
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(column)
	column.add_child(_label("GAME_TITLE", &"TitleLabel"))
	column.add_child(_spacer(TITLE_GAP))
	column.add_child(_label("GAME_TAGLINE", &"SubtitleLabel"))
	column.add_child(_spacer(LIST_GAP))
	var list_box: CenterContainer = CenterContainer.new()
	column.add_child(list_box)
	_list = MenuList.new()
	list_box.add_child(_list)
	_list.add_item(&"duel", tr("MENU_DUEL"))
	_list.add_item(&"training", tr("MENU_TRAINING"))
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


func _on_chosen(id: StringName) -> void:
	match id:
		&"duel":
			SceneRouter.change(&"duel", {"mode": VersusMode.new()})
		&"training":
			SceneRouter.change(&"duel", {"mode": TrainingMode.new()})
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
