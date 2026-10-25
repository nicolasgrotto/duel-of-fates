class_name FinisherMotion
extends PoseTrack

const NEVER: float = -1.0
const PATH: String = "res://data/finishers/%s.tres"

@export var front_arm_at: float = NEVER
@export var back_arm_at: float = NEVER
@export var drops_hilt: bool = false
@export var kneel_at: float = NEVER
@export var head_at: float = NEVER
@export var split_at: float = NEVER
@export var fall_at: float = 0.0
@export var push_back: float = 0.0
@export var push_time: float = 0.3
@export var hole: bool = false
@export var streak_at: float = NEVER
@export var streaks_both: bool = false
@export var pull_at: float = NEVER
@export var catch_at: float = NEVER
@export var release_at: float = NEVER

static var _cache: Dictionary = {}


static func for_kind(kind: Finisher.Kind) -> FinisherMotion:
	if not _cache.has(kind):
		var path: String = PATH % String(Finisher.Kind.keys()[kind]).to_lower()
		_cache[kind] = load(path) if ResourceLoader.exists(path) else null
	return _cache[kind]


static func fired(at: float, before: float, now: float) -> bool:
	return at >= 0.0 and before < at and now >= at
