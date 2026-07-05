extends RefCounted
class_name ActionBarView

const DataCatalog = preload("res://scripts/core/data_catalog.gd")


func render(
	parent: Control,
	session: Variant,
	input_locked: bool,
	attack_callback: Callable,
	defend_callback: Callable,
	dodge_callback: Callable,
	end_turn_callback: Callable,
	skill_callback: Callable,
	charge_callback: Callable
) -> Dictionary:
	var action_buttons: Array[Button] = []
	var skill_buttons: Array[Button] = []
	var charge_buttons: Array[Button] = []
	var actions := VBoxContainer.new()
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(actions)

	var basic_row := HBoxContainer.new()
	basic_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(basic_row)
	basic_row.add_child(_action_button("普通攻击", attack_callback, input_locked))
	basic_row.add_child(_action_button("防御", defend_callback, input_locked))
	basic_row.add_child(_action_button("躲避", dodge_callback, input_locked))
	basic_row.add_child(_action_button("结束回合", end_turn_callback, input_locked))
	for child in basic_row.get_children():
		action_buttons.append(child as Button)

	var skill_row := HBoxContainer.new()
	skill_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(skill_row)
	for i in range(4):
		var button := Button.new()
		button.custom_minimum_size = Vector2(124, 46)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.disabled = input_locked or i >= session.player["equipped_skills"].size()
		if i < session.player["equipped_skills"].size():
			var skill_id: String = session.player["equipped_skills"][i]
			var skill: Dictionary = DataCatalog.SKILLS[skill_id]
			button.text = "%s（%d）" % [skill["name"], int(skill.get("cost", 0))]
			button.disabled = input_locked or session.action_points < int(skill.get("cost", 0))
			button.pressed.connect(skill_callback.bind(i))
		else:
			button.text = "未解锁"
		skill_row.add_child(button)
		skill_buttons.append(button)

	var charges: Array[Dictionary] = session.available_charges()
	if not charges.is_empty():
		var charge_grid := GridContainer.new()
		charge_grid.columns = 4
		charge_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		actions.add_child(charge_grid)
		for charge in charges:
			var button := Button.new()
			var charge_id := String(charge.get("charge_id", ""))
			button.set_meta("charge_id", charge_id)
			button.custom_minimum_size = Vector2(136, 66)
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.text = "%s\n%s" % [_charge_button_label(charge), String(charge.get("source_label", ""))]
			button.disabled = input_locked or bool(charge.get("used", false)) or not bool(charge.get("ready", false))
			button.pressed.connect(charge_callback.bind(charge_id))
			charge_grid.add_child(button)
			charge_buttons.append(button)

	refresh(session, input_locked, action_buttons, skill_buttons, charge_buttons)
	return {
		"action_buttons": action_buttons,
		"skill_buttons": skill_buttons,
		"charge_buttons": charge_buttons
	}


func refresh(
	session: Variant,
	input_locked: bool,
	action_buttons: Array[Button],
	skill_buttons: Array[Button],
	charge_buttons: Array[Button]
) -> void:
	for i in range(action_buttons.size()):
		var button := action_buttons[i]
		if button == null or not is_instance_valid(button):
			continue
		if i < 3:
			button.disabled = input_locked or session.action_points < 1
		else:
			button.disabled = input_locked
	for i in range(skill_buttons.size()):
		var button := skill_buttons[i]
		if button == null or not is_instance_valid(button):
			continue
		if i >= session.player["equipped_skills"].size():
			button.disabled = true
			continue
		var skill_id: String = session.player["equipped_skills"][i]
		var skill: Dictionary = DataCatalog.SKILLS[skill_id]
		button.disabled = input_locked or session.action_points < int(skill.get("cost", 0))
	for button in charge_buttons:
		if button == null or not is_instance_valid(button):
			continue
		var charge_id := String(button.get_meta("charge_id", ""))
		button.disabled = input_locked or bool(session.charge_used.get(charge_id, false)) or not bool(session.charge_ready.get(charge_id, false))


func _action_button(text_value: String, callback: Callable, input_locked: bool) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(118, 50)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.disabled = input_locked
	button.pressed.connect(callback)
	return button


func _charge_button_label(charge: Dictionary) -> String:
	var label := String(charge.get("label", "充能"))
	label = label.replace("充能：", "")
	var state := "已使用" if bool(charge.get("used", false)) else ("已充能" if bool(charge.get("ready", false)) else "未充能")
	return "%s\n%s" % [label, state]
