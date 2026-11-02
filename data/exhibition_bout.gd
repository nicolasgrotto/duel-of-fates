class_name ExhibitionBout
extends Resource

@export var id: StringName
@export var title_key: String
@export var characters: Array[CharacterData] = []
@export var costumes: PackedInt32Array = PackedInt32Array([0, 0])
@export var arena: ArenaData
@export var powers_left: Array[PowerData] = []
@export var powers_right: Array[PowerData] = []
@export var start_health: PackedFloat32Array = PackedFloat32Array([1.0, 1.0])
@export var flow_levels: PackedInt32Array = PackedInt32Array([0, 0])
@export var match_seed: int = 1
@export var fighter_intros: bool = true
@export var card_fade: float = 0.5
@export var card_hold: float = 2.4
@export var cues: Array[ExhibitionCue] = []
