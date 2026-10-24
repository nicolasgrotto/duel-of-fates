class_name CampaignData
extends Resource

@export var common: Array[EncounterData] = []
@export var aurora: Array[EncounterData] = []
@export var eclipse: Array[EncounterData] = []
@export var aurora_secret: EncounterData
@export var eclipse_secret: EncounterData
@export var aurora_normal_ending: EndingData
@export var aurora_secret_ending: EndingData
@export var eclipse_normal_ending: EndingData
@export var eclipse_secret_ending: EndingData
@export var names: PackedStringArray = ["Kael", "Iria", "Tarin", "Vessa", "Oren", "Lyse"]
@export var styles: Array[StringName] = [&"guardian", &"shadow", &"heron"]
@export var style_keys: PackedStringArray = ["STYLE_TECHNIQUE", "STYLE_FURY", "STYLE_FLIGHT"]
@export var look_keys: PackedStringArray = ["LOOK_WANDERER", "LOOK_WATCHER", "LOOK_PILGRIM"]
@export var blade_sources: Array[StringName] = [&"guardian", &"shadow", &"bastion", &"wasp", &"mirror", &"lance", &"ember", &"forge", &"heron", &"reaper"]
@export var aurora_powers: Array[StringName] = [&"repulse", &"barrier", &"throw", &"heal", &"absorption", &"focus", &"pull"]
@export var eclipse_powers: Array[StringName] = [&"lightning", &"pull", &"choke", &"freeze", &"wrath", &"drain", &"repulse"]
@export var start_attribute: int = 3
@export var start_points: int = 3
@export var max_attribute: int = 7
@export var points_per_win: PackedInt32Array = [3, 2, 1]
@export var milestone_points: Array[PackedInt32Array] = [PackedInt32Array([3, 3]), PackedInt32Array([3, 2]), PackedInt32Array([2, 2])]
@export var secret_health_ratio: float = 0.75
