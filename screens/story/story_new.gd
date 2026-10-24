extends Control

const LEFT: float = 140.0
const TOP: float = 260.0
const PREVIEW: Vector2 = Vector2(1300.0, 780.0)
const TITLE_TOP: float = 80.0
const SUBTITLE_TOP: float = 150.0
const NAME_LIMIT: int = 16
const PALETTE: UiPalette = preload("res://ui/palette.tres")
const STEPS: Array[StringName] = [&"name", &"path", &"style", &"look", &"hair", &"beard", &"hair_color", &"skin", &"color", &"difficulty"]
const APPEARANCE_FIRST: StringName = &"look"
const APPEARANCE_LAST: StringName = &"skin"
const STEP_KEYS: Dictionary = {
	&"name": "STORY_STEP_NAME", &"path": "STORY_STEP_PATH", &"style": "STORY_STEP_STYLE",
	&"look": "STORY_STEP_LOOK", &"hair": "STORY_STEP_HAIR", &"beard": "STORY_STEP_BEARD", &"hair_color": "STORY_STEP_HAIR_COLOR",
	&"skin": "STORY_STEP_SKIN", &"color": "STORY_STEP_COLOR", &"difficulty": "STORY_STEP_DIFFICULTY",
}
const TYPE_NAME: StringName = &"type"

var _step: int = 0
var _choices: Dictionary = {
	&"name": "Kael", &"path": 0, &"style": 0, &"look": 0, &"hair": StoryCampaign.CAMPAIGN.default_hair, &"beard": 0,
	&"hair_color": 0, &"skin": StoryCampaign.CAMPAIGN.default_skin, &"color": 0, &"difficulty": 1,
}
var _editing: StoryCampaign
var _list: MenuList
var _subtitle: Label
var _preview: FighterPreview
var _input: LineEdit
var _campaign_data: CampaignData = StoryCampaign.CAMPAIGN


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var title: Label = _label(tr("STORY_NEW_TITLE"), &"ScreenTitleLabel")
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = TITLE_TOP
	add_child(title)
	_subtitle = _label("", &"SubtitleLabel")
	_subtitle.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_subtitle.offset_top = SUBTITLE_TOP
	add_child(_subtitle)
	_list = MenuList.new()
	_list.position = Vector2(LEFT, TOP)
	add_child(_list)
	_list.chosen.connect(_on_chosen)
	_list.highlighted.connect(_on_highlighted)
	_input = LineEdit.new()
	_input.max_length = NAME_LIMIT
	_input.position = Vector2(LEFT, TOP - 70.0)
	_input.custom_minimum_size = Vector2(420.0, 0.0)
	_input.visible = false
	_input.text_submitted.connect(_on_name_typed)
	add_child(_input)
	_preview = FighterPreview.new()
	_preview.position = PREVIEW
	add_child(_preview)
	var footer: Label = _label(ControlHints.line(PackedStringArray(["↑ ↓  " + tr("HINT_CHANGE"), ControlHints.hint(&"ui_accept", "HINT_CONFIRM"), ControlHints.hint(&"ui_cancel", "HINT_BACK")])), &"HintLabel")
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_top = -66.0
	add_child(footer)
	_show_step()


func _label(text: String, variation: StringName) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.theme_type_variation = variation
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _show_step() -> void:
	var step: StringName = STEPS[_step]
	_subtitle.text = "%d/%d · %s" % [_step + 1, STEPS.size(), tr(STEP_KEYS[step])]
	_list.clear_items()
	match step:
		&"name":
			for i in _campaign_data.names.size():
				_list.add_item(StringName(str(i)), _campaign_data.names[i])
			_list.add_item(TYPE_NAME, tr("STORY_TYPE_NAME"))
		&"path":
			_list.add_item(&"0", tr("STORY_PATH_AURORA"))
			_list.add_item(&"1", tr("STORY_PATH_ECLIPSE"))
			_list.set_item_color(&"0", PALETTE.aurora)
			_list.set_item_color(&"1", PALETTE.eclipse)
		&"style":
			for i in _campaign_data.style_keys.size():
				_list.add_item(StringName(str(i)), tr(_campaign_data.style_keys[i]))
		&"look":
			for i in _campaign_data.outfits.size():
				_list.add_item(StringName(str(i)), tr(_campaign_data.outfits[i].name_key))
		&"hair":
			_add_options(_campaign_data.hair_keys)
		&"beard":
			_add_options(_campaign_data.beard_keys)
		&"hair_color":
			_add_options(_campaign_data.hair_color_keys)
			for i in _campaign_data.hair_colors.size():
				_list.set_item_color(StringName(str(i)), _campaign_data.hair_colors[i].lightened(0.35))
		&"skin":
			_add_options(_campaign_data.skin_keys)
		&"color":
			for i in _campaign_data.blade_sources.size():
				var source: CharacterData = DuelMode.character(_campaign_data.blade_sources[i])
				_list.add_item(StringName(str(i)), tr(source.blade_color_keys[0]))
		&"difficulty":
			for i in StoryCampaign.DIFFICULTIES.size():
				_list.add_item(StringName(str(i)), tr(DuelMode.difficulty(StoryCampaign.DIFFICULTIES[i]).name_key))
	if step != &"name":
		_list.select_id(StringName(str(_choices[step])))
	_refresh_preview()


func _on_highlighted(id: StringName) -> void:
	var step: StringName = STEPS[_step]
	if step != &"name" and id != TYPE_NAME:
		_choices[step] = int(String(id))
	_refresh_preview()


func _refresh_preview() -> void:
	var preview_campaign: StoryCampaign = _build()
	var hero: CharacterData = preview_campaign.protagonist()
	_preview.show_fighter(hero, hero.costumes[0], hero.blade_colors[0])


func _add_options(keys: PackedStringArray) -> void:
	for i in keys.size():
		_list.add_item(StringName(str(i)), tr(keys[i]))


func open(params: Dictionary) -> void:
	if not params.get("edit", false):
		return
	_editing = StoryCampaign.current()
	if _editing == null:
		return
	for key in [&"name", &"path", &"style", &"look", &"hair", &"beard", &"hair_color", &"skin", &"color", &"difficulty"]:
		_choices[key] = _editing.get(String(key))
	_step = STEPS.find(APPEARANCE_FIRST)
	_show_step()


func _build() -> StoryCampaign:
	if _editing != null:
		_editing.set_appearance(_choices)
		return _editing
	var campaign: StoryCampaign = StoryCampaign.create(_choices[&"name"], _choices[&"path"], _choices[&"style"], _choices[&"look"], _choices[&"color"], _choices[&"difficulty"])
	campaign.set_appearance(_choices)
	return campaign


func _on_chosen(id: StringName) -> void:
	if STEPS[_step] == &"name":
		if id == TYPE_NAME:
			_input.visible = true
			_input.text = ""
			_input.grab_focus()
			_list.set_process_unhandled_input(false)
			return
		_choices[&"name"] = _campaign_data.names[int(String(id))]
	_next()


func _on_name_typed(text: String) -> void:
	var trimmed: String = text.strip_edges()
	_input.visible = false
	_list.set_process_unhandled_input(true)
	if trimmed == "":
		return
	_choices[&"name"] = trimmed
	_next()


func _next() -> void:
	if _editing != null and STEPS[_step] == APPEARANCE_LAST:
		_build().save()
		SceneRouter.change(&"story_hub")
		return
	if _step + 1 >= STEPS.size():
		var campaign: StoryCampaign = _build()
		campaign.save()
		SceneRouter.change(&"story_attributes", {"first": true})
		return
	_step += 1
	_show_step()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		if _input.visible:
			_input.visible = false
			_list.set_process_unhandled_input(true)
		elif _editing != null and STEPS[_step] == APPEARANCE_FIRST:
			SceneRouter.change(&"story_hub")
		elif _step == 0:
			SceneRouter.change(&"menu", {"group": &"play", "focus": &"story"})
		else:
			_step -= 1
			_show_step()
