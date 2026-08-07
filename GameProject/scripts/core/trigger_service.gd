extends RefCounted
class_name TriggerService

const TriggerEvents = preload("res://scripts/core/trigger_events.gd")
const TriggerDispatchModule = preload("res://scripts/core/battle/trigger/trigger_dispatch_module.gd")

var _status_service_ref: WeakRef = null
var trigger_dispatch_module: RefCounted


func _init() -> void:
	trigger_dispatch_module = TriggerDispatchModule.new()


func set_status_service(service: RefCounted) -> void:
	_status_service_ref = weakref(service)


func _status_service():
	if _status_service_ref == null:
		return null
	return _status_service_ref.get_ref()


# 只负责事件与条件筛选；匹配后的动作全部委托给 TriggerDispatchModule 执行，
# 伤害类动作经由嵌套行动队列进入统一命中流程。
func fire_trigger(target: Dictionary, event: String, context: Dictionary) -> void:
	if not target.has("statuses"):
		return
	var service = _status_service()
	var statuses: Array = target["statuses"]
	for status in statuses:
		for trigger in status.get("triggers", []):
			if String(trigger.get("event", "")) != event:
				continue
			if service == null:
				continue
			if trigger.has("condition") and not service.evaluate_condition(target, trigger["condition"], context):
				continue
			var conditions: Array = trigger.get("conditions", [])
			if not conditions.is_empty() and not service.evaluate_conditions(target, conditions, context):
					continue
			for action in trigger.get("actions", []):
				trigger_dispatch_module.dispatch(target, action, context, service)
