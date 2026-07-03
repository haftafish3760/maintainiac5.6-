import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

import '../qa_harness/qa_harness.dart';
import 'work_supply_parser_admin_report_contract_qa.dart';
import 'work_supply_parser_admin_diagnostic_batch_qa.dart';
import 'work_supply_parser_artifact_contract_qa.dart';
import 'work_supply_parser_artifact_retention_qa.dart';
import 'work_supply_parser_admin_privacy_rollup_qa.dart';
import 'work_supply_catalog_coverage_qa.dart';
import 'work_supply_parser_baseline_contract_qa.dart';
import 'work_supply_parser_accumulated_coverage_qa.dart';
import 'work_supply_parser_accuracy_budget_qa.dart';
import 'work_supply_parser_batch_continuation_qa.dart';
import 'work_supply_parser_barcode_inventory_identity_qa.dart';
import 'work_supply_parser_category_reuse_qa.dart';
import 'work_supply_parser_catalog_batch_memory_qa.dart';
import 'work_supply_parser_catalog_batch_manifest_qa.dart';
import 'work_supply_parser_catalog_item_batch_generation_qa.dart';
import 'work_supply_parser_catalog_family_rerun_qa.dart';
import 'work_supply_parser_cloud_cost_guard_qa.dart';
import 'work_supply_parser_cloud_local_mode_qa.dart';
import 'work_supply_parser_confidence_qa.dart';
import 'work_supply_parser_conflict_graph_qa.dart';
import 'work_supply_parser_boundary_qa.dart';
import 'work_supply_parser_blueprint_contract_qa.dart';
import 'work_supply_parser_blueprint_promotion_qa.dart';
import 'work_supply_parser_bulk_generation_pipeline_qa.dart';
import 'work_supply_parser_category_inference_qa.dart';
import 'work_supply_parser_context_qa.dart';
import 'work_supply_parser_correction_feedback_qa.dart';
import 'work_supply_parser_data_provenance_qa.dart';
import 'work_supply_parser_determinism_qa.dart';
import 'work_supply_parser_delivery_policy_qa.dart';
import 'work_supply_parser_device_budget_matrix_qa.dart';
import 'work_supply_parser_device_storage_qa.dart';
import 'work_supply_parser_differential_regression_qa.dart';
import 'work_supply_parser_duplicate_receipt_import_qa.dart';
import 'work_supply_parser_economics_qa.dart';
import 'work_supply_parser_estimate_section_qa.dart';
import 'work_supply_parser_evidence_qa.dart';
import 'work_supply_parser_evidence_summary_qa.dart';
import 'work_supply_parser_execution_command_qa.dart';
import 'work_supply_parser_failure_taxonomy_qa.dart';
import 'work_supply_parser_failure_routing_qa.dart';
import 'work_supply_parser_financial_duplicate_guard_qa.dart';
import 'work_supply_parser_file_size_qa.dart';
import 'work_supply_parser_fleet_permission_context_qa.dart';
import 'work_supply_parser_fixture_coverage_qa.dart';
import 'work_supply_parser_fixture_corpus_contract_qa.dart';
import 'work_supply_parser_fixture_expectation_qa.dart';
import 'work_supply_parser_fixture_batch_plan_qa.dart';
import 'work_supply_parser_fixture_privacy_qa.dart';
import 'work_supply_parser_fixture_holdout_rotation_qa.dart';
import 'work_supply_parser_fixture_qa.dart';
import 'work_supply_parser_governance_qa.dart';
import 'work_supply_parser_generated_artifact_manifest_qa.dart';
import 'work_supply_parser_generated_fixture_cell_qa.dart';
import 'work_supply_parser_generated_manifest_qa.dart';
import 'work_supply_parser_generated_performance_qa.dart';
import 'work_supply_parser_generator_pairing_qa.dart';
import 'work_supply_parser_gate_ledger_qa.dart';
import 'work_supply_parser_holdout_fixture_qa.dart';
import 'work_supply_parser_human_correction_learning_qa.dart';
import 'work_supply_parser_hive_authority_qa.dart';
import 'work_supply_parser_hive_firestore_sync_qa.dart';
import 'work_supply_parser_impact_qa.dart';
import 'work_supply_parser_import_export_safety_qa.dart';
import 'work_supply_parser_input_attack_surface_qa.dart';
import 'work_supply_parser_item_metadata_depth_qa.dart';
import 'work_supply_parser_item_promotion_gate_qa.dart';
import 'work_supply_parser_job_context_bridge_qa.dart';
import 'work_supply_parser_language_pack_separation_qa.dart';
import 'work_supply_parser_legal_safety_qa.dart';
import 'work_supply_parser_locale_qa.dart';
import 'work_supply_parser_maintainability_qa.dart';
import 'work_supply_parser_master_coverage_matrix_qa.dart';
import 'work_supply_parser_merchant_alias_normalization_qa.dart';
import 'work_supply_parser_merchant_qa.dart';
import 'work_supply_parser_merchant_matrix_qa.dart';
import 'work_supply_parser_known_debt_qa.dart';
import 'work_supply_parser_math_qa.dart';
import 'work_supply_parser_metamorphic_qa.dart';
import 'work_supply_parser_mutation_contract_qa.dart';
import 'work_supply_parser_mutation_fault_probe_qa.dart';
import 'work_supply_parser_mutation_plan_qa.dart';
import 'work_supply_parser_mutation_runner_contract_qa.dart';
import 'work_supply_parser_mutation_scenario_qa.dart';
import 'work_supply_parser_next_action_qa.dart';
import 'work_supply_parser_noise_qa.dart';
import 'work_supply_parser_no_live_services_qa.dart';
import 'work_supply_parser_pack_health_qa.dart';
import 'work_supply_parser_pack_integrity_recovery_qa.dart';
import 'work_supply_parser_pack_lifecycle_qa.dart';
import 'work_supply_parser_pack_recovery_qa.dart';
import 'work_supply_parser_pack_overlap_qa.dart';
import 'work_supply_parser_pack_scope_gate_qa.dart';
import 'work_supply_parser_pack_version_regression_qa.dart';
import 'work_supply_parser_pass_evidence_qa.dart';
import 'work_supply_parser_platform_contract_qa.dart';
import 'work_supply_parser_portability_qa.dart';
import 'work_supply_parser_price_tax_allocation_qa.dart';
import 'work_supply_parser_profile_matrix_qa.dart';
import 'work_supply_parser_product_normalization_qa.dart';
import 'work_supply_parser_property_qa.dart';
import 'work_supply_parser_ranked_candidate_qa.dart';
import 'work_supply_parser_recipe_completeness_qa.dart';
import 'work_supply_parser_receipt_line_torture_qa.dart';
import 'work_supply_parser_receipt_line_parser_fuzz_qa.dart';
import 'work_supply_parser_receipt_invoice_feed_qa.dart';
import 'work_supply_parser_receipt_line_mapping_qa.dart';
import 'work_supply_parser_receipt_source_immutability_qa.dart';
import 'work_supply_parser_regression_lock_qa.dart';
import 'work_supply_parser_release_one_cell_manifest_qa.dart';
import 'work_supply_parser_release_one_command_manifest_qa.dart';
import 'work_supply_parser_release_one_fastener_support_qa.dart';
import 'work_supply_parser_release_one_pack_balance_qa.dart';
import 'work_supply_parser_release_one_residential_qa.dart';
import 'work_supply_parser_release_one_service_family_qa.dart';
import 'work_supply_parser_release_one_tier_role_qa.dart';
import 'work_supply_parser_release_manifest_qa.dart';
import 'work_supply_parser_release_orchestration_qa.dart';
import 'work_supply_parser_release_shard_qa.dart';
import 'work_supply_parser_release_signoff_qa.dart';
import 'work_supply_parser_registry_qa.dart';
import 'work_supply_parser_registry_snapshot_qa.dart';
import 'work_supply_parser_requirement_coverage_qa.dart';
import 'work_supply_parser_review_safety_qa.dart';
import 'work_supply_parser_result_contract_qa.dart';
import 'work_supply_parser_runtime_profile_qa.dart';
import 'work_supply_parser_runtime_measurement_qa.dart';
import 'work_supply_parser_scalability_qa.dart';
import 'work_supply_parser_search_indexing_qa.dart';
import 'work_supply_parser_separation_qa.dart';
import 'work_supply_parser_service_truck_core_qa.dart';
import 'work_supply_parser_security_qa.dart';
import 'work_supply_parser_slo_contract_qa.dart';
import 'work_supply_parser_spanish_release_one_qa.dart';
import 'work_supply_parser_sku_collision_qa.dart';
import 'work_supply_parser_surgical_rerun_qa.dart';
import 'work_supply_parser_telemetry_qa.dart';
import 'work_supply_parser_validation_strategy_qa.dart';
import 'work_supply_parser_vendor_sku_matrix_qa.dart';
import 'work_supply_parser_vendor_readiness_qa.dart';
import 'work_supply_parser_workflow_routing_qa.dart';

QaHarness buildWorkSupplyParserQaHarness() {
  return QaHarness(
    domain: 'work_supply_inventory_parser',
    suites: const [
      WorkSupplyCatalogSchemaSuite(),
      WorkSupplyCatalogCoverageSuite(),
      WorkSupplyParserBlueprintContractSuite(),
      WorkSupplyParserBlueprintPromotionSuite(),
      WorkSupplyParserGeneratorPairingSuite(),
      WorkSupplyParserAccumulatedCoverageSuite(),
      WorkSupplyParserCloudCostGuardSuite(),
      WorkSupplyParserCloudLocalModeSuite(),
      WorkSupplyParserDeliveryPolicySuite(),
      WorkSupplyParserReleaseOneCellManifestSuite(),
      WorkSupplyParserReleaseOneCommandManifestSuite(),
      WorkSupplyParserMasterCoverageMatrixSuite(),
      WorkSupplyParserGeneratedArtifactManifestSuite(),
      WorkSupplyParserGeneratedFixtureCellSuite(),
      WorkSupplyParserRegressionLockSuite(),
      WorkSupplyParserDifferentialRegressionSuite(),
      WorkSupplyParserEvidenceSummarySuite(),
      WorkSupplyParserNextActionSuite(),
      WorkSupplyParserGateLedgerSuite(),
      WorkSupplyParserBatchContinuationSuite(),
      WorkSupplyParserPassEvidenceSuite(),
      WorkSupplyParserFileSizeSuite(),
      WorkSupplyParserFixtureBatchPlanSuite(),
      WorkSupplyParserFixtureExpectationSuite(),
      WorkSupplyParserFixturePrivacySuite(),
      WorkSupplyParserRecipeCompletenessSuite(),
      WorkSupplyParserReceiptLineTortureSuite(),
      WorkSupplyParserReceiptLineParserFuzzSuite(),
      WorkSupplyParserReceiptLineMappingSuite(),
      WorkSupplyParserProductNormalizationSuite(),
      WorkSupplyParserServiceTruckCoreSuite(),
      WorkSupplyParserReleaseOneResidentialSuite(),
      WorkSupplyParserReleaseOneServiceFamilySuite(),
      WorkSupplyParserReleaseOneTierRoleSuite(),
      WorkSupplyParserReleaseOneFastenerSupportSuite(),
      WorkSupplyParserReleaseOnePackBalanceSuite(),
      WorkSupplyParserItemMetadataDepthSuite(),
      WorkSupplyParserItemPromotionGateSuite(),
      WorkSupplyParserVendorReadinessSuite(),
      WorkSupplyParserVendorSkuMatrixSuite(),
      WorkSupplyParserMerchantAliasNormalizationSuite(),
      WorkSupplyParserSkuCollisionSuite(),
      WorkSupplyParserWorkflowRoutingSuite(),
      WorkSupplyParserJobContextBridgeSuite(),
      WorkSupplyParserCategoryInferenceSuite(),
      WorkSupplyParserFleetPermissionContextSuite(),
      WorkSupplyParserPriceTaxAllocationSuite(),
      WorkSupplyParserFinancialDuplicateGuardSuite(),
      WorkSupplyParserReceiptSourceImmutabilitySuite(),
      WorkSupplyParserReceiptInvoiceFeedSuite(),
      WorkSupplyParserDuplicateReceiptImportSuite(),
      WorkSupplyParserSpanishReleaseOneSuite(),
      WorkSupplyParserLanguagePackSeparationSuite(),
      WorkSupplyAliasConflictSuite(),
      WorkSupplyDangerousWordSuite(),
      WorkSupplyGoldenFixtureSuite(),
      WorkSupplyGeneratedCaseSuite(),
      WorkSupplyParserSecurityPrivacySuite(),
      WorkSupplyParserInputAttackSurfaceSuite(),
      WorkSupplyParserBoundarySuite(),
      WorkSupplyParserNoLiveServicesSuite(),
      WorkSupplyParserHiveAuthoritySuite(),
      WorkSupplyParserHiveFirestoreSyncSuite(),
      WorkSupplyParserReviewSafetySuite(),
      WorkSupplyParserResultContractSuite(),
      WorkSupplyParserEvidenceAttributionSuite(),
      WorkSupplyParserPackLifecycleSuite(),
      WorkSupplyParserPackRecoverySuite(),
      WorkSupplyParserPackIntegrityRecoverySuite(),
      WorkSupplyParserPackVersionRegressionSuite(),
      WorkSupplyParserPackOverlapSuite(),
      WorkSupplyParserPackScopeGateSuite(),
      WorkSupplyParserPackHealthSuite(),
      WorkSupplyParserScalabilitySuite(),
      WorkSupplyParserSearchIndexingSuite(),
      WorkSupplyParserRuntimeProfileSuite(),
      WorkSupplyParserRuntimeMeasurementSuite(),
      WorkSupplyParserGeneratedManifestSuite(),
      WorkSupplyParserGeneratedPerformanceSuite(),
      WorkSupplyParserFailureTaxonomySuite(),
      WorkSupplyParserFailureRoutingSuite(),
      WorkSupplyParserFixtureGovernanceSuite(),
      WorkSupplyParserFixtureCoverageSuite(),
      WorkSupplyParserFixtureCorpusContractSuite(),
      WorkSupplyParserHoldoutFixtureSuite(),
      WorkSupplyParserChangedItemImpactSuite(),
      WorkSupplyParserDeterminismSuite(),
      WorkSupplyParserMetamorphicSuite(),
      WorkSupplyParserPropertySuite(),
      WorkSupplyParserSeparationSafetySuite(),
      WorkSupplyParserConflictGraphSuite(),
      WorkSupplyParserRankedCandidateSuite(),
      WorkSupplyParserContextSuite(),
      WorkSupplyParserMerchantSuite(),
      WorkSupplyParserMerchantMatrixSuite(),
      WorkSupplyParserReceiptNoiseSuite(),
      WorkSupplyParserAccuracyBudgetSuite(),
      WorkSupplyParserEconomicsContractSuite(),
      WorkSupplyParserEstimateSectionSuite(),
      WorkSupplyParserConfidenceCalibrationSuite(),
      WorkSupplyParserReceiptMathSuite(),
      WorkSupplyParserLocaleContractSuite(),
      WorkSupplyParserTelemetryContractSuite(),
      WorkSupplyParserDeviceStorageSuite(),
      WorkSupplyParserDeviceBudgetMatrixSuite(),
      WorkSupplyParserCorrectionFeedbackSuite(),
      WorkSupplyParserHumanCorrectionLearningSuite(),
      WorkSupplyParserReleaseManifestSuite(),
      WorkSupplyParserReleaseOrchestrationSuite(),
      WorkSupplyParserReleaseShardSuite(),
      WorkSupplyParserReleaseSignoffSuite(),
      WorkSupplyParserRegistrySuite(),
      WorkSupplyParserRegistrySnapshotSuite(),
      WorkSupplyParserKnownDebtSuite(),
      WorkSupplyParserArtifactContractSuite(),
      WorkSupplyParserArtifactRetentionSuite(),
      WorkSupplyParserImportExportSafetySuite(),
      WorkSupplyParserAdminReportContractSuite(),
      WorkSupplyParserAdminDiagnosticBatchSuite(),
      WorkSupplyParserAdminPrivacyRollupSuite(),
      WorkSupplyParserExecutionCommandSuite(),
      WorkSupplyParserPortabilitySuite(),
      WorkSupplyParserMaintainabilitySuite(),
      WorkSupplyParserPlatformContractSuite(),
      WorkSupplyParserCategoryReuseSuite(),
      WorkSupplyParserBarcodeInventoryIdentitySuite(),
      WorkSupplyParserCatalogBatchMemorySuite(),
      WorkSupplyParserCatalogBatchManifestSuite(),
      WorkSupplyParserCatalogItemBatchGenerationSuite(),
      WorkSupplyParserBulkGenerationPipelineSuite(),
      WorkSupplyParserCatalogFamilyRerunSuite(),
      WorkSupplyParserDataProvenanceSuite(),
      WorkSupplyParserLegalSafetySuite(),
      WorkSupplyParserValidationStrategySuite(),
      WorkSupplyParserSloContractSuite(),
      WorkSupplyParserSurgicalRerunSuite(),
      WorkSupplyParserMutationContractSuite(),
      WorkSupplyParserMutationScenarioSuite(),
      WorkSupplyParserMutationDryRunPlanSuite(),
      WorkSupplyParserMutationFaultProbeSuite(),
      WorkSupplyParserMutationRunnerContractSuite(),
      WorkSupplyParserRequirementCoverageSuite(),
      WorkSupplyParserProfileMatrixSuite(),
      WorkSupplyParserBaselineContractSuite(),
      WorkSupplyParserFixtureHoldoutRotationSuite(),
    ],
  );
}

class WorkSupplyCatalogSchemaSuite extends QaSuite {
  const WorkSupplyCatalogSchemaSuite() : super('inventory.catalog_schema');

  static const _validUnits = {
    'each',
    'ea',
    'piece',
    'pc',
    'pack',
    'pk',
    'box',
    'case',
    'bag',
    'roll',
    'sheet',
    'ft',
    'foot',
    'lf',
    'sq ft',
    'gal',
    'qt',
    'pt',
    'oz',
    'lb',
    'stick',
    'kit',
    'can',
    'tub',
    'tube',
    'bottle',
    'bucket',
    'bundle',
    'carton',
    'section',
    'pair',
    'set',
    'linear foot',
    'square foot',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final ids = <String, WorkSupplyItem>{};
    final canonicalNames = <String, WorkSupplyItem>{};
    final items = context.isFullProfile
        ? workSupplyCatalogItems
        : _sampledItems(
            workSupplyCatalogItems,
            limit: context.catalogSchemaSampleLimit,
          );

    for (final item in items) {
      _require(
        failures,
        item.id.trim().isNotEmpty,
        id: 'missing_id:${item.name}',
        message: 'Inventory item is missing stable id.',
        actual: item.path,
        fix: 'Add a stable item id before parser QA can trust this row.',
      );
      final previousId = ids[item.id];
      if (previousId != null) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'duplicate_id:${item.id}',
            message: 'Duplicate inventory item id.',
            expected: previousId.name,
            actual: item.name,
            suggestedFix: 'Give each canonical row a unique stable id.',
          ),
        );
      } else {
        ids[item.id] = item;
      }

      _requireText(
        failures,
        item.name,
        'missing_name:${item.id}',
        'Inventory item is missing canonical name.',
        item,
      );
      _requireText(
        failures,
        item.trade,
        'missing_trade:${item.id}',
        'Inventory item is missing trade.',
        item,
      );
      _requireText(
        failures,
        item.category,
        'missing_category:${item.id}',
        'Inventory item is missing category.',
        item,
      );
      _requireText(
        failures,
        item.system,
        'missing_system:${item.id}',
        'Inventory item is missing system.',
        item,
      );
      _requireText(
        failures,
        item.itemType,
        'missing_item_type:${item.id}',
        'Inventory item is missing item type.',
        item,
      );
      _requireText(
        failures,
        item.variant,
        'missing_variant:${item.id}',
        'Inventory item is missing variant.',
        item,
      );

      if (item.aliases.isEmpty) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'empty_aliases:${item.id}',
            message: 'Inventory item has no aliases.',
            severity: QaSeverity.warning,
            actual: item.name,
            suggestedFix:
                'Add common aliases, receipt abbreviations, or search terms.',
          ),
        );
      }

      if (!_validUnits.contains(item.unit.toLowerCase().trim())) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'invalid_unit:${item.id}',
            message: 'Inventory item has unsupported unit.',
            expected: _validUnits.take(12).join(', '),
            actual: item.unit,
            suggestedFix: 'Normalize the unit or add it to the allowed list.',
          ),
        );
      }

      final nameKey = _canonicalKey([
        item.trade,
        item.category,
        item.system,
        item.itemType,
        item.name,
      ]);
      final previousName = canonicalNames[nameKey];
      if (previousName != null && previousName.id != item.id) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'duplicate_canonical_name:${item.id}',
            message: 'Duplicate canonical name in same catalog path.',
            expected: previousName.id,
            actual: item.id,
            suggestedFix:
                'Merge true duplicates or add variant/size/brand distinction.',
          ),
        );
      } else {
        canonicalNames[nameKey] = item;
      }

      _checkIntelligenceMetadata(failures, item, name);
    }

    return timer.finish(
      suite: name,
      checked: items.length,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'itemCount': workSupplyCatalogItems.length,
        'profileItemCount': items.length,
        'sampleLimit': context.isFullProfile
            ? 'all'
            : context.catalogSchemaSampleLimit,
        'uniqueIds': ids.length,
      },
    );
  }

  void _checkIntelligenceMetadata(
    List<QaFailure> failures,
    WorkSupplyItem item,
    String suite,
  ) {
    final intelligence = item.intelligence;
    if (intelligence == WorkSupplyItemIntelligence.empty) {
      failures.add(
        QaFailure(
          suite: suite,
          id: 'empty_intelligence:${item.id}',
          message: 'Inventory item has no parser intelligence metadata.',
          severity: QaSeverity.warning,
          actual: item.name,
          suggestedFix:
              'Add parser version, catalog version, source confidence, tokens, and receipt patterns.',
        ),
      );
      return;
    }
    if (intelligence.catalogVersion.trim().isEmpty) {
      failures.add(
        QaFailure(
          suite: suite,
          id: 'missing_catalog_version:${item.id}',
          message: 'Inventory item is missing catalog version metadata.',
          severity: QaSeverity.warning,
          actual: item.name,
          suggestedFix: 'Set catalogVersion for pack migration safety.',
        ),
      );
    }
    if (intelligence.parserVersion.trim().isEmpty) {
      failures.add(
        QaFailure(
          suite: suite,
          id: 'missing_parser_version:${item.id}',
          message: 'Inventory item is missing parser-pack version metadata.',
          severity: QaSeverity.warning,
          actual: item.name,
          suggestedFix: 'Set parserVersion for parser compatibility tracking.',
        ),
      );
    }
    if (intelligence.sourceConfidence.trim().isEmpty) {
      failures.add(
        QaFailure(
          suite: suite,
          id: 'missing_source_confidence:${item.id}',
          message: 'Inventory item is missing source confidence metadata.',
          severity: QaSeverity.warning,
          actual: item.name,
          suggestedFix:
              'Mark generated/manual/source confidence before release gates.',
        ),
      );
    }
  }
}

class WorkSupplyAliasConflictSuite extends QaSuite {
  const WorkSupplyAliasConflictSuite() : super('inventory.alias_conflicts');

  static const _tooGenericAliases = {
    'pvc',
    'tape',
    'filter',
    'box',
    'adapter',
    'coupling',
    'elbow',
    'tee',
    'cap',
    'plug',
    'pipe',
    'wire',
    'conduit',
    'cement',
    'primer',
    'valve',
    'fitting',
    'connector',
    'kit',
    'supply',
    'black',
    'white',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final aliasOwners = <String, List<WorkSupplyItem>>{};
    var checked = 0;

    final items = context.isFullProfile
        ? workSupplyCatalogItems
        : _sampledItems(
            workSupplyCatalogItems,
            limit: context.aliasSampleLimit,
          );
    for (final item in items) {
      for (final alias in item.aliases) {
        checked++;
        final normalized = _normalizeAlias(alias);
        if (normalized.isEmpty) continue;
        if (_tooGenericAliases.contains(normalized)) {
          failures.add(
            QaFailure(
              suite: name,
              id: 'generic_alias:${item.id}:$normalized',
              message: 'Alias is too generic to be trusted by itself.',
              severity: QaSeverity.warning,
              actual: '${item.name} -> $alias',
              suggestedFix:
                  'Move generic word into attribute tokens or require conflict rules.',
            ),
          );
        }
        aliasOwners.putIfAbsent(normalized, () => []).add(item);
      }
      for (final pattern in item.intelligence.receiptPatterns) {
        checked++;
        final normalized = _normalizeAlias(pattern);
        if (normalized.isEmpty) continue;
        aliasOwners.putIfAbsent(normalized, () => []).add(item);
      }
    }

    for (final entry in aliasOwners.entries) {
      final owners = entry.value;
      final unrelated = _unrelatedOwners(owners);
      if (unrelated.length <= 1) continue;
      failures.add(
        QaFailure(
          suite: name,
          id: 'cross_item_alias:${entry.key}',
          message: 'Alias maps to multiple unrelated catalog rows.',
          severity: QaSeverity.warning,
          expected: 'Alias must be unique or protected by conflict rules.',
          actual: unrelated.take(6).map((item) => item.path).join(' | '),
          suggestedFix:
              'Add negative-match/conflict metadata or make aliases more specific.',
        ),
      );
    }

    return timer.finish(
      suite: name,
      checked: checked,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'uniqueAliases': aliasOwners.length,
        'sampleLimit': context.isFullProfile ? 'all' : context.aliasSampleLimit,
        'profileItemCount': items.length,
      },
    );
  }
}

class WorkSupplyDangerousWordSuite extends QaSuite {
  const WorkSupplyDangerousWordSuite() : super('inventory.dangerous_words');

  static const _dangerousWords = [
    'PVC',
    'tape',
    'filter',
    'box',
    'adapter',
    'coupling',
    'elbow',
    'tee',
    'cap',
    'plug',
    'pipe',
    'wire',
    'conduit',
    'cement',
    'primer',
    'valve',
    'fitting',
    'connector',
    'kit',
    'supply',
    'black',
    'white',
  ];

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    if (!context.isFullProfile) {
      return timer.finish(
        suite: name,
        checked: _dangerousWords.length,
        failures: failures,
        maxFailures: context.maxFailuresPerSuite,
        metrics: {
          'mode': 'static-smoke',
          'note':
              'Full dangerous-word parser calls run in full/release profiles.',
        },
      );
    }
    for (final word in _dangerousWords) {
      final match = matchReceiptLineToCatalog(word, maxCandidates: 12);
      if (match == null) continue;
      if (match.confidence >= .82) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'forced_confident_generic:${word.toLowerCase()}',
            message: 'Dangerous generic word produced confident item match.',
            expected: 'unknown, ambiguous, or needs review',
            actual:
                '${match.item.path} / ${match.item.name} confidence=${match.confidence}',
            suggestedFix:
                'Lower confidence, return ranked ambiguity, or add conflict rule.',
          ),
        );
      }
    }
    return timer.finish(
      suite: name,
      checked: _dangerousWords.length,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
    );
  }
}

List<WorkSupplyItem> _sampledItems(
  List<WorkSupplyItem> items, {
  required int limit,
}) {
  if (items.length <= limit) return items;
  final sampled = <WorkSupplyItem>[];
  final step = (items.length / limit).ceil();
  for (
    var index = 0;
    index < items.length && sampled.length < limit;
    index += step
  ) {
    sampled.add(items[index]);
  }
  return sampled;
}

List<WorkSupplyItem> _unrelatedOwners(List<WorkSupplyItem> owners) {
  final byFamily = <String, WorkSupplyItem>{};
  for (final owner in owners) {
    byFamily[_canonicalKey([
          owner.trade,
          owner.category,
          owner.system,
          owner.itemType,
        ])] =
        owner;
  }
  return byFamily.values.toList(growable: false);
}

String _normalizeAlias(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9/\-\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String _canonicalKey(Iterable<String> parts) {
  return parts.map(_normalizeAlias).join('|');
}

void _requireText(
  List<QaFailure> failures,
  String value,
  String id,
  String message,
  WorkSupplyItem item,
) {
  _require(
    failures,
    value.trim().isNotEmpty,
    id: id,
    message: message,
    actual: item.id,
    fix: 'Fill required catalog identity field.',
  );
}

void _require(
  List<QaFailure> failures,
  bool condition, {
  required String id,
  required String message,
  required String actual,
  required String fix,
}) {
  if (condition) return;
  failures.add(
    QaFailure(
      suite: 'inventory.catalog_schema',
      id: id,
      message: message,
      actual: actual,
      suggestedFix: fix,
    ),
  );
}
