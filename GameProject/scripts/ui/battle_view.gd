extends RefCounted
class_name BattleView

const DataCatalog = preload("res://scripts/core/data_catalog.gd")
const UIHelpers = preload("res://scripts/ui/ui_helpers.gd")


func enemy_card(
	session: Variant,
	index: int,
	selected_target: int,
	rank_label: Callable,
	trait_labels: Callable,
	trait_tooltip: Callable,
	pressed_callback: Callable
) -> Button:
	var enemy: Dictionary = session.enemies[index]
	var button := Button.new()
	button.custom_minimum_size = Vector2(146, 136)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var selected := ">" if index == selected_target else ""
	button.text = enemy_card_text(session, index, selected, rank_label, trait_labels)
	button.tooltip_text = trait_tooltip.call(enemy["traits"])
	button.disabled = int(enemy["hp"]) <= 0
	button.pressed.connect(pressed_callback.bind(index))
	return button


func enemy_card_text(session: Variant, index: int, selected: String, rank_label: Callable, trait_labels: Callable) -> String:
	var enemy: Dictionary = session.enemies[index]
	return "%s%s  %s\n生命 %d/%d\n攻%d 护%d  格%d/%d\n意图：%s\n特性：%s" % [
		selected,
		enemy["name"],
		rank_label.call(enemy["rank"]),
		int(enemy["hp"]),
		int(enemy["max_hp"]),
		int(enemy["attack"]),
		int(enemy.get("armor", enemy.get("defense", 0))),
		int(enemy.get("block", 0)),
		int(enemy.get("block_power", enemy.get("defense", 0))),
		session.enemy_intent_text(index),
		trait_labels.call(enemy["traits"])
	]


func player_status(session: Variant, class_label: String, label_factory: Callable, class_key: String = "") -> Dictionary:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(170, 150)
	panel.size_flags_vertical = Control.SIZE_SHRINK_END
	var box := VBoxContainer.new()
	panel.add_child(box)
	if class_key != "":
		box.add_child(UIHelpers.avatar_for(class_key))
	var labels := {
		"class": label_factory.call(class_label, 18),
		"action": label_factory.call("能量 %d/%d" % [session.energy, DataCatalog.ENERGY_MAX], 15),
		"hp": label_factory.call("hp %d/%d" % [int(session.player["hp"]), int(session.player["max_hp"])], 15),
		"block": label_factory.call("格挡 %d" % session.player_block, 15),
		"block_power": label_factory.call("格挡值 %d" % int(session.player["block_power"]), 15),
		"attack": label_factory.call("攻击 %d" % int(session.player["attack"]), 15),
		"armor": label_factory.call("护甲 %d" % int(session.player["defense"]), 15)
	}
	for key in ["class", "action", "hp", "block", "block_power", "attack", "armor"]:
		box.add_child(labels[key])
	return {"panel": panel, "labels": labels}


func ally_card(
	session: Variant,
	index: int,
	rank_label: Callable,
	trait_labels: Callable,
	trait_tooltip: Callable
) -> Button:
	var ally: Dictionary = session.allies[index]
	var button := Button.new()
	button.custom_minimum_size = Vector2(146, 136)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.text = ally_card_text(session, index, rank_label, trait_labels)
	button.tooltip_text = trait_tooltip.call(ally["traits"])
	button.disabled = int(ally["hp"]) <= 0
	return button




func ally_card_text(session: Variant, index: int, rank_label: Callable, trait_labels: Callable) -> String:
	var ally: Dictionary = session.allies[index]
	return "%s  %s\n生命 %d/%d\n攻%d 护%d  格%d/%d\n意图：%s\n特性：%s" % [
		ally["name"],
		rank_label.call(ally.get("rank", "normal")),
		int(ally["hp"]),
		int(ally["max_hp"]),
		int(ally["attack"]),
		int(ally.get("armor", ally.get("defense", 0))),
		int(ally.get("block", 0)),
		int(ally.get("block_power", ally.get("defense", 0))),
		"支援",
		trait_labels.call(ally.get("traits", []))
	]
