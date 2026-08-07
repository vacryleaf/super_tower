extends RefCounted
class_name BattleActionQueue

const MAX_CHAIN_DEPTH := 10

var _queue: Array[RefCounted] = []
var _depth_by_chain: Dictionary = {}


func enqueue_nested_action(action_context: RefCounted, parent_chain_id: String = "") -> bool:
	if action_context == null:
		return false
	var chain_id := String(action_context.get("chain_id"))
	if chain_id == "":
		return false
	var depth := 1
	if parent_chain_id != "":
		depth = int(_depth_by_chain.get(parent_chain_id, 1)) + 1
	if depth > MAX_CHAIN_DEPTH:
		return false
	_depth_by_chain[chain_id] = depth
	_queue.append(action_context)
	return true


func dequeue_nested_action() -> RefCounted:
	if _queue.is_empty():
		return null
	var action_context: RefCounted = _queue[0]
	_queue.remove_at(0)
	return action_context


func is_empty() -> bool:
	return _queue.is_empty()


func chain_depth(chain_id: String) -> int:
	return int(_depth_by_chain.get(chain_id, 0))
