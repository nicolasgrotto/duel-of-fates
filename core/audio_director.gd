extends Node

const BANK: SoundBank = preload("res://data/audio/sound_bank.tres")
const VOICES: int = 18
const SILENT_DB: float = -60.0
const MUSIC_LAYER_FADE: float = 2.5
const MUFFLED_BUSES: Array[StringName] = [&"Effects", &"Ambience"]
const ATTENUATION: float = 0.35
const MAX_DISTANCE: float = 5000.0

var _voices: Array[AudioStreamPlayer2D] = []
var _next_voice: int = 0
var _ui: AudioStreamPlayer
var _music: AudioStreamPlayer
var _music_stream: AudioStreamSynchronized
var _ambience: AudioStreamPlayer
var _layer_db: PackedFloat32Array = [0.0, SILENT_DB, SILENT_DB]
var _layer_target: PackedFloat32Array = [0.0, SILENT_DB, SILENT_DB]
var _muffle_left: float = 0.0
var _duck_left: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in VOICES:
		var voice: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
		voice.bus = &"Effects"
		voice.attenuation = ATTENUATION
		voice.max_distance = MAX_DISTANCE
		add_child(voice)
		_voices.append(voice)
	_ui = AudioStreamPlayer.new()
	_ui.bus = &"Interface"
	add_child(_ui)
	_music = AudioStreamPlayer.new()
	_music.bus = &"Music"
	add_child(_music)
	_ambience = AudioStreamPlayer.new()
	_ambience.bus = &"Ambience"
	add_child(_ambience)


func _exit_tree() -> void:
	for voice in _voices:
		voice.stop()
		voice.stream = null
	for player in [_ui, _music, _ambience]:
		player.stop()
		player.stream = null


func play(id: StringName, at: Vector2, volume_db: float = 0.0, pitch: float = 1.0, bus: StringName = &"Effects") -> void:
	var stream: AudioStream = BANK.stream(id)
	if stream == null:
		return
	var voice: AudioStreamPlayer2D = _voices[_next_voice]
	_next_voice = (_next_voice + 1) % VOICES
	voice.stream = stream
	voice.global_position = at
	voice.volume_db = volume_db
	voice.pitch_scale = pitch
	voice.bus = bus
	voice.play()


func play_ui(id: StringName) -> void:
	var stream: AudioStream = BANK.stream(id)
	if stream == null:
		return
	_ui.stream = stream
	_ui.play()


func stream(id: StringName) -> AudioStream:
	return BANK.stream(id)


func play_music(music: MusicData) -> void:
	if music == null:
		stop_music()
		return
	_music_stream = AudioStreamSynchronized.new()
	_music_stream.stream_count = 3
	_music_stream.set_sync_stream(0, music.base)
	_music_stream.set_sync_stream(1, music.percussion)
	_music_stream.set_sync_stream(2, music.tension)
	for i in 3:
		_layer_db[i] = 0.0 if i == 0 else SILENT_DB
		_layer_target[i] = _layer_db[i]
		_music_stream.set_sync_stream_volume(i, _layer_db[i])
	_music.stream = _music_stream
	_music.pitch_scale = music.pitch
	_music.play()


func stop_music() -> void:
	_music.stop()
	_music_stream = null


func set_music_intensity(intensity: float) -> void:
	_layer_target[1] = lerpf(SILENT_DB, 0.0, clampf(intensity * 1.6, 0.0, 1.0))
	_layer_target[2] = lerpf(SILENT_DB, -3.0, smoothstep(0.45, 1.0, intensity))


func play_ambience(ambience: AudioStream) -> void:
	if ambience == null:
		_ambience.stop()
		return
	_ambience.stream = ambience
	_ambience.play()


func stop_ambience() -> void:
	_ambience.stop()


func muffle(seconds: float) -> void:
	_muffle_left = maxf(_muffle_left, seconds)


func duck_music(seconds: float) -> void:
	_duck_left = maxf(_duck_left, seconds)


func _process(delta: float) -> void:
	_muffle_left = maxf(_muffle_left - delta, 0.0)
	_duck_left = maxf(_duck_left - delta, 0.0)
	for bus_name in MUFFLED_BUSES:
		AudioServer.set_bus_effect_enabled(AudioServer.get_bus_index(bus_name), 0, _muffle_left > 0.0)
	AudioServer.set_bus_effect_enabled(AudioServer.get_bus_index(&"Music"), 0, _muffle_left > 0.0 or _duck_left > 0.0)
	if _music_stream == null:
		return
	var step: float = absf(SILENT_DB) * delta / MUSIC_LAYER_FADE
	for i in 3:
		_layer_db[i] = move_toward(_layer_db[i], _layer_target[i], step)
		_music_stream.set_sync_stream_volume(i, _layer_db[i] - (8.0 if _duck_left > 0.0 else 0.0))
