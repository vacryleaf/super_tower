extends RefCounted

var failures: Array[String] = []


func assert_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)


func assert_equal(actual, expected, message: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [message, str(expected), str(actual)])


func assert_catalog_value_equal(actual, expected, message: String) -> void:
	if typeof(actual) == TYPE_FLOAT or typeof(expected) == TYPE_FLOAT:
		if absf(float(actual) - float(expected)) > 0.001:
			failures.append("%s: expected %s, got %s" % [message, str(expected), str(actual)])
		return
	assert_equal(actual, expected, message)