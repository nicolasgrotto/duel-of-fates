class_name FlowBar
extends HudBar

const MARK_WIDTH: float = 2.0
const MARK_OVERHANG: float = 3.0
const MARK_DIM: float = 0.3
const MARK_PULSE: float = 0.35
const GLINT_SIZE: float = 4.0
const GLINT_HALO: float = 3.0
const GLINT_HALO_ALPHA: float = 0.35

var mark_ratios: PackedFloat32Array = []
var mark_colors: PackedColorArray = []
var _lit: Array[bool] = []
var _pulses: PackedFloat32Array = []


func set_marks(ratios: PackedFloat32Array, colors: PackedColorArray) -> void:
	mark_ratios = ratios
	mark_colors = colors
	_lit.resize(ratios.size())
	_lit.fill(false)
	_pulses.resize(ratios.size())
	_pulses.fill(0.0)


func update_marks(delta: float) -> void:
	for i in mark_ratios.size():
		var lit: bool = ratio >= mark_ratios[i]
		if lit and not _lit[i]:
			_pulses[i] = MARK_PULSE
		_lit[i] = lit
		_pulses[i] = maxf(_pulses[i] - delta, 0.0)


func _draw() -> void:
	super._draw()
	for i in mark_ratios.size():
		var x: float = size.x * clampf(mark_ratios[i], 0.0, 1.0)
		if anchored_right:
			x = size.x - x
		var color: Color = mark_colors[i] if _lit[i] else Color(mark_colors[i], MARK_DIM)
		var overhang: float = MARK_OVERHANG * (1.0 + 2.0 * _pulses[i] / MARK_PULSE)
		draw_line(Vector2(x, -overhang), Vector2(x, size.y + overhang), color, MARK_WIDTH)
		if _lit[i]:
			_draw_glint(Vector2(x, -overhang), color, _pulses[i] / MARK_PULSE)


func _draw_glint(at: Vector2, color: Color, pulse: float) -> void:
	var halo: float = GLINT_SIZE + GLINT_HALO * 2.0 * (1.0 + pulse)
	draw_rect(Rect2(at - Vector2.ONE * halo * 0.5, Vector2.ONE * halo), Color(color, GLINT_HALO_ALPHA * (1.0 + pulse)))
	draw_rect(Rect2(at - Vector2.ONE * GLINT_SIZE * 0.5, Vector2.ONE * GLINT_SIZE), color.lightened(0.5))
