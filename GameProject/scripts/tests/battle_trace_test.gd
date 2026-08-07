extends "res://scripts/tests/battle_trace_assert.gd"

const BattleActionContext = preload("res://scripts/core/battle/battle_action_context.gd")
const BattleContext = preload("res://scripts/core/battle/battle_context.gd")
const BattleFlow = preload("res://scripts/core/battle/battle_flow.gd")
const BattleModule = preload("res://scripts/core/battle/battle_module.gd")
const BattleStepResult = preload("res://scripts/core/battle/battle_step_result.gd")
const BattleTiming = preload("res://scripts/core/battle/battle_timing.gd")
const BattleTrace = preload("res://scripts/core/battle/battle_trace.gd")
const BattleTraceLogger = preload("res://scripts/core/battle/battle_trace_logger.gd")


class RecordingModule extends BattleModule:
	var timings: Array[String] = []
	var fail_timing := ""
	var fail_message := "module exploded"

	func supports(_timing: String) -> bool:
		return true

	func execute(timing: String, context: RefCounted) -> RefCounted:
		timings.append(timing)
		if timing == fail_timing:
			return BattleStepResult.new(BattleStepResult.ERROR, fail_message, "module_error")
		return BattleStepResult.new(BattleStepResult.CONTINUE)


class CapturingLogger extends RefCounted:
	var lines: Array[String] = []

	func log(message: String) -> void:
		lines.append(message)


func run() -> void:
	test_flow_records_timing_events_in_order()
	test_flow_records_result_and_error_fields()
	test_trace_keeps_nested_span_linkage()
	test_flow_records_nested_action_span()
	test_trace_disabled_ignores_records()
	test_trace_logger_formats_and_flushes()
	test_trace_logger_disabled_skips_sink()


func test_flow_records_timing_events_in_order() -> void:
	var module := RecordingModule.new()
	var flow := BattleFlow.new()
	flow.register_module(module)
	var trace := BattleTrace.new()
	flow.set_trace(trace)
	var context := BattleContext.new()
	context.set_current_actor({"name": "玩家"})
	flow.start_battle(context)
	assert_event_kinds(trace.events, [
		"timing",
		"timing_result",
		"timing",
		"timing_result",
	], "battle flow should record enter and result events per timing")
	assert_event_timings(trace.events, [
		BattleTiming.BATTLE_PREPARE,
		BattleTiming.BATTLE_PREPARE,
		BattleTiming.BATTLE_START,
		BattleTiming.BATTLE_START,
	], "battle flow should trace battle prepare and start timings")
	assert_event_field(trace.events, 0, "context_id", context.context_id, "timing event carries context id")
	assert_event_field(trace.events, 0, "actor", "玩家", "timing event carries actor label")
	assert_event_field(trace.events, 1, "result", BattleStepResult.CONTINUE, "result event carries continue result")


func test_flow_records_result_and_error_fields() -> void:
	var module := RecordingModule.new()
	module.fail_timing = BattleTiming.ACTION_VALIDATE
	module.fail_message = "invalid intent"
	var flow := BattleFlow.new()
	flow.register_module(module)
	var trace := BattleTrace.new()
	flow.set_trace(trace)
	var result: RefCounted = flow.submit_action(BattleActionContext.new())
	assert_equal(String(result.get("kind")), BattleStepResult.ERROR, "flow should return module error")
	var error_index := -1
	for index in range(trace.events.size()):
		if String(trace.events[index].get("kind", "")) == "timing_result" and String(trace.events[index].get("result", "")) == BattleStepResult.ERROR:
			error_index = index
			break
	assert_true(error_index >= 0, "trace should record an error result event")
	assert_event_field(trace.events, error_index, "error", "invalid intent", "error event carries module message")
	assert_event_field(trace.events, error_index, "error_code", "module_error", "error event carries module error code")
	assert_true(trace.has_error(), "trace should report an error")


func test_trace_keeps_nested_span_linkage() -> void:
	var trace := BattleTrace.new()
	var outer := trace.begin_span("action", BattleTiming.ACTION_EXECUTE, {"context_id": "outer-1"})
	var inner := trace.begin_span("skill", BattleTiming.SKILL_EFFECT, {"context_id": "inner-1"})
	var hit := trace.record("timing", BattleTiming.HIT_CONFIRMED, {"context_id": "hit-1"})
	trace.end_span()
	trace.end_span()
	assert_event_kinds(trace.events, ["action", "skill", "timing"], "spans should record begin events in order")
	assert_event_parented(trace.events, 1, outer, "inner span should be parented to outer span")
	assert_event_parented(trace.events, 2, inner, "hit event should be parented to inner span")
	assert_event_field(trace.events, 1, "depth", 1, "inner span depth should be one")
	assert_event_field(trace.events, 2, "depth", 2, "hit event depth should be two")


func test_flow_records_nested_action_span() -> void:
	var flow := BattleFlow.new()
	var trace := BattleTrace.new()
	flow.set_trace(trace)
	var action := BattleActionContext.new()
	flow.enqueue_nested_action(action)
	flow.dequeue_nested_action()
	assert_event_kinds(trace.events, ["nested_action"], "flow should trace nested action span begin")
	assert_event_field(trace.events, 0, "context_id", action.context_id, "nested action span carries context id")


func test_trace_disabled_ignores_records() -> void:
	var trace := BattleTrace.new()
	trace.set_enabled(false)
	var outer := trace.begin_span("action", BattleTiming.ACTION_EXECUTE)
	var seq := trace.record("timing", BattleTiming.HIT_CONFIRMED)
	trace.end_span()
	assert_equal(outer, -1, "disabled trace should reject span begin")
	assert_equal(seq, -1, "disabled trace should reject records")
	assert_equal(trace.count(), 0, "disabled trace should keep no events")


func test_trace_logger_formats_and_flushes() -> void:
	var trace := BattleTrace.new()
	trace.record("timing", BattleTiming.BATTLE_START, {"context_id": "ctx-9", "actor": "玩家"})
	var logger := BattleTraceLogger.new()
	var sink := CapturingLogger.new()
	logger.bind_logger(sink)
	var written := logger.flush(trace)
	assert_equal(written, 1, "logger should flush every event")
	assert_equal(sink.lines.size(), 1, "logger should write one line to sink")
	assert_true(String(sink.lines[0]).find("battle_start") >= 0, "log line should include timing")
	assert_true(String(sink.lines[0]).find("ctx=ctx-9") >= 0, "log line should include context id")
	assert_true(String(sink.lines[0]).find("玩家") >= 0, "log line should include actor label")


func test_trace_logger_disabled_skips_sink() -> void:
	var trace := BattleTrace.new()
	trace.record("timing", BattleTiming.BATTLE_START)
	var logger := BattleTraceLogger.new()
	logger.set_enabled(false)
	var sink := CapturingLogger.new()
	logger.bind_logger(sink)
	logger.write_event(trace.events[0])
	assert_equal(sink.lines.size(), 0, "disabled logger should not write to sink")
