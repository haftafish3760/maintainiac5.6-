import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserGeneratedManifestSuite extends QaSuite {
  const WorkSupplyParserGeneratedManifestSuite()
    : super('inventory.generated_manifest_contract');

  static const _contracts = [
    _GeneratedManifestContract(
      name: 'golden_fixture_manifest',
      path:
          'test/support/work_supply_parser_qa/work_supply_parser_fixture_qa.dart',
      tokens: [
        'fixturePath',
        'fixtureCount',
        'test/fixtures/work_supply_parser/golden_fixtures.json',
      ],
    ),
    _GeneratedManifestContract(
      name: 'catalog_generated_manifest',
      path:
          'test/support/work_supply_parser_qa/work_supply_parser_fixture_qa.dart',
      tokens: [
        'requestedLimit',
        'generationSeed',
        'generatedCaseSource',
        'candidateMerchantPrefix',
        'tradeScope',
      ],
    ),
    _GeneratedManifestContract(
      name: 'metamorphic_variant_manifest',
      path:
          'test/support/work_supply_parser_qa/work_supply_parser_metamorphic_qa.dart',
      tokens: [
        'generationSeed',
        'variantKinds',
        'uniqueVariants',
        'parserCaseLimit',
      ],
    ),
    _GeneratedManifestContract(
      name: 'property_grammar_manifest',
      path:
          'test/support/work_supply_parser_qa/work_supply_parser_property_qa.dart',
      tokens: [
        'requestedLimit',
        'generationSeed',
        'grammarDimensions',
        'uniqueCases',
      ],
    ),
    _GeneratedManifestContract(
      name: 'fixture_generator_manifest',
      path: 'tool/work_supply_parser_qa_generate_fixtures.dart',
      tokens: [
        'generationSeed',
        'requestedLimit',
        'generatedCount',
        'sourceType',
        'synthetic',
        '_sourceModalityTag',
        'photo_ocr_text_after_extraction',
        'generic_unknown_merchant_receipt_text',
        'local_regional_supplier_receipt_text',
        'liveServicesAllowed',
        'firebaseWritesAllowed',
        'ocrCameraExpensesTouched',
        'tractor_supply_style',
        'northern_tool_style',
        'electrical_supply_house_style',
        'hvac_supply_house_style',
        'plumbing_supply_house_style',
        'regional_supplier_style',
        'counter_sale_style',
        'local_hardware_style',
      ],
    ),
    _GeneratedManifestContract(
      name: 'fixture_generator_recipes',
      path: 'tool/work_supply_parser_qa_fixture_recipes.dart',
      tokens: [
        'WorkSupplyFixtureRecipe',
        'englishPlumbingCoreRecipes',
        'spanishPlumbingCoreRecipes',
        'englishElectricalCoreRecipes',
        'spanishElectricalCoreRecipes',
        'englishHvacCoreRecipes',
        'spanishHvacCoreRecipes',
        'ambiguous_review',
      ],
    ),
    _GeneratedManifestContract(
      name: 'fixture_generator_executable_test',
      path: 'test/work_supply_parser_qa_fixture_generator_test.dart',
      tokens: [
        'QA_GENERATED_FIXTURES',
        'generated-not-release-approved',
        'localePackId',
        'parserCalls',
        '_sourceModalityRiskTags',
        'containsAll(_sourceModalityRiskTags)',
        'containsAll({',
        'Tractor Supply',
        'Northern Tool',
        'Electrical Supply House',
        'HVAC Supply House',
        'Plumbing Supply House',
      ],
    ),
    _GeneratedManifestContract(
      name: 'generated_fixture_runner',
      path: 'test/work_supply_parser_generated_fixture_runner_test.dart',
      tokens: [
        'PARSER_QA_GENERATED_FIXTURE_PATH',
        'PARSER_QA_GENERATED_FIXTURE_MAX_CASES',
        'QA_GENERATED_FIXTURE_RUN',
        'matchReceiptLineToCatalog',
        'semanticTimingExcludesWarmup',
        'PARSER_QA_GENERATED_REPORT_DIR',
        'latest_generated_fixture_run.json',
        'liveServicesAllowed',
      ],
    ),
    _GeneratedManifestContract(
      name: 'generated_fixture_dart_runner',
      path: 'tool/work_supply_parser_qa_run_generated_fixtures.dart',
      tokens: [
        'work_supply_parser_qa_run_generated_fixtures.dart',
        '--fixture',
        '--max-cases',
        '--fixture-ids',
        'QA_GENERATED_FIXTURE_RUN_WRAPPER',
        'parser_core_not_yet_extracted_for_dart_cli',
        'test/work_supply_parser_generated_fixture_runner_test.dart',
        'PARSER_QA_GENERATED_FIXTURE_PATH',
        'PARSER_QA_GENERATED_FIXTURE_MAX_CASES',
      ],
    ),
    _GeneratedManifestContract(
      name: 'catalog_blueprint_generator',
      path: 'tool/work_supply_catalog_blueprint_generator.dart',
      tokens: [
        'QA_CATALOG_BLUEPRINTS',
        'generationSeed',
        'promotionMode',
        'writesProductionCatalog',
        'liveServicesAllowed',
      ],
    ),
    _GeneratedManifestContract(
      name: 'catalog_blueprint_generator_test',
      path: 'test/work_supply_catalog_blueprint_generator_test.dart',
      tokens: [
        'manual-review-required',
        'synthetic-blueprint',
        'receiptPatterns',
        'negativeMatchTokens',
      ],
    ),
    _GeneratedManifestContract(
      name: 'catalog_blueprint_validator',
      path: 'tool/work_supply_catalog_blueprint_validate.dart',
      tokens: [
        'QA_CATALOG_BLUEPRINT_VALIDATION',
        'promotionAllowed',
        'liveServicesAllowed',
        "empty_\$field",
        'promotion_must_require_manual_review',
      ],
    ),
    _GeneratedManifestContract(
      name: 'catalog_blueprint_validator_test',
      path: 'test/work_supply_catalog_blueprint_validator_test.dart',
      tokens: [
        'QA_CATALOG_BLUEPRINT_VALIDATION',
        'empty_aliases',
        'generated_blueprint_cannot_be_verified',
        'promotion_must_require_manual_review',
      ],
    ),
    _GeneratedManifestContract(
      name: 'economical_pipeline',
      path: 'tool/work_supply_parser_qa_pipeline.dart',
      tokens: [
        'QA_ECONOMICAL_PIPELINE',
        'QA_ECONOMICAL_PIPELINE_MULTI_LOCALE',
        'runWorkSupplyCatalogBlueprintGenerator',
        'runWorkSupplyCatalogBlueprintValidator',
        'runWorkSupplyParserFixtureGenerator',
        'work_supply_parser_qa_run_generated_fixtures.dart',
        'writesProductionCatalog',
        'liveServicesAllowed',
        'QA_ECONOMICAL_PIPELINE_ARTIFACT',
        'QA_PIPELINE_RESUME',
        'fixtureRunLimit',
        'latest_pipeline_summary.json',
      ],
    ),
    _GeneratedManifestContract(
      name: 'economical_pipeline_artifacts',
      path: 'tool/work_supply_parser_qa_pipeline_artifacts.dart',
      tokens: [
        'writePipelineSummary',
        'latest_pipeline_summary.json',
        'PipelineArtifact',
        'timestampedJsonPath',
      ],
    ),
    _GeneratedManifestContract(
      name: 'economical_pipeline_test',
      path: 'test/work_supply_parser_qa_pipeline_test.dart',
      tokens: [
        'QA_ECONOMICAL_PIPELINE',
        'QA_ECONOMICAL_PIPELINE_MULTI_LOCALE',
        'QA_ECONOMICAL_PIPELINE_ARTIFACT',
        'QA_PIPELINE_RESUME',
        'fixtureRunLimit',
        'latest_pipeline_summary.json',
        'generate_catalog_blueprints',
        'validate_catalog_blueprints',
        'generate_parser_fixtures',
        'run_generated_parser_fixtures',
      ],
    ),
    _GeneratedManifestContract(
      name: 'economical_pipeline_status',
      path: 'tool/work_supply_parser_qa_pipeline_status.dart',
      tokens: [
        'QA_ECONOMICAL_PIPELINE_STATUS',
        'QA_ECONOMICAL_PIPELINE_STATUS_ARTIFACT',
        'expectedCells',
        'presentCells',
        'missingCells',
        'unsafeCells',
        'requireComplete',
        'liveServicesAllowed',
        'writesProductionCatalog',
        'latest_pipeline_status.json',
        'latest_pipeline_summary.json',
      ],
    ),
    _GeneratedManifestContract(
      name: 'economical_pipeline_status_test',
      path: 'test/work_supply_parser_qa_pipeline_status_test.dart',
      tokens: [
        'QA_ECONOMICAL_PIPELINE_STATUS',
        'QA_ECONOMICAL_PIPELINE_STATUS_ARTIFACT',
        'presentCells',
        'missingCells',
        'unsafeCells',
        'latest_pipeline_status.json',
        'require-complete',
        'localOnlySafe',
      ],
    ),
    _GeneratedManifestContract(
      name: 'economical_matrix_pipeline',
      path: 'tool/work_supply_parser_qa_matrix_pipeline.dart',
      tokens: [
        'QA_ECONOMICAL_MATRIX_PIPELINE',
        'QA_ECONOMICAL_MATRIX_PIPELINE_ARTIFACT',
        'runWorkSupplyParserQaPipeline',
        'runWorkSupplyParserQaPipelineStatus',
        'writePipelineSummary',
        'fixtureRunLimit',
        'firstRound',
        'runFixtures',
        'statusGate',
        'liveServicesAllowed',
        'writesProductionCatalog',
      ],
    ),
    _GeneratedManifestContract(
      name: 'economical_matrix_pipeline_test',
      path: 'test/work_supply_parser_qa_matrix_pipeline_test.dart',
      tokens: [
        'QA_ECONOMICAL_MATRIX_PIPELINE',
        'runFixtures',
        'run-fixtures',
        'fixtureRunLimit',
        'firstRound',
        'first-round',
        'require-complete',
        'status-gate',
        'presentCells',
        'missingCells',
        'unsafeCells',
      ],
    ),
    _GeneratedManifestContract(
      name: 'supported_matrix_reporter',
      path: 'tool/work_supply_parser_qa_supported_matrix.dart',
      tokens: [
        'QA_SUPPORTED_MATRIX',
        'supportedTrades',
        'supportedTiers',
        'unsupportedPolicy',
        'fail-before-writing-files',
        'liveServicesAllowed',
        'writesProductionCatalog',
      ],
    ),
    _GeneratedManifestContract(
      name: 'supported_matrix_reporter_test',
      path: 'test/work_supply_parser_qa_supported_matrix_test.dart',
      tokens: [
        'QA_SUPPORTED_MATRIX',
        'cellCount',
        'supportedTrades',
        'supportedTiers',
        'supportedLocales',
        'fail-before-writing-files',
      ],
    ),
    _GeneratedManifestContract(
      name: 'run_config_limit_manifest',
      path: 'test/support/qa_harness/qa_harness.dart',
      tokens: ['maxGeneratedCases', 'runConfig', 'suiteFilter'],
    ),
    _GeneratedManifestContract(
      name: 'artifact_report_metrics',
      path: 'test/support/qa_harness/qa_harness.dart',
      tokens: ['metrics', 'results', 'toJson'],
    ),
  ];

  static const _docContracts = [
    _GeneratedManifestDocContract('generated_case_manifest_docs', [
      'generated-case manifest',
      'generationSeed',
      'requestedLimit',
    ]),
    _GeneratedManifestDocContract('reproducible_batch_docs', [
      'reproduced',
      'PARSER_QA_MAX_GENERATED_CASES',
    ]),
  ];

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final cache = <String, String>{};
    final present = <String>[];
    var checked = 0;

    for (final contract in _contracts) {
      final source = _read(contract.path, failures, cache);
      checked += contract.tokens.length;
      final missing = [
        for (final token in contract.tokens)
          if (!_containsContractToken(source, token)) token,
      ];
      if (missing.isEmpty) {
        present.add(contract.name);
        continue;
      }
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_generated_manifest_contract:${contract.name}',
          message: 'Generated QA case manifest contract is missing.',
          severity: QaSeverity.error,
          expected: contract.tokens.join(' + '),
          actual: 'missing ${missing.join(' + ')}',
          suggestedFix:
              'Record generated-case source, seed, limits, and dimensions so parser QA failures can be reproduced.',
          metadata: const {'triageCategory': QaFailureTriage.governance},
        ),
      );
    }

    final plan = _read(
      'docs/inventory_parser_qa_harness_plan.md',
      failures,
      cache,
    );
    final presentDocs = <String>[];
    for (final doc in _docContracts) {
      checked++;
      if (doc.isPresentIn(plan)) {
        presentDocs.add(doc.name);
        continue;
      }
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_generated_manifest_doc:${doc.name}',
          message: 'Generated-case manifest is not documented.',
          severity: QaSeverity.warning,
          expected: doc.tokens.join(' + '),
          actual: 'not found',
          suggestedFix:
              'Document generated QA case provenance so large parser runs remain reproducible.',
          metadata: const {'triageCategory': QaFailureTriage.governance},
        ),
      );
    }

    return timer.finish(
      suite: name,
      checked: checked + cache.length,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'presentContracts': present,
        'presentDocs': presentDocs,
        'filesScanned': cache.keys.toList()..sort(),
      },
    );
  }

  String _read(
    String path,
    List<QaFailure> failures,
    Map<String, String> cache,
  ) {
    final cached = cache[path];
    if (cached != null) return cached;
    final file = File(path);
    if (!file.existsSync()) {
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_generated_manifest_file:$path',
          message: 'Generated manifest scan file is missing.',
          expected: path,
          actual: 'not found',
          suggestedFix: 'Update this suite if generated-case files move.',
          metadata: const {'triageCategory': QaFailureTriage.schema},
        ),
      );
      cache[path] = '';
      return '';
    }
    final source = file.readAsStringSync();
    cache[path] = source;
    return source;
  }
}

class _GeneratedManifestContract {
  const _GeneratedManifestContract({
    required this.name,
    required this.path,
    required this.tokens,
  });

  final String name;
  final String path;
  final List<String> tokens;
}

class _GeneratedManifestDocContract {
  const _GeneratedManifestDocContract(this.name, this.tokens);

  final String name;
  final List<String> tokens;

  bool isPresentIn(String source) {
    return tokens.every((token) => _containsContractToken(source, token));
  }
}

bool _containsContractToken(String source, String token) {
  return _normalizeContractText(source).contains(_normalizeContractText(token));
}

String _normalizeContractText(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}
