extends Control

const TITLE_TOP: float = 90.0
const LIST_TOP: float = 220.0
const FOOTER_MARGIN: float = 36.0
const STATUS_GAP: float = 30.0
const PALETTE: UiPalette = preload("res://ui/palette.tres")

var _list: MenuList
var _title: Label
var _status: Label
var _footer: Label
var _waiting: String = ""


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_title = _label(&"ScreenTitleLabel")
	_title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_title.offset_top = TITLE_TOP
	_title.text = tr("KEYS_TITLE")
	var holder: VBoxContainer = VBoxContainer.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	holder.offset_top = LIST_TOP
	add_child(holder)
	_list = MenuList.new()
	_list.centered = true
	holder.add_child(_list)
	for action in InputBindings.REBINDABLE:
		_list.add_item(StringName(action), "")
	_list.add_item(&"restore", tr("KEYS_RESTORE"))
	_list.add_item(&"back", tr("MENU_BACK"))
	_list.chosen.connect(_on_chosen)
	_status = _label(&"HintLabel")
	_status.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_status.offset_top = -FOOTER_MARGIN - STATUS_GAP * 3.0
	_status.offset_bottom = -FOOTER_MARGIN - STATUS_GAP * 2.0
	_footer = _label(&"HintLabel")
	_footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_footer.offset_top = -FOOTER_MARGIN - STATUS_GAP
	_footer.offset_bottom = -FOOTER_MARGIN
	_footer.text = ControlHints.line(PackedStringArray([
		"↑ ↓  " + tr("HINT_CHANGE"), ControlHints.hint(&"ui_accept", "HINT_CONFIRM"), ControlHints.hint(&"ui_cancel", "HINT_BACK"),
	]))
	_refresh()


func _label(variation: StringName) -> Label:
	var label: Label = Label.new()
	label.theme_type_variation = variation
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)
	return label


func _input(event: InputEvent) -> void:
	if _waiting == "":
		return
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	get_viewport().set_input_as_handled()
	var code: Key = key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
	if code == KEY_ESCAPE:
		_waiting = ""
		_list.set_process_unhandled_input(true)
		_refresh()
		return
	if InputBindings.is_reserved(code):
		_status.text = tr("KEYS_RESERVED").format({"key": ControlHints.key_name(code)})
		_status.add_theme_color_override(&"font_color", PALETTE.danger)
		AudioDirector.play_ui(&"rejected")
		return
	Settings.set_custom_keys(InputBindings.rebind(InputBindings.keyboard_map(), _waiting, code))
	Settings.apply()
	Settings.save_settings()
	_waiting = ""
	_list.set_process_unhandled_input(true)
	AudioDirector.play_ui(&"ui_confirm")
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if _waiting == "" and event.is_action_pressed(&"ui_cancel"):
		_leave()
		get_viewport().set_input_as_handled()


func _on_chosen(id: StringName) -> void:
	match id:
		&"back":
			_leave()
		&"restore":
			Settings.key_preset = &"default"
			Settings.custom_keys = {}
			Settings.apply()
			Settings.save_settings()
			_refresh()
		_:
			_waiting = String(id)
			_list.set_process_unhandled_input(false)
			_status.remove_theme_color_override(&"font_color")
			_status.text = tr("KEYS_WAITING").format({"action": tr(_action_key(_waiting))})


func _refresh() -> void:
	_status.text = ""
	for action in InputBindings.REBINDABLE:
		var keys: PackedStringArray = ControlHints.key_names(StringName(InputBindings.player_prefix(0) + action))
		_list.set_item_text(StringName(action), tr("KEYS_ROW").format({"action": tr(_action_key(action)), "keys": " / ".join(keys)}))


static func _action_key(action: String) -> String:
	return "ACTION_" + action.to_upper()


func _leave() -> void:
	SceneRouter.change(&"options", {"select": &"keys"})
