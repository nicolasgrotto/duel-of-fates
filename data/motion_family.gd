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

@export_group("Grip")
@export var back_hand_spacing: float = 5.5
@export var free_hand: Vector2 = Vector2(-4.0, -30.0)
@export var off_guard_hand: Vector2 = Vector2(-6.0, -34.0)
@export var off_guard_angle: float = 150.0

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
@export var windup_shift: float = 5.0
@export var lunge: float = 7.0
@export var arc_bulge: float = 0.4
@export var windup_lean: float = -7.0
@export_range(0.4, 3.0) var wrist_lag: float = 1.0
@export_range(0.1, 0.8) var recover_share: float = 0.35
@export var one_hand_follow: bool = false
@export var dash_cut: MoveData.Cut = MoveData.Cut.RISING
@export var dash_twirl: bool = false
@export var plunge_cut: MoveData.Cut = MoveData.Cut.THRUST
@export var plunge_pirouette: bool = false

@export_group("Air and dodges")
@export var flip_on_double_jump: bool = true
@export var double_jump_turns: float = 1.0
@export var double_jump_time: float = 0.42
@export var double_jump_corkscrew: bool = false
@export var air_twirl: bool = false
@export var roll_on_dodge: bool = false
@export var vault_time: float = 0.42
@export var acrobatic_recovery: bool = false
@export var tumble_time: float = 0.45

@export_group("Blade lock")
@export var lock_lean: float = 18.0
@export var lock_crouch: float = 10.0
