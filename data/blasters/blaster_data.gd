class_name BlasterData
extends Resource

enum Carry { HIP_HOLSTER, THIGH_HOLSTER, BACK, LOWER_BACK }
enum SizeClass { PISTOL, CARBINE, LONG }

@export var id: StringName
@export var name_key: String
@export var description_key: String
@export var price: int = 0
@export var shot_count: int = 0
@export var shot_interval: float = 0.0
@export var vigor_multiplier: float = 1.0
@export var bolt: BoltData
@export var draw_time: float = 0.15
@export var holster_time: float = 0.15
@export var carry: Carry = Carry.HIP_HOLSTER
@export var carry_anchor: Vector2 = Vector2(10.0, 5.0)
@export var carry_angle: float = 80.0
@export var size_class: SizeClass = SizeClass.PISTOL
@export var guard_cost_multiplier: float = 1.25
@export var muzzle: Vector2 = Vector2(18.0, -4.0)
@export var art_part: StringName
@export var texture: Texture2D
@export var normal: Texture2D
@export var pivot: Vector2
@export var support_texture: Texture2D
@export var support_normal: Texture2D
@export var support_pivot: Vector2
@export var shot_sound: StringName = &"bolt_shot"
@export var hit_sound: StringName = &"bolt_hit"
@export var block_sound: StringName = &"bolt_deflect"
@export var reflect_sound: StringName = &"bolt_reflect"


func draw_ticks() -> int:
	return maxi(Ticks.from_seconds(draw_time), 1)


func holster_ticks() -> int:
	return maxi(Ticks.from_seconds(holster_time), 1)


func two_handed() -> bool:
	return size_class == SizeClass.LONG


func reach_anchor() -> Vector2:
	match carry:
		Carry.BACK:
			return carry_anchor + Vector2(0.0, -8.0)
		Carry.LOWER_BACK:
			return carry_anchor + Vector2(-4.0, 0.0)
		_:
			return carry_anchor
