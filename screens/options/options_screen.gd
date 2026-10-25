extends Control

const TITLE_TOP: float = 90.0
const LIST_TOP: float = 220.0
const FOOTER_MARGIN: float = 36.0
const WEB_FEATURE: String = "web"
const LOCALE_KEYS: Dictionary = {"pt_BR": "LANGUAGE_PT_BR", "en": "LANGUAGE_EN"}
const PRESET_KEYS: Dictionary = {&"default": "PRESET_DEFAULT", &"arrows": "PRESET_ARROWS", &"custom": "PRESET_CUSTOM"}

var _list: MenuList
var _title: Label
var _footer: Label
var _scroll: ScrollContainer
var _return_focus: StringName = &"options"


func open(params: Dictionary) -> void:
	_return_focus = params.get("focus", &"options")
	if params.has("select"):
		_list.select_id(params["select"])


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_title = Label.new()
	_title.theme_type_variation = &"ScreenTitleLabel"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_title.offset_top = TITLE_TOP
	add_child(_title)
	_scroll = ScrollContainer.new()
	_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scroll.offset_top = LIST_TOP
	_scroll.offset_bottom = -FOOTER_MARGIN * 3.0
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll)
	_list = MenuList.new()
	_list.centered = true
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_list)
	for id in _ids():
		_list.add_item(id, "")
	_list.chosen.connect(_on_chosen)
	_list.adjusted.connect(_on_adjusted)
	_list.highlighted.connect(_on_highlighted)
	_footer = Label.new()
	_footer.theme_type_variation = &"HintLabel"
	_footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_footer.offset_top = -FOOTER_MARGIN - 30.0
	_footer.offset_bottom = -FOOTER_MARGIN
	add_child(_footer)
	_refresh()
	_on_highlighted(_list.current_id())


func _on_highlighted(_id: StringName) -> void:
	_scroll.ensure_control_visible.call_deferred(_list.get_child(_list.selected))


func _ids() -> Array[StringName]:
	var ids: Array[StringName] = [&"language", &"difficulty", &"effects", &"intros", &"replay", &"finishers", &"powers", &"hold_p1", &"hold_p2",
		&"key_preset", &"keys", &"vibration", &"master", &"music", &"sfx", &"fullscreen"]
	if not OS.has_feature(WEB_FEATURE):
		ids.append(&"vsync")
	ids.append(&"back")
	return ids


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		_leave()
		get_viewport().set_input_as_handled()


func _on_chosen(id: StringName) -> void:
	if id == &"back":
		_leave()
	elif id == &"keys":
		SceneRouter.change(&"keys")
	else:
		_on_adjusted(id, 1)


func _on_adjusted(id: StringName, step: int) -> void:
	match id:
		&"language":
			Settings.cycle_locale(step)
		&"difficulty":
			Settings.cycle_difficulty(step)
		&"effects":
			Settings.reduced_effects = not Settings.reduced_effects
		&"replay":
			Settings.final_blow_replay = not Settings.final_blow_replay
		&"intros":
			Settings.fighter_intros = not Settings.fighter_intros
		&"finishers":
			Settings.show_finishers = not Settings.show_finishers
		&"powers":
			Settings.powers = not Settings.powers
		&"hold_p1":
			Settings.hold_to_lock[0] = not Settings.hold_to_lock[0]
		&"hold_p2":
			Settings.hold_to_lock[1] = not Settings.hold_to_lock[1]
		&"master":
			Settings.master_volume = clampi(Settings.master_volume + step, 0, Settings.VOLUME_STEPS)
		&"music":
			Settings.music_volume = clampi(Settings.music_volume + step, 0, Settings.VOLUME_STEPS)
		&"sfx":
			Settings.effects_volume = clampi(Settings.effects_volume + step, 0, Settings.VOLUME_STEPS)
		&"fullscreen":
			Settings.fullscreen = not Settings.fullscreen
		&"vsync":
			Settings.vsync = not Settings.vsync
		&"key_preset":
			Settings.cycle_key_preset(step)
		&"vibration":
			Settings.vibration = not Settings.vibration
		_:
			return
	Settings.apply()
	Settings.save_settings()
	_refresh()


func _refresh() -> void:
	_title.text = tr("OPTIONS_TITLE")
	_list.set_item_text(&"language", tr("OPTION_LANGUAGE").format({"value": tr(LOCALE_KEYS.get(Settings.locale, "LANGUAGE_PT_BR"))}))
	_list.set_item_text(&"difficulty", tr("MENU_DIFFICULTY").format({"value": tr(Settings.difficulty_data().name_key)}))
	_list.set_item_text(&"effects", tr("OPTION_EFFECTS").format({"value": tr("EFFECTS_REDUCED") if Settings.reduced_effects else tr("EFFECTS_FULL")}))
	_list.set_item_text(&"replay", tr("OPTION_REPLAY").format({"value": _on_off(Settings.final_blow_replay)}))
	_list.set_item_text(&"intros", tr("OPTION_FIGHTER_INTROS").format({"value": _on_off(Settings.fighter_intros)}))
	_list.set_item_text(&"finishers", tr("OPTION_FINISHERS").format({"value": _on_off(Settings.show_finishers)}))
	_list.set_item_text(&"powers", tr("OPTION_POWERS").format({"value": _on_off(Settings.powers)}))
	_list.set_item_text(&"hold_p1", tr("OPTION_HOLD_LOCK").format({"player": 1, "value": _on_off(Settings.hold_to_lock[0])}))
	_list.set_item_text(&"hold_p2", tr("OPTION_HOLD_LOCK").format({"player": 2, "value": _on_off(Settings.hold_to_lock[1])}))
	_list.set_item_text(&"master", tr("OPTION_MASTER_VOLUME").format({"value": _volume(Settings.master_volume)}))
	_list.set_item_text(&"music", tr("OPTION_MUSIC_VOLUME").format({"value": _volume(Settings.music_volume)}))
	_list.set_item_text(&"sfx", tr("OPTION_EFFECTS_VOLUME").format({"value": _volume(Settings.effects_volume)}))
	_list.set_item_text(&"fullscreen", tr("OPTION_FULLSCREEN").format({"value": _on_off(Settings.fullscreen)}))
	_list.set_item_text(&"vsync", tr("OPTION_VSYNC").format({"value": _on_off(Settings.vsync)}))
	_list.set_item_text(&"key_preset", tr("OPTION_KEY_PRESET").format({"value": tr(PRESET_KEYS[Settings.key_preset])}))
	_list.set_item_text(&"keys", tr("OPTION_KEYS"))
	_list.set_item_text(&"vibration", tr("OPTION_VIBRATION").format({"value": _on_off(Settings.vibration)}))
	_list.set_item_text(&"back", tr("MENU_BACK"))
	_footer.text = ControlHints.line(PackedStringArray([
		"↑ ↓  " + tr("HINT_CHANGE"), "← →  " + tr("HINT_ADJUST"),
		ControlHints.hint(&"ui_accept", "HINT_CONFIRM"), ControlHints.hint(&"ui_cancel", "HINT_BACK"),
	]))


func _on_off(value: bool) -> String:
	return tr("VALUE_ON") if value else tr("VALUE_OFF")


func _volume(steps: int) -> String:
	return "%d%%" % (steps * 100 / Settings.VOLUME_STEPS)


func _leave() -> void:
	SceneRouter.change(&"menu", {"group": &"root", "focus": _return_focus})
