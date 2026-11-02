extends Control

const CAMPAIGN: CampaignData = preload("res://data/story/campaign.tres")
const MARGIN: float = 100.0
const LIST_WIDTH: float = 540.0
const COLUMN_GAP: int = 80
const DETAIL_GAP: int = 16
const PREVIEW_SCALE: float = 6.0
const PREVIEW_HEIGHT: float = 240.0
const BACK_ROW: StringName = &"back"

var campaign: StoryCampaign
var _list: MenuList
var _credits: Label
var _preview: TextureRect
var _title: Label
var _detail: Label


func _ready() -> void:
	campaign = StoryCampaign.current()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var heading: Label = _label(tr("ARSENAL_TITLE").to_upper(), &"ScreenTitleLabel")
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	heading.offset_top = 70.0
	add_child(heading)
	_credits = _label("", &"HuntSubtitleLabel")
	_credits.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_credits.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_credits.offset_top = 130.0
	add_child(_credits)
	var columns: HBoxContainer = HBoxContainer.new()
	columns.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	columns.offset_left = MARGIN
	columns.offset_right = -MARGIN
	columns.offset_top = 200.0
	columns.offset_bottom = -110.0
	columns.add_theme_constant_override(&"separation", COLUMN_GAP)
	add_child(columns)
	_list = MenuList.new()
	_list.custom_minimum_size.x = LIST_WIDTH
	columns.add_child(_list)
	_list.chosen.connect(_choose)
	_list.highlighted.connect(_highlight)
	var detail: VBoxContainer = VBoxContainer.new()
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_theme_constant_override(&"separation", DETAIL_GAP)
	columns.add_child(detail)
	_preview = TextureRect.new()
	_preview.custom_minimum_size.y = PREVIEW_HEIGHT
	_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	_preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	detail.add_child(_preview)
	_title = _label("", &"HuntSubtitleLabel")
	detail.add_child(_title)
	_detail = _label("", &"HuntBodyLabel")
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_child(_detail)
	var hints: PackedStringArray = ["↑ ↓  " + tr("HINT_CHANGE")]
	hints.append(ControlHints.hint(&"ui_accept", "HINT_CONFIRM"))
	hints.append(ControlHints.hint(&"ui_cancel", "HINT_BACK"))
	var footer: Label = _label(ControlHints.line(hints), &"HuntHintLabel")
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_top = -65.0
	add_child(footer)
	for blaster in CAMPAIGN.blasters:
		_list.add_item(blaster.id, "")
	_list.add_item(BACK_ROW, tr("MENU_BACK"))
	_refresh_rows()
	_list.select_id(campaign.blaster_id if campaign.blaster_equipped() else CAMPAIGN.blasters[0].id)
	_highlight(_list._ids[_list.selected])


func _refresh_rows() -> void:
	_credits.text = tr("ARSENAL_CREDITS").format({"credits": campaign.credits})
	for blaster in CAMPAIGN.blasters:
		_list.set_item_text(blaster.id, "%s · %s" % [tr(blaster.name_key), _status(blaster)])


func _status(blaster: BlasterData) -> String:
	if campaign.blaster_equipped() and campaign.blaster_id == blaster.id:
		return tr("ARSENAL_EQUIPPED")
	return tr("ARSENAL_OWNED") if campaign.owns_blaster(blaster) else tr("ARSENAL_PRICE").format({"price": blaster.price})


func _blaster(id: StringName) -> BlasterData:
	for blaster in CAMPAIGN.blasters:
		if blaster.id == id:
			return blaster
	return null


func _highlight(id: StringName) -> void:
	var blaster: BlasterData = _blaster(id)
	if blaster == null:
		_preview.texture = null
		_title.text = ""
		_detail.text = tr("ARSENAL_RULES")
		return
	var baked: ImageTexture = PaletteBake.texture(blaster.texture, campaign.appearance().colors)
	var image: Image = baked.get_image()
	image.resize(image.get_width() * int(PREVIEW_SCALE), image.get_height() * int(PREVIEW_SCALE), Image.INTERPOLATE_NEAREST)
	_preview.texture = ImageTexture.create_from_image(image)
	_title.text = tr(blaster.name_key).to_upper()
	var lines: PackedStringArray = [tr(blaster.description_key), _stats(blaster), ""]
	lines.append(tr("ARSENAL_SKILL_NOTE"))
	lines.append(_action(blaster))
	_detail.text = "\n".join(lines)


func _stats(blaster: BlasterData) -> String:
	return tr("ARSENAL_STATS").format({
		"shots": blaster.shot_count if blaster.shot_count > 0 else tr("ARSENAL_SHOTS_TECHNIQUE"),
		"damage": int(blaster.bolt.damage), "draw": "%.2f" % blaster.draw_time, "flinch": "%.2f" % blaster.bolt.flinch,
	})


func _action(blaster: BlasterData) -> String:
	if not campaign.owns_blaster(blaster):
		return tr("ARSENAL_BUY" if campaign.can_buy_blaster(blaster) else "ARSENAL_NOT_ENOUGH")
	var equipped: bool = campaign.blaster_equipped() and campaign.blaster_id == blaster.id
	if not equipped:
		return tr("ARSENAL_EQUIP")
	return "" if campaign.uses_blaster_style() else tr("ARSENAL_UNEQUIP")


func _choose(id: StringName) -> void:
	var blaster: BlasterData = _blaster(id)
	if blaster == null:
		_leave()
		return
	if not campaign.owns_blaster(blaster):
		campaign.buy_blaster(blaster)
	elif not campaign.uses_blaster_style() and campaign.blaster_equipped() and campaign.blaster_id == blaster.id:
		campaign.unequip_blaster()
	else:
		campaign.equip_blaster(blaster)
	campaign.save()
	_refresh_rows()
	_highlight(id)


func _leave() -> void:
	SceneRouter.change(&"story_hub")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_leave()


func _label(text: String, variation: StringName) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.theme_type_variation = variation
	return label
