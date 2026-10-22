class_name UiPalette
extends Resource

@export_group("Interface")
@export var background: Color = Color("#05070d")
@export var text: Color = Color("#e8ecf5")
@export var secondary: Color = Color("#8a94ab")
@export var accent: Color = Color("#9fb4d9")
@export var danger: Color = Color("#e5484d")
@export var aurora: Color = Color("#5aa2ff")
@export var eclipse: Color = Color("#ff4458")
@export var potential: Color = Color("#d9b45a")
@export var flow_tiers: PackedColorArray = PackedColorArray([Color("#9cc4ff"), Color("#5d8dff"), Color("#b26bff"), Color("#ff2b45")])

@export_group("Duel HUD")
@export var bar_back: Color = Color(0.91, 0.925, 0.96, 0.1)
@export var health_ghost: Color = Color(0.91, 0.925, 0.96, 0.35)
@export var exhausted: Color = Color("#7a2a2e")
@export var letterbox: Color = Color("#000000")

@export_group("Effects")
@export var spark_hot: Color = Color("#ffffff")
@export var spark_warm: Color = Color("#fff1b8")
@export var hit_flash: Color = Color("#ffffff")
@export var ember: Color = Color("#ff7a2a")
