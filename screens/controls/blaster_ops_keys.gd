extends Control

var _list: MenuList
var _status: Label
var _waiting: String = ""


func _ready() -> void:
	BlasterOpsBindings.install(Settings.blaster_ops_keys, Settings.blaster_ops_buttons)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var title: Label = _label(&"ScreenTitleLabel")
	title.text = tr("BOPS_KEYS_TITLE")
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 90.0
	var holder: VBoxContainer = VBoxContainer.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.offset_top = 180.0
	holder.offset_bottom = -190.0
	add_child(holder)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	holder.add_child(scroll)
	_list = MenuList.new()
	_list.centered = true
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	_list.highlighted.connect(func(id: StringName) -> void: scroll.ensure_control_visible(_list.get_child(_list._ids.find(id))))
	for action in BlasterOpsBindings.ACTIONS:
		_list.add_item(StringName(action), "")
	_list.add_item(&"restore", tr("KEYS_RESTORE"))
	_list.add_item(&"back", tr("MENU_BACK"))
	_list.chosen.connect(_on_chosen)
	_status = _label(&"HintLabel")
	_status.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_status.offset_top = -150.0
	var footer: Label = _label(&"HintLabel")
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_top = -70.0
	footer.text = ControlHints.line(PackedStringArray([ControlHints.hint(&"ui_accept", "HINT_CONFIRM"), ControlHints.hint(&"ui_cancel", "HINT_BACK")]))
	_refresh()


func _label(variation: StringName) -> Label:
	var label: Label = Label.new()
	label.theme_type_variation = variation
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)
	return label


func _refresh() -> void:
	for action in BlasterOpsBindings.ACTIONS:
		_list.set_item_text(StringName(action), ControlHints.blaster_ops_hint(action))


func _on_chosen(id: StringName) -> void:
	if id == &"back":
		_leave()
	elif id == &"restore":
		Settings.blaster_ops_keys = {}
		Settings.blaster_ops_buttons = {}
		_commit()
	else:
		_waiting = String(id)
		_list.set_process_unhandled_input(false)
		_status.text = tr("KEYS_WAITING").format({"action": tr("BOPS_ACTION_" + _waiting.to_upper())})


func _input(event: InputEvent) -> void:
	if _waiting.is_empty() or event.is_echo():
		return
	if event is InputEventKey and event.pressed:
		get_viewport().set_input_as_handled()
		var code: Key = event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode
		if code == KEY_ESCAPE:
			_finish()
		elif not InputBindings.is_reserved(code) and not BlasterOpsBindings.is_unsafe_key(code):
			Settings.blaster_ops_keys = InputBindings.rebind(BlasterOpsBindings.keyboard_map(), _waiting, code)
			_commit()
		else:
			_status.text = tr("KEYS_RESERVED").format({"key": ControlHints.key_name(code)})
	elif event is InputEventJoypadButton and event.pressed:
		get_viewport().set_input_as_handled()
		if not InputBindings.is_reserved_button(event.button_index):
			Settings.blaster_ops_buttons = InputBindings.rebind_button(BlasterOpsBindings.button_map(), _waiting, event.button_index)
			_commit()
		else:
			_status.text = tr("KEYS_RESERVED").format({"key": ControlHints.button_name(event.button_index)})


func _commit() -> void:
	BlasterOpsBindings.apply(Settings.blaster_ops_keys, Settings.blaster_ops_buttons)
	InfiltrationBindings.refresh()
	Settings.save_settings()
	AudioDirector.play_ui(&"ui_confirm")
	_finish()


func _finish() -> void:
	_waiting = ""
	_status.text = ""
	_list.set_process_unhandled_input(true)
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if _waiting.is_empty() and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_leave()


func _leave() -> void:
	SceneRouter.change(&"keys")


func _exit_tree() -> void:
	BlasterOpsBindings.uninstall()
