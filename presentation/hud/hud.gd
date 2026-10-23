class_name Hud
extends CanvasLayer

const PALETTE: UiPalette = preload("res://ui/palette.tres")
const SIDE_MARGIN: float = 56.0
const TOP_MARGIN: float = 30.0
const BAR_WIDTH_RATIO: float = 0.36
const HEALTH_HEIGHT: float = 10.0
const VIGOR_HEIGHT: float = 5.0
const FLOW_HEIGHT: float = 3.0
const BAR_GAP: float = 6.0
const NAME_HEIGHT: float = 28.0
const LOW_HEALTH_RATIO: float = 0.25
const BLINK_SPEED: float = 4.0
const GHOST_DELAY: float = 0.5
const GHOST_SPEED: float = 0.6
const REJECT_FLASH: float = 0.3
const MESSAGE_KO_SECONDS: float = 1.5
const FOOTER_MARGIN: float = 24.0

var sim: MatchSimulation
var show_rounds: bool = true

var _root: Control
var _names: Array[Label] = []
var _wounds: Array[Label] = []
var _health: Array[HudBar] = []
var _vigor: Array[HudBar] = []
var _flow: Array[FlowBar] = []
var _flow_reject_left: Array[float] = [0.0, 0.0]
var _marks: Array[RoundMarks] = []
var _ghost: Array[float] = [1.0, 1.0]
var _ghost_delay: Array[float] = [0.0, 0.0]
var _reject_left: Array[float] = [0.0, 0.0]
var _message: Label
var _message_left: float = 0.0
var _footer: Label
var _time: float = 0.0


func tag_players() -> void:
	for i in 2:
		_names[i].text = tr("HUD_PLAYER_TAG").format({"player": i + 1, "name": tr(sim.fighters[i].character.name_key)})


func setup(simulation: MatchSimulation, rounds_visible: bool) -> void:
	layer = 10
	sim = simulation
	show_rounds = rounds_visible
	if _root == null:
		_build()
	for i in 2:
		_names[i].text = tr(sim.fighters[i].character.name_key)
		_marks[i].total = sim.rules.rounds_to_win
		_marks[i].visible = show_rounds
		_ghost[i] = sim.fighters[i].health_ratio()
		_setup_flow(i)
	if show_rounds and sim.phase == MatchSimulation.Phase.INTRO:
		_show_message(_round_title(), Ticks.to_seconds(Ticks.from_seconds(sim.config.round_intro) - sim.phase_ticks))


func _setup_flow(i: int) -> void:
	var fighter: FighterState = sim.fighters[i]
	var bar: FlowBar = _flow[i]
	bar.visible = sim.rules.powers
	bar.fill_color = PALETTE.aurora if fighter.character.path == CharacterData.Path.AURORA else PALETTE.eclipse
	var ratios: PackedFloat32Array = []
	var colors: PackedColorArray = []
	for power in fighter.powers:
		if power != null and power.high_cost:
			ratios.append(power.cost_for(fighter.flow_level) / sim.config.flow.maximum)
			colors.append(power.mark_color)
	bar.set_marks(ratios, colors)


func show_flow_only(index: int) -> void:
	for i in 2:
		for control in [_names[i], _wounds[i], _health[i], _vigor[i], _marks[i]]:
			control.visible = false
		_flow[i].visible = i == index


func set_footer(text: String) -> void:
	_footer.text = text


func on_event(event: CombatEvent) -> void:
	match event.type:
		CombatEvent.Type.ROUND_STARTED:
			if show_rounds:
				_show_message(_round_title(), sim.config.round_intro)
		CombatEvent.Type.FIGHT_STARTED:
			_message_left = 0.0
		CombatEvent.Type.DEATH:
			_show_message(tr("HUD_KO"), MESSAGE_KO_SECONDS)
		CombatEvent.Type.HIT, CombatEvent.Type.BLADE_LOCK_ENDED:
			if event.target >= 0:
				_ghost_delay[event.target] = GHOST_DELAY
		CombatEvent.Type.ACTION_REJECTED:
			_reject_left[event.source] = REJECT_FLASH
		CombatEvent.Type.POWER_REJECTED:
			_flow_reject_left[event.source] = REJECT_FLASH


func _round_title() -> String:
	var last: int = sim.rules.rounds_to_win - 1
	if sim.fighters[0].round_wins == last and sim.fighters[1].round_wins == last:
		return tr("HUD_ROUND_FINAL")
	return tr("HUD_ROUND").format({"number": sim.round_number})


func _show_message(text: String, seconds: float) -> void:
	_message.text = text
	_message_left = seconds


func _process(delta: float) -> void:
	if sim == null:
		return
	_time += delta
	_message_left = maxf(_message_left - delta, 0.0)
	_message.visible = _message_left > 0.0
	for i in 2:
		_update_side(i, delta)


func _update_side(i: int, delta: float) -> void:
	var fighter: FighterState = sim.fighters[i]
	var health_ratio: float = fighter.health_ratio()
	if _ghost_delay[i] > 0.0:
		_ghost_delay[i] -= delta
	else:
		_ghost[i] = move_toward(_ghost[i], health_ratio, GHOST_SPEED * delta)
	_ghost[i] = maxf(_ghost[i], health_ratio)
	var health: HudBar = _health[i]
	health.ratio = health_ratio
	health.ghost_ratio = _ghost[i]
	var low: bool = health_ratio < LOW_HEALTH_RATIO and fighter.is_alive()
	health.fill_color = PALETTE.danger if low else PALETTE.text
	health.modulate.a = 0.55 + 0.45 * absf(cos(_time * BLINK_SPEED * 0.5)) if low else 1.0
	health.queue_redraw()
	var vigor: HudBar = _vigor[i]
	_reject_left[i] = maxf(_reject_left[i] - delta, 0.0)
	vigor.ratio = fighter.vigor_ratio()
	vigor.outlined = fighter.exhausted
	if _reject_left[i] > 0.0:
		vigor.fill_color = PALETTE.danger
		vigor.modulate.a = 1.0 if fmod(_reject_left[i], 0.1) > 0.05 else 0.4
	elif fighter.exhausted:
		vigor.fill_color = PALETTE.exhausted
		vigor.modulate.a = 0.6 + 0.4 * absf(sin(_time * BLINK_SPEED * 0.4))
	else:
		vigor.fill_color = PALETTE.accent
		vigor.modulate.a = 1.0
	vigor.queue_redraw()
	_update_flow(i, fighter, delta)
	_wounds[i].text = _wound_text(fighter)
	_marks[i].won = fighter.round_wins
	_marks[i].queue_redraw()


func _update_flow(i: int, fighter: FighterState, delta: float) -> void:
	var bar: FlowBar = _flow[i]
	if not bar.visible:
		return
	_flow_reject_left[i] = maxf(_flow_reject_left[i] - delta, 0.0)
	bar.ratio = fighter.flow / sim.config.flow.maximum
	bar.modulate.a = (1.0 if fmod(_flow_reject_left[i], 0.1) > 0.05 else 0.3) if _flow_reject_left[i] > 0.0 else 1.0
	bar.update_marks(delta)
	bar.queue_redraw()


func _wound_text(fighter: FighterState) -> String:
	match fighter.wound:
		FighterState.Wound.ARM:
			return tr("HUD_WOUND_ARM")
		FighterState.Wound.LEG:
			return tr("HUD_WOUND_LEG")
	return ""


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	for i in 2:
		_build_side(i == 1)
	_message = Label.new()
	_message.theme_type_variation = &"HudMessageLabel"
	_message.set_anchors_preset(Control.PRESET_CENTER)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_message.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_message.grow_vertical = Control.GROW_DIRECTION_BOTH
	_message.visible = false
	_root.add_child(_message)
	_footer = Label.new()
	_footer.theme_type_variation = &"HintLabel"
	_footer.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_footer.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_footer.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_footer.offset_bottom = -FOOTER_MARGIN
	_root.add_child(_footer)


func _build_side(right: bool) -> void:
	var anchor: float = 1.0 if right else 0.0
	var name_label: Label = Label.new()
	name_label.theme_type_variation = &"HudNameLabel"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if right else HORIZONTAL_ALIGNMENT_LEFT
	_place(name_label, anchor, right, TOP_MARGIN, NAME_HEIGHT)
	_names.append(name_label)
	var wound: Label = Label.new()
	wound.theme_type_variation = &"HudWoundLabel"
	wound.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if right else HORIZONTAL_ALIGNMENT_RIGHT
	_place(wound, anchor, right, TOP_MARGIN, NAME_HEIGHT)
	_wounds.append(wound)
	var top: float = TOP_MARGIN + NAME_HEIGHT
	var health: HudBar = HudBar.new()
	health.anchored_right = right
	health.back_color = PALETTE.bar_back
	health.ghost_color = PALETTE.health_ghost
	_place(health, anchor, right, top, HEALTH_HEIGHT)
	_health.append(health)
	top += HEALTH_HEIGHT + BAR_GAP
	var vigor: HudBar = HudBar.new()
	vigor.anchored_right = right
	vigor.back_color = PALETTE.bar_back
	_place(vigor, anchor, right, top, VIGOR_HEIGHT)
	_vigor.append(vigor)
	top += VIGOR_HEIGHT + BAR_GAP
	var flow: FlowBar = FlowBar.new()
	flow.anchored_right = right
	flow.back_color = PALETTE.bar_back
	_place(flow, anchor, right, top, FLOW_HEIGHT)
	_flow.append(flow)
	top += FLOW_HEIGHT + BAR_GAP * 2.0
	var marks: RoundMarks = RoundMarks.new()
	marks.anchored_right = right
	marks.color = PALETTE.text
	_place(marks, anchor, right, top, RoundMarks.MARK_SIZE)
	_marks.append(marks)


func _place(control: Control, anchor: float, right: bool, top: float, height: float) -> void:
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	control.anchor_left = anchor
	control.anchor_right = anchor
	var width: float = get_viewport().get_visible_rect().size.x * BAR_WIDTH_RATIO
	control.offset_left = -SIDE_MARGIN - width if right else SIDE_MARGIN
	control.offset_right = -SIDE_MARGIN if right else SIDE_MARGIN + width
	control.offset_top = top
	control.offset_bottom = top + height
	_root.add_child(control)
