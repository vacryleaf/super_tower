extends RefCounted
class_name UIHelpers

const DataCatalog = preload("res://scripts/core/data_catalog.gd")

const SLOTS := ["weapon", "armor", "accessory", "offhand"]

const SLOT_LABELS := {
	"weapon": "武器", "armor": "防具", "accessory": "饰品", "offhand": "副手"
}

const CATEGORIES := [
	["状态Buff", "state_cards"],
	["技能", "skills"],
	["职业", "classes"],
	["被动技能", "traits"],
	["怪物图鉴", "bestiary"],
]


static func avatar_for(class_key: String) -> Control:
	var texture := texture_from_png("res://img/%s.png" % class_key)
	if texture != null:
		var portrait := TextureRect.new()
		portrait.texture = texture
		portrait.custom_minimum_size = Vector2(88, 88)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		return portrait

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(88, 88)
	var label := Label.new()
	label.text = String(DataCatalog.CLASSES.get(class_key, {}).get("name", class_key))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	panel.add_child(label)
	return panel


static func texture_from_png(path: String) -> Texture2D:
	if not FileAccess.file_exists(path):
		return null
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null:
		return null
	return ImageTexture.create_from_image(image)


static func skill_type_name(skill: Dictionary) -> String:
	match String(skill.get("type", "")):
		"attack":
			var hits := int(skill.get("hits", 1))
			var mult := float(skill.get("multiplier", 1.0))
			if hits > 1:
				return "攻击（%d 段，每段 x%.2f）" % [hits, mult]
			return "攻击（x%.2f）" % mult
		"defense":
			return "防御（格挡 x%.2f）" % float(skill.get("multiplier", 1.0))
		"stance":
			return "架式（格挡 x%.2f，反击 x%.2f）" % [float(skill.get("block_multiplier", 1.0)), float(skill.get("counter_multiplier", 1.0))]
		"dodge":
			return "闪避（%d 层）" % int(skill.get("dodge_layers", 1))
		"heal":
			return "治疗（生命上限 x%.2f）" % float(skill.get("heal_multiplier", 0.25))
		"buff":
			return "增益（攻击 x%.2f）" % float(skill.get("attack_multiplier", 1.0))
		"debuff":
			return "减益（增伤 x%.2f，削弱 x%.2f）" % [float(skill.get("mark_multiplier", 1.0)), float(skill.get("weaken_multiplier", 1.0))]
	return "未知"


static func skill_energy_cost(skill: Dictionary) -> int:
	return int(skill.get("energy_cost", skill.get("cost", 0)))


static func slot_label(slot: String) -> String:
	return SLOT_LABELS.get(slot, slot)


static func rank_label(rank: String) -> String:
	match rank:
		"normal":
			return "普通"
		"elite":
			return "精英"
		"boss":
			return "首领"
	return rank
