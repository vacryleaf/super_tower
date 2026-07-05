extends RefCounted
class_name EquipmentOverlay


func show(parent: Control, equipment_panel: Control) -> void:
	var overlay := Control.new()
	overlay.name = "EquipmentOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 200
	parent.add_child(overlay)

	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0, 0, 0, 0.45)
	overlay.add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.add_child(equipment_panel)
	overlay.add_child(center)
