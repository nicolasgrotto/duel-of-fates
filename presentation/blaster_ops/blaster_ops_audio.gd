class_name BlasterOpsAudio
extends Node2D

const WARNING: AudioStream = preload("res://assets/audio/infiltration/suspicion.wav")
const MUSIC: MusicData = preload("res://data/audio/duel_music.tres")
const SOUNDS: Dictionary = {
	InfiltrationEvent.Type.SHOT_FIRED: &"bolt_shot", InfiltrationEvent.Type.BOLT_HIT: &"bolt_hit",
	InfiltrationEvent.Type.BOLT_BLOCKED: &"bolt_deflect", InfiltrationEvent.Type.BOLT_REFLECTED: &"bolt_reflect",
	InfiltrationEvent.Type.FOOTSTEP: &"step", InfiltrationEvent.Type.OVERHEATED: &"rejected",
	InfiltrationEvent.Type.DODGED: &"dodge", InfiltrationEvent.Type.PRECISION_DODGED: &"evade",
	InfiltrationEvent.Type.COVER_HIT: &"hit_light", InfiltrationEvent.Type.COVER_DESTROYED: &"hit_heavy",
	InfiltrationEvent.Type.POWER_PREPARED: &"power_cast",
}
const POWER_SOUNDS: Dictionary = {
	PowerData.Kind.REPULSE: &"power_repulse", PowerData.Kind.PULL: &"power_pull", PowerData.Kind.BARRIER: &"power_barrier_absorb",
	PowerData.Kind.THROW: &"power_rock_lift", PowerData.Kind.HEAL: &"power_heal", PowerData.Kind.ABSORPTION: &"power_absorption",
	PowerData.Kind.LIGHTNING: &"power_lightning_snap", PowerData.Kind.CHOKE: &"power_choke", PowerData.Kind.FREEZE: &"power_freeze",
	PowerData.Kind.WRATH: &"power_wrath", PowerData.Kind.STORM: &"power_thunder",
}
const VOICES: int = 12

var _config: BlasterOpsConfig
var _voices: Array[AudioStreamPlayer2D] = []
var _music: AudioStreamPlayer
var _next: int = 0


func setup(configuration: BlasterOpsConfig) -> void:
	_config = configuration
	for index in VOICES:
		var voice: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
		voice.bus = &"Effects"
		voice.max_distance = 3000.0
		add_child(voice)
		_voices.append(voice)
	_music = AudioStreamPlayer.new()
	_music.stream = MUSIC.base
	_music.bus = &"Music"
	_music.volume_db = _config.music_db
	add_child(_music)
	_music.play()


func on_event(event: InfiltrationEvent, sim: BlasterOpsSimulation) -> void:
	var stream: AudioStream
	var volume: float = _config.effects_db
	var pitch: float = 1.0
	if event.type == InfiltrationEvent.Type.ATTACK_PREPARED:
		stream = WARNING
		volume = _config.warning_db
	elif event.type == InfiltrationEvent.Type.POWER_RELEASED:
		stream = AudioDirector.stream(&"power_repulse" if int(event.amount) == PowerData.Kind.REPULSE else (&"power_pull" if int(event.amount) == PowerData.Kind.PULL else &"power_barrier_absorb"))
	elif SOUNDS.has(event.type):
		stream = AudioDirector.stream(SOUNDS[event.type])
		if event.type == InfiltrationEvent.Type.SHOT_FIRED and event.source == 0:
			pitch = sim.loadout.blaster.bolt.pitch
		if event.type == InfiltrationEvent.Type.FOOTSTEP:
			volume = _config.footstep_db
	if stream == null:
		return
	var voice: AudioStreamPlayer2D = _voices[_next]
	_next = (_next + 1) % _voices.size()
	voice.position = event.position
	voice.stream = stream
	voice.volume_db = volume
	voice.pitch_scale = pitch
	voice.play()


func set_paused(value: bool) -> void:
	for voice in _voices:
		voice.stream_paused = value
	_music.stream_paused = value
