class_name InfiltrationActor
extends RefCounted

enum Locomotion { WALK, RUN, SNEAK }
enum Awareness { UNAWARE, SUSPICIOUS, ALERTED }
enum Decision { PATROL, INVESTIGATE, FIGHT, ALARM }

var awareness: Awareness = Awareness.UNAWARE
var decision: Decision = Decision.PATROL
var suspicion: float = 0.0
var last_known: Vector2 = Vector2.ZERO
var memory_ticks: int = 0
var visible_player: bool = false
var waypoint: int = 0
var spawned: bool = true

var position: Vector2
var previous: Vector2
var velocity: Vector2 = Vector2.ZERO
var aim: Vector2 = Vector2.RIGHT
var health: float = 100.0
var vigor: float = 100.0
var guard: bool = false
var parry_age: int = -1
var parry_cooldown: int = 0
var swing_tick: int = -1
var swing_id: int = 0
var swing_aim: Vector2 = Vector2.RIGHT
var last_swing_id: int = -1
var stun_ticks: int = 0
var regeneration_ticks: int = 0
var fire_ticks: int = 0
var burst_left: int = 0
var burst_ticks: int = 0
var respawn_ticks: int = 0
var walked: float = 0.0
var locomotion: Locomotion = Locomotion.WALK


func capture() -> Dictionary:
	var state: Dictionary = {}
	for property in get_property_list():
		if (property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0:
			state[property.name] = get(property.name)
	return state


func restore(state: Dictionary) -> void:
	for key in state:
		set(key, state[key])
