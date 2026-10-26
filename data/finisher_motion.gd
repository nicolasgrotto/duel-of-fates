class_name FinisherMotion
extends PoseTrack

const NEVER: float = -1.0
const PATH: String = "res://data/finishers/%s.tres"

@export var travel_from: float = NEVER
@export var travel_to: float = NEVER
@export var pull_at: float = NEVER
@export var catch_at: float = NEVER
@export var release_at: float = NEVER
@export var extinguish_at: float = NEVER
@export var reaction: FinisherReaction
@export var effects: FinisherEffects
@export var cues: Array[FinisherCue] = []

static var _cache: Dictionary = {}


static func for_kind(kind: Finisher.Kind, style: FinisherStyle = null) -> FinisherMotion:
	var key: String = "%d:%d" % [kind, style.get_instance_id() if style != null else 0]
	if not _cache.has(key):
		var path: String = PATH % String(Finisher.Kind.keys()[kind]).to_lower()
		var base: FinisherMotion = load(path) if ResourceLoader.exists(path) else null
		_cache[key] = base.styled(style) if base != null and style != null else base
	return _cache[key]


static func fired(at: float, before: float, now: float) -> bool:
	return at >= 0.0 and before < at and now >= at


static func scaled(at: float, tempo: float) -> float:
	return at * tempo if at >= 0.0 else at


func travels() -> bool:
	return travel_from >= 0.0 and travel_to > travel_from


func styled(style: FinisherStyle) -> FinisherMotion:
	var copy: FinisherMotion = duplicate()
	var styled_keys: Array[PoseKey] = []
	for key in keys:
		styled_keys.append(_styled_key(key, style))
	copy.keys = styled_keys
	copy.blend_time = blend_time * style.tempo
	copy.travel_from = scaled(travel_from, style.tempo)
	copy.travel_to = scaled(travel_to, style.tempo)
	copy.pull_at = scaled(pull_at, style.tempo)
	copy.catch_at = scaled(catch_at, style.tempo)
	copy.release_at = scaled(release_at, style.tempo)
	copy.extinguish_at = scaled(extinguish_at, style.tempo)
	copy.reaction = reaction.duplicate()
	copy.reaction.scale_times(style.tempo)
	copy.effects = effects.duplicate()
	copy.effects.streaks = effects.streaks.duplicate()
	copy.effects.shots = effects.shots.duplicate()
	copy.effects.scale_times(style.tempo)
	var styled_cues: Array[FinisherCue] = []
	for cue in cues:
		var timed: FinisherCue = cue.duplicate()
		timed.time *= style.tempo
		styled_cues.append(timed)
	copy.cues = styled_cues
	return copy


static func _styled_key(key: PoseKey, style: FinisherStyle) -> PoseKey:
	var copy: PoseKey = key.duplicate()
	copy.time *= style.tempo
	copy.grip *= style.reach
	copy.off_hand *= style.reach
	copy.lean += style.lean
	copy.crouch += style.crouch
	copy.step *= style.step_scale
	if key.accent:
		copy.twirl += style.accent_twirl
		copy.off_twirl += style.accent_off_twirl
		copy.turn += style.accent_turn
	return copy
