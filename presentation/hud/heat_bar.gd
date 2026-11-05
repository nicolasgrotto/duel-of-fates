class_name HeatBar
extends HudBar

enum Level { COOL, HOT, OVERHEATED }

const PALETTE: UiPalette = preload("res://ui/palette.tres")
const MARK_WIDTH: float = 2.0
const PULSE_LOW: float = 0.55

var reduced: bool = false
var level: Level = Level.COOL
var resume_ratio: float = 0.0
var pulse_speed: float = 0.0


static func level_for(ratio_value: float, overheated: bool, hot_ratio: float) -> Level:
	if overheated:
		return Level.OVERHEATED
	return Level.HOT if ratio_value >= hot_ratio else Level.COOL


static func label_key(state: BlasterOpsState) -> String:
	if state.overheated:
		return "BOPS_OVERHEATED"
	return "BOPS_COOLING" if state.heat > 0.0 and state.cooling_ticks == 0 else "BOPS_HEAT"


func _ready() -> void:
	back_color = PALETTE.bar_back
	set_process(not reduced)


func _process(_delta: float) -> void:
	if level == Level.OVERHEATED:
		queue_redraw()


func show_heat(sim: BlasterOpsSimulation, config: BlasterOpsConfig) -> void:
	ratio = sim.state.heat / config.heat_capacity
	ghost_ratio = ratio
	resume_ratio = config.resume_heat / config.heat_capacity
	pulse_speed = config.heat_pulse_speed
	level = level_for(ratio, sim.state.overheated, config.heat_hot_ratio)
	fill_color = [PALETTE.accent, PALETTE.menu_blade_b, PALETTE.danger][level]
	queue_redraw()


func _draw() -> void:
	var shown: Color = fill_color
	if level == Level.OVERHEATED and not reduced:
		shown.a = lerpf(PULSE_LOW, 1.0, 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.001 * pulse_speed))
	draw_rect(Rect2(Vector2.ZERO, size), back_color)
	draw_rect(_portion(ratio), shown)
	if level == Level.OVERHEATED:
		var mark: float = size.x * resume_ratio
		draw_line(Vector2(mark, -2.0), Vector2(mark, size.y + 2.0), PALETTE.text, MARK_WIDTH)
