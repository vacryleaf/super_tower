extends "res://scripts/tests/test_base.gd"

const RuntimeCatalog = preload("res://scripts/core/runtime_catalog.gd")
const DataCatalog = preload("res://scripts/core/data_catalog.gd")


func run() -> void:
	test_runtime_default_lookup()
	test_external_complete_table()
	test_partial_table_fallback()
	test_mod_namespace_lookup()
	test_missing_and_unknown_ids()


func test_runtime_default_lookup() -> void:
	var catalog := RuntimeCatalog.new()
	assert_equal(catalog.runtime_table("skills").size(), DataCatalog.SKILLS.size(), "runtime skills table size")
	assert_equal(catalog.entry("skills", "po_jun").get("name", ""), "破军", "vanilla skill lookup")
	assert_equal(catalog.entry("classes", "unified").get("name", ""), "探索者", "vanilla class lookup")
	assert_equal(catalog.entry("monsters", "normal_rat_01").get("name", ""), "腐鼠", "vanilla monster lookup")
	assert_equal(catalog.entry("items", "minor_heal").get("kind", ""), "heal", "vanilla item lookup")
	assert_equal(catalog.entry("weapons", "long_sword").get("name", ""), "剑", "vanilla weapon lookup")


func test_external_complete_table() -> void:
	var catalog := RuntimeCatalog.new()
	assert_true(catalog.can_use_external("state_cards"), "state_cards should be externally complete")
	assert_equal(catalog.resolved_table("state_cards"), catalog.external_table("state_cards"), "resolved state_cards should come from external table")
	assert_equal(int(catalog.entry("state_cards", "critical").get("weight", 0)), 5, "external state card lookup")


func test_partial_table_fallback() -> void:
	var catalog := RuntimeCatalog.new()
	assert_true(not catalog.can_use_external("classes"), "classes should fallback")
	assert_true(not catalog.can_use_external("skills"), "skills should fallback")
	assert_equal(catalog.resolved_table("classes"), catalog.runtime_table("classes"), "classes fallback to runtime")
	assert_equal(catalog.resolved_table("skills"), catalog.runtime_table("skills"), "skills fallback to runtime")
	assert_equal(catalog.entry("classes", "unified").get("avatar_asset", ""), "warrior", "fallback class keeps runtime avatar")


func test_mod_namespace_lookup() -> void:
	var catalog := RuntimeCatalog.new("res://data/test_mods")
	var registered := catalog.load_mods()
	assert_true(registered.has("fixture.good"), "fixture.good should register")
	assert_true(catalog.has("skills", "fixture.good.skill.arc_burst"), "mod skill should be queryable")
	assert_true(catalog.entry("skills", "fixture.good.skill.arc_burst").has("id"), "mod skill entry has id")
	assert_true(catalog.has("items", "fixture.good.item.test_potion"), "mod item should be queryable")
	assert_true(catalog.table("skills").has("fixture.good.skill.arc_burst"), "merged skills table includes mod content")
	assert_true(catalog.table("skills").has("po_jun"), "merged skills table keeps vanilla content")


func test_missing_and_unknown_ids() -> void:
	var catalog := RuntimeCatalog.new()
	assert_true(not catalog.has("skills", "not_a_real_skill"), "missing id should not exist")
	assert_equal(catalog.entry("skills", "not_a_real_skill"), {}, "missing entry should be empty")
	assert_equal(catalog.entry("unknown_table", "whatever"), {}, "unknown table should be empty")
	assert_equal(catalog.table("unknown_table"), {}, "unknown table should be empty")
	assert_true(not catalog.has("unknown_table", "x"), "unknown table should not have entries")
