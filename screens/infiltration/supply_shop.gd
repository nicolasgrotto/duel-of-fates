class_name SupplyShop
extends CanvasLayer

signal purchase_requested(offer: int)
signal closed

const PALETTE: UiPalette = preload("res://ui/palette.tres")
const PANEL_SIZE: Vector2 = Vector2(1480.0, 760.0)
const COLUMN_GAP: int = 16
const LIST_WIDTH: float = 760.0
const DETAIL_GAP: int = 14
const STATUS_GAP: int = 8
const OVERLAY_ALPHA: float = 0.82
const BACK_ROW: StringName = &"back"
const ROW_HEIGHT: float = 56.0

var _sim: BlasterOpsSimulation
var _balance: Label
var _list: TacticalList
var _name: Label
var _description: Label
var _change: Label
var _note: Label
var _status: HBoxContainer
var _purchased_name: String = ""
var _footer: KeyFooter


func _init() -> void:
	layer = 30
	visible = false


func _ready() -> void:
	var overlay: ColorRect = ColorRect.new()
	overlay.color = Color(PALETTE.background, OVERLAY_ALPHA)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var root: VBoxContainer = VBoxContainer.new()
	root.custom_minimum_size = PANEL_SIZE
	root.add_theme_constant_override(&"separation", COLUMN_GAP)
	center.add_child(root)
	var header: HBoxContainer = HBoxContainer.new()
	root.add_child(header)
	var title: TacticalHeader = TacticalHeader.new()
	title.set_content(tr("OPS_SHOP_TITLE"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_balance = Label.new()
	_balance.theme_type_variation = &"TacticalNameLabel"
	_balance.add_theme_color_override(&"font_color", PALETTE.menu_blade_b)
	_balance.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(_balance)
	var columns: HBoxContainer = HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override(&"separation", COLUMN_GAP)
	root.add_child(columns)
	var list_panel: PanelContainer = PanelContainer.new()
	list_panel.theme_type_variation = &"TacticalPanel"
	list_panel.custom_minimum_size.x = LIST_WIDTH
	columns.add_child(list_panel)
	_list = TacticalList.new()
	_list.row_height = ROW_HEIGHT
	list_panel.add_child(_list)
	_list.chosen.connect(_on_chosen)
	_list.highlighted.connect(_on_highlighted)
	_list.set_process_unhandled_input(false)
	columns.add_child(_build_detail())
	_footer = KeyFooter.new()
	root.add_child(_footer)
	_footer.set_hints([
		{"keys": PackedStringArray(["↑", "↓"]), "text": tr("HINT_CHANGE")},
		{"keys": PackedStringArray([ControlHints.key_label(&"ui_accept")]), "text": tr("OPS_SHOP_BUY")},
		{"keys": PackedStringArray([ControlHints.key_label(&"ui_cancel")]), "text": tr("HINT_BACK")},
	])


func _build_detail() -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.theme_type_variation = &"TacticalDetailPanel"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override(&"separation", DETAIL_GAP)
	panel.add_child(column)
	_name = _make_label(&"TacticalNameLabel")
	column.add_child(_name)
	_description = _make_label(&"TacticalBodyLabel")
	column.add_child(_description)
	_change = _make_label(&"TacticalValueLabel")
	_change.add_theme_color_override(&"font_color", PALETTE.menu_blade_a)
	column.add_child(_change)
	_note = _make_label(&"TacticalAmberLabel")
	column.add_child(_note)
	var space: Control = Control.new()
	space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(space)
	var caption: Label = _make_label(&"TacticalCaptionLabel")
	caption.text = tr("OPS_SHOP_STATUS").to_upper()
	column.add_child(caption)
	_status = HBoxContainer.new()
	_status.add_theme_constant_override(&"separation", STATUS_GAP)
	column.add_child(_status)
	return panel


func _make_label(variation: StringName) -> Label:
	var label: Label = Label.new()
	label.theme_type_variation = variation
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func open(sim: BlasterOpsSimulation) -> void:
	_sim = sim
	visible = true
	_purchased_name = ""
	_list.set_process_unhandled_input(true)
	_list.selected = 0
	refresh()


func close() -> void:
	visible = false
	_list.set_process_unhandled_input(false)


func purchased(offer: int) -> void:
	_purchased_name = tr(BlasterOpsTraining.SUPPLY_OFFERS[offer].name_key)
	refresh()


func refresh() -> void:
	var progress: BlasterOpsMissionState = _sim.mission as BlasterOpsMissionState
	_balance.text = tr("OPS_SHOP_BALANCE").format({"supplies": progress.supplies})
	var keep: int = _list.selected
	_list.clear_items()
	for index in BlasterOpsTraining.SUPPLY_OFFERS.size():
		_add_offer(progress, index)
	_list.add_rule()
	_list.add_row(BACK_ROW, tr("MENU_BACK"))
	_list.selected = keep
	_list._refresh()
	_refresh_status(progress)
	_show_detail(_list.current_id())


func _add_offer(progress: BlasterOpsMissionState, index: int) -> void:
	var offer: BlasterOpsSupplyOffer = BlasterOpsTraining.SUPPLY_OFFERS[index]
	var bought: int = progress.offer_counts[index]
	var block: BlasterOpsMissionState.OfferBlock = progress.offer_block(_sim, index)
	var dimmed: bool = block != BlasterOpsMissionState.OfferBlock.NONE
	var extra: Control = null
	var maxed: bool = block == BlasterOpsMissionState.OfferBlock.LIMIT
	if offer.limit > 0:
		extra = LevelPips.new(bought, offer.limit)
	var mark: String = "×%d" % bought if offer.limit == 0 and bought > 0 else " "
	var price: String = tr("SPACE_TRACK_MAX") if maxed else str(offer.cost)
	_list.add_row(StringName(str(index)), tr(offer.name_key), StatusGlyph.State.NONE, mark, price, dimmed, extra)


func _refresh_status(progress: BlasterOpsMissionState) -> void:
	for child in _status.get_children():
		_status.remove_child(child)
		child.queue_free()
	_status.add_child(InfoChip.new(tr("OPS_SHOP_HEALTH"), "%d / %d" % [roundi(_sim.player.health), roundi(_sim.operations.health)]))
	_status.add_child(InfoChip.new(tr("OPS_SHOP_BARRIERS"), str(progress.barrier_charges)))
	_status.add_child(InfoChip.new(tr("OPS_SHOP_BULWARKS"), str(progress.heavy_barrier_charges)))
	_status.add_child(InfoChip.new(tr("OPS_SHOP_ALLIES"), str(progress.living_allies(_sim))))


func _on_highlighted(id: StringName) -> void:
	_purchased_name = ""
	_show_detail(id)


func _show_detail(id: StringName) -> void:
	var is_offer: bool = id != BACK_ROW
	_name.visible = is_offer
	_description.visible = is_offer
	_change.visible = is_offer
	_note.visible = is_offer
	if not is_offer:
		return
	var index: int = int(String(id))
	var progress: BlasterOpsMissionState = _sim.mission as BlasterOpsMissionState
	var offer: BlasterOpsSupplyOffer = BlasterOpsTraining.SUPPLY_OFFERS[index]
	var block: BlasterOpsMissionState.OfferBlock = progress.offer_block(_sim, index)
	_name.text = tr(offer.name_key)
	_description.text = tr(offer.description_key)
	_change.text = _change_text(progress, offer)
	_note.text = _note_text(progress, offer, index, block)


func _note_text(progress: BlasterOpsMissionState, offer: BlasterOpsSupplyOffer, index: int, block: BlasterOpsMissionState.OfferBlock) -> String:
	if _purchased_name != "":
		return tr("OPS_SHOP_BOUGHT").format({"name": _purchased_name})
	if block != BlasterOpsMissionState.OfferBlock.NONE:
		return tr("OPS_SHOP_BLOCK_%d" % block).format({"missing": offer.cost - progress.supplies})
	if offer.limit > 0 and offer.limit - progress.offer_counts[index] == 1:
		return tr("OPS_SHOP_ONE_LEFT")
	return tr("OPS_SHOP_TEMPORARY")


func _change_text(progress: BlasterOpsMissionState, offer: BlasterOpsSupplyOffer) -> String:
	match offer.kind:
		BlasterOpsSupplyOffer.Kind.HEAL:
			return _pair("OPS_SHOP_HEALTH", roundi(_sim.player.health), roundi(minf(_sim.player.health + offer.amount, _sim.operations.health)))
		BlasterOpsSupplyOffer.Kind.BARRIER:
			return _pair("OPS_SHOP_BARRIERS", progress.barrier_charges, progress.barrier_charges + int(offer.amount))
		BlasterOpsSupplyOffer.Kind.BULWARK:
			return _pair("OPS_SHOP_BULWARKS", progress.heavy_barrier_charges, progress.heavy_barrier_charges + int(offer.amount))
		BlasterOpsSupplyOffer.Kind.COOLANT:
			return _percent("OPS_SHOP_HEAT", progress.heat_scale, progress.heat_scale * offer.amount)
		BlasterOpsSupplyOffer.Kind.COMBAT_TUNE:
			return _percent("OPS_SHOP_DAMAGE", progress.damage_scale, progress.damage_scale * offer.amount)
		BlasterOpsSupplyOffer.Kind.ALLY_UPGRADE:
			return _percent("OPS_SHOP_ALLY_DAMAGE", progress.ally_scale, progress.ally_scale * offer.amount)
	return _pair("OPS_SHOP_ALLIES", progress.living_allies(_sim), progress.living_allies(_sim) + 1)


func _pair(key: String, now: int, after: int) -> String:
	return "%s  %d → %d" % [tr(key), now, after]


func _percent(key: String, now: float, after: float) -> String:
	return "%s  %d%% → %d%%" % [tr(key), roundi(now * 100.0), roundi(after * 100.0)]


func _on_chosen(id: StringName) -> void:
	if id == BACK_ROW:
		closed.emit()
		return
	var index: int = int(String(id))
	var progress: BlasterOpsMissionState = _sim.mission as BlasterOpsMissionState
	if progress.offer_block(_sim, index) != BlasterOpsMissionState.OfferBlock.NONE:
		AudioDirector.play_ui(&"rejected")
		_show_detail(id)
		return
	purchase_requested.emit(index)
