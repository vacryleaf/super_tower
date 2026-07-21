extends RefCounted
class_name SaveSlotView


func render(
	root: Control,
	label_factory: Callable,
	title: String,
	subtitle: String,
	slots: Array[Dictionary],
	select_callback: Callable,
	back_callback: Callable,
	confirm_mode: String = ""
) -> void:
	var outer := VBoxContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("separation", 10)
	root.add_child(outer)

	outer.add_child(label_factory.call(title, 28))
	outer.add_child(label_factory.call(subtitle, 16))

	var slot_row := HBoxContainer.new()
	slot_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot_row.add_theme_constant_override("separation", 10)
	outer.add_child(slot_row)

	for slot in slots:
		slot_row.add_child(_slot_button(label_factory, slot, select_callback, confirm_mode))

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(spacer)

	var back_button := Button.new()
	back_button.text = "返回"
	back_button.custom_minimum_size = Vector2(160, 44)
	back_button.pressed.connect(back_callback)
	outer.add_child(back_button)


func _slot_button(label_factory: Callable, slot: Dictionary, select_callback: Callable, confirm_mode: String) -> Control:
	var slot_index := int(slot.get("slot_index", 1))
	var mode := confirm_mode
	var button := Button.new()
	button.custom_minimum_size = Vector2(360, 170)
	button.text = _slot_text(slot)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.pressed.connect(func(): select_callback.call(slot_index, mode))
	if not bool(slot.get("occupied", false)) and mode == "load":
		button.disabled = true
	return button


func _slot_text(slot: Dictionary) -> String:
	var slot_index := int(slot.get("slot_index", 1))
	var headline := String(slot.get("headline", "空槽"))
	var detail := String(slot.get("detail", ""))
	if headline == "":
		headline = "空槽"
	return "槽位 %d\n%s\n%s" % [slot_index, headline, detail]
