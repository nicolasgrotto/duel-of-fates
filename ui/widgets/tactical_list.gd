class_name TacticalList
extends MenuList

const ROW_HEIGHT: float = 38.0
const ROW_GAP: int = 0
const CELL_GAP: int = 10
const MARK_WIDTH: float = 52.0
const TIME_WIDTH: float = 96.0
const HEADING_TOP: float = 8.0
const RULE_HEIGHT: float = 1.0
const RULE_GAP: int = 8

var row_height: float = ROW_HEIGHT
var active: bool = true:
	set(value):
		active = value
		set_process_unhandled_input(value)
		_refresh()
var _rows: Array[PanelContainer] = []
var _dimmed: Array[bool] = []


func _ready() -> void:
	add_theme_constant_override(&"separation", ROW_GAP)


func add_item(id: StringName, text: String) -> void:
	add_row(id, text)


func add_row(id: StringName, text: String, state: StatusGlyph.State = StatusGlyph.State.NONE, mark: String = "", time: String = "", dimmed: bool = false, extra: Control = null) -> void:
	var row: PanelContainer = PanelContainer.new()
	row.custom_minimum_size.y = row_height
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	var cells: HBoxContainer = HBoxContainer.new()
	cells.add_theme_constant_override(&"separation", CELL_GAP)
	cells.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(cells)
	if state != StatusGlyph.State.NONE:
		cells.add_child(StatusGlyph.new(state))
	var label: Label = _cell(text, &"TacticalRowDimLabel" if dimmed else &"TacticalRowLabel")
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.clip_text = true
	cells.add_child(label)
	if extra != null:
		extra.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		cells.add_child(extra)
	if mark != "":
		var mark_label: Label = _cell(mark, &"TacticalMarkLabel")
		mark_label.custom_minimum_size.x = MARK_WIDTH
		mark_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cells.add_child(mark_label)
	if time != "":
		var time_label: Label = _cell(time, &"TacticalMutedLabel")
		time_label.custom_minimum_size.x = TIME_WIDTH
		time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		cells.add_child(time_label)
	var index: int = _ids.size()
	row.gui_input.connect(_on_row_input.bind(index))
	add_child(row)
	_ids.append(id)
	_labels.append(label)
	_rows.append(row)
	_dimmed.append(dimmed)
	_refresh()


func add_heading(text: String) -> void:
	var box: VBoxContainer = VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override(&"separation", 0)
	var space: Control = Control.new()
	space.custom_minimum_size.y = HEADING_TOP
	box.add_child(space)
	box.add_child(_cell(text.to_upper(), &"TacticalGroupLabel"))
	add_child(box)


func add_rule() -> void:
	var box: MarginContainer = MarginContainer.new()
	box.add_theme_constant_override(&"margin_top", RULE_GAP)
	box.add_theme_constant_override(&"margin_bottom", RULE_GAP)
	var line: ColorRect = ColorRect.new()
	line.custom_minimum_size.y = RULE_HEIGHT
	line.color = PALETTE.tactical_line
	box.add_child(line)
	add_child(box)


func set_item_color(id: StringName, color: Color) -> void:
	var index: int = _ids.find(id)
	if index >= 0:
		_labels[index].add_theme_color_override(&"font_color", color)


func clear_items() -> void:
	super.clear_items()
	_rows.clear()
	_dimmed.clear()


func row_control(id: StringName) -> Control:
	var index: int = _ids.find(id)
	return _rows[index] if index >= 0 else null


func _refresh() -> void:
	for index in _rows.size():
		var held: StringName = &"TacticalRowSelected" if active else &"TacticalRowHeld"
		_rows[index].theme_type_variation = held if index == selected else &"TacticalRow"


func _cell(text: String, variation: StringName) -> Label:
	var label: Label = Label.new()
	label.theme_type_variation = variation
	label.text = text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
