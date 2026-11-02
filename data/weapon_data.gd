class_name WeaponData
extends Resource

enum Kind { SINGLE, DUAL, LANCE, STAFF }
enum Hilt { RING, CURVED_POMMEL, WRAPPED, CROSSGUARD, BANDED, DOUBLE, PLAIN }
enum Sidearm { NONE, BLASTER, HILT_EMITTER, HOLSTER }

@export var kind: Kind = Kind.SINGLE
@export var hilt: Hilt = Hilt.RING
@export var blade_length: float = 92.0
@export var blade_width: float = 1.0
@export var hilt_length: float = 12.0
@export var second_blade_length: float = 0.0
@export var hum_pitch: float = 1.0
@export var hum_detune: float = 0.0
@export var sidearm: Sidearm = Sidearm.NONE
@export var blaster: BlasterData


func reach_tip() -> float:
	return hilt_length * 0.5 + blade_length
