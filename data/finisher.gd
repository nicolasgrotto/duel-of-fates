class_name Finisher

enum Kind { NONE, DASH_THROUGH, WAIST, VERTICAL, DIAGONAL, PULL_CUT, CHARRED, BLAST, CHOKED, EXECUTION, SCISSORS, STAB, TWIN_BLADES, OVERHEAD, DOUBLE_ROTATION, WHIRL }

const STAGED: Array[Kind] = [Kind.EXECUTION, Kind.SCISSORS, Kind.STAB, Kind.TWIN_BLADES, Kind.OVERHEAD, Kind.DOUBLE_ROTATION, Kind.WHIRL]


static func is_staged(kind: Kind) -> bool:
	return STAGED.has(kind)


static func is_long(kind: Kind) -> bool:
	return kind == Kind.TWIN_BLADES
