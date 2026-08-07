extends RefCounted
class_name BattleTraceLogger

# BattleTraceLogger 把 BattleTrace 事件格式化为一行文本并写入日志 sink。
# sink 需提供 log(message: String)；未绑定 sink 时仅返回格式化文本。

var sink: RefCounted = null
var enabled := true


func bind_logger(logger: RefCounted) -> void:
	sink = logger


func set_enabled(value: bool) -> void:
	enabled = value


func is_enabled() -> bool:
	return enabled


# 将 trace 的当前事件全部写为日志行，返回写入行数。
func flush(trace: RefCounted) -> int:
	var written := 0
	for event in trace.events:
		write_event(event)
		written += 1
	return written


# 写一条事件日志行，返回格式化文本。
func write_event(event: Dictionary) -> String:
	var line := format_event(event)
	if enabled and sink != null and sink.has_method("log"):
		sink.call("log", line)
	return line


static func format_event(event: Dictionary) -> String:
	var parts: Array[String] = [
		"[trace]",
		"seq=%d" % int(event.get("seq", 0)),
		"kind=%s" % String(event.get("kind", "")),
		"timing=%s" % String(event.get("timing", "")),
		"ctx=%s" % String(event.get("context_id", "")),
		"actor=%s" % String(event.get("actor", "")),
		"target=%s" % String(event.get("target", "")),
		"result=%s" % String(event.get("result", "")),
	]
	var error := String(event.get("error", ""))
	var error_code := String(event.get("error_code", ""))
	if error != "":
		parts.append("error=%s" % error)
	if error_code != "":
		parts.append("error_code=%s" % error_code)
	return " ".join(parts)
