import 'maintainiac_qa_case_registry.dart';
import 'maintainiac_qa_environment.dart';

class MaintainiacInventoryParserQaFamily {
  const MaintainiacInventoryParserQaFamily({
    required this.id,
    required this.label,
    required this.files,
    required this.riskTags,
    required this.command,
    this.releaseBlocker = true,
  });

  final String id;
  final String label;
  final List<String> files;
  final Set<String> riskTags;
  final String command;
  final bool releaseBlocker;

  List<String> validate() {
    final failures = <String>[];
    if (id.trim().isEmpty) failures.add('inventory parser family missing id');
    if (label.trim().isEmpty) failures.add('$id missing label');
    if (files.isEmpty) failures.add('$id missing QA files');
    if (riskTags.length < 2) failures.add('$id needs searchable risk tags');
    if (!command.startsWith('flutter test ')) {
      failures.add('$id needs focused flutter test command');
    }
    if (_mentionsLiveServices(command)) {
      failures.add('$id command must not use live services');
    }
    for (final file in files) {
      if (!file.startsWith('test/')) {
        failures.add('$id has non-test file $file');
      }
      if (!file.endsWith('.dart')) {
        failures.add('$id file must be a Dart QA file: $file');
      }
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'label': label,
      'files': files,
      'riskTags': riskTags.toList()..sort(),
      'command': command,
      'releaseBlocker': releaseBlocker,
    };
  }
}

class MaintainiacInventoryParserConsumerContract {
  const MaintainiacInventoryParserConsumerContract({
    required this.domain,
    required this.locale,
    required this.country,
    required this.releaseTrades,
    required this.packLevels,
    required this.families,
    required this.supportedResultUses,
    this.liveServicesAllowed = false,
    this.firebaseWritesAllowed = false,
    this.ocrCameraImplementationTouched = false,
  });

  final String domain;
  final String locale;
  final String country;
  final Set<String> releaseTrades;
  final Set<String> packLevels;
  final List<MaintainiacInventoryParserQaFamily> families;
  final Set<String> supportedResultUses;
  final bool liveServicesAllowed;
  final bool firebaseWritesAllowed;
  final bool ocrCameraImplementationTouched;

  static const requiredRiskTags = {
    'schema',
    'alias',
    'merchant',
    'dangerous-word',
    'ambiguity',
    'context',
    'security',
    'privacy',
    'performance',
    'governance',
    'regression',
    'locale',
    'spanish',
    'workflow',
    'sync',
    'financial',
    'source-of-truth',
    'pack-lifecycle',
    'vendor-sku',
    'device-storage',
  };

  static const requiredResultUses = {
    'inventory',
    'estimate_materials',
    'job_materials',
    'invoice_materials',
    'fleet_vehicle_inventory',
  };

  List<String> validate() {
    final failures = <String>[];
    if (domain != 'work_supply_inventory_parser') {
      failures.add('inventory consumer domain mismatch');
    }
    if (locale != 'en-US' && locale != 'es-US') {
      failures.add(
        'inventory consumer locale must be release-one US English or Spanish',
      );
    }
    if (country != 'US') failures.add('inventory consumer country must be US');
    if (!releaseTrades.containsAll({'plumbing', 'electrical', 'hvac'})) {
      failures.add('inventory consumer missing release-one trades');
    }
    if (!packLevels.containsAll({'core', 'standard'})) {
      failures.add('inventory consumer missing release-one pack levels');
    }
    if (liveServicesAllowed || firebaseWritesAllowed) {
      failures.add('inventory parser consumer QA must run offline only');
    }
    if (ocrCameraImplementationTouched) {
      failures.add(
        'inventory parser consumer must not touch OCR/camera implementation',
      );
    }
    if (!supportedResultUses.containsAll(requiredResultUses)) {
      failures.add('inventory consumer missing result-use routing coverage');
    }
    if (families.length < 12) {
      failures.add('inventory consumer needs broad QA family coverage');
    }

    final ids = <String>{};
    final tags = <String>{};
    final commands = <String>{};
    for (final family in families) {
      if (!ids.add(family.id)) {
        failures.add('duplicate inventory parser QA family ${family.id}');
      }
      commands.add(family.command);
      tags.addAll(family.riskTags);
      failures.addAll(family.validate());
    }
    if (commands.length < 8) {
      failures.add('inventory consumer needs surgical focused commands');
    }
    for (final tag in requiredRiskTags) {
      if (!tags.contains(tag)) {
        failures.add('inventory consumer missing required risk tag $tag');
      }
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'domain': domain,
      'locale': locale,
      'country': country,
      'releaseTrades': releaseTrades.toList()..sort(),
      'packLevels': packLevels.toList()..sort(),
      'familyCount': families.length,
      'releaseBlockerFamilies': families
          .where((family) => family.releaseBlocker)
          .length,
      'supportedResultUses': supportedResultUses.toList()..sort(),
      'liveServicesAllowed': liveServicesAllowed,
      'firebaseWritesAllowed': firebaseWritesAllowed,
      'ocrCameraImplementationTouched': ocrCameraImplementationTouched,
      'families': [for (final family in families) family.toJson()],
    };
  }
}

const maintainiacInventoryParserConsumerContract = MaintainiacInventoryParserConsumerContract(
  domain: 'work_supply_inventory_parser',
  locale: 'en-US',
  country: 'US',
  releaseTrades: {'plumbing', 'electrical', 'hvac'},
  packLevels: {'core', 'standard'},
  supportedResultUses: {
    'inventory',
    'estimate_materials',
    'job_materials',
    'invoice_materials',
    'fleet_vehicle_inventory',
  },
  families: [
    MaintainiacInventoryParserQaFamily(
      id: 'catalog_schema_metadata',
      label: 'Catalog identity, metadata, and source governance',
      files: [
        'test/support/work_supply_parser_qa/work_supply_parser_item_metadata_depth_qa.dart',
        'test/support/work_supply_parser_qa/work_supply_parser_data_provenance_qa.dart',
        'test/support/work_supply_parser_qa/work_supply_parser_governance_qa.dart',
      ],
      riskTags: {'schema', 'governance', 'source-of-truth'},
      command: 'flutter test test/work_supply_catalog_audit_test.dart',
    ),
    MaintainiacInventoryParserQaFamily(
      id: 'alias_vendor_sku',
      label: 'Alias, vendor, merchant, and SKU recognition',
      files: [
        'test/support/work_supply_parser_qa/work_supply_parser_vendor_sku_matrix_qa.dart',
        'test/support/work_supply_parser_qa/work_supply_parser_vendor_readiness_qa.dart',
        'test/support/work_supply_parser_qa/work_supply_parser_merchant_alias_normalization_qa.dart',
      ],
      riskTags: {'alias', 'merchant', 'vendor-sku'},
      command: 'flutter test test/work_supply_parser_vendor_qa_test.dart',
    ),
    MaintainiacInventoryParserQaFamily(
      id: 'dangerous_ambiguity_context',
      label:
          'Dangerous words, ambiguity, negative matches, and context ranking',
      files: [
        'test/support/work_supply_parser_qa/work_supply_parser_conflict_graph_qa.dart',
        'test/support/work_supply_parser_qa/work_supply_parser_context_qa.dart',
        'test/support/work_supply_parser_qa/work_supply_parser_ranked_candidate_qa.dart',
      ],
      riskTags: {'dangerous-word', 'ambiguity', 'context'},
      command: 'flutter test test/work_supply_parser_ambiguity_qa_test.dart',
    ),
    MaintainiacInventoryParserQaFamily(
      id: 'receipt_fixture_corpus',
      label: 'Golden receipt fixture corpus and holdout governance',
      files: [
        'test/support/work_supply_parser_qa/work_supply_parser_fixture_corpus_contract_qa.dart',
        'test/support/work_supply_parser_qa/work_supply_parser_holdout_fixture_qa.dart',
        'test/support/work_supply_parser_qa/work_supply_parser_fixture_expectation_qa.dart',
      ],
      riskTags: {'regression', 'governance', 'merchant'},
      command: 'flutter test test/work_supply_parser_fixture_corpus_test.dart',
    ),
    MaintainiacInventoryParserQaFamily(
      id: 'security_privacy_attack_surface',
      label: 'Input attack surface, privacy, and no-live-service boundaries',
      files: [
        'test/support/work_supply_parser_qa/work_supply_parser_input_attack_surface_qa.dart',
        'test/support/work_supply_parser_qa/work_supply_parser_security_qa.dart',
        'test/support/work_supply_parser_qa/work_supply_parser_fixture_privacy_qa.dart',
      ],
      riskTags: {'security', 'privacy', 'source-of-truth'},
      command: 'flutter test test/work_supply_parser_security_qa_test.dart',
    ),
    MaintainiacInventoryParserQaFamily(
      id: 'performance_scalability',
      label: 'Fast batch execution, search indexing, and large-catalog load',
      files: [
        'test/support/work_supply_parser_qa/work_supply_parser_runtime_profile_qa.dart',
        'test/support/work_supply_parser_qa/work_supply_parser_search_indexing_qa.dart',
        'test/support/work_supply_parser_qa/work_supply_parser_scalability_qa.dart',
      ],
      riskTags: {'performance', 'device-storage', 'pack-lifecycle'},
      command: 'flutter test test/work_supply_catalog_scale_test.dart',
    ),
    MaintainiacInventoryParserQaFamily(
      id: 'locale_spanish_release_one',
      label: 'US Spanish release-one language pack separation',
      files: [
        'test/support/work_supply_parser_qa/work_supply_parser_spanish_release_one_qa.dart',
        'test/support/work_supply_parser_qa/work_supply_parser_language_pack_separation_qa.dart',
        'test/support/work_supply_parser_qa/work_supply_parser_locale_qa.dart',
      ],
      riskTags: {'locale', 'spanish', 'alias'},
      command:
          'flutter test test/work_supply_parser_spanish_release_one_test.dart',
    ),
    MaintainiacInventoryParserQaFamily(
      id: 'workflow_routing',
      label: 'Inventory, estimate, job, invoice, and fleet routing',
      files: [
        'test/support/work_supply_parser_qa/work_supply_parser_workflow_routing_qa.dart',
        'test/support/work_supply_parser_qa/work_supply_parser_job_context_bridge_qa.dart',
        'test/support/work_supply_parser_qa/work_supply_parser_estimate_section_qa.dart',
      ],
      riskTags: {'workflow', 'context', 'source-of-truth'},
      command:
          'flutter test test/work_supply_parser_workflow_routing_test.dart',
    ),
    MaintainiacInventoryParserQaFamily(
      id: 'sync_authority',
      label: 'Hive authority, Firestore mirror, and import/export safety',
      files: [
        'test/support/work_supply_parser_qa/work_supply_parser_hive_authority_qa.dart',
        'test/support/work_supply_parser_qa/work_supply_parser_hive_firestore_sync_qa.dart',
        'test/support/work_supply_parser_qa/work_supply_parser_import_export_safety_qa.dart',
      ],
      riskTags: {'sync', 'source-of-truth', 'privacy'},
      command: 'flutter test test/work_supply_parser_sync_authority_test.dart',
    ),
    MaintainiacInventoryParserQaFamily(
      id: 'financial_math',
      label: 'Receipt totals, tax allocation, duplicate import, and line math',
      files: [
        'test/support/work_supply_parser_qa/work_supply_parser_price_tax_allocation_qa.dart',
        'test/support/work_supply_parser_qa/work_supply_parser_financial_duplicate_guard_qa.dart',
        'test/support/work_supply_parser_qa/work_supply_parser_math_qa.dart',
      ],
      riskTags: {'financial', 'regression', 'source-of-truth'},
      command: 'flutter test test/work_supply_parser_financial_qa_test.dart',
    ),
    MaintainiacInventoryParserQaFamily(
      id: 'pack_lifecycle_recovery',
      label:
          'Pack install, recovery, versioning, rollback, and chunk integrity',
      files: [
        'test/support/work_supply_parser_qa/work_supply_parser_pack_recovery_qa.dart',
        'test/support/work_supply_parser_qa/work_supply_parser_pack_version_regression_qa.dart',
        'test/support/work_supply_parser_qa/work_supply_parser_pack_integrity_recovery_qa.dart',
      ],
      riskTags: {'pack-lifecycle', 'regression', 'device-storage'},
      command:
          'flutter test test/work_supply_trade_pack_import_recovery_test.dart',
    ),
    MaintainiacInventoryParserQaFamily(
      id: 'generated_batch_runner',
      label: 'Generated fixture batch runner and surgical rerun safety',
      files: [
        'test/work_supply_parser_generated_fixture_runner_test.dart',
        'test/support/work_supply_parser_qa/work_supply_parser_surgical_rerun_qa.dart',
        'test/support/work_supply_parser_qa/work_supply_parser_generated_performance_qa.dart',
      ],
      riskTags: {'performance', 'regression', 'governance'},
      command:
          'flutter test test/work_supply_parser_generated_fixture_runner_test.dart',
    ),
    MaintainiacInventoryParserQaFamily(
      id: 'catalog_expansion_lifecycle',
      label:
          'Post-harness catalog expansion backlog, evidence, and promotion gates',
      files: [
        'test/support/work_supply_parser_qa/work_supply_parser_catalog_expansion_lifecycle_qa.dart',
        'test/support/work_supply_parser_qa/work_supply_parser_catalog_item_batch_generation_qa.dart',
        'test/support/work_supply_parser_qa/work_supply_parser_item_promotion_gate_qa.dart',
      ],
      riskTags: {
        'schema',
        'governance',
        'regression',
        'pack-lifecycle',
        'vendor-sku',
      },
      command:
          'flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.catalog_expansion_lifecycle_contract,qa.threshold_gate',
    ),
    MaintainiacInventoryParserQaFamily(
      id: 'real_receipt_validation_privacy',
      label: 'Private real receipt validation summaries and synthetic fixtures',
      files: [
        'test/support/work_supply_parser_qa/work_supply_parser_real_receipt_validation_qa.dart',
        'test/support/work_supply_parser_qa/work_supply_parser_fixture_privacy_qa.dart',
        'test/support/work_supply_parser_qa/work_supply_parser_legal_safety_qa.dart',
      ],
      riskTags: {'privacy', 'security', 'regression', 'governance'},
      command:
          'flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.real_receipt_validation_contract,qa.threshold_gate',
    ),
    MaintainiacInventoryParserQaFamily(
      id: 'portable_parser_core_boundary',
      label: 'Environment-independent parser core and adapter boundaries',
      files: [
        'test/support/work_supply_parser_qa/work_supply_parser_platform_contract_qa.dart',
        'test/support/work_supply_parser_qa/work_supply_parser_portability_qa.dart',
        'test/support/work_supply_parser_qa/work_supply_parser_boundary_qa.dart',
      ],
      riskTags: {
        'governance',
        'performance',
        'pack-lifecycle',
        'source-of-truth',
      },
      command:
          'flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.parser_platform_contract,inventory.portability_contract,inventory.boundary_guard,qa.threshold_gate',
    ),
  ],
);

const maintainiacInventoryParserConsumerCases = [
  MaintainiacQaCase(
    id: 'inventory_parser_consumer_contract',
    title: 'Inventory parser consumer is wired to the shared QA backbone',
    module: MaintainiacQaModule.inventory,
    priority: MaintainiacQaCasePriority.releaseBlocker,
    behavior:
        'Parser QA families are labeled, offline, focused, and release-one scoped.',
    evidenceTarget: 'maintainiac_inventory_parser_consumer_test',
    testCommand:
        'flutter test test/maintainiac_inventory_parser_consumer_test.dart',
    tags: {'inventory', 'parser', 'qa-backbone'},
  ),
];

bool _mentionsLiveServices(String command) {
  final normalized = command.toLowerCase();
  return normalized.contains('firebase') ||
      normalized.contains('firestore') ||
      normalized.contains('googlevision') ||
      normalized.contains('mlkit') ||
      normalized.contains('camera');
}
