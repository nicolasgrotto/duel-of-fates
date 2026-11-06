class_name BlasterOpsLoadout
extends Resource

@export var blaster: BlasterData
@export var power: BlasterOpsPowerData
@export var extra_powers: Array[BlasterOpsPowerData] = []
@export var damage_scale: float = 2.5
@export var fire_interval: float = 0.16
@export var heat_per_shot: float = 20.0
@export var can_deflect: bool = true


func slot_count() -> int:
	return (1 if power != null else 0) + extra_powers.size()


func slot(index: int) -> BlasterOpsPowerData:
	if index == 0:
		return power
	return extra_powers[index - 1] if index - 1 < extra_powers.size() else null
