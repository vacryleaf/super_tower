extends "res://scripts/tests/test_base.gd"

const ModLoader = preload("res://scripts/core/mod_loader.gd")


func run() -> void:
	test_discover_and_register_mods()
	test_dependency_registration_and_disable()
	test_invalid_manifest_errors()


func test_discover_and_register_mods() -> void:
	var loader := ModLoader.new("res://data/test_mods")
	var discovered := loader.discover_mods()
	assert_true(discovered.size() >= 3, "mod loader should discover fixture packages")
	assert_true(loader.register_content("fixture.good"), "valid fixture mod should register")
	var skills := loader.content_table("skills")
	var items := loader.content_table("items")
	assert_true(skills.has("fixture.good.skill.arc_burst"), "registered mod skill should be queryable")
	assert_true(items.has("fixture.good.item.test_potion"), "registered mod item should be queryable")
	assert_true(loader.active_mod_ids().has("fixture.good"), "registered mod should be active")


func test_dependency_registration_and_disable() -> void:
	var loader := ModLoader.new("res://data/test_mods")
	loader.discover_mods()
	assert_true(loader.register_content("fixture.dependent"), "dependent mod should resolve compatible dependency")
	assert_true(loader.active_mod_ids().has("fixture.good"), "dependency should register before dependent")
	assert_true(loader.active_mod_ids().has("fixture.dependent"), "dependent mod should become active")
	assert_true(loader.disable_mod("fixture.good"), "active dependency should be disableable")
	assert_true(loader.active_mod_ids().is_empty(), "disabling dependency should disable dependent mods")
	assert_true(loader.content_table("skills").is_empty(), "disabled mod content should be removed")


func test_invalid_manifest_errors() -> void:
	var loader := ModLoader.new("res://data/test_mods")
	loader.discover_mods()
	assert_true(not loader.register_content("fixture.bad"), "invalid domain manifest should be rejected")
	var found_domain_error := false
	for error in loader.content_errors():
		if String(error.get("code", "")) == "unsupported_domain":
			found_domain_error = true
			assert_equal(String(error.get("mod_id", "")), "fixture.bad", "manifest error should identify package")
	assert_true(found_domain_error, "invalid manifest should expose a structured domain error")
