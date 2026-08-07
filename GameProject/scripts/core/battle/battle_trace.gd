extends RefCounted
class_name BattleTrace

# BattleTrace 是纯事件记录器，用于诊断模块执行顺序与嵌套链路。
# 约束：不得改变业务状态、不得作为业务判断依据；关闭时所有记录为 no-op。

var enabled := true
var events: Array[Dictionary] = []
var _next_seq := 1
var _span_stack: Array[Dictionary] = []


func reset() -> void:
	events.clear()
	_next_seq = 1
	_span_stack.clear()


func is_enabled() -> bool:
	return enabled


func set_enabled(value: bool) -> void:
	enabled = value


func count() -> int:
	return events.size()


# 记录一条事件，返回其 seq；关闭或记录失败时返回 -1。
func record(kind: String, timing: String, payload: Dictionary = {}) -> int:
	if not enabled:
		return -1
	var parent_seq := 0
	var depth := 0
	if not _span_stack.is_empty():
		var top: Variant = _span_stack.back()
		if top is Dictionary:
			parent_seq = int((top as Dictionary)["seq"])
			depth = _span_stack.size()
	var event := {
		"seq": _next_seq,
		"kind": kind,
		"timing": timing,
		"context_id": String(payload.get("context_id", "")),
		"actor": String(payload.get("actor", "")),
		"target": String(payload.get("target", "")),
		"result": String(payload.get("result", "")),
		"error": String(payload.get("error", "")),
		"error_code": String(payload.get("error_code", "")),
		"parent_seq": parent_seq,
		"depth": depth,
	}
	events.append(event)
	_next_seq += 1
	return int(event["seq"])


# 按 seq 更新既有事件的结果字段（用于 dispatch 完成后的回填）。
func update_result(seq: int, result: String, error: String = "", error_code: String = "") -> void:
	for event in events:
		if int(event.get("seq", -1)) == seq:
			event["result"] = result
			event["error"] = error
			event["error_code"] = error_code
			return


# 进入嵌套链路（span），返回 span 起始事件 seq；关闭时返回 -1。
func begin_span(kind: String, timing: String, payload: Dictionary = {}) -> int:
	var seq := record(kind, timing, payload)
	if seq > 0:
		_span_stack.append({"seq": seq, "kind": kind})
	return seq


# 退出最近进入的 span，返回其起始事件 seq；无 span 时返回 -1。
func end_span() -> int:
	if _span_stack.is_empty():
		return -1
	var span: Dictionary = _span_stack[_span_stack.size() - 1]
	_span_stack.pop_back()
	return int(span["seq"])


# 过滤出带错误的事件（error 或 error_code 非空）。
func errors() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for event in events:
		if String(event.get("error", "")) != "" or String(event.get("error_code", "")) != "":
			result.append(event)
	return result


func has_error() -> bool:
	return not errors().is_empty()


# 按记录顺序返回事件 kind 序列。
func sequence_of_kinds() -> Array[String]:
	var kinds: Array[String] = []
	for event in events:
		kinds.append(String(event.get("kind", "")))
	return kinds


# 按记录顺序返回事件 timing 序列。
func sequence_of_timings() -> Array[String]:
	var timings: Array[String] = []
	for event in events:
		timings.append(String(event.get("timing", "")))
	return timings


func by_kind(kind: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for event in events:
		if String(event.get("kind", "")) == kind:
			result.append(event)
	return result
