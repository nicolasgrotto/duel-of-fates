class_name IntentRecording
extends RefCounted

var slots: int = 2
var data: PackedInt32Array = []


func _init(slot_count: int = 2) -> void:
	slots = slot_count


func clear() -> void:
	data.clear()


func append_tick(intents: Array[Intent]) -> void:
	for i in slots:
		data.append(intents[i].pack())


func append_relative(intent: Intent, facing: int) -> void:
	data.append(intent.pack_relative(facing))


func length() -> int:
	return data.size() / slots


func packed_at(tick: int, slot: int = 0) -> int:
	return data[tick * slots + slot]
