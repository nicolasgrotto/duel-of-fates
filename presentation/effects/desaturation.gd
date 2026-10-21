class_name Desaturation
extends CanvasLayer

const SHADER: Shader = preload("res://presentation/effects/desaturation.gdshader")

var _rect: ColorRect
var _shader_material: ShaderMaterial
var _left: float = 0.0
var _duration: float = 0.15


func _ready() -> void:
	_shader_material = ShaderMaterial.new()
	_shader_material.shader = SHADER
	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.material = _shader_material
	_rect.visible = false
	add_child(_rect)


func pulse(seconds: float) -> void:
	_duration = seconds
	_left = seconds
	_rect.visible = true


func _process(delta: float) -> void:
	if _left <= 0.0:
		return
	_left = maxf(_left - delta, 0.0)
	var progress: float = 1.0 - _left / _duration
	_shader_material.set_shader_parameter(&"amount", 1.0 - smoothstep(0.6, 1.0, progress))
	_rect.visible = _left > 0.0
