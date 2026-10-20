class_name ScreenEffects
extends CanvasLayer

const PALETTE: UiPalette = preload("res://ui/palette.tres")
const LABEL_MARGIN: float = 48.0

var config: EffectsConfig
var letterbox_target: float = 0.0

var _flash: ColorRect
var _top: ColorRect
var _bottom: ColorRect
var _replay_label: Label
var _skip_label: Label
var _letterbox: float = 0.0
var _pulse_left: float = 0.0


func setup(effects_config: EffectsConfig) -> void:
	config = effects_config
	if _flash != null:
		return
	_flash = _rect(PALETTE.hit_flash)
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.modulate.a = 0.0
	var additive: CanvasItemMaterial = CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_flash.material = additive
	_top = _rect(PALETTE.letterbox)
	_top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_bottom = _rect(PALETTE.letterbox)
	_bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_replay_label = _label(tr("REPLAY_LABEL"), HORIZONTAL_ALIGNMENT_LEFT)
	_skip_label = _label("", HORIZONTAL_ALIGNMENT_RIGHT)
	show_replay(false)


func flash(alpha: float) -> void:
	_flash.modulate.a = maxf(_flash.modulate.a, alpha)


func pulse_letterbox(seconds: float) -> void:
	_pulse_left = maxf(_pulse_left, seconds)


func show_replay(visible_now: bool, skip_hint: String = "") -> void:
	_replay_label.visible = visible_now
	_skip_label.visible = visible_now
	_skip_label.text = skip_hint


func _process(delta: float) -> void:
	if config == null:
		return
	_flash.modulate.a = move_toward(_flash.modulate.a, 0.0, delta / config.flash_decay)
	_pulse_left = maxf(_pulse_left - delta, 0.0)
	var target: float = 1.0 if _pulse_left > 0.0 else letterbox_target
	_letterbox = move_toward(_letterbox, target, delta * config.letterbox_speed)
	var height: float = get_viewport().get_visible_rect().size.y * config.letterbox_height * ease(_letterbox, 0.6)
	_top.offset_bottom = height
	_bottom.offset_top = -height
	var label_y: float = -height * 0.5 - _replay_label.size.y * 0.5
	_replay_label.offset_top = label_y
	_skip_label.offset_top = label_y


func _rect(color: Color) -> ColorRect:
	var rect: ColorRect = ColorRect.new()
	rect.color = color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)
	return rect


func _label(text: String, alignment: HorizontalAlignment) -> Label:
	var label: Label = Label.new()
	label.theme_type_variation = &"HintLabel"
	label.text = text
	label.horizontal_alignment = alignment
	label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	label.offset_left = LABEL_MARGIN
	label.offset_right = -LABEL_MARGIN
	add_child(label)
	return label
