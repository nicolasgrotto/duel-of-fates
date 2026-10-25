class_name Finisher

enum Kind { NONE, DASH_THROUGH, WAIST, VERTICAL, DIAGONAL, PULL_CUT, CHARRED, BLAST, CHOKED, EXECUTION, SCISSORS, STAB }


static func is_execution(kind: Kind) -> bool:
	return kind == Kind.EXECUTION or kind == Kind.SCISSORS
