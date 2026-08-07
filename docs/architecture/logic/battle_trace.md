# BattleTrace 诊断记录

状态：已实现（2026-08-07，ARCH-18）。

## 目标

统一记录战斗模块执行过程中的时机、上下文 ID、行动者、目标、结果和错误，帮助定位模块顺序与嵌套链路问题；测试可直接用事件顺序断言流程，不依赖 UI 文案。

## 约束

- Trace 不得改变业务状态，不得作为业务判断依据；仅做旁路记录。
- 未绑定 trace 时 BattleFlow 行为与之前完全一致（零开销）。
- 关闭 trace（`set_enabled(false)`）后所有记录为 no-op。

## 组件

- `GameProject/scripts/core/battle/battle_trace.gd`：`BattleTrace` 纯事件记录器。
  - `record(kind, timing, payload)`：追加一条事件，返回 seq；事件含 `seq/kind/timing/context_id/actor/target/result/error/error_code/parent_seq/depth`。
  - `begin_span(kind, timing, payload)` / `end_span()`：维护嵌套链路栈，子事件自动携带 `parent_seq` 与 `depth`。
  - `update_result(seq, result, error, error_code)`：按 seq 回填结果字段（dispatch 完成后的结果）。
  - `errors()/has_error()/by_kind()/sequence_of_kinds()/sequence_of_timings()`：查询辅助。
- `GameProject/scripts/core/battle/battle_trace_logger.gd`：`BattleTraceLogger` 日志适配。
  - `bind_logger(sink)`：绑定具备 `log(message)` 的日志对象（如 DebugLogger）。
  - `flush(trace)`：将当前事件全部写为一行日志，返回写入行数。
  - `format_event(event)`：静态格式化（`[trace] seq=... kind=... timing=... ctx=... actor=... target=... result=... error=...`）。
- `GameProject/scripts/core/battle/battle_flow.gd`：接入点。
  - `set_trace(trace)`：绑定 trace；`dispatch_timing` 对每个时机记录 `timing`（进入）与 `timing_result`（结果/错误）两条事件。
  - `enqueue_nested_action`/`dequeue_nested_action`：以 `nested_action` span 记录嵌套行动链路。
- `GameProject/scripts/tests/battle_trace_assert.gd`：测试基类，提供 `assert_event_kinds/assert_event_timings/assert_event_field/assert_event_parented` 结构化断言。
- `GameProject/scripts/tests/battle_trace_test.gd`：接入默认入口，覆盖时机顺序、结果与错误字段、嵌套链路、关闭 trace、日志格式与 flush、禁用日志跳过 sink。

## 事件结构

```
{
  "seq": 1,            # 全局递增序号
  "kind": "timing",    # 事件类型（timing/timing_result/nested_action/自定义 span）
  "timing": "battle_prepare",
  "context_id": "battle-1",
  "actor": "玩家",
  "target": "老鼠",
  "result": "continue",
  "error": "",
  "error_code": "",
  "parent_seq": 0,     # 0 表示根；否则指向父 span 起始 seq
  "depth": 0
}
```

## 测试命令

- `sh run_tests.sh`：通过，输出 `ALL TESTS PASSED`（连续 5 轮验证）。
