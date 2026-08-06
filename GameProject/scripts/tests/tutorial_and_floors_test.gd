extends SceneTree

const DataValidationTests = preload("res://scripts/tests/data_validation_test.gd")
const CombatMechanicsTests = preload("res://scripts/tests/combat_mechanics_test.gd")
const RewardSystemTests = preload("res://scripts/tests/reward_system_test.gd")
const PersistenceTests = preload("res://scripts/tests/persistence_test.gd")
const CampaignTests = preload("res://scripts/tests/campaign_test.gd")
const BattleServiceTests = preload("res://scripts/tests/battle_service_test.gd")
const BattleContextContractTests = preload("res://scripts/tests/battle_context_contract_test.gd")
const BattleModuleRegistryTests = preload("res://scripts/tests/battle_module_registry_test.gd")
const BattleFlowContractTests = preload("res://scripts/tests/battle_flow_contract_test.gd")
const ActionIntentTests = preload("res://scripts/tests/action_intent_test.gd")
const EffectDispatcherTests = preload("res://scripts/tests/effect_dispatcher_test.gd")
const NonDamageEffectTests = preload("res://scripts/tests/non_damage_effect_test.gd")
const HitResolutionTests = preload("res://scripts/tests/hit_resolution_test.gd")
const DodgeResolutionTests = preload("res://scripts/tests/dodge_resolution_test.gd")
const ModLoaderTests = preload("res://scripts/tests/mod_loader_test.gd")

var failures: Array[String] = []


func _init() -> void:
	run_all()
	call_deferred("_finish")


func _finish() -> void:
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
	_run(BattleServiceTests.new())
	_run(BattleContextContractTests.new())
	_run(BattleModuleRegistryTests.new())
	_run(BattleFlowContractTests.new())
	_run(ActionIntentTests.new())
	_run(EffectDispatcherTests.new())
	_run(NonDamageEffectTests.new())
	_run(HitResolutionTests.new())
	_run(DodgeResolutionTests.new())
	_run(ModLoaderTests.new())


func _run(suite: RefCounted) -> void:
	suite.run()
	failures.append_array(suite.failures)
	suite = null
