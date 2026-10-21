class_name MotionFamily
extends Resource

enum Grip { TWO_HANDED, ONE_HANDED, DUAL, STAFF }

@export var id: StringName
@export var grip: Grip = Grip.TWO_HANDED

@export_group("Stance")
@export var stance_width: float = 30.0
@export var crouch: float = 6.0
@export var lean: float = 4.0
@export var breath: float = 1.4
@export var sway: float = 1.5

@export_group("Walk")
@export var stride: float = 10.0
@export var bob: float = 2.0

@export_group("Strikes")
@export var windup_pull: float = 1.0
@export var strike_reach: float = 1.0
@export var strike_lean: float = 14.0
@export var follow_through: float = 10.0
@export var heavy_crouch: float = 8.0
@export var heavy_step: float = 10.0
@export var finisher_twirl: bool = false

@export_group("Air and dodges")
@export var flip_on_double_jump: bool = false
@export var roll_on_dodge: bool = false

@export_group("Blade lock")
@export var lock_lean: float = 18.0
@export var lock_crouch: float = 10.0
