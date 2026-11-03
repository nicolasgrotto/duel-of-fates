class_name BlasterOpsMap
extends InfiltrationMapData

var source: InfiltrationMapData
var covers: Array[BlasterOpsCover] = []
var _cells: PackedInt32Array = []


func _init(data: InfiltrationMapData) -> void:
	source = data
	for property in data.get_property_list():
		if (property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0 and property.name not in [&"covers", &"cover_atlas", &"enemies_alerted"]:
			set(property.name, data.get(property.name))
	_cells.resize(width() * rows.size())
	_cells.fill(-1)
	var arena: BlasterOpsArenaData = data as BlasterOpsArenaData
	if arena == null:
		return
	for definition in arena.covers:
		_cells[definition.cell.y * width() + definition.cell.x] = covers.size()
		covers.append(BlasterOpsCover.new(definition))


func cover_at(x: int, y: int) -> int:
	if x < 0 or y < 0 or x >= width() or y >= rows.size():
		return -1
	return _cells[y * width() + x]


func is_solid(x: int, y: int) -> bool:
	var index: int = cover_at(x, y)
	return covers[index].health > 0.0 if index >= 0 else source.is_solid(x, y)


func tile_index(x: int, y: int) -> int:
	var index: int = cover_at(x, y)
	return 0 if index >= 0 else source.tile_index(x, y)
