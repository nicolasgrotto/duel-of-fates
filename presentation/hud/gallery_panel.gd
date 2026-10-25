class_name GalleryPanel
extends CanvasLayer

signal caster_changed(index: int)

const PALETTE: UiPalette = preload("res://ui/palette.tres")
const CATALOG: PowerCatalog = preload("res://data/powers/catalog.tres")
const TOP_MARGIN: float = 120.0
const BOTTOM_MARGIN: float = 36.0
const CHIP_GAP: int = 18
const CHIP_LINE: float = 2.0
const TARGET_POWERS: Dictionary = {
	GalleryTarget.Behavior.BARRIER: &"barrier",
	GalleryTarget.Behavior.ABSORPTION: &"absorption",
	GalleryTarget.Behavior.LIGHTNING: &"lightning",
}
const TARGET_KEYS: Dictionary = {
	GalleryTarget.Behavior.STAND: "GALLERY_TARGET_STAND",
	GalleryTarget.Behavior.GUARD: "GALLERY_TARGET_GUARD",
	GalleryTarget.Behavior.BARRIER: "GALLERY_TARGET_BARRIER",
	GalleryTarget.Behavior.ABSORPTION: "GALLERY_TARGET_ABSORPTION",
	GalleryTarget.Behavior.AIR: "GALLERY_TARGET_AIR",
	GalleryTarget.Behavior.LIGHTNING: "GALLERY_TARGET_LIGHTNING",
}
const SIDE_KEYS: Dictionary = {
	PowerData.Path.COMMON: "GALLERY_SIDE_COMMON",
	PowerData.Path.AURORA: "GALLERY_SIDE_AURORA",
	PowerData.Path.ECLIPSE: "GALLERY_SIDE_ECLIPSE",
}
const LOCKED_ALPHA: float = 0.35

var runner: TickRunner
var config: TrainingConfig
var caster: GalleryCaster = GalleryCaster.new()
var target: GalleryTarget = GalleryTarget.new()
var caster_index: int = 0

var _entries: Array[Resource] = []
var _entry_index: int = 0
var _tier: int = 2
var _repeat: bool = true
var _finishers: bool = false
var _round: int = 0
var _wait: int = 0
var _pause: int = 0
var _cast_requested: bool = true
var _name: Label
var _description: Label
var _side: Label
var _details: Label
var _chips: Array[Label] = []
var _underlines: Array[ColorRect] = []
var _footer: Label


func setup(tick_runner: TickRunner, training_config: TrainingConfig) -> void:
	layer = 11
	runner = tick_runner
	config = training_config
	_entries.assign(CATALOG.powers)
	_entries.append_array(CATALOG.techniques)
	_build()


func controllers() -> Array[FighterController]:
	var list: Array[FighterController] = [caster, target]
	if caster_index == 1:
		list.reverse()
	return list


func _build() -> void:
	var column: VBoxContainer = VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	column.grow_horizontal = Control.GROW_DIRECTION_BOTH
	column.offset_top = TOP_MARGIN
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(column)
	_name = _centered(column, &"FighterNameLabel")
	_description = _centered(column, &"InfoLabel")
	_side = _centered(column, &"CaptionLabel")
	var chips: HBoxContainer = HBoxContainer.new()
	chips.alignment = BoxContainer.ALIGNMENT_CENTER
	chips.add_theme_constant_override(&"separation", CHIP_GAP)
	column.add_child(chips)
	for tier in PALETTE.flow_tiers.size():
		var chip: VBoxContainer = VBoxContainer.new()
		var label: Label = Label.new()
		label.theme_type_variation = &"InfoLabel"
		label.text = tr("GALLERY_TIER").format({"tier": tier + 1})
		chip.add_child(label)
		var underline: ColorRect = ColorRect.new()
		underline.color = PALETTE.flow_tiers[tier]
		underline.custom_minimum_size = Vector2(0.0, CHIP_LINE)
		chip.add_child(underline)
		chips.add_child(chip)
		_chips.append(label)
		_underlines.append(underline)
	_details = _centered(column, &"CaptionLabel")
	_footer = Label.new()
	_footer.theme_type_variation = &"HintLabel"
	_footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_footer.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_footer.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_footer.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_footer.offset_bottom = -BOTTOM_MARGIN
	add_child(_footer)
	_footer.text = ControlHints.line(PackedStringArray([
		"← →  " + tr("HINT_GALLERY_ENTRY"), "↑ ↓  " + tr("HINT_GALLERY_TIER"),
		ControlHints.hint(&"gallery_target", "HINT_GALLERY_TARGET"), ControlHints.hint(&"gallery_repeat", "HINT_GALLERY_REPEAT"),
		ControlHints.hint(&"gallery_swap", "HINT_GALLERY_SWAP"), ControlHints.hint(&"gallery_finisher", "HINT_GALLERY_FINISHER"),
		ControlHints.hint(&"ui_accept", "HINT_GALLERY_CAST"),
		ControlHints.hint(&"p1_pause", "HINT_PAUSE"),
	]))


func _centered(parent: Control, variation: StringName) -> Label:
	var label: Label = Label.new()
	label.theme_type_variation = variation
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(label)
	return label


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_right"):
		_select(_entry_index + 1)
	elif event.is_action_pressed(&"ui_left"):
		_select(_entry_index - 1)
	elif event.is_action_pressed(&"ui_up"):
		_tier = mini(_tier + 1, PALETTE.flow_tiers.size() - 1)
		_restart()
	elif event.is_action_pressed(&"ui_down"):
		_tier = maxi(_tier - 1, 0)
		_restart()
	elif event.is_action_pressed(&"gallery_target"):
		target.behavior = ((target.behavior + 1) % GalleryTarget.Behavior.size()) as GalleryTarget.Behavior
		_restart()
	elif event.is_action_pressed(&"gallery_repeat"):
		_repeat = not _repeat
	elif event.is_action_pressed(&"gallery_finisher"):
		_finishers = not _finishers
		_restart()
	elif event.is_action_pressed(&"gallery_swap"):
		caster_index = 1 - caster_index
		runner.controllers = controllers()
		caster_changed.emit(caster_index)
		_restart()
	elif event.is_action_pressed(&"ui_accept"):
		_restart()
	else:
		return
	AudioDirector.play_ui(&"ui_move")
	get_viewport().set_input_as_handled()


func _select(index: int) -> void:
	_entry_index = posmod(index, _entries.size())
	_restart()


func _restart() -> void:
	_cast_requested = true
	_wait = 0
	_pause = 0


func on_ticked() -> void:
	var sim: MatchSimulation = runner.sim
	if sim.phase != MatchSimulation.Phase.FIGHT:
		return
	if sim.round_number != _round:
		_round = sim.round_number
		_cast_requested = _cast_requested or _repeat
	_wait -= 1
	if _wait > 0 and demonstrating(sim):
		_pause = Ticks.from_seconds(config.gallery_pause)
	else:
		_pause -= 1
	if (_cast_requested or _pause <= 0) and (_repeat or _cast_requested):
		_stage(sim)
	_refresh(sim)


func demonstrating(sim: MatchSimulation) -> bool:
	if sim.cinematic_ticks > 0:
		return true
	var fighter: FighterState = sim.fighters[caster_index]
	if fighter.is_casting() or fighter.is_attacking() or fighter.blade_out or fighter.rain_ticks > 0:
		return true
	if sim.fighters[1 - caster_index].state == FighterState.State.HELD:
		return true
	for hazard in sim.hazards:
		if hazard.active:
			return true
	for projectile in sim.projectiles:
		if projectile.active and projectile.kind != Projectile.Kind.ARSENAL:
			return true
	return false


func _stage(sim: MatchSimulation) -> void:
	_cast_requested = false
	sim.restage()
	var entry: Resource = _entries[_entry_index]
	var power: PowerData = entry as PowerData
	var technique: MoveData = entry as MoveData
	var fighter: FighterState = sim.fighters[caster_index]
	var other: FighterState = sim.fighters[1 - caster_index]
	fighter.set_flow_level(sim.config.flow.tier_floors[_tier], sim.config)
	other.set_flow_level(config.gallery_target_level, sim.config)
	var caster_powers: Array[PowerData] = [power, null, null]
	fighter.equip_powers(caster_powers)
	if technique != null:
		fighter.character.technique_forward = technique
		fighter.character.technique_air = technique
	if power != null:
		_close_in(sim, power.targeted_reach(fighter.flow_tier))
	elif not technique.throws_blade and technique.projectile_range <= 0.0:
		_close_in(sim, technique.reach + technique.lunge)
	var finishing: bool = _finishers and has_finisher(entry)
	sim.rules.endless_finishers = finishing
	target.finishing = finishing
	if finishing:
		other.health = minf(config.gallery_finisher_health, other.max_health)
	var target_powers: Array[PowerData] = [null if finishing else CATALOG.find(TARGET_POWERS.get(target.behavior, &"")), null, null]
	other.equip_powers(target_powers)
	if power != null and _tier < power.min_tier(sim.config.flow):
		return
	caster.perform(power, technique)
	_wait = Ticks.from_seconds(config.gallery_max_time)
	_pause = Ticks.from_seconds(config.gallery_pause)


static func has_finisher(entry: Resource) -> bool:
	var power: PowerData = entry as PowerData
	if power != null:
		return power.finisher != Finisher.Kind.NONE
	return (entry as MoveData).cinematic_finisher != Finisher.Kind.NONE


func _close_in(sim: MatchSimulation, reach: float) -> void:
	if reach <= 0.0:
		return
	var gap: float = minf(sim.config.round_start_distance - sim.config.body_width, reach * config.gallery_reach_ratio)
	var half: float = (gap + sim.config.body_width) * 0.5
	var first: FighterState = sim.fighters[0]
	var second: FighterState = sim.fighters[1]
	first.x = -half
	second.x = half


func _refresh(sim: MatchSimulation) -> void:
	var entry: Resource = _entries[_entry_index]
	var power: PowerData = entry as PowerData
	var path: CharacterData.Path = sim.fighters[caster_index].character.path
	_name.text = "‹ %s ›" % tr(power.name_key if power != null else PowerCatalog.technique_key(entry as MoveData))
	_name.add_theme_color_override(&"font_color", PALETTE.eclipse if path == CharacterData.Path.ECLIPSE else PALETTE.aurora)
	_description.text = tr(power.description_key) if power != null else ""
	_side.text = tr(SIDE_KEYS[power.path] if power != null else "GALLERY_SIDE_TECHNIQUE")
	var lowest: int = power.min_tier(sim.config.flow) if power != null else 0
	for tier in _chips.size():
		var active: bool = tier == _tier
		var locked: bool = tier < lowest
		_chips[tier].modulate.a = (1.0 if active else 0.4) * (LOCKED_ALPHA if locked else 1.0)
		_underlines[tier].modulate.a = (1.0 if active else 0.25) * (LOCKED_ALPHA if locked else 1.0)
	var details: PackedStringArray = PackedStringArray([
		tr("GALLERY_TARGET").format({"target": tr(TARGET_KEYS[target.behavior])}),
		tr("GALLERY_REPEAT_ON" if _repeat else "GALLERY_REPEAT_OFF"),
	])
	if lowest > 0:
		details.insert(0, tr("POWER_TIER_REQUIRED").format({"tier": lowest + 1, "level": power.min_level}))
	if has_finisher(entry):
		details.append(tr("GALLERY_FINISHER_ON" if _finishers else "GALLERY_FINISHER_OFF"))
	_details.text = ControlHints.line(details)
