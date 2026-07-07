extends SceneTree

const DataValidationTests = preload("res://scripts/tests/data_validation_test.gd")
const CombatMechanicsTests = preload("res://scripts/tests/combat_mechanics_test.gd")
const RewardSystemTests = preload("res://scripts/tests/reward_system_test.gd")
const PersistenceTests = preload("res://scripts/tests/persistence_test.gd")
const CampaignTests = preload("res://scripts/tests/campaign_test.gd")

var failures: Array[String] = []


func _init() -> void:
	run_all()
	if failures.is_empty():
		print("ALL TESTS PASSED")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func run_all() -> void:
	_run(DataValidationTests.new())
	_run(CombatMechanicsTests.new())
	_run(RewardSystemTests.new())
	_run(PersistenceTests.new())
	_run(CampaignTests.new())


func _run(suite: RefCounted) -> void:
	suite.run()
	failures.append_array(suite.failures)