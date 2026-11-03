class_name BlasterOpsMissionResult
extends RefCounted

var mission_id: StringName
var won: bool = false
var ticks: int = 0
var damage: float = 0.0
var attempts: int = 0
var hits: int = 0
var bonuses: int = 0
var rating: int = 0


func to_dict() -> Dictionary:
	return {"mission_id": String(mission_id), "won": won, "ticks": ticks, "damage": damage, "attempts": attempts, "hits": hits, "bonuses": bonuses, "rating": rating}
