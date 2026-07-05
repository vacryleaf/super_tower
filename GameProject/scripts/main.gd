extends Control

const RunSimulator = preload("res://scripts/core/run_simulator.gd")

@onready var summary: RichTextLabel = $Root/Summary


func _ready() -> void:
	var simulator := RunSimulator.new()
	var result := simulator.run_campaign("warrior", 10)
	var lines: Array[String] = []
	lines.append("[b]Super Tower text prototype[/b]")
	lines.append("")
	lines.append("Class: warrior")
	lines.append("Victory: %s" % str(result.get("success", false)))
	lines.append("Floors completed: %d" % int(result.get("floors_completed", 0)))
	lines.append("Battles completed: %d" % int(result.get("battles_completed", 0)))
	lines.append("Final HP: %d/%d" % [int(result.get("hp", 0)), int(result.get("max_hp", 0))])
	lines.append("")
	lines.append("This first implementation focuses on deterministic combat, tutorial flow, rewards, and 1-10 floor validation. Visual cards can now bind to the same core data.")
	summary.text = "\n".join(lines)
