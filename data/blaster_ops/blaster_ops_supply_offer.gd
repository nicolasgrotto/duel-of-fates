class_name BlasterOpsSupplyOffer
extends Resource

enum Kind { HEAL, BARRIER, BULWARK, COOLANT, COMBAT_TUNE, REINFORCEMENT, ALLY_UPGRADE }

@export var id: StringName
@export var name_key: String
@export var description_key: String
@export var kind: Kind = Kind.HEAL
@export var cost: int = 1
@export var amount: float = 0.0
@export var limit: int = 0
