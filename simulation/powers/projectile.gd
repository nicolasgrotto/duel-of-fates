class_name Projectile
extends RefCounted

enum Kind { ROCK, CLEAVE, BLADE, ARSENAL, SINGULARITY, BOLT }

var active: bool = false
var kind: Kind = Kind.ROCK
var owner: int = 0
var x: float = 0.0
var y: float = 0.0
var vx: float = 0.0
var vy: float = 0.0
var damage: float = 0.0
var size: float = 12.0
var travelled: float = 0.0
var max_distance: float = 700.0
var returning: bool = false
var hit_done: bool = false
var flow_level: int = 4
var tier: int = 1
var delay_ticks: int = 0
var power: PowerData
var move: MoveData
var bolt: BoltData
var shooter: int = 0


func capture() -> Dictionary:
	return {
		"active": active, "kind": kind, "owner": owner, "x": x, "y": y, "vx": vx, "vy": vy, "damage": damage, "size": size,
		"travelled": travelled, "max_distance": max_distance, "returning": returning, "hit_done": hit_done,
		"flow_level": flow_level, "tier": tier, "delay_ticks": delay_ticks, "power": power, "move": move, "bolt": bolt, "shooter": shooter,
	}


func restore(snapshot: Dictionary) -> void:
	for key in snapshot:
		set(key, snapshot[key])
