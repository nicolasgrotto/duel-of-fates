class_name RoundMarks
extends Control

const MARK_SIZE: float = 12.0
const MARK_GAP: float = 8.0
const OUTLINE_WIDTH: float = 1.5

var total: int = 2
var won: int = 0
var color: Color = Color.WHITE
var anchored_right: bool = false


func _draw() -> void:
	for i in total:
		var offset: float = i * (MARK_SIZE + MARK_GAP)
		var left: float = size.x - MARK_SIZE - offset if anchored_right else offset
		var mark: Rect2 = Rect2(left, 0.0, MARK_SIZE, MARK_SIZE)
		if i < won:
			draw_rect(mark, color)
		else:
			draw_rect(mark, color, false, OUTLINE_WIDTH)
