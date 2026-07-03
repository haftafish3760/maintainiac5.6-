import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserRegistrySuite extends QaSuite {
  const WorkSupplyParserRegistrySuite() : super('inventory.harness_registry');

  static const _qaSourceDirectory = 'test/support/work_supply_parser_qa';
  static const _presetPath = 'test/support/qa_harness/qa_suite_presets.dart';
  static const _presetTestPath = 'test/qa_suite_presets_test.dart';
  static const _planPath = 'docs/inventory_parser_qa_harness_plan.md';

  static const _intentionallyTargetedSuites = {
    'inventory.dangerous_words',
    'inventory.generated_cases',
    'inventory.accumulated_coverage_contract',
    'inventory.admin_diagnostic_batch_contract',
    'inventory.admin_privacy_rollup_contract',
    'inventory.barcode_inventory_identity_contract',
    'inventory.batch_continuation_contract',
    'inventory.blueprint_contract',
    'inventory.blueprint_promotion_contract',
    'inventory.bulk_generation_pipeline_contract',
    'inventory.catalog_batch_manifest_contract',
    'inventory.catalog_batch_memory_contract',
    'inventory.catalog_family_rerun_contract',
    'inventory.catalog_item_batch_generation_contract',
    'inventory.category_inference_contract',
    'inventory.cloud_cost_guard_contract',
    'inventory.cloud_local_mode_contract',
    'inventory.delivery_policy_contract',
    'inventory.device_budget_matrix_contract',
    'inventory.differential_regression_contract',
    'inventory.duplicate_receipt_import_contract',
    'inventory.evidence_summary_contract',
    'inventory.failure_routing_contract',
    'inventory.file_size_contract',
    'inventory.financial_duplicate_guard_contract',
    'inventory.fixture_batch_plan_contract',
    'inventory.fixture_expectation_contract',
    'inventory.fixture_holdout_rotation_contract',
    'inventory.fixture_privacy_contract',
    'inventory.fleet_permission_context_contract',
    'inventory.gate_ledger_contract',
    'inventory.generated_artifact_manifest',
    'inventory.generated_fixture_cell_contract',
    'inventory.generator_pairing_contract',
    'inventory.hive_authority_contract',
    'inventory.hive_firestore_sync_contract',
    'inventory.human_correction_learning_contract',
    'inventory.import_export_safety_contract',
    'inventory.input_attack_surface_contract',
    'inventory.item_metadata_depth',
    'inventory.item_promotion_gate_contract',
    'inventory.job_context_bridge_contract',
    'inventory.language_pack_separation_contract',
    'inventory.master_coverage_matrix_contract',
    'inventory.merchant_alias_normalization_contract',
    'inventory.merchant_matrix_contract',
    'inventory.next_action_contract',
    'inventory.pack_integrity_recovery_contract',
    'inventory.pack_overlap_contract',
    'inventory.pack_scope_gate_contract',
    'inventory.pack_version_regression_contract',
    'inventory.pass_evidence_contract',
    'inventory.price_tax_allocation_contract',
    'inventory.product_normalization_contract',
    'inventory.receipt_invoice_feed_contract',
    'inventory.receipt_line_mapping_contract',
    'inventory.receipt_line_parser_fuzz_contract',
    'inventory.receipt_line_torture_contract',
    'inventory.receipt_source_immutability_contract',
    'inventory.recipe_completeness_contract',
    'inventory.registry_snapshot_contract',
    'inventory.regression_lock_contract',
    'inventory.release_one_cell_manifest',
    'inventory.release_one_command_manifest',
    'inventory.release_one_pack_balance',
    'inventory.release_one_residential_contract',
    'inventory.release_one_fastener_support_contract',
    'inventory.release_one_service_family_contract',
    'inventory.release_one_tier_role_contract',
    'inventory.search_indexing_contract',
    'inventory.service_truck_core_contract',
    'inventory.sku_collision_contract',
    'inventory.spanish_release_one',
    'inventory.surgical_rerun_contract',
    'inventory.vendor_readiness',
    'inventory.vendor_sku_matrix_contract',
    'inventory.workflow_routing',
    'qa.baseline_diff',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final registry = _readQaSources(failures);
    final presets = _read(_presetPath, failures);
    final presetTests = _read(_presetTestPath, failures);
    final plan = _read(_planPath, failures);

    final registeredSuites = _suiteNames(registry);
    final presetSuites = _suiteNames(presets);
    final presetTestSuites = _suiteNames(presetTests);
    final planSuites = _suiteNames(plan);
    final knownSuiteUniverse = {...registeredSuites, 'qa.threshold_gate'};

    for (final suite in presetSuites) {
      if (knownSuiteUniverse.contains(suite)) continue;
      failures.add(
        QaFailure(
          suite: name,
          id: 'preset_references_unknown_suite:$suite',
          message: 'A QA preset references a suite that is not registered.',
          expected: (knownSuiteUniverse.toList()..sort()).join(', '),
          actual: suite,
          suggestedFix:
              'Register the suite in buildWorkSupplyParserQaHarness or remove it from the preset.',
          metadata: const {'triageCategory': QaFailureTriage.governance},
        ),
      );
    }

    for (final suite in presetSuites) {
      if (presetTestSuites.contains(suite)) continue;
      failures.add(
        QaFailure(
          suite: name,
          id: 'preset_suite_missing_test_expectation:$suite',
          message: 'Preset suite is not covered by qa_suite_presets_test.',
          expected: suite,
          actual: 'not found in preset test',
          suggestedFix:
              'Add an explicit preset-test assertion so suite groups cannot drift silently.',
          metadata: const {'triageCategory': QaFailureTriage.governance},
        ),
      );
    }

    for (final suite in registeredSuites) {
      if (presetSuites.contains(suite) ||
          _intentionallyTargetedSuites.contains(suite)) {
        continue;
      }
      failures.add(
        QaFailure(
          suite: name,
          id: 'registered_suite_not_in_preset:$suite',
          message: 'Registered suite is not in any named preset.',
          expected: 'preset membership or targeted-suite exception',
          actual: suite,
          suggestedFix:
              'Add it to quick/fixtures/catalog, or explicitly mark it as targeted-only in the registry suite.',
          metadata: const {'triageCategory': QaFailureTriage.governance},
        ),
      );
    }

    for (final suite in registeredSuites) {
      if (planSuites.contains(suite) ||
          _intentionallyTargetedSuites.contains(suite)) {
        continue;
      }
      failures.add(
        QaFailure(
          suite: name,
          id: 'registered_suite_missing_plan_reference:$suite',
          message: 'Registered suite is not mentioned in the harness plan.',
          expected: suite,
          actual: 'not found in plan doc',
          suggestedFix:
              'Document the suite in docs/inventory_parser_qa_harness_plan.md.',
          metadata: const {'triageCategory': QaFailureTriage.governance},
        ),
      );
    }

    return timer.finish(
      suite: name,
      checked:
          registeredSuites.length +
          presetSuites.length +
          presetTestSuites.length +
          planSuites.length +
          4,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'registeredSuites': registeredSuites.toList()..sort(),
        'presetSuites': presetSuites.toList()..sort(),
        'presetTestSuites': presetTestSuites.toList()..sort(),
        'planSuites': planSuites.toList()..sort(),
        'targetedOnlySuites': _intentionallyTargetedSuites.toList()..sort(),
      },
    );
  }

  String _read(String path, List<QaFailure> failures) {
    final file = File(path);
    if (file.existsSync()) return file.readAsStringSync();
    failures.add(
      QaFailure(
        suite: name,
        id: 'missing_registry_scan_file:$path',
        message: 'Harness registry scan file is missing.',
        expected: path,
        actual: 'not found',
        suggestedFix: 'Update this suite if harness registry files move.',
        metadata: const {'triageCategory': QaFailureTriage.schema},
      ),
    );
    return '';
  }

  String _readQaSources(List<QaFailure> failures) {
    final directory = Directory(_qaSourceDirectory);
    if (!directory.existsSync()) {
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_registry_scan_directory:$_qaSourceDirectory',
          message: 'Harness registry scan directory is missing.',
          expected: _qaSourceDirectory,
          actual: 'not found',
          suggestedFix: 'Update this suite if harness source files move.',
          metadata: const {'triageCategory': QaFailureTriage.schema},
        ),
      );
      return '';
    }

    final buffer = StringBuffer();
    final files =
        directory
            .listSync(recursive: false)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))
            .toList()
          ..sort((left, right) => left.path.compareTo(right.path));
    for (final file in files) {
      buffer.writeln('// ${file.path}');
      buffer.writeln(file.readAsStringSync());
    }
    return buffer.toString();
  }

  Set<String> _suiteNames(String source) {
    final suites = <String>{};
    final pattern = RegExp(r'''['"`]((?:inventory|qa)\.[a-z0-9_]+)['"`]''');
    for (final match in pattern.allMatches(source)) {
      suites.add(match.group(1)!);
    }
    return suites;
  }
}
