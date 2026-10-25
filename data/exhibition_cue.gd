class_name ExhibitionCue
extends Resource

@export var at: int = 0
@export var fighter: int = 0
@export_flags("Jump", "Light", "Heavy", "Block", "Dodge", "Evade", "Special", "Power") var command: int = 0
@export var move: int = 0
@export var hold: int = 1
