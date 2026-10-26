extends Control

const PALETTE: UiPalette = preload("res://ui/palette.tres")
const OVERLAY_ALPHA: float = 0.72
const TITLE_GAP: float = 48.0

var mode: DuelMode
var _list: MenuList
var _move_lists: Array[Dictionary] = []


func open(params: Dictionary) -> void:
	mode = params["mode"]
	_move_lists.assign(params.get("move_lists", []))
	_list.add_item(&"continue", tr("PAUSE_CONTINUE"))
	for index in _move_lists.size():
		var label: String = tr("PAUSE_MOVES") if _move_lists.size() == 1 else tr("PAUSE_MOVES_PLAYER").format({"player": _move_lists[index]["player"]})
		_list.add_item(StringName("moves_%d" % index), label)
	_list.add_item(&"restart", tr("PAUSE_RESTART"))
	_list.add_item(&"quit", tr("PAUSE_QUIT"))


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var overlay: ColorRect = ColorRect.new()
	overlay.color = Color(PALETTE.background, OVERLAY_ALPHA)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	var column: VBoxContainer = VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_CENTER)
	column.grow_horizontal = Control.GROW_DIRECTION_BOTH
	column.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(column)
	var title: Label = Label.new()
	title.text = tr("PAUSE_TITLE")
	title.theme_type_variation = &"TitleLabel"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0.0, TITLE_GAP)
	column.add_child(spacer)
	var list_box: CenterContainer = CenterContainer.new()
	column.add_child(list_box)
	_list = MenuList.new()
	list_box.add_child(_list)
	_list.chosen.connect(_on_chosen)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"p1_pause") or event.is_action_pressed(&"p2_pause"):
		get_viewport().set_input_as_handled()
		SceneRouter.pop()


func _on_chosen(id: StringName) -> void:
	match id:
		&"continue":
			SceneRouter.pop()
		&"restart":
			mode.restart()
		&"quit":
			SceneRouter.change(&"menu")
		_:
			if String(id).begins_with("moves_"):
				SceneRouter.push(&"moves", _move_lists[int(String(id).get_slice("_", 1))])
