extends Control

const PALETTE: UiPalette = preload("res://ui/palette.tres")
const COMBAT: CombatConfig = preload("res://data/balance/combat_config.tres")
const BLADE_SLOT_KEYS: Array[String] = ["TREE_BLADE_FORWARD", "TREE_BLADE_BACK", "TREE_BLADE_AIR"]
const SLOT_KEYS: Array[String] = ["TREE_SLOT_NEUTRAL", "TREE_SLOT_FORWARD", "TREE_SLOT_BACK"]
const STATE_KEYS: Array[String] = ["TREE_LOCKED", "TREE_AFFORDABLE", "TREE_EXPENSIVE", "TREE_TIER_BLOCKED", "TREE_LEARNED", "TREE_EQUIPPED"]
const PATH_KEYS: Array[String] = ["PATH_COMMON", "PATH_AURORA", "PATH_ECLIPSE"]
const STATE_STYLES: Array[StringName] = [&"locked", &"next", &"locked", &"learned", &"learned", &"equipped"]

class NodeButton extends Button:
	var frame: StringName = &"locked"
	var cursor: bool = false

	func _draw() -> void:
		draw_style_box(get_theme_stylebox(frame, &"PowerNode"), Rect2(Vector2.ZERO, size))
		if frame == &"equipped":
			draw_style_box(get_theme_stylebox(&"learned", &"PowerNode"), Rect2(Vector2.ZERO, size).grow(-5.0))
		if cursor:
			draw_style_box(get_theme_stylebox(&"selected", &"PowerNode"), Rect2(Vector2.ZERO, size).grow(7.0))

class TreeGraph extends Control:
	var buttons: Array[NodeButton] = []
	var tree: StoryPowerTree

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			arrange()

	func arrange() -> void:
		for index in buttons.size():
			var column: int = index if index < 4 else (7 - index if index < 8 else index - 8)
			var row: int = 0 if index < 4 else (1 if index < 8 else 2)
			var center: Vector2 = Vector2((column + 0.5) / 4.0, (row + 0.5) / 3.0) * size
			buttons[index].size = Vector2(minf(190.0, size.x / 4.0 - 24.0), minf(178.0, size.y / 3.0 - 20.0))
			buttons[index].position = center - buttons[index].size * 0.5
		queue_redraw()

	func _draw() -> void:
		for index in buttons.size():
			var parent: int = tree.nodes[index].definition.parent
			if parent < 0:
				continue
			var previous: NodeButton = buttons[parent]
			var current: NodeButton = buttons[index]
			var start: Vector2 = previous.position + previous.size * 0.5
			var end: Vector2 = current.position + current.size * 0.5
			var direction: Vector2 = (end - start).normalized()
			var margin: float = minf(previous.size.x * 0.5 / maxf(absf(direction.x), 0.001), previous.size.y * 0.5 / maxf(absf(direction.y), 0.001)) + 9.0
			var color_key: StringName = &"connector" if tree.nodes[index].owned else &"locked_connector"
			var tint: Color = get_theme_color(color_key, &"PowerNode")
			if tree.nodes[index].definition.branch != tree.nodes[parent].definition.branch:
				var from: Vector2 = Vector2(start.x, previous.position.y + previous.size.y + 6.0)
				var to: Vector2 = Vector2(end.x, current.position.y - 6.0)
				var middle: float = (from.y + to.y) * 0.5
				draw_line(from, Vector2(from.x, middle), tint, 1.0)
				draw_line(Vector2(from.x, middle), Vector2(to.x, middle), tint, 1.0)
				draw_line(Vector2(to.x, middle), to, tint, 1.0)
			else:
				draw_line(start + direction * margin, end - direction * margin, tint, 1.0)

var campaign: StoryCampaign
var tree: StoryPowerTree
var selected: int = 0
var _graph: TreeGraph
var _name: Label
var _description: Label
var _facts: Label
var _requirement: Label
var _status: Label
var _icon: TextureRect
var _badges: Array[Label] = []
var _icons: Array[TextureRect] = []
var _detail_scroll: ScrollContainer
var _picker: VBoxContainer
var _slots: Array[Button] = []
var _picking: bool = false
var _slot: int = 0
var _trees: Array[StoryPowerTree] = []
var _graphs: Array[TreeGraph] = []
var _tab_badges: Array[Array] = []
var _tab_icons: Array[Array] = []
var _tabs: TabContainer
var _buy_button: Button
var _points: Label
var _footer: Label


func _ready() -> void:
	if campaign == null:
		campaign = StoryCampaign.current()
	if campaign == null:
		SceneRouter.change.call_deferred(&"story_new")
		return
	_trees = [StoryPowerTree.new(campaign), StoryPowerTree.new(campaign, true)]
	tree = _trees[0]
	_build()
	_refresh()
	_focus_node.call_deferred(0)


func _build() -> void:
	var margins: MarginContainer = MarginContainer.new()
	margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margins.anchor_left = 0.065
	margins.anchor_right = 0.935
	margins.anchor_top = 0.07
	margins.anchor_bottom = 0.9
	add_child(margins)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 24)
	margins.add_child(column)
	column.add_child(_label(tr("TREE_TITLE"), &"ScreenTitleLabel"))
	var subtitle: Label = _label(tr("TREE_SUBTITLE").format({"path": tr("PATH_AURORA" if campaign.path == 0 else "PATH_ECLIPSE")}), &"InfoLabel")
	subtitle.modulate = PALETTE.aurora if campaign.path == 0 else PALETTE.eclipse
	column.add_child(subtitle)
	_points = _label("", &"InfoLabel")
	column.add_child(_points)
	var body: HBoxContainer = HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override(&"separation", 72)
	column.add_child(body)
	var graph_column: VBoxContainer = VBoxContainer.new()
	graph_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	graph_column.size_flags_stretch_ratio = 2.0
	body.add_child(graph_column)
	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	graph_column.add_child(_tabs)
	for tab in _trees.size():
		tree = _trees[tab]
		var panel: Control = Control.new()
		panel.name = tr("TREE_TAB_BLADE" if tab == 1 else "TREE_TAB_POWERS")
		_tabs.add_child(panel)
		_graph = TreeGraph.new()
		_graph.tree = tree
		_graph.size_flags_vertical = Control.SIZE_EXPAND_FILL
		panel.add_child(_graph)
		_graph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_badges = []
		_icons = []
		for index in tree.nodes.size():
			_build_node(index)
		_graphs.append(_graph)
		_tab_badges.append(_badges)
		_tab_icons.append(_icons)
		_graph.arrange.call_deferred()
	tree = _trees[0]
	_graph = _graphs[0]
	_badges = []
	_badges.assign(_tab_badges[0])
	_icons = []
	_icons.assign(_tab_icons[0])
	for index in tree.milestones.size():
		var milestone: EncounterData = tree.milestones[index]
		graph_column.add_child(_label(tr("TREE_MILESTONE").format({"slot": tr(SLOT_KEYS[index + 1]), "chapter": milestone.chapter, "state": tr("TREE_OPEN" if index + 1 < campaign.slots_open else "TREE_LOCKED")}), &"HintLabel"))
	_detail_scroll = ScrollContainer.new()
	_detail_scroll.follow_focus = true
	_detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_detail_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(_detail_scroll)
	var detail: VBoxContainer = VBoxContainer.new()
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_theme_constant_override(&"separation", 16)
	_detail_scroll.add_child(detail)
	_icon = _texture(144.0)
	detail.add_child(_icon)
	_name = _label("", &"InfoLabel")
	detail.add_child(_name)
	_description = _label("", &"InfoLabel")
	detail.add_child(_description)
	_facts = _label("", &"InfoLabel")
	detail.add_child(_facts)
	_requirement = _label("", &"InfoLabel")
	detail.add_child(_requirement)
	_status = _label("", &"HintLabel")
	detail.add_child(_status)
	_buy_button = Button.new()
	_buy_button.theme_type_variation = &"PowerSlotButton"
	_buy_button.text = tr("TREE_BUY")
	_buy_button.focus_mode = Control.FOCUS_NONE
	_buy_button.pressed.connect(_buy_selected)
	detail.add_child(_buy_button)
	_picker = VBoxContainer.new()
	_picker.add_theme_constant_override(&"separation", 12)
	detail.add_child(_picker)
	_picker.add_child(_label(tr("TREE_PICK_SLOT"), &"HintLabel"))
	for slot in StoryCampaign.SLOTS:
		var button: Button = Button.new()
		button.theme_type_variation = &"PowerSlotButton"
		button.custom_minimum_size.y = 44.0
		button.pressed.connect(_equip.bind(slot))
		button.focus_entered.connect(_slot_focused.bind(slot))
		_picker.add_child(button)
		_slots.append(button)
	_picker.hide()
	_footer = _label("", &"HintLabel")
	_footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_footer.offset_top = -65.0
	_footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_footer)
	_tabs.tab_changed.connect(_tab_changed)


func _build_node(index: int) -> void:
	var button: NodeButton = NodeButton.new()
	button.theme_type_variation = &"PowerNode"
	button.pressed.connect(_confirm.bind(index))
	button.mouse_entered.connect(_hovered.bind(index))
	button.focus_entered.connect(_node_focused.bind(index))
	_graph.add_child(button)
	_graph.buttons.append(button)
	var content: VBoxContainer = VBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 8.0
	content.offset_right = -8.0
	content.offset_top = 10.0
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override(&"separation", 8)
	button.add_child(content)
	var icon: TextureRect = _texture(72.0)
	icon.texture = tree.nodes[index].icon
	content.add_child(icon)
	_icons.append(icon)
	var name_label: Label = _label(tr(tree.nodes[index].name_key), &"PowerNodeNameLabel")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(name_label)
	var badge: Label = _label("", &"PowerNodeStateLabel")
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(badge)
	_badges.append(badge)


func _label(text: String, variation: StringName) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.theme_type_variation = variation
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _texture(side: float) -> TextureRect:
	var texture: TextureRect = TextureRect.new()
	texture.custom_minimum_size = Vector2(side, side)
	texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	texture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return texture


func _refresh() -> void:
	_points.text = tr("TREE_SKILL_COST").format({"cost": tree.nodes[selected].definition.cost, "points": campaign.skill_points})
	for index in tree.nodes.size():
		var node: StoryPowerTree.PowerNode = tree.nodes[index]
		_badges[index].text = tr(_slot_keys()[node.slot]) if node.slot >= 0 and node.state == StoryPowerTree.State.EQUIPPED else (tr("TREE_TIER_BADGE").format({"level": node.power.min_level if node.power != null else 0}) if node.state == StoryPowerTree.State.TIER_BLOCKED else _state_text(node))
		_graph.buttons[index].frame = STATE_STYLES[node.state]
		_graph.buttons[index].cursor = index == selected
		_icons[index].modulate = PALETTE.secondary if not node.owned else PALETTE.text
		_icons[index].modulate.a = 0.45 if node.state == StoryPowerTree.State.LOCKED else 1.0
		_graph.buttons[index].queue_redraw()
	_graph.queue_redraw()
	_show_detail()
	_footer.text = ControlHints.line(PackedStringArray([ControlHints.hint(&"ui_left", "TREE_PREVIOUS"), ControlHints.hint(&"ui_right", "TREE_NEXT_NODE"), ControlHints.hint(&"ui_accept", "TREE_ACTION"), ControlHints.hint(&"menu_variant", "TREE_SWITCH_TAB"), ControlHints.hint(&"ui_cancel", "HINT_BACK")]))


func _show_detail() -> void:
	var node: StoryPowerTree.PowerNode = tree.nodes[selected]
	_icon.texture = node.icon
	_name.text = tr(node.name_key)
	_description.text = tr(node.description_key)
	if node.power != null:
		var power: PowerData = node.power
		var level: int = campaign.attributes.get(&"flow", StoryCampaign.CAMPAIGN.start_attribute)
		_facts.text = tr("TREE_FACTS").format({"path": tr(PATH_KEYS[power.path]), "cost": String.num(power.cost_for(level), 1), "cooldown": String.num(power.cooldown_for(level), 1), "flow": level})
	elif node.technique != null:
		var move: MoveData = node.technique
		_facts.text = tr("TREE_BLADE_FACTS").format({"cost": String.num(move.vigor_cost, 0), "damage": String.num(move.damage, 0), "startup": String.num(move.startup, 2), "recovery": String.num(move.recovery, 2)})
		if node.definition.kind == StoryCampaign.TreeNodeData.Kind.TECHNIQUE:
			_description.text = tr("TREE_PROJECTED_TEXT")
	else:
		_facts.text = tr("TREE_ABILITY_FACTS").format({"cost": String.num(node.ability.move.vigor_cost if node.ability.kind in [AbilityData.Kind.STRIKE, AbilityData.Kind.CHARGE] and node.ability.move != null else node.ability.vigor_cost, 0)})
	_requirement.text = tr("TREE_CREATION") if node.initial else tr("TREE_PARENT").format({"name": tr(tree.nodes[node.definition.parent].name_key)})
	if not node.allowed and node.power != null:
		_requirement.text += "\n" + tr("TREE_FLOW_REQUIRED").format({"level": node.power.min_level, "tier": node.power.min_tier(COMBAT.flow) + 1})
	_status.text = tr("TREE_IN_SLOT").format({"slot": tr(_slot_keys()[node.slot])}) if node.slot >= 0 else _state_text(node)
	_buy_button.visible = not node.owned
	_buy_button.disabled = node.state != StoryPowerTree.State.AFFORDABLE
	var hero: CharacterData = campaign.protagonist()
	for slot in _slots.size():
		_slots[slot].visible = slot < _slot_count()
		var name: String = tr("TREE_EMPTY")
		if tree.blade:
			var move: MoveData = hero.get([&"technique_forward", &"technique_back", &"technique_air"][slot]) as MoveData
			if move != null:
				name = tr(PowerCatalog.technique_key(move))
		else:
			var power: PowerData = StoryCampaign.load_power(campaign.equipped[slot])
			if power != null:
				name = tr(power.name_key)
		_slots[slot].text = tr("TREE_SLOT_CONTENT").format({"slot": tr(_slot_keys()[slot]), "power": name})


func _slot_keys() -> Array[String]:
	return BLADE_SLOT_KEYS if tree.blade else SLOT_KEYS


func _slot_count() -> int:
	return StoryCampaign.SLOTS if tree.blade else campaign.slots_open


func _tab_changed(index: int) -> void:
	_picking = false
	_picker.hide()
	tree = _trees[index]
	tree.rebuild()
	_graph = _graphs[index]
	_badges = []
	_badges.assign(_tab_badges[index])
	_icons = []
	_icons.assign(_tab_icons[index])
	selected = 0
	for button in _graph.buttons:
		button.focus_mode = Control.FOCUS_ALL
	_refresh()
	_focus_node.call_deferred(0)


func _state_text(node: StoryPowerTree.PowerNode) -> String:
	return tr(STATE_KEYS[node.state]).format({"level": node.power.min_level if node.power != null else 0})


func _buy_selected() -> void:
	if not tree.buy(selected):
		AudioDirector.play_ui(&"rejected")
		return
	campaign.save()
	AudioDirector.play_ui(&"ui_confirm")
	_refresh()


func _focus_node(index: int) -> void:
	_graph.buttons[posmod(index, tree.nodes.size())].grab_focus()


func _node_focused(index: int) -> void:
	if _picking:
		return
	if selected != index:
		AudioDirector.play_ui(&"ui_move")
	selected = index
	_refresh()


func _hovered(index: int) -> void:
	if not _picking:
		_focus_node(index)


func _confirm(index: int) -> void:
	if _picking:
		return
	_focus_node(index)
	var node: StoryPowerTree.PowerNode = tree.nodes[selected]
	if not node.owned:
		_buy_selected()
		return
	if not node.allowed:
		AudioDirector.play_ui(&"rejected")
		return
	if tree.blade and node.definition.kind != StoryCampaign.TreeNodeData.Kind.TECHNIQUE:
		if node.definition.style_slot() >= 0 and tree.equip(selected, node.definition.style_slot()):
			campaign.save()
			AudioDirector.play_ui(&"ui_confirm")
			_refresh()
		return
	AudioDirector.play_ui(&"ui_confirm")
	_picking = true
	for button in _graph.buttons:
		button.focus_mode = Control.FOCUS_NONE
	_picker.show()
	_slot = maxi(node.slot, 0)
	_focus_slot(_slot)


func _focus_slot(slot: int) -> void:
	await get_tree().process_frame
	if not _picking:
		return
	_slots[slot].grab_focus()
	_detail_scroll.ensure_control_visible(_slots[slot])


func _slot_focused(slot: int) -> void:
	if _slot != slot:
		AudioDirector.play_ui(&"ui_move")
	_slot = slot


func _equip(slot: int) -> void:
	if not tree.equip(selected, slot):
		AudioDirector.play_ui(&"rejected")
		return
	campaign.save()
	AudioDirector.play_ui(&"ui_confirm")
	_close_picker()
	_refresh()


func _close_picker() -> void:
	_picking = false
	_picker.hide()
	for button in _graph.buttons:
		button.focus_mode = Control.FOCUS_ALL
	_focus_node(selected)


func _input(event: InputEvent) -> void:
	if tree == null or not is_visible_in_tree():
		return
	if event.is_action_pressed(&"menu_variant") or event.is_action_pressed(&"ui_focus_next"):
		_tabs.current_tab = 1 - _tabs.current_tab
		get_viewport().set_input_as_handled()
		return
	var step: int = 0
	if event.is_action_pressed(&"ui_right") or event.is_action_pressed(&"ui_down"):
		step = 1
	elif event.is_action_pressed(&"ui_left") or event.is_action_pressed(&"ui_up"):
		step = -1
	if step != 0:
		if _picking:
			_slots[posmod(_slot + step, _slot_count())].grab_focus()
		else:
			_focus_node(selected + step)
	elif event.is_action_pressed(&"ui_accept"):
		if _picking:
			_equip(_slot)
		else:
			_confirm(selected)
	elif event.is_action_pressed(&"ui_cancel"):
		if _picking:
			_close_picker()
		else:
			SceneRouter.change(&"story_hub")
	else:
		return
	get_viewport().set_input_as_handled()
