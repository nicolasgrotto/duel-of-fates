extends Control

const PALETTE: UiPalette = preload("res://ui/palette.tres")
const UPSCALE_SHADER: Shader = preload("res://presentation/camera/pixel_upscale.gdshader")
const PIXEL_SCALE: float = 4.0
const BLADE_HALF: float = 110.0
const IGNITE_DELAY: float = 0.3
const IGNITE_TIME: float = 0.6
const TITLE_AT: float = 0.9
const TAGLINE_AT: float = 1.3
const PROMPT_AT: float = 2.0
const FADE_TIME: float = 0.6
const BLINK_SPEED: float = 2.2
const SECRET_WINDOW: float = 2.5
const SECRET_SHOW: float = 3.0
const TAGLINE_TAPS: int = 5
const TITLE_GAP: float = 230.0
const BALANCE: Array[StringName] = [&"ui_left", &"ui_left", &"ui_right", &"ui_right", &"ui_up", &"ui_down", &"ui_up", &"ui_down"]
const WARDROBE: Array[StringName] = [&"ui_down", &"ui_down", &"ui_up", &"ui_up", &"ui_right", &"ui_left", &"ui_right", &"ui_left"]
const DIRECTIONS: Array[StringName] = [&"ui_left", &"ui_right", &"ui_up", &"ui_down"]

var _time: float = 0.0
var _entered: Array[StringName] = []
var _last_entry: float = -INF
var _secret_left: float = 0.0
var _taps: int = 0
var _leaving: bool = false

var _viewport: SubViewport
var _canvas: Node2D
var _title: Label
var _tagline: Label
var _prompt: Label
var _secret: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_blade()
	var column: VBoxContainer = VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_CENTER)
	column.grow_horizontal = Control.GROW_DIRECTION_BOTH
	column.grow_vertical = Control.GROW_DIRECTION_BOTH
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(column)
	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0.0, TITLE_GAP)
	column.add_child(spacer)
	_title = _label(tr("GAME_TITLE"), &"TitleLabel")
	column.add_child(_title)
	_tagline = _label(tr("GAME_TAGLINE"), &"SubtitleLabel")
	_tagline.mouse_filter = Control.MOUSE_FILTER_STOP
	_tagline.gui_input.connect(_on_tagline_input)
	column.add_child(_tagline)
	_secret = _label("", &"SubtitleLabel")
	_secret.add_theme_color_override(&"font_color", PALETTE.flow_tiers[3])
	column.add_child(_secret)
	_prompt = _label("", &"HintLabel")
	_prompt.text = tr("OPENING_PRESS").format({"key": ControlHints.key_label(&"ui_accept")})
	_prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_prompt.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_prompt.offset_bottom = -120.0
	add_child(_prompt)
	_title.modulate.a = 0.0
	_tagline.modulate.a = 0.0
	_prompt.modulate.a = 0.0


func _build_blade() -> void:
	_viewport = SubViewport.new()
	_viewport.transparent_bg = false
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.snap_2d_transforms_to_pixel = true
	_viewport.snap_2d_vertices_to_pixel = true
	_viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	add_child(_viewport)
	var backdrop: ColorRect = ColorRect.new()
	backdrop.color = PALETTE.background
	backdrop.size = Vector2(4096.0, 4096.0)
	_viewport.add_child(backdrop)
	_canvas = Node2D.new()
	var additive: CanvasItemMaterial = CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_canvas.material = additive
	_canvas.draw.connect(_draw_blade)
	_viewport.add_child(_canvas)
	var display: TextureRect = TextureRect.new()
	display.texture = _viewport.get_texture()
	display.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	display.stretch_mode = TextureRect.STRETCH_SCALE
	display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var upscale: ShaderMaterial = ShaderMaterial.new()
	upscale.shader = UPSCALE_SHADER
	display.material = upscale
	display.name = "Display"
	add_child(display)


func _label(text: String, variation: StringName) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.theme_type_variation = variation
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _process(delta: float) -> void:
	_time += delta
	_secret_left = maxf(_secret_left - delta, 0.0)
	if _secret_left == 0.0:
		_secret.text = ""
	var screen: Vector2 = get_viewport_rect().size
	var grid: Vector2i = Vector2i(ceili(screen.x / PIXEL_SCALE), ceili(screen.y / PIXEL_SCALE))
	if _viewport.size != grid:
		_viewport.size = grid
		(get_node("Display") as TextureRect).size = Vector2(grid) * PIXEL_SCALE
	_title.modulate.a = clampf((_time - TITLE_AT) / FADE_TIME, 0.0, 1.0)
	_tagline.modulate.a = clampf((_time - TAGLINE_AT) / FADE_TIME, 0.0, 1.0)
	_prompt.modulate.a = 0.0 if _time < PROMPT_AT else 0.45 + 0.55 * absf(sin((_time - PROMPT_AT) * BLINK_SPEED))
	_canvas.queue_redraw()


func _draw_blade() -> void:
	var center: Vector2 = (Vector2(_viewport.size) * 0.5).round()
	var lit: float = clampf((_time - IGNITE_DELAY) / IGNITE_TIME, 0.0, 1.0)
	if _secret_left > 0.0:
		var glow: float = _secret_left / SECRET_SHOW
		_canvas.draw_circle(center, 60.0 + 20.0 * glow, Color(PALETTE.flow_tiers[3], 0.18 * glow))
		_canvas.draw_circle(center, 30.0, Color(PALETTE.flow_tiers[3], 0.25 * glow))
	if lit <= 0.0:
		return
	var reach: float = BLADE_HALF * (1.0 - pow(1.0 - lit, 3.0))
	var from: Vector2 = center - Vector2(reach, 0.0)
	var to: Vector2 = center + Vector2(reach, 0.0)
	var hum: float = 0.85 + 0.15 * sin(_time * 9.0)
	_canvas.draw_line(from, to, Color(PALETTE.menu_blade_a, 0.12 * hum), 9.0)
	_canvas.draw_line(from, to, Color(PALETTE.menu_blade_a, 0.25 * hum), 5.0)
	_canvas.draw_line(from, to, Color(PALETTE.menu_blade_a, 0.9), 3.0)
	_canvas.draw_line(from, to, Color.WHITE, 1.0)


func _unhandled_input(event: InputEvent) -> void:
	if _leaving:
		return
	if event.is_action_pressed(&"ui_accept"):
		get_viewport().set_input_as_handled()
		if _time < PROMPT_AT:
			_time = PROMPT_AT
		else:
			_leave()
		return
	for direction in DIRECTIONS:
		if event.is_action_pressed(direction):
			get_viewport().set_input_as_handled()
			_enter(direction)
			return


func _enter(direction: StringName) -> void:
	if _time - _last_entry > SECRET_WINDOW:
		_entered.clear()
	_last_entry = _time
	_entered.append(direction)
	if _entered.size() > BALANCE.size():
		_entered.pop_front()
	if _entered == BALANCE:
		_reveal(Unlocks.SECRETS_KEY, "SECRET_BALANCE", &"perfect_parry")
	elif _entered == WARDROBE:
		_reveal(Unlocks.WARDROBE_KEY, "SECRET_WARDROBE", &"ui_confirm")


func _on_tagline_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_taps += 1
		if _taps >= TAGLINE_TAPS:
			_taps = 0
			_reveal(Unlocks.WARDROBE_KEY, "SECRET_WARDROBE", &"ui_confirm")


func _reveal(key: String, phrase_key: String, sound: StringName) -> void:
	_entered.clear()
	SaveService.unlock(key)
	_secret.text = tr(phrase_key)
	_secret_left = SECRET_SHOW
	AudioDirector.play_ui(sound)


func _leave() -> void:
	_leaving = true
	AudioDirector.play_ui(&"ui_confirm")
	SceneRouter.change(&"menu")
