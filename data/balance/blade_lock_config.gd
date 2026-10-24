class_name BladeLockConfig
extends Resource

const DISENGAGE_MOVE: MoveData = preload("res://data/characters/common/disengage.tres")

@export var entry_gap: float = 70.0
@export var cooldown: float = 4.0
@export var presses_to_win: int = 5
@export var max_presses_per_second: float = 15.0
@export var hold_presses_per_second: float = 6.0
@export var max_duration: float = 3.0
@export var center_distance: float = 84.0
@export var loser_damage: float = 8.0
@export var loser_vigor_loss: float = 35.0
@export var loser_stagger: float = 0.35
@export var winner_recovery: float = 0.25
@export var separation: float = 420.0
@export var hitstop_start: float = 0.06
@export var hitstop_end: float = 0.06

@export_group("Disengage")
@export var disengage_after: float = 0.5
@export var disengage_separation: float = 60.0
@export var disengage_release: float = 0.08

@export_group("Blade press")
@export var press_contacts: int = 3
@export var press_contact_window: float = 0.6
@export var press_entry_gap: float = 90.0
@export var press_parry_advantage: int = 1
@export var press_presses_to_win: int = 3
@export var press_max_duration: float = 1.5
@export var press_center_distance: float = 70.0
@export var press_loser_damage: float = 4.0
@export var press_loser_vigor_loss: float = 20.0
@export var press_loser_stagger: float = 0.3
@export var press_separation: float = 300.0


func press_interval_ticks() -> int:
	return ceili(Ticks.RATE / max_presses_per_second)


func hold_interval_ticks() -> int:
	return ceili(Ticks.RATE / hold_presses_per_second)
