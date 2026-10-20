class_name DebugOverlay
extends CanvasLayer

const PALETTE: UiPalette = preload("res://ui/palette.tres")
const MARGIN: float = 24.0
const TOP: float = 150.0
const BOX_ALPHA: float = 0.25
const LINE_WIDTH: float = 1.5

var sim: MatchSimulation
var runner: TickRunner
var always_show_boxes: bool = false

var _world_drawer: Node2D
var _labels: Array[Label] = []
var _header: Label


func _ready() -> void:
	layer = 40
	_header = _label(HORIZONTAL_ALIGNMENT_LEFT)
	_header.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_header.offset_left = MARGIN
	_header.offset_top = TOP - MARGIN * 1.5
	for i in 2:
		var label: Label = _label(HORIZONTAL_ALIGNMENT_RIGHT if i == 1 else HORIZONTAL_ALIGNMENT_LEFT)
		label.set_anchors_preset(Control.PRESET_TOP_RIGHT if i == 1 else Control.PRESET_TOP_LEFT)
		label.grow_horizontal = Control.GROW_DIRECTION_BEGIN if i == 1 else Control.GROW_DIRECTION_END
		label.offset_left = -MARGIN if i == 1 else MARGIN
		label.offset_right = -MARGIN if i == 1 else MARGIN
		label.offset_top = TOP
		_labels.append(label)
	_set_visible(false)


func attach(world: Node2D, simulation: MatchSimulation, tick_runner: TickRunner) -> void:
	sim = simulation
	runner = tick_runner
	if _world_drawer == null:
		_world_drawer = Node2D.new()
		_world_drawer.z_index = 50
		_world_drawer.draw.connect(_draw_world)
		world.add_child(_world_drawer)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"debug_overlay"):
		_set_visible(not _header.visible)
		get_viewport().set_input_as_handled()


func _set_visible(value: bool) -> void:
	_header.visible = value
	for label in _labels:
		label.visible = value


func _process(_delta: float) -> void:
	if sim == null:
		return
	if _world_drawer != null:
		_world_drawer.visible = _header.visible or always_show_boxes
		_world_drawer.queue_redraw()
	if not _header.visible:
		return
	_header.text = "FPS %d  tick %d  round %d  %s %d  lock cd %d" % [
		Engine.get_frames_per_second(), sim.tick, sim.round_number,
		MatchSimulation.Phase.keys()[sim.phase].to_lower(), sim.phase_ticks, sim.lock_cooldown_ticks,
	]
	for i in 2:
		_labels[i].text = "\n".join(_fighter_lines(i))


func _fighter_lines(i: int) -> PackedStringArray:
	var fighter: FighterState = sim.fighters[i]
	var lines: PackedStringArray = [
		"%s  %s %d" % [fighter.character.id, FighterState.State.keys()[fighter.state].to_lower(), fighter.state_ticks],
		"pos %.0f, %.0f  vel %.0f, %.0f  facing %d" % [fighter.x, fighter.y, fighter.vx, fighter.vy, fighter.facing],
		"health %.1f / %.0f  vigor %.1f / %.0f" % [fighter.health, fighter.max_health, fighter.vigor, fighter.max_vigor],
		"exhausted %s  wound %s  freeze %d" % [fighter.exhausted, FighterState.Wound.keys()[fighter.wound].to_lower(), fighter.freeze_ticks],
		"buffer %s %d" % [FighterState.Action.keys()[fighter.buffered_action].to_lower(), fighter.buffer_ticks],
	]
	lines.append_array(sim.state_logic(fighter).debug_lines(sim, fighter))
	if runner != null and i < runner.controllers.size():
		var intent: Intent = runner.intents[i]
		lines.append("intent move %d  held %s  pressed %s" % [intent.move_x, _bits(intent.held), _bits(intent.pressed)])
		lines.append_array(runner.controllers[i].debug_lines())
	return lines


func _bits(mask: int) -> String:
	var names: PackedStringArray = []
	for command in Intent.Command.values():
		if mask & command:
			names.append(Intent.Command.find_key(command).to_lower())
	return ",".join(names) if not names.is_empty() else "-"


func _draw_world() -> void:
	var config: CombatConfig = sim.config
	for fighter in sim.fighters:
		_box(CombatGeometry.hurtbox(config, fighter), PALETTE.aurora)
		if fighter.is_active() and fighter.move != null:
			_box(CombatGeometry.hitbox(config, fighter, fighter.move), PALETTE.danger)
			if fighter.move.can_clash():
				_box(CombatGeometry.blade_box(config, fighter, fighter.move), PALETTE.accent)


func _box(rect: Rect2, color: Color) -> void:
	var screen_rect: Rect2 = Rect2(rect.position.x, -rect.end.y, rect.size.x, rect.size.y)
	_world_drawer.draw_rect(screen_rect, Color(color, BOX_ALPHA))
	_world_drawer.draw_rect(screen_rect, color, false, LINE_WIDTH)


func _label(alignment: HorizontalAlignment) -> Label:
	var label: Label = Label.new()
	label.theme_type_variation = &"DebugLabel"
	label.horizontal_alignment = alignment
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label
