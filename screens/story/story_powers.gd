extends Control

const TOP: float = 280.0
const TITLE_TOP: float = 80.0
const DETAIL_TOP: float = 560.0
const SLOT_KEYS: Array[String] = ["SELECT_POWER_NEUTRAL", "SELECT_POWER_FORWARD", "SELECT_POWER_BACK"]
const OPENS_AT: Array[String] = ["", "STORY_SLOT_OPENS_3", "STORY_SLOT_OPENS_6"]

var campaign: StoryCampaign
var _list: MenuList
var _detail: Label


func _ready() -> void:
	campaign = StoryCampaign.current()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var title: Label = _label(tr("STORY_POWERS_TITLE"), &"ScreenTitleLabel")
	title.offset_top = TITLE_TOP
	var holder: VBoxContainer = VBoxContainer.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	holder.offset_top = TOP
	add_child(holder)
	_list = MenuList.new()
	_list.centered = true
	holder.add_child(_list)
	for slot in StoryCampaign.SLOTS:
		_list.add_item(StringName(str(slot)), "")
	_list.add_item(&"done", tr("STORY_DONE_BUTTON"))
	_list.chosen.connect(_on_chosen)
	_list.adjusted.connect(_on_adjusted)
	_list.highlighted.connect(func(_id: StringName) -> void: _refresh())
	_detail = _label("", &"InfoLabel")
	_detail.offset_top = DETAIL_TOP
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var footer: Label = _label(ControlHints.line(PackedStringArray(["↑ ↓  " + tr("HINT_CHANGE"), "← →  " + tr("HINT_EDIT_POWER"), ControlHints.hint(&"ui_cancel", "HINT_BACK")])), &"HintLabel")
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
	for slot in StoryCampaign.SLOTS:
		var value: String
		if slot >= campaign.slots_open:
			value = "%s · %s" % [tr("STORY_SLOT_CLOSED"), tr(OPENS_AT[slot])]
		else:
			var power: PowerData = StoryCampaign.load_power(campaign.equipped[slot]) if campaign.equipped[slot] != &"" else null
			value = "‹ %s ›" % tr(power.name_key) if power != null else "—"
		_list.set_item_text(StringName(str(slot)), tr(SLOT_KEYS[slot]).format({"name": value}))
	var current: StringName = _list.current_id()
	_detail.text = ""
	if current != &"done" and int(String(current)) < campaign.slots_open:
		var id: StringName = campaign.equipped[int(String(current))]
		if id != &"":
			var power: PowerData = StoryCampaign.load_power(id)
			_detail.text = "%s · %s %d" % [tr(power.description_key), tr("STORY_COST"), int(power.cost)]


func _on_adjusted(id: StringName, step: int) -> void:
	if id == &"done":
		return
	campaign.cycle_power(int(String(id)), step)
	campaign.save()
	_refresh()


func _on_chosen(id: StringName) -> void:
	if id == &"done":
		SceneRouter.change(&"story_hub")
	else:
		_on_adjusted(id, 1)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		SceneRouter.change(&"story_hub")
