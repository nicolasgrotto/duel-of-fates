extends Control

const PALETTE: UiPalette = preload("res://ui/palette.tres")
const TOP: float = 280.0
const TITLE_TOP: float = 80.0
const SUBTITLE_TOP: float = 150.0
const WARNING_TOP: float = 200.0
const ATTRIBUTE_KEYS: Dictionary = {
	&"health": "ATTRIBUTE_HEALTH", &"vigor": "ATTRIBUTE_VIGOR", &"blade": "ATTRIBUTE_BLADE",
	&"defense": "ATTRIBUTE_DEFENSE", &"agility": "ATTRIBUTE_AGILITY", &"flow": "ATTRIBUTE_FLOW",
}

var campaign: StoryCampaign
var _list: MenuList
var _subtitle: Label


func _ready() -> void:
	campaign = StoryCampaign.current()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var title: Label = _label(tr("STORY_ATTRIBUTES_TITLE"), &"ScreenTitleLabel")
	title.offset_top = TITLE_TOP
	_subtitle = _label("", &"SubtitleLabel")
	_subtitle.offset_top = SUBTITLE_TOP
	var warning: Label = _label(tr("STORY_POINTS_FINAL"), &"CaptionLabel")
	warning.offset_top = WARNING_TOP
	warning.add_theme_color_override(&"font_color", PALETTE.danger)
	var holder: VBoxContainer = VBoxContainer.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	holder.offset_top = TOP
	add_child(holder)
	_list = MenuList.new()
	_list.centered = true
	holder.add_child(_list)
	for attribute in StoryCampaign.ATTRIBUTES:
		_list.add_item(attribute, "")
	_list.add_item(&"done", tr("STORY_DONE_BUTTON"))
	_list.chosen.connect(_on_chosen)
	var footer: Label = _label(ControlHints.line(PackedStringArray(["↑ ↓  " + tr("HINT_CHANGE"), ControlHints.hint(&"ui_accept", "HINT_RAISE"), ControlHints.hint(&"ui_cancel", "HINT_BACK")])), &"HintLabel")
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_top = -66.0
	_refresh()


func _label(text: String, variation: StringName) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.theme_type_variation = variation
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	add_child(label)
	return label


func _refresh() -> void:
	_subtitle.text = tr("STORY_POINTS").format({"points": campaign.free_points, "total": campaign.attribute_total()})
	for attribute in StoryCampaign.ATTRIBUTES:
		_list.set_item_text(attribute, "%s · %d" % [tr(ATTRIBUTE_KEYS[attribute]), campaign.attributes[attribute]])


func _on_chosen(id: StringName) -> void:
	if id == &"done":
		_leave()
		return
	if campaign.raise(id):
		campaign.save()
		_refresh()
	else:
		AudioDirector.play_ui(&"rejected")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_leave()


func _leave() -> void:
	SceneRouter.change(&"story_hub")
