extends Control

const PALETTE: UiPalette = preload("res://ui/palette.tres")
const LEFT: float = 140.0
const TOP: float = 230.0
const INFO_LEFT: float = 1020.0
const PREVIEW: Vector2 = Vector2(1460.0, 860.0)
const TITLE_TOP: float = 80.0
const LINE_GAP: int = 10
const ATTRIBUTE_KEYS: Dictionary = {
	&"health": "ATTRIBUTE_HEALTH", &"vigor": "ATTRIBUTE_VIGOR", &"blade": "ATTRIBUTE_BLADE",
	&"defense": "ATTRIBUTE_DEFENSE", &"agility": "ATTRIBUTE_AGILITY", &"flow": "ATTRIBUTE_FLOW",
}

var campaign: StoryCampaign
var _list: MenuList


func _ready() -> void:
	campaign = StoryCampaign.current()
	if campaign == null:
		SceneRouter.change.call_deferred(&"story_new")
		return
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var title: Label = _label(tr("STORY_HUB_TITLE"), &"ScreenTitleLabel")
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = TITLE_TOP
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)
	_list = MenuList.new()
	_list.position = Vector2(LEFT, TOP)
	add_child(_list)
	var next: EncounterData = campaign.next_encounter()
	if next != null:
		_list.add_item(&"continue", tr("STORY_CONTINUE").format({"chapter": next.chapter, "title": tr(next.title_key)}))
	elif campaign.is_finished():
		_list.add_item(&"ending", tr("STORY_SEE_ENDING"))
	_list.add_item(&"attributes", tr("STORY_RAISE").format({"points": campaign.free_points}) if campaign.free_points > 0 else tr("STORY_VIEW_ATTRIBUTES"))
	_list.add_item(&"powers", tr("STORY_SKILLS").format({"points": campaign.skill_points}))
	_list.add_item(&"appearance", tr("STORY_APPEARANCE"))
	_list.add_item(&"new", tr("STORY_RESTART"))
	_list.add_item(&"back", tr("MENU_BACK"))
	_list.chosen.connect(_on_chosen)
	_build_info()
	var preview: FighterPreview = FighterPreview.new()
	preview.position = PREVIEW
	add_child(preview)
	var hero: CharacterData = campaign.protagonist()
	preview.show_fighter(hero, hero.costumes[0], hero.blade_colors[0])
	var footer: Label = _label(ControlHints.line(PackedStringArray(["↑ ↓  " + tr("HINT_CHANGE"), ControlHints.hint(&"ui_accept", "HINT_CONFIRM"), ControlHints.hint(&"ui_cancel", "HINT_BACK")])), &"HintLabel")
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_top = -66.0
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(footer)


func _build_info() -> void:
	var column: VBoxContainer = VBoxContainer.new()
	column.position = Vector2(INFO_LEFT, TOP)
	column.add_theme_constant_override(&"separation", LINE_GAP)
	add_child(column)
	column.add_child(_label(campaign.name, &"ScreenTitleLabel"))
	var path: Label = _label(tr("PATH_AURORA" if campaign.path == 0 else "PATH_ECLIPSE"), &"InfoLabel")
	path.add_theme_color_override(&"font_color", PALETTE.aurora if campaign.path == 0 else PALETTE.eclipse)
	column.add_child(path)
	column.add_child(_label("%s · %s" % [tr("SELECT_STYLE"), tr(StoryCampaign.CAMPAIGN.style_keys[campaign.style])], &"InfoLabel"))
	column.add_child(_label(tr("SELECT_POWERS"), &"InfoLabel"))
	for power in campaign.equipped_powers():
		if power != null:
			var row: HBoxContainer = HBoxContainer.new()
			row.add_theme_constant_override(&"separation", LINE_GAP)
			var icon: TextureRect = TextureRect.new()
			icon.texture = power.icon
			icon.custom_minimum_size = Vector2(24.0, 24.0)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			row.add_child(icon)
			row.add_child(_label(tr(power.name_key), &"InfoLabel"))
			column.add_child(row)
	var attributes: PackedStringArray = []
	for attribute in StoryCampaign.ATTRIBUTES:
		attributes.append("%s %d" % [tr(ATTRIBUTE_KEYS[attribute]), campaign.attributes[attribute]])
	column.add_child(_label(" · ".join(attributes), &"CaptionLabel"))
	var status: String = tr("STORY_DONE") if campaign.is_finished() else tr("STORY_STATUS").format({
		"difficulty": tr(DuelMode.difficulty(StoryCampaign.DIFFICULTIES[campaign.difficulty]).name_key), "wins": campaign.cleared.size(),
	})
	column.add_child(_label(status, &"CaptionLabel"))


func _label(text: String, variation: StringName) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.theme_type_variation = variation
	return label


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		SceneRouter.change(&"menu", {"group": &"play", "focus": &"story"})


func _on_chosen(id: StringName) -> void:
	match id:
		&"continue":
			SceneRouter.change(&"dialogue", {"campaign": campaign, "encounter": campaign.next_encounter(), "part": &"before"})
		&"ending":
			SceneRouter.change(&"ending", {"ending": campaign.ending_data(), "campaign": campaign})
		&"attributes":
			SceneRouter.change(&"story_attributes")
		&"powers":
			SceneRouter.change(&"story_powers")
		&"appearance":
			SceneRouter.change(&"story_new", {"edit": true})
		&"new":
			SceneRouter.change(&"story_new")
		&"back":
			SceneRouter.change(&"menu", {"group": &"play", "focus": &"story"})
