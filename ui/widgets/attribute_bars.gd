class_name AttributeBars
extends Control

const PALETTE: UiPalette = preload("res://ui/palette.tres")
const LABEL_KEYS: Array[String] = [
	"ATTRIBUTE_HEALTH", "ATTRIBUTE_VIGOR", "ATTRIBUTE_BLADE", "ATTRIBUTE_DEFENSE", "ATTRIBUTE_AGILITY", "ATTRIBUTE_FLOW",
]
const COMMON_MAXIMUM: int = 7
const SEGMENTS: int = 10
const ROW_HEIGHT: float = 30.0
const SEGMENT_SIZE: Vector2 = Vector2(26.0, 8.0)
const SEGMENT_GAP: float = 5.0
const LABEL_WIDTH: float = 150.0

var values: Array[int] = [4, 4, 4, 4, 4, 4]
var _labels: Array[Label] = []


func _ready() -> void:
	custom_minimum_size = Vector2(LABEL_WIDTH + SEGMENTS * (SEGMENT_SIZE.x + SEGMENT_GAP), ROW_HEIGHT * LABEL_KEYS.size())
	for i in LABEL_KEYS.size():
		var label: Label = Label.new()
		label.theme_type_variation = &"CaptionLabel"
		label.text = tr(LABEL_KEYS[i])
		label.position = Vector2(0.0, i * ROW_HEIGHT - 4.0)
		add_child(label)
		_labels.append(label)


func show_character(data: CharacterData) -> void:
	values = [data.health, data.vigor, data.blade, data.defense, data.agility, data.flow]
	queue_redraw()


func _draw() -> void:
	for row in values.size():
		var y: float = row * ROW_HEIGHT + ROW_HEIGHT * 0.5 - SEGMENT_SIZE.y * 0.5
		for segment in SEGMENTS:
			var x: float = LABEL_WIDTH + segment * (SEGMENT_SIZE.x + SEGMENT_GAP)
			var rect: Rect2 = Rect2(Vector2(x, y), SEGMENT_SIZE)
			if segment < values[row]:
				draw_rect(rect, PALETTE.potential if segment >= COMMON_MAXIMUM else PALETTE.accent)
			elif segment < COMMON_MAXIMUM:
				draw_rect(rect, PALETTE.bar_back)
