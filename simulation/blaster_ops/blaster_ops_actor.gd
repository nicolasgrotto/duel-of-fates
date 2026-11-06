class_name BlasterOpsActor
extends InfiltrationActor

var telegraph_ticks: int = -1
var target_cover: int = -1
var telegraph_aim: Vector2 = Vector2.RIGHT
var impulse: Vector2 = Vector2.ZERO
var impulse_ticks: int = 0
var power_wait_ticks: int = 0
var casting_power: bool = false
