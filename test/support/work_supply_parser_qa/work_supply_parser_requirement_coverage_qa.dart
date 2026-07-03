import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserRequirementCoverageSuite extends QaSuite {
  const WorkSupplyParserRequirementCoverageSuite()
    : super('inventory.requirement_coverage');

  static const _planPath = 'docs/inventory_parser_qa_harness_plan.md';
  static const _qaSourceDirectory = 'test/support/work_supply_parser_qa';

  static const _requiredMatrixTokens = [
    'Requirement Coverage Matrix',
    'Requirement ID',
    'Owner suite',
    'Evidence',
  ];

  static const _requirements = [
    _RequirementCoverage('schema_identity', 'inventory.catalog_schema', [
      'stable ids',
      'canonical names',
      'parser metadata',
    ]),
    _RequirementCoverage(
      'catalog_release_scope',
      'inventory.catalog_coverage',
      ['trade counts', 'market-scope/pack-tier matrix'],
    ),
    _RequirementCoverage('blueprint_contract', 'inventory.blueprint_contract', [
      'bulk item fields',
      'manual review promotion',
      'local-only generation',
    ]),
    _RequirementCoverage(
      'blueprint_promotion',
      'inventory.blueprint_promotion_contract',
      ['manual review required', 'no production writes', 'no live services'],
    ),
    _RequirementCoverage(
      'generator_pairing',
      'inventory.generator_pairing_contract',
      ['shared matrix dimensions', 'shared manifests', 'catalog plus fixture'],
    ),
    _RequirementCoverage(
      'accumulated_coverage',
      'inventory.accumulated_coverage_contract',
      ['catalog batch cell', 'fixture batch cell', 'priority cells'],
    ),
    _RequirementCoverage(
      'cloud_cost_guard',
      'inventory.cloud_cost_guard_contract',
      ['no live Firebase', 'cost flags', 'local-only QA'],
    ),
    _RequirementCoverage(
      'delivery_policy',
      'inventory.delivery_policy_contract',
      ['local packs', 'cloud fallback', '100-read budget'],
    ),
    _RequirementCoverage(
      'release_one_cell_manifest',
      'inventory.release_one_cell_manifest',
      ['priority cells', 'en-US', 'es-US'],
    ),
    _RequirementCoverage(
      'release_one_command_manifest',
      'inventory.release_one_command_manifest',
      ['dry-run commands', 'priority cells', 'safe execution flags'],
    ),
    _RequirementCoverage(
      'generated_artifact_manifest',
      'inventory.generated_artifact_manifest',
      [
        'release-one commands artifact',
        'pass evidence artifact',
        'safety flags',
      ],
    ),
    _RequirementCoverage(
      'evidence_summary',
      'inventory.evidence_summary_contract',
      ['missing artifacts', 'unsafe findings', 'local-only summary'],
    ),
    _RequirementCoverage('next_action', 'inventory.next_action_contract', [
      'readyForNextBatch',
      'release-one cells',
      'missing/unsafe blockers',
      'active wave blockers',
      'active wave unsafe findings',
      'corrupt artifact blockers',
      'stale active wave blockers',
      'failed active wave blockers',
    ]),
    _RequirementCoverage(
      'domain_adapter',
      'inventory.category_reuse_contract',
      ['parser-domain adapters', 'maintenance parser', 'forbidden boundaries'],
    ),
    _RequirementCoverage('gate_ledger', 'inventory.gate_ledger_contract', [
      'gate',
      'command',
      'inputCount',
      'fingerprint',
      'should-run checker',
    ]),
    _RequirementCoverage(
      'registry_snapshot',
      'inventory.registry_snapshot_contract',
      ['registeredSuiteCount', 'artifactPresence', 'latestPassEvidence'],
    ),
    _RequirementCoverage(
      'fixture_batch_plan',
      'inventory.fixture_batch_plan_contract',
      [
        'generateFixturesCommand',
        'runParserCommand',
        'generatedFixtureCount',
        'residential',
      ],
    ),
    _RequirementCoverage(
      'batch_continuation',
      'inventory.batch_continuation_contract',
      ['resume', 'accumulated waves', 'local-only continuation'],
    ),
    _RequirementCoverage('pass_evidence', 'inventory.pass_evidence_contract', [
      'wave summary',
      'numbered pass evidence',
      'scope evidence',
      'local-only safety flags',
    ]),
    _RequirementCoverage('qa_file_size', 'inventory.file_size_contract', [
      '500-line preferred',
      '1000-line hard',
      'split-by-responsibility',
    ]),
    _RequirementCoverage(
      'fixture_expectation',
      'inventory.fixture_expectation_contract',
      ['expected status', 'expected candidate', 'expected review flag'],
    ),
    _RequirementCoverage(
      'fixture_candidate_identity',
      'inventory.fixture_candidate_identity_contract',
      ['semantic candidate key', 'expected trade', 'expected name hint'],
    ),
    _RequirementCoverage(
      'fixture_privacy',
      'inventory.fixture_privacy_contract',
      ['no private raw lines', 'card/email/phone/address guards'],
    ),
    _RequirementCoverage(
      'recipe_completeness',
      'inventory.recipe_completeness_contract',
      ['English recipes', 'Spanish recipes', 'Core/Standard priority cells'],
    ),
    _RequirementCoverage(
      'service_truck_core',
      'inventory.service_truck_core_contract',
      ['everydayCore priority', 'service-truck signals', 'Core tier focus'],
    ),
    _RequirementCoverage(
      'release_one_pack_balance',
      'inventory.release_one_pack_balance',
      ['Core service-truck focus', 'tier expansion sanity'],
    ),
    _RequirementCoverage(
      'item_metadata_depth',
      'inventory.item_metadata_depth',
      ['receipt patterns', 'negative-match guards', 'output classification'],
    ),
    _RequirementCoverage('vendor_readiness', 'inventory.vendor_readiness', [
      'vendor mappings',
      'merchant-style receipt patterns',
      'SKU/part-number pattern slots',
    ]),
    _RequirementCoverage('workflow_routing', 'inventory.workflow_routing', [
      'inventory/job/estimate/invoice routing',
      'tax reporting',
      'markup behavior',
    ]),
    _RequirementCoverage(
      'spanish_release_one',
      'inventory.spanish_release_one',
      ['es-US aliases', 'Spanish receipt patterns', 'Spanish unit variants'],
    ),
    _RequirementCoverage('alias_conflicts', 'inventory.alias_conflicts', [
      'duplicate aliases',
      'cross-trade alias collisions',
    ]),
    _RequirementCoverage('dangerous_words', 'inventory.dangerous_words', [
      'generic words',
      'confident single-item matches',
    ]),
    _RequirementCoverage('golden_fixtures', 'inventory.golden_fixtures', [
      'fixture-driven parser expectations',
    ]),
    _RequirementCoverage('generated_cases', 'inventory.generated_cases', [
      'data-driven catalog receipt lines',
    ]),
    _RequirementCoverage('security_privacy', 'inventory.security_privacy', [
      'redaction',
      'hostile receipt-like strings',
      'huge_input',
      'unicode_control',
      'path_like',
      'injection_like',
      'long_token',
      'ocr_dirty_text',
    ]),
    _RequirementCoverage('boundary_guard', 'inventory.boundary_guard', [
      'forbidden Firebase',
      'OCR',
    ]),
    _RequirementCoverage(
      'no_live_services',
      'inventory.no_live_services_contract',
      ['local-only parser QA', 'separately approved'],
    ),
    _RequirementCoverage('review_safety', 'inventory.review_safety_contract', [
      'auto-accept/autosave',
      'parser review evidence',
    ]),
    _RequirementCoverage('result_contract', 'inventory.result_contract', [
      'possible matches',
      'suggested inventory action',
    ]),
    _RequirementCoverage(
      'evidence_attribution',
      'inventory.evidence_attribution',
      ['raw receipt evidence', 'per-field source attribution'],
    ),
    _RequirementCoverage('pack_lifecycle', 'inventory.pack_lifecycle', [
      'chunk checksums',
      'rollback',
    ]),
    _RequirementCoverage('pack_recovery', 'inventory.pack_recovery_contract', [
      'corrupt pack',
      'interrupted download',
      'missing locale pack',
    ]),
    _RequirementCoverage('pack_health', 'inventory.pack_health_score', [
      'health score',
      'readiness label',
    ]),
    _RequirementCoverage('scalability', 'inventory.scalability', [
      'throughput budgets',
      'full-scan debt',
    ]),
    _RequirementCoverage(
      'runtime_profile',
      'inventory.runtime_profile_contract',
      ['smoke profile', 'full/release profiles'],
    ),
    _RequirementCoverage(
      'runtime_measurement',
      'inventory.runtime_measurement',
      ['coldStartMs', 'warmCacheMs'],
    ),
    _RequirementCoverage(
      'generated_manifest',
      'inventory.generated_manifest_contract',
      ['generationSeed', 'requestedLimit'],
    ),
    _RequirementCoverage(
      'failure_taxonomy',
      'inventory.failure_taxonomy_contract',
      ['triage category', 'QA_TRIAGE_GROUP'],
    ),
    _RequirementCoverage('fixture_governance', 'inventory.fixture_governance', [
      'Fixture governance suite',
    ]),
    _RequirementCoverage(
      'fixture_coverage',
      'inventory.fixture_coverage_matrix',
      [
        'required case types',
        'merchant coverage',
        'Menards',
        'True Value',
        'Walmart',
        'Supply House',
        'return_line',
        'discount_line',
        'canadian_format',
        'mixed_trade_receipt',
      ],
    ),
    _RequirementCoverage(
      'fixture_corpus',
      'inventory.fixture_corpus_contract',
      ['privacy-safe', 'release-one merchant/locale'],
    ),
    _RequirementCoverage(
      'holdout_fixture_contract',
      'inventory.holdout_fixture_contract',
      [
        'holdoutOnly',
        'releaseOnlySemanticUse',
        'holdout_raw_line_also_in_golden',
      ],
    ),
    _RequirementCoverage(
      'changed_item_impact',
      'inventory.changed_item_impact',
      [
        'Changed-item impact suite',
        'oldNewRankedCandidateComparisons',
        'impact_ranked_candidate_changed',
      ],
    ),
    _RequirementCoverage('determinism', 'inventory.determinism', [
      'identical parser inputs',
      'changes between runs',
    ]),
    _RequirementCoverage(
      'metamorphic_variants',
      'inventory.metamorphic_variants',
      [
        'case, spacing, punctuation',
        'pluralized_family',
        'unit_order_size_last',
        'pack_count_prefix',
        'merchant_prefix_home_depot',
        'locale_decimal_price_suffix',
      ],
    ),
    _RequirementCoverage('property_cases', 'inventory.property_cases', [
      'generated risky receipt-line families',
      'trade_context',
      'merchant_context',
      'locale',
      'package_quantity',
      'return_line',
      'discount_line',
      'tax_line',
      'mixed_trade_job',
    ]),
    _RequirementCoverage('separation_safety', 'inventory.separation_safety', [
      'SKU/part-number',
      'cross-trade lines',
    ]),
    _RequirementCoverage('conflict_graph', 'inventory.conflict_graph', [
      'Negative-match/conflict graph',
      'ranked alternatives',
    ]),
    _RequirementCoverage(
      'ranked_candidate_accuracy',
      'inventory.ranked_candidate_accuracy',
      ['top-3', 'top-5'],
    ),
    _RequirementCoverage('trade_context', 'inventory.trade_context', [
      'ambiguous mixed-trade lines',
    ]),
    _RequirementCoverage('merchant_rules', 'inventory.merchant_rules', [
      'major merchant alias normalization',
    ]),
    _RequirementCoverage('receipt_noise', 'inventory.noise_lines', [
      'subtotal, tax, payment',
    ]),
    _RequirementCoverage('accuracy_budget', 'inventory.accuracy_budget', [
      'top-1 clear-match accuracy',
      'false-confident rate',
    ]),
    _RequirementCoverage('economics', 'inventory.economics_contract', [
      'quantity/price fixtures',
    ]),
    _RequirementCoverage(
      'estimate_section_ranking',
      'inventory.estimate_section_ranking',
      ['active estimate sections', 'no auto-save'],
    ),
    _RequirementCoverage('confidence', 'inventory.confidence_calibration', [
      'Good/Review/Poor confidence bands',
    ]),
    _RequirementCoverage('math', 'inventory.math_reconciliation', [
      'total units',
      'unit cost',
    ]),
    _RequirementCoverage('locale', 'inventory.locale_contract', [
      'US Spanish',
      'language packs',
    ]),
    _RequirementCoverage('telemetry', 'inventory.telemetry_contract', [
      'admin-safe contract',
      'no raw receipt content',
    ]),
    _RequirementCoverage(
      'device_storage',
      'inventory.device_storage_contract',
      ['older-phone parser limits', 'not-enough-storage'],
    ),
    _RequirementCoverage(
      'correction_feedback',
      'inventory.correction_feedback_contract',
      ['user parser corrections', 'manual promotion'],
    ),
    _RequirementCoverage('release_manifest', 'inventory.release_manifest', [
      'release readiness',
      'zero-failure release budgets',
    ]),
    _RequirementCoverage(
      'release_orchestration',
      'inventory.release_orchestration_contract',
      ['release shard strategy', 'full-profile timeout guard'],
    ),
    _RequirementCoverage(
      'release_shard_manifest',
      'inventory.release_shard_manifest',
      [
        'PARSER_QA_SHARD_ID',
        'PARSER_QA_TIMEOUT_BUDGET_MS',
        'PARSER_QA_RESUME_FROM',
        'resume evidence',
      ],
    ),
    _RequirementCoverage(
      'release_signoff_manifest',
      'inventory.release_signoff_manifest',
      ['QA_RELEASE_SIGNOFF', 'missing_expected_shard', 'profile_mismatch'],
    ),
    _RequirementCoverage('harness_registry', 'inventory.harness_registry', [
      'registered suite ids',
    ]),
    _RequirementCoverage('known_debt', 'inventory.known_debt_ledger', [
      'Known Debt Ledger',
    ]),
    _RequirementCoverage('artifact_contract', 'inventory.artifact_contract', [
      'timestamped/latest JSON',
      'pack-health artifacts',
      '[REDACTED_CARD_LAST4]',
      '[REDACTED_PRIVATE_FIELD]',
    ]),
    _RequirementCoverage(
      'artifact_retention',
      'inventory.artifact_retention_contract',
      ['timestamped report', 'latest alias'],
    ),
    _RequirementCoverage(
      'admin_report_contract',
      'inventory.admin_report_contract',
      [
        'admin-safe report',
        'Command One diagnostics',
        '[REDACTED_CARD_LAST4]',
        '[REDACTED_PRIVATE_FIELD]',
      ],
    ),
    _RequirementCoverage(
      'execution_command',
      'inventory.execution_command_contract',
      ['PARSER_QA_PRESET', 'PARSER_QA_SUITES', 'PARSER_QA_BASELINE'],
    ),
    _RequirementCoverage(
      'portability_contract',
      'inventory.portability_contract',
      ['Windows', 'Mac Mini', 'external SSD', 'GitHub'],
    ),
    _RequirementCoverage(
      'harness_maintainability',
      'inventory.harness_maintainability_contract',
      ['500-line preferred', '1000-line hard ceiling'],
    ),
    _RequirementCoverage(
      'parser_platform',
      'inventory.parser_platform_contract',
      [
        'environment-independent parser core',
        'pure parser input',
        'pure parser output',
        'mobile adapter',
        'server adapter',
        'QA harness adapter',
        'batch parser adapter',
        'review-only parser result',
        'Merchant rule packs',
        'Release gates',
      ],
    ),
    _RequirementCoverage(
      'category_reuse',
      'inventory.category_reuse_contract',
      ['Maintenance', 'Do not duplicate the whole harness'],
    ),
    _RequirementCoverage(
      'data_provenance',
      'inventory.data_provenance_contract',
      ['Ground-truth dataset governance', 'synthetic/real flag'],
    ),
    _RequirementCoverage('legal_safety', 'inventory.legal_safety_contract', [
      'Legal and proprietary-data safety',
      'No full private receipts',
    ]),
    _RequirementCoverage(
      'validation_strategy',
      'inventory.validation_strategy_contract',
      ['Independent validation set', 'holdout fixture set'],
    ),
    _RequirementCoverage('slo_metrics', 'inventory.slo_metrics_contract', [
      'Parser SLO and quality metrics',
      'false-confident rate',
    ]),
    _RequirementCoverage('mutation_contract', 'inventory.mutation_contract', [
      'Mutation/fault-injection tests',
      'intentionally break aliases',
    ]),
    _RequirementCoverage(
      'mutation_scenario_matrix',
      'inventory.mutation_scenario_matrix',
      ['alias_removed', 'trade_context_overpowered'],
    ),
    _RequirementCoverage(
      'mutation_dry_run_plan',
      'inventory.mutation_dry_run_plan',
      [
        'localOnlyMutationArtifacts',
        'firebaseWritesAllowed',
        'mutation_requires_explicit_scenario_selection',
      ],
    ),
    _RequirementCoverage(
      'mutation_fault_probe',
      'inventory.mutation_fault_probe',
      [
        'injected_mutation',
        'blockingProbeCount',
        'catalogMutationAllowed',
        'firebaseWritesAllowed',
      ],
    ),
    _RequirementCoverage(
      'mutation_runner_contract',
      'inventory.mutation_runner_contract',
      ['PARSER_QA_MUTATION_MODE', 'dry-run by default'],
    ),
    _RequirementCoverage(
      'requirement_coverage',
      'inventory.requirement_coverage',
      ['Requirement Coverage Matrix'],
    ),
    _RequirementCoverage('profile_matrix', 'inventory.profile_matrix', [
      'smoke/full/release profile budgets',
      'strict mode',
    ]),
    _RequirementCoverage('baseline_contract', 'inventory.baseline_contract', [
      'baseline diff wiring',
      'severity regression',
      'failure_id_added:',
    ]),
  ];

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final plan = _read(_planPath, failures);
    final registry = _readQaSources(failures);
    final registeredSuites = _suiteNames(registry);
    final present = <String>[];

    for (final token in _requiredMatrixTokens) {
      if (plan.contains(token)) {
        present.add(token);
        continue;
      }
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_requirement_matrix_token:$token',
          message: 'Requirement coverage matrix is missing a required heading.',
          expected: token,
          actual: 'not found',
          suggestedFix:
              'Document requirement ownership so world-class QA promises do not drift.',
          metadata: const {'triageCategory': QaFailureTriage.governance},
        ),
      );
    }

    for (final requirement in _requirements) {
      if (!registeredSuites.contains(requirement.ownerSuite)) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'requirement_owner_not_registered:${requirement.id}',
            message: 'Requirement owner suite is not registered.',
            expected: requirement.ownerSuite,
            actual: registeredSuites.join(', '),
            suggestedFix:
                'Register the owner suite before claiming this requirement is covered.',
            metadata: const {'triageCategory': QaFailureTriage.governance},
          ),
        );
      }

      final hasRow =
          plan.contains(requirement.id) &&
          plan.contains(requirement.ownerSuite);
      final hasEvidence = requirement.tokens.every(plan.contains);
      if (hasRow && hasEvidence) {
        present.add(requirement.id);
        continue;
      }
      failures.add(
        QaFailure(
          suite: name,
          id: 'requirement_missing_coverage_row:${requirement.id}',
          message: 'Requirement is missing documented suite ownership.',
          expected:
              '${requirement.ownerSuite} with ${requirement.tokens.join(' + ')}',
          actual: hasRow ? 'row found without evidence tokens' : 'row missing',
          suggestedFix:
              'Add or update the requirement coverage matrix row with owner suite and evidence.',
          metadata: const {'triageCategory': QaFailureTriage.governance},
        ),
      );
    }

    return timer.finish(
      suite: name,
      checked: _requiredMatrixTokens.length + _requirements.length,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'requirementCount': _requirements.length,
        'presentCoverage': present,
      },
    );
  }

  String _read(String path, List<QaFailure> failures) {
    final file = File(path);
    if (file.existsSync()) return file.readAsStringSync();
    failures.add(
      QaFailure(
        suite: name,
        id: 'missing_requirement_coverage_file:$path',
        message: 'Requirement coverage scan file is missing.',
        expected: path,
        actual: 'not found',
        suggestedFix: 'Update the requirement coverage suite if files move.',
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
          id: 'missing_requirement_coverage_directory:$_qaSourceDirectory',
          message: 'Requirement coverage source directory is missing.',
          expected: _qaSourceDirectory,
          actual: 'not found',
          suggestedFix: 'Update this suite if inventory QA source files move.',
          metadata: const {'triageCategory': QaFailureTriage.schema},
        ),
      );
      return '';
    }
    final files =
        directory
            .listSync(recursive: false)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))
            .toList()
          ..sort((left, right) => left.path.compareTo(right.path));
    final buffer = StringBuffer();
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

class _RequirementCoverage {
  const _RequirementCoverage(this.id, this.ownerSuite, this.tokens);

  final String id;
  final String ownerSuite;
  final List<String> tokens;
}
