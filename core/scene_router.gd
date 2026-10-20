extends Node

const SCREENS: Dictionary = {
	&"menu": "res://screens/menu/main_menu.tscn",
	&"duel": "res://screens/duel/duel_screen.tscn",
	&"pause": "res://screens/pause/pause_screen.tscn",
	&"result": "res://screens/result/result_screen.tscn",
}
const FADE_SECONDS: float = 0.18
const OVERLAY_LAYER: int = 50
const FADE_LAYER: int = 100
const PALETTE: UiPalette = preload("res://ui/palette.tres")

var _stack: Array[Node] = []
var _overlay: CanvasLayer
var _fade: ColorRect
var _busy: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_overlay = CanvasLayer.new()
	_overlay.layer = OVERLAY_LAYER
	add_child(_overlay)
	var fade_layer: CanvasLayer = CanvasLayer.new()
	fade_layer.layer = FADE_LAYER
	add_child(fade_layer)
	_fade = ColorRect.new()
	_fade.color = PALETTE.background
	_fade.modulate.a = 0.0
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_layer.add_child(_fade)


func change(screen: StringName, params: Dictionary = {}) -> void:
	if _busy:
		return
	_busy = true
	await _fade_to(1.0)
	_clear_stack()
	get_tree().paused = false
	var old_scene: Node = get_tree().current_scene
	var node: Node = _instantiate(screen)
	get_tree().root.add_child(node)
	get_tree().current_scene = node
	if old_scene != null:
		old_scene.queue_free()
	_open(node, params)
	await _fade_to(0.0)
	_busy = false


func push(screen: StringName, params: Dictionary = {}) -> void:
	var node: Node = _instantiate(screen)
	node.process_mode = Node.PROCESS_MODE_ALWAYS
	_overlay.add_child(node)
	_stack.append(node)
	get_tree().paused = true
	_open(node, params)


func pop() -> void:
	if _stack.is_empty():
		return
	var node: Node = _stack.pop_back()
	node.queue_free()
	if _stack.is_empty():
		get_tree().paused = false


func _instantiate(screen: StringName) -> Node:
	var scene: PackedScene = load(SCREENS[screen])
	return scene.instantiate()


func _open(node: Node, params: Dictionary) -> void:
	if node.has_method("open"):
		node.call("open", params)


func _clear_stack() -> void:
	for node in _stack:
		node.queue_free()
	_stack.clear()


func _fade_to(alpha: float) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(_fade, "modulate:a", alpha, FADE_SECONDS)
	await tween.finished
