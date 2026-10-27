class_name InfiltrationNavigation
extends RefCounted

const NEIGHBORS: Array[Vector2i] = [Vector2i.LEFT, Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN]

var _map: InfiltrationMapData
var _queue: PackedInt32Array = []
var _parents: PackedInt32Array = []


func _init(map: InfiltrationMapData) -> void:
	_map = map
	_queue.resize(map.width() * map.rows.size())
	_parents.resize(_queue.size())


func direction(start: Vector2, destination: Vector2, radius: float) -> Vector2:
	if InfiltrationGeometry.wall_fraction(_map, start, destination, radius) == INF:
		return (destination - start).normalized()
	var width: int = _map.width()
	var first: Vector2i = Vector2i((start / _map.tile_size).floor())
	var last: Vector2i = Vector2i((destination / _map.tile_size).floor())
	if _map.is_solid(last.x, last.y):
		return Vector2.ZERO
	var begin: int = first.y * width + first.x
	var goal: int = last.y * width + last.x
	_parents.fill(-1)
	_parents[begin] = begin
	_queue[0] = begin
	var read: int = 0
	var written: int = 1
	while read < written and _parents[goal] < 0:
		var current: int = _queue[read]
		read += 1
		var cell: Vector2i = Vector2i(current % width, current / width)
		for offset in NEIGHBORS:
			var next: Vector2i = cell + offset
			if _map.is_solid(next.x, next.y):
				continue
			var index: int = next.y * width + next.x
			if _parents[index] >= 0:
				continue
			_parents[index] = current
			_queue[written] = index
			written += 1
	if _parents[goal] < 0:
		return Vector2.ZERO
	var step: int = goal
	while step != begin and _parents[step] != begin:
		step = _parents[step]
	var center: Vector2 = (Vector2(step % width, step / width) + Vector2.ONE * 0.5) * _map.tile_size
	if InfiltrationGeometry.wall_fraction(_map, start, center, radius) != INF:
		center = (Vector2(first) + Vector2.ONE * 0.5) * _map.tile_size
	return (center - start).normalized()
