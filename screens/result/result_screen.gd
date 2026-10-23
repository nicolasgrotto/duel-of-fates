extends Control

const PALETTE: UiPalette = preload("res://ui/palette.tres")
const OVERLAY_ALPHA: float = 0.78
const SECTION_GAP: float = 36.0
const COLUMN_GAP: int = 64
const ROW_GAP: int = 8
const STAT_LABELS: Dictionary = {
	&"hits": "STAT_HITS",
	&"damage": "STAT_DAMAGE",
	&"blocks": "STAT_BLOCKS",
	&"parries": "STAT_PARRIES",
	&"perfect_parries": "STAT_PERFECT_PARRIES",
	&"guard_breaks": "STAT_GUARD_BREAKS",
	&"shoves": "STAT_SHOVES",
	&"best_combo": "STAT_BEST_COMBO",
}
const OPTION_LABELS: Dictionary = {
	&"rematch": "RESULT_REMATCH",
	&"menu": "RESULT_MENU",
	&"next": "RESULT_NEXT",
	&"retry": "RESULT_RETRY",
	&"parry_challenge": "MENU_PARRY_CHALLENGE",
}

var mode: DuelMode
var _column: VBoxContainer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var overlay: ColorRect = ColorRect.new()
	overlay.color = Color(PALETTE.background, OVERLAY_ALPHA)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	_column = VBoxContainer.new()
	_column.set_anchors_preset(Control.PRESET_CENTER)
	_column.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_column.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(_column)


func open(params: Dictionary) -> void:
	mode = params["mode"]
	var names: Array = params["names"]
	var winner: int = params["winner"]
	var player: int = params["player_index"]
	var title: String = tr("RESULT_VICTORY") if winner == player else tr("RESULT_DEFEAT")
	if player < 0 and winner >= 0:
		title = tr("RESULT_PLAYER_WINS").format({"player": winner + 1})
	if params.get("title", "") != "":
		title = params["title"]
	_column.add_child(_label(title, &"TitleLabel"))
	if params.get("note", "") != "":
		_column.add_child(_label(params["note"], &"SubtitleLabel"))
	for message in params.get("unlocks", PackedStringArray()):
		var unlock: Label = _label(message, &"SubtitleLabel")
		unlock.add_theme_color_override(&"font_color", PALETTE.potential)
		_column.add_child(unlock)
	if winner >= 0:
		_column.add_child(_label(tr("RESULT_WINNER").format({"name": names[winner]}), &"SubtitleLabel"))
	_column.add_child(_label(tr("RESULT_DURATION").format({"time": _time_text(params["duration"])}), &"HintLabel"))
	_column.add_child(_spacer())
	_column.add_child(_stats_table(names, params["stats"]))
	_column.add_child(_spacer())
	var list_box: CenterContainer = CenterContainer.new()
	_column.add_child(list_box)
	var list: MenuList = MenuList.new()
	list_box.add_child(list)
	for option in mode.result_options():
		list.add_item(option, tr(OPTION_LABELS[option]))
	list.chosen.connect(mode.choose)


func _stats_table(names: Array, stats: Array) -> CenterContainer:
	var box: CenterContainer = CenterContainer.new()
	var grid: GridContainer = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override(&"h_separation", COLUMN_GAP)
	grid.add_theme_constant_override(&"v_separation", ROW_GAP)
	box.add_child(grid)
	grid.add_child(_label("", &"HintLabel"))
	grid.add_child(_label(names[0], &"HudNameLabel"))
	grid.add_child(_label(names[1], &"HudNameLabel"))
	for key in STAT_LABELS:
		grid.add_child(_label(tr(STAT_LABELS[key]), &"HintLabel", HORIZONTAL_ALIGNMENT_LEFT))
		grid.add_child(_label(str(stats[0][key]), &"Label"))
		grid.add_child(_label(str(stats[1][key]), &"Label"))
	return box


func _time_text(seconds: float) -> String:
	var total: int = int(seconds)
	return "%d:%02d" % [floori(total / 60.0), total % 60]


func _label(text: String, variation: StringName, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.theme_type_variation = variation
	label.horizontal_alignment = alignment
	return label


func _spacer() -> Control:
	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0.0, SECTION_GAP)
	return spacer
