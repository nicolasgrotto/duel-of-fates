class_name SpaceAudio
extends Node

const ENGINE: AudioStream = preload("res://assets/audio/space/engine.wav")
const MISSILE: AudioStream = preload("res://assets/audio/space/missile.wav")
const SOUNDS: Dictionary = {
	SpaceEvent.Type.BOOST_STARTED: preload("res://assets/audio/space/boost.wav"),
	SpaceEvent.Type.WEAPON_PRIMED: preload("res://assets/audio/space/charge.wav"),
	SpaceEvent.Type.SHOT_FIRED: preload("res://assets/audio/space/shot.wav"),
	SpaceEvent.Type.SHIELD_HIT: preload("res://assets/audio/space/shield.wav"),
	SpaceEvent.Type.HULL_HIT: preload("res://assets/audio/space/hull.wav"),
	SpaceEvent.Type.SHIP_DESTROYED: preload("res://assets/audio/space/explosion.wav"),
	SpaceEvent.Type.MISSILE_DESTROYED: preload("res://assets/audio/space/hull.wav"),
}

var _engine: AudioStreamPlayer
var _voices: Array[AudioStreamPlayer2D] = []
var _next: int = 0
var _config: SpaceConfig


func setup(config: SpaceConfig) -> void:
	_config = config
	_engine = AudioStreamPlayer.new()
	var stream: AudioStreamWAV = ENGINE.duplicate() as AudioStreamWAV
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = roundi(stream.get_length() * stream.mix_rate)
	_engine.stream = stream
	_engine.bus = &"Ambience"
	_engine.volume_db = config.engine_db
	add_child(_engine)
	_engine.play()
	for index in config.audio_voices:
		var voice: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
		voice.bus = &"Effects"
		voice.max_distance = 5000.0
		voice.attenuation = 0.35
		voice.volume_db = config.effects_db
		add_child(voice)
		_voices.append(voice)


func on_event(event: SpaceEvent) -> void:
	if not SOUNDS.has(event.type) or _voices.is_empty():
		return
	var voice: AudioStreamPlayer2D = _voices[_next]
	voice.stream = MISSILE if event.type == SpaceEvent.Type.SHOT_FIRED and event.amount == float(SpaceWeaponData.Kind.MISSILE) else SOUNDS[event.type]
	voice.global_position = event.position
	voice.pitch_scale = 0.92 if event.source > 0 and event.type == SpaceEvent.Type.SHOT_FIRED else 1.0
	voice.play()
	_next = (_next + 1) % _voices.size()


func update(ship: SpaceShipState) -> void:
	_engine.volume_db = _config.engine_db + (3.0 if ship.boost_tick >= 0 else 0.0 if absf(ship.thrust) > 0.01 else -12.0)
	_engine.pitch_scale = 1.15 if ship.boost_tick >= 0 else 0.9 + absf(ship.thrust) * 0.1


func set_paused(paused: bool) -> void:
	_engine.stream_paused = paused
	if paused:
		for voice in _voices:
			voice.stop()


func _exit_tree() -> void:
	if is_instance_valid(_engine):
		_engine.stop()
	for voice in _voices:
		voice.stop()
