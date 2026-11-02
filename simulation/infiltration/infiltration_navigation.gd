class_name InfiltrationNavigation
extends RefCounted

const CACHED_GOALS: int = 8
const NONE: int = -1

var _map: InfiltrationMapData
var _width: int = 0
var _passable: PackedByteArray = []
var _goals: PackedInt32Array = []
var _steps: Array[PackedInt32Array] = []
var _queues: Array[PackedInt32Array] = []
var _reads: PackedInt32Array = []
var _writes: PackedInt32Array = []
var _next_slot: int = 0


func _init(map: InfiltrationMapData) -> void:
	_map = map
	_width = map.width()
	var cells: int = _width * map.rows.size()
	_passable.resize(cells)
	for y in map.rows.size():
		for x in _width:
			_passable[y * _width + x] = 0 if map.is_solid(x, y) else 1
	_goals.resize(CACHED_GOALS)
	_goals.fill(NONE)
	_reads.resize(CACHED_GOALS)
	_writes.resize(CACHED_GOALS)
	for slot in CACHED_GOALS:
		var steps: PackedInt32Array = []
		steps.resize(cells)
		_steps.append(steps)
		var queue: PackedInt32Array = []
		queue.resize(cells)
		_queues.append(queue)


func direction(start: Vector2, destination: Vector2, radius: float) -> Vector2:
	if InfiltrationGeometry.wall_fraction(_map, start, destination, radius) == INF:
		return (destination - start).normalized()
	var first: Vector2i = Vector2i((start / _map.tile_size).floor())
	var last: Vector2i = Vector2i((destination / _map.tile_size).floor())
	if _map.is_solid(last.x, last.y) or _map.is_solid(first.x, first.y):
		return Vector2.ZERO
	var begin: int = first.y * _width + first.x
	var step: int = _step_from(begin, last.y * _width + last.x)
	if step == NONE:
		return Vector2.ZERO
	var center: Vector2 = (Vector2(step % _width, step / _width) + Vector2.ONE * 0.5) * _map.tile_size
	if InfiltrationGeometry.wall_fraction(_map, start, center, radius) != INF:
		center = (Vector2(first) + Vector2.ONE * 0.5) * _map.tile_size
	return (center - start).normalized()


func path_tiles(start: Vector2, destination: Vector2) -> int:
	var first: Vector2i = Vector2i((start / _map.tile_size).floor())
	var last: Vector2i = Vector2i((destination / _map.tile_size).floor())
	if _map.is_solid(last.x, last.y) or _map.is_solid(first.x, first.y):
		return NONE
	var cell: int = first.y * _width + first.x
	var goal: int = last.y * _width + last.x
	if _step_from(cell, goal) == NONE:
		return NONE
	var steps: PackedInt32Array = _steps[_slot_for(goal)]
	var tiles: int = 0
	while cell != goal:
		cell = steps[cell]
		tiles += 1
	return tiles


func _step_from(begin: int, goal: int) -> int:
	var slot: int = _slot_for(goal)
	var steps: PackedInt32Array = _steps[slot]
	if steps[begin] != NONE:
		return steps[begin]
	var queue: PackedInt32Array = _queues[slot]
	var read: int = _reads[slot]
	var written: int = _writes[slot]
	while read < written and steps[begin] == NONE:
		var current: int = queue[read]
		read += 1
		var left: int = current - 1 if current % _width > 0 else NONE
		var right: int = current + 1 if current % _width < _width - 1 else NONE
		written = _visit(steps, queue, left, current, written)
		written = _visit(steps, queue, current - _width, current, written)
		written = _visit(steps, queue, right, current, written)
		written = _visit(steps, queue, current + _width, current, written)
	_reads[slot] = read
	_writes[slot] = written
	return steps[begin]


func _visit(steps: PackedInt32Array, queue: PackedInt32Array, cell: int, parent: int, written: int) -> int:
	if cell < 0 or cell >= steps.size() or _passable[cell] == 0 or steps[cell] != NONE:
		return written
	steps[cell] = parent
	queue[written] = cell
	return written + 1


func _slot_for(goal: int) -> int:
	var slot: int = _goals.find(goal)
	if slot >= 0:
		return slot
	slot = _next_slot
	_next_slot = (_next_slot + 1) % CACHED_GOALS
	_goals[slot] = goal
	_steps[slot].fill(NONE)
	_steps[slot][goal] = goal
	_queues[slot][0] = goal
	_reads[slot] = 0
	_writes[slot] = 1
	return slot
