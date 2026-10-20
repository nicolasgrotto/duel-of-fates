class_name MenuList
extends VBoxContainer

signal chosen(id: StringName)
signal adjusted(id: StringName, step: int)

const PALETTE: UiPalette = preload("res://ui/palette.tres")
const DASH_SIZE: Vector2 = Vector2(22.0, 2.0)
const ROW_SEPARATION: int = 18
const DASH_GAP: int = 14

var selected: int = 0
var _ids: Array[StringName] = []
var _labels: Array[Label] = []
var _dashes: Array[ColorRect] = []


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
	var index: int = _ids.size()
	row.gui_input.connect(_on_row_input.bind(index))
	add_child(row)
	_ids.append(id)
	_labels.append(label)
	_dashes.append(dash)
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
	elif event.is_action_pressed(&"ui_up"):
		_select(selected - 1)
	elif event.is_action_pressed(&"ui_accept"):
		chosen.emit(_ids[selected])
	elif event.is_action_pressed(&"ui_right"):
		adjusted.emit(_ids[selected], 1)
	elif event.is_action_pressed(&"ui_left"):
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


func _refresh() -> void:
	for i in _ids.size():
		var active: bool = i == selected
		_labels[i].theme_type_variation = &"MenuItemSelectedLabel" if active else &"MenuItemLabel"
		_dashes[i].modulate.a = 1.0 if active else 0.0
