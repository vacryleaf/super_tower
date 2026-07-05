extends RefCounted
class_name CombatLogView


func render(parent: Control, battle_log: Array[String], label_factory: Callable) -> RichTextLabel:
	parent.add_child(label_factory.call("战斗日志", 18))
	var log_text := RichTextLabel.new()
	log_text.custom_minimum_size = Vector2(320, 180)
	log_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_text.text = log_text_from_entries(battle_log)
	parent.add_child(log_text)
	return log_text


func refresh(log_text: RichTextLabel, battle_log: Array[String]) -> void:
	if log_text != null and is_instance_valid(log_text):
		log_text.text = log_text_from_entries(battle_log)


func log_text_from_entries(battle_log: Array[String]) -> String:
	var start: int = maxi(0, battle_log.size() - 8)
	var lines: Array[String] = []
	for i in range(start, battle_log.size()):
		lines.append(battle_log[i])
	return "\n".join(lines)
