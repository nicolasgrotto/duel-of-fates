extends Resource

enum Kind { POWER, STYLE_FORWARD, STYLE_BACK, STYLE_AIR, STYLE_ABILITY, TECHNIQUE, ABILITY }

@export var id: StringName
@export var kind: Kind = Kind.POWER
@export var power: PowerData
@export var technique: MoveData
@export var ability: AbilityData
@export var cost: int = 0
@export var parent: int = -1
@export var branch: int = 0


func node_id() -> StringName:
	return power.id if kind == Kind.POWER and power != null else id


func move_for(character: CharacterData) -> MoveData:
	match kind:
		Kind.STYLE_FORWARD:
			return character.technique_forward
		Kind.STYLE_BACK:
			return character.technique_back
		Kind.STYLE_AIR:
			return character.technique_air
	return technique


func ability_for(character: CharacterData) -> AbilityData:
	return character.ability if kind == Kind.STYLE_ABILITY else ability


func style_slot() -> int:
	return int(kind) - int(Kind.STYLE_FORWARD) if kind in [Kind.STYLE_FORWARD, Kind.STYLE_BACK, Kind.STYLE_AIR] else -1
