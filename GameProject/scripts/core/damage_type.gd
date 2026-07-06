extends RefCounted
class_name DamageType

const PHYSICAL := "physical"
const FIRE := "fire"
const ICE := "ice"
const LIGHTNING := "lightning"
const POISON := "poison"
const HOLY := "holy"
const SHADOW := "shadow"
const TRUE := "true"

const ALL := [PHYSICAL, FIRE, ICE, LIGHTNING, POISON, HOLY, SHADOW]


static func resist_key(damage_type: String) -> String:
	return "resist_" + damage_type