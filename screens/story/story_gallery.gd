extends Control

const LEFT: float = 140.0
const TOP: float = 230.0
const COLUMN_GAP: float = 820.0
const TITLE_TOP: float = 80.0
const HINT_DROP: float = 220.0
const ROUTE_MARKS: Array[String] = ["", "A", "E"]
const HIDDEN: String = "???"
const ENDING_PREFIX: String = "ending:"

var _encounters: Array[EncounterData] = []
var _endings: Array[EndingData] = []
var _chapters: MenuList
var _ending_list: MenuList
var _hint: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var data: CampaignData = StoryCampaign.CAMPAIGN
	_encounters.append_array(data.common)
	_encounters.append_array(data.aurora)
	_encounters.append_array(data.eclipse)
	_encounters.append_array([data.aurora_secret, data.eclipse_secret])
	_endings.append_array([data.aurora_normal_ending, data.aurora_secret_ending, data.eclipse_normal_ending, data.eclipse_secret_ending])
	add_child(_label(tr("STORY_GALLERY_TITLE"), &"ScreenTitleLabel", Vector2(0.0, TITLE_TOP), true))
	_chapters = MenuList.new()
	_chapters.position = Vector2(LEFT, TOP)
	add_child(_chapters)
	for encounter in _encounters:
		_chapters.add_item(encounter.id, _chapter_text(encounter))
	_chapters.add_item(&"back", tr("MENU_BACK"))
	_chapters.chosen.connect(_on_chapter_chosen)
	_chapters.adjusted.connect(func(_id: StringName, _step: int) -> void: _swap_column(_ending_list, _chapters))
	_ending_list = MenuList.new()
	_ending_list.position = Vector2(LEFT + COLUMN_GAP, TOP)
	add_child(_ending_list)
	for ending in _endings:
		_ending_list.add_item(StringName(ENDING_PREFIX + String(ending.id)), tr(ending.title_key) if _seen_ending(ending) else HIDDEN)
	_ending_list.chosen.connect(_on_ending_chosen)
	_ending_list.adjusted.connect(func(_id: StringName, _step: int) -> void: _swap_column(_chapters, _ending_list))
	_ending_list.set_process_unhandled_input(false)
	_ending_list.modulate.a = 0.6
	_hint = _label(tr("STORY_GALLERY_HINT"), &"CaptionLabel", Vector2(LEFT + COLUMN_GAP, TOP + HINT_DROP), false)
	add_child(_hint)
	var footer: Label = _label(ControlHints.line(PackedStringArray(["↑ ↓ ← →  " + tr("HINT_CHANGE"), ControlHints.hint(&"ui_accept", "HINT_CONFIRM"), ControlHints.hint(&"ui_cancel", "HINT_BACK")])), &"HintLabel", Vector2.ZERO, true)
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_top = -66.0
	add_child(footer)


func _label(text: String, variation: StringName, at: Vector2, wide: bool) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.theme_type_variation = variation
	if wide:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		label.offset_top = at.y
	else:
		label.position = at
	return label


func _chapter_text(encounter: EncounterData) -> String:
	var mark: String = str(encounter.chapter) + ROUTE_MARKS[encounter.route]
	var title: String = tr(encounter.title_key) if SaveService.is_unlocked("seen:encounter:%s" % encounter.id) else HIDDEN
	return "%s · %s" % [mark, title]


func _seen_ending(ending: EndingData) -> bool:
	return SaveService.is_unlocked("seen:ending:%s" % ending.id)


func _swap_column(target: MenuList, source: MenuList) -> void:
	source.set_process_unhandled_input(false)
	source.modulate.a = 0.6
	target.set_process_unhandled_input.call_deferred(true)
	target.modulate.a = 1.0


func _on_chapter_chosen(id: StringName) -> void:
	if id == &"back":
		_leave()
		return
	for encounter in _encounters:
		if encounter.id == id:
			if not SaveService.is_unlocked("seen:encounter:%s" % id):
				AudioDirector.play_ui(&"rejected")
				return
			var flow_path: int = 1 if encounter.route == EncounterData.Route.ECLIPSE else 0
			SceneRouter.change(&"dialogue", {"encounter": encounter, "part": &"both", "gallery": true, "path": flow_path})
			return


func _on_ending_chosen(id: StringName) -> void:
	for ending in _endings:
		if StringName(ENDING_PREFIX + String(ending.id)) == id:
			if not _seen_ending(ending):
				AudioDirector.play_ui(&"rejected")
				return
			SceneRouter.change(&"ending", {"ending": ending, "gallery": true})
			return


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_leave()


func _leave() -> void:
	SceneRouter.change(&"menu", {"group": &"extras", "focus": &"story_gallery"})
