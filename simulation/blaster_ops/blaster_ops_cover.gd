class_name BlasterOpsCover
extends RefCounted

var data: BlasterOpsCoverData
var health: float
var last_swing_id: int = -1


func _init(definition: BlasterOpsCoverData) -> void:
	data = definition
	health = data.health


func damage_stage() -> int:
	if health <= 0.0:
		return 3
	return clampi(floori((1.0 - health / data.health) * 3.0), 0, 2)
