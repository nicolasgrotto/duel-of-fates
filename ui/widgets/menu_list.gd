class_name MenuList
extends VBoxContainer

signal chosen(id: StringName)
signal adjusted(id: StringName, step: int)
signal highlighted(id: StringName)

const PALETTE: UiPalette = preload("res://ui/palette.tres")
const DASH_SIZE: Vector2 = Vector2(22.0, 2.0)
const ROW_SEPARATION: int = 18
const DASH_GAP: int = 14
const TINTED_IDLE_ALPHA: float = 0.6

var selected: int = 0
var centered: bool = false
var _ids: Array[StringName] = []
var _labels: Array[Label] = []
var _dashes: Array[ColorRect] = []
var _tinted: Array[bool] = []


func _ready() -> void:
	add_theme_constant_override(&"separation", ROW_SEPARATION)


func add_item(id: StringName, text: String) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override(&"separation", DASH_GAP)
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	var dash_box: CenterContainer = CenterContainer.new()
	var dash: ColorRect = ColorRect.new()
	dash.color = PALETTE.accent
	dash.custom_minimum_size = DASH_SIZE
	dash_box.add_child(dash)
	row.add_child(dash_box)
	var label: Label = Label.new()
	label.text = text
	row.add_child(label)
	if centered:
		row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var balance: Control = Control.new()
		balance.custom_minimum_size = DASH_SIZE
		row.add_child(balance)
	var index: int = _ids.size()
	row.gui_input.connect(_on_row_input.bind(index))
	add_child(row)
	_ids.append(id)
	_labels.append(label)
	_dashes.append(dash)
	_tinted.append(false)
	_refresh()


func set_item_color(id: StringName, color: Color) -> void:
	var index: int = _ids.find(id)
	if index < 0:
		return
	_labels[index].add_theme_color_override(&"font_color", color)
	_dashes[index].color = color
	_tinted[index] = true
	_refresh()


func set_item_text(id: StringName, text: String) -> void:
	var index: int = _ids.find(id)
	if index >= 0:
		_labels[index].text = text


func _unhandled_input(event: InputEvent) -> void:
	if _ids.is_empty() or not is_visible_in_tree():
		return
	if event.is_action_pressed(&"ui_down"):
		_select(selected + 1)
		AudioDirector.play_ui(&"ui_move")
	elif event.is_action_pressed(&"ui_up"):
		_select(selected - 1)
		AudioDirector.play_ui(&"ui_move")
	elif event.is_action_pressed(&"ui_accept"):
		AudioDirector.play_ui(&"ui_confirm")
		chosen.emit(_ids[selected])
	elif event.is_action_pressed(&"ui_right"):
		AudioDirector.play_ui(&"ui_move")
		adjusted.emit(_ids[selected], 1)
	elif event.is_action_pressed(&"ui_left"):
		AudioDirector.play_ui(&"ui_move")
		adjusted.emit(_ids[selected], -1)
	else:
		return
	get_viewport().set_input_as_handled()


func _on_row_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseMotion and index != selected:
		_select(index)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select(index)
		chosen.emit(_ids[index])


func _select(index: int) -> void:
	selected = posmod(index, _ids.size())
	_refresh()
	highlighted.emit(_ids[selected])


func clear_items() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_ids.clear()
	_labels.clear()
	_dashes.clear()
	_tinted.clear()
	selected = 0


func select_id(id: StringName) -> void:
	var index: int = _ids.find(id)
	if index >= 0:
		_select(index)


func current_id() -> StringName:
	return _ids[selected] if not _ids.is_empty() else &""


func _refresh() -> void:
	for i in _ids.size():
		var active: bool = i == selected
		_labels[i].theme_type_variation = &"MenuItemSelectedLabel" if active else &"MenuItemLabel"
		_dashes[i].modulate.a = 1.0 if active else 0.0
		_labels[i].modulate.a = TINTED_IDLE_ALPHA if _tinted[i] and not active else 1.0
