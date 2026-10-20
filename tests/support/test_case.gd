class_name TestCase
extends RefCounted

var failures: PackedStringArray = []
var current_test: String = ""


func before_each() -> void:
	pass


func assert_true(condition: bool, message: String = "") -> void:
	if not condition:
		_fail("expected true. %s" % message)


func assert_false(condition: bool, message: String = "") -> void:
	if condition:
		_fail("expected false. %s" % message)


func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if typeof(actual) != typeof(expected) or actual != expected:
		_fail("expected %s, got %s. %s" % [str(expected), str(actual), message])


func assert_ne(actual: Variant, unexpected: Variant, message: String = "") -> void:
	if typeof(actual) == typeof(unexpected) and actual == unexpected:
		_fail("did not expect %s. %s" % [str(unexpected), message])


func assert_almost(actual: float, expected: float, tolerance: float = 0.001, message: String = "") -> void:
	if absf(actual - expected) > tolerance:
		_fail("expected %f ± %f, got %f. %s" % [expected, tolerance, actual, message])


func assert_gt(actual: float, limit: float, message: String = "") -> void:
	if not actual > limit:
		_fail("expected > %f, got %f. %s" % [limit, actual, message])


func assert_lt(actual: float, limit: float, message: String = "") -> void:
	if not actual < limit:
		_fail("expected < %f, got %f. %s" % [limit, actual, message])


func _fail(text: String) -> void:
	failures.append("%s: %s" % [current_test, text])
