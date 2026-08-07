extends "res://scripts/tests/test_base.gd"

# BattleTrace 测试基类：提供结构化事件断言辅助，不依赖 UI 文案。

# 断言事件的 kind 序列与预期一致。
func assert_event_kinds(events: Array, expected: Array, message: String) -> void:
	var actual: Array[String] = []
	for event in events:
		actual.append(String(event.get("kind", "")))
	assert_equal(actual, expected, message)


# 断言事件的 timing 序列与预期一致。
func assert_event_timings(events: Array, expected: Array, message: String) -> void:
	var actual: Array[String] = []
	for event in events:
		actual.append(String(event.get("timing", "")))
	assert_equal(actual, expected, message)


# 断言指定索引事件某字段的值。
func assert_event_field(events: Array, index: int, field: String, expected, message: String) -> void:
	if index < 0 or index >= events.size():
		assert_true(false, "%s: index %d out of range" % [message, index])
		return
	var event: Dictionary = events[index]
	assert_equal(event.get(field, ""), expected, "%s: field %s" % [message, field])


# 断言事件链为父子嵌套关系：child 的 parent_seq 指向 parent 的 seq，depth 递增。
func assert_event_parented(events: Array, child_index: int, parent_seq: int, message: String) -> void:
	if child_index < 0 or child_index >= events.size():
		assert_true(false, "%s: child index %d out of range" % [message, child_index])
		return
	var event: Dictionary = events[child_index]
	assert_equal(int(event.get("parent_seq", -1)), parent_seq, "%s: parent_seq" % message)
