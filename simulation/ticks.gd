class_name Ticks

const RATE: int = 60
const DELTA: float = 1.0 / 60.0


static func from_seconds(seconds: float) -> int:
	return roundi(seconds * RATE)


static func to_seconds(ticks: int) -> float:
	return float(ticks) / RATE
