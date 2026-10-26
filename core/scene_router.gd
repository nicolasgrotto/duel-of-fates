extends Node

const SCREENS: Dictionary = {
	&"opening": "res://screens/opening/opening_screen.tscn",
	&"menu": "res://screens/menu/main_menu.tscn",
	&"select": "res://screens/select/character_select.tscn",
	&"duel": "res://screens/duel/duel_screen.tscn",
	&"pause": "res://screens/pause/pause_screen.tscn",
	&"moves": "res://screens/moves/move_list_screen.tscn",
	&"result": "res://screens/result/result_screen.tscn",
	&"options": "res://screens/options/options_screen.tscn",
	&"keys": "res://screens/controls/key_config_screen.tscn",
	&"controls": "res://screens/controls/controls_screen.tscn",
	&"story_hub": "res://screens/story/story_hub.tscn",
	&"story_new": "res://screens/story/story_new.tscn",
	&"story_attributes": "res://screens/story/story_attributes.tscn",
	&"story_powers": "res://screens/story/story_powers.tscn",
	&"story_gallery": "res://screens/story/story_gallery.tscn",
	&"dialogue": "res://screens/story/dialogue_screen.tscn",
	&"ending": "res://screens/story/ending_screen.tscn",
}
const FADE_SECONDS: float = 0.18
const SETTLE_FRAMES: int = 2
const REQUIRED_RESOURCES: StringName = &"required_resources"
const SINGLE_THREAD_FEATURE: String = "nothreads"
const OVERLAY_LAYER: int = 50
const FADE_LAYER: int = 100
const PALETTE: UiPalette = preload("res://ui/palette.tres")
const LOADING_WIDTH: float = 220.0
const LOADING_MARGIN: Vector2 = Vector2(48.0, 36.0)
const LOADING_DOTS: int = 3
const LOADING_DOT_SECONDS: float = 0.3

var _stack: Array[Node] = []
var _overlay: CanvasLayer
var _fade: ColorRect
var _busy: bool = false
var _loading: Label
var _loading_time: float = 0.0


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
	_loading = Label.new()
	_loading.theme_type_variation = &"HintLabel"
	_loading.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_loading.offset_left = -LOADING_WIDTH - LOADING_MARGIN.x
	_loading.offset_right = -LOADING_MARGIN.x
	_loading.offset_bottom = -LOADING_MARGIN.y
	_loading.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_loading.visible = false
	fade_layer.add_child(_loading)


func _process(delta: float) -> void:
	if not _loading.visible:
		return
	_loading_time += delta
	var lit: int = int(_loading_time / LOADING_DOT_SECONDS) % (LOADING_DOTS + 1)
	_loading.text = tr("LOADING") + ".".repeat(lit)


func _show_loading(shown: bool) -> void:
	_loading_time = 0.0
	_loading.text = tr("LOADING")
	_loading.visible = shown


func change(screen: StringName, params: Dictionary = {}) -> void:
	if _busy:
		return
	_busy = true
	var path: String = SCREENS[screen]
	var background_loading: bool = not OS.has_feature(SINGLE_THREAD_FEATURE)
	if background_loading:
		ResourceLoader.load_threaded_request(path)
	await _fade_to(1.0)
	_show_loading(true)
	await RenderingServer.frame_post_draw
	if not background_loading:
		ResourceLoader.load_threaded_request(path)
	var scene: PackedScene = await _finish_loading(path)
	var node: Node = scene.instantiate()
	var held: Array[Resource] = []
	if node.has_method(REQUIRED_RESOURCES):
		var required: PackedStringArray = node.call(REQUIRED_RESOURCES, params)
		for resource_path in required:
			ResourceLoader.load_threaded_request(resource_path)
		for resource_path in required:
			held.append(await _finish_loading(resource_path))
	_clear_stack()
	get_tree().paused = false
	var old_scene: Node = get_tree().current_scene
	get_tree().root.add_child(node)
	get_tree().current_scene = node
	if old_scene != null:
		old_scene.queue_free()
	_open(node, params)
	held.clear()
	for i in SETTLE_FRAMES:
		await RenderingServer.frame_post_draw
	_show_loading(false)
	await _fade_to(0.0)
	_busy = false


func _finish_loading(path: String) -> Resource:
	while ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame
	return ResourceLoader.load_threaded_get(path)


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
