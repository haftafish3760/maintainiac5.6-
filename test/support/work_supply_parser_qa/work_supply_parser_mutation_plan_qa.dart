import '../qa_harness/qa_harness.dart';

class WorkSupplyParserMutationDryRunPlanSuite extends QaSuite {
  const WorkSupplyParserMutationDryRunPlanSuite()
    : super('inventory.mutation_dry_run_plan');

  static const _mutationMode = String.fromEnvironment(
    'PARSER_QA_MUTATION_MODE',
  );
  static const _mutationScenarios = String.fromEnvironment(
    'PARSER_QA_MUTATION_SCENARIOS',
  );
  static const _mutationDryRun = bool.fromEnvironment(
    'PARSER_QA_MUTATION_DRY_RUN',
    defaultValue: true,
  );

  static const _artifactRoot = 'build/parser_qa_reports/mutations';

  static const _scenarios = [
    _MutationPlanScenario(
      id: 'alias_removed_known_receipt_phrase',
      mutationType: 'alias_removed',
      ownerSuite: 'inventory.golden_fixtures',
      artifactName: 'alias_removed_known_receipt_phrase.json',
    ),
    _MutationPlanScenario(
      id: 'alias_added_as_generic_pvc',
      mutationType: 'alias_too_generic',
      ownerSuite: 'inventory.alias_conflicts',
      artifactName: 'alias_added_as_generic_pvc.json',
    ),
    _MutationPlanScenario(
      id: 'half_inch_fraction_read_as_one_inch',
      mutationType: 'size_extraction_shifted',
      ownerSuite: 'inventory.golden_fixtures',
      artifactName: 'half_inch_fraction_read_as_one_inch.json',
    ),
    _MutationPlanScenario(
      id: 'pvc_single_word_confident_match',
      mutationType: 'dangerous_word_overconfident',
      ownerSuite: 'inventory.dangerous_words',
      artifactName: 'pvc_single_word_confident_match.json',
    ),
    _MutationPlanScenario(
      id: 'good_threshold_accepts_risky_lines',
      mutationType: 'confidence_threshold_loosened',
      ownerSuite: 'inventory.confidence_calibration',
      artifactName: 'good_threshold_accepts_risky_lines.json',
    ),
    _MutationPlanScenario(
      id: 'parser_output_marked_confirmed',
      mutationType: 'review_state_auto_confirmed',
      ownerSuite: 'inventory.review_safety_contract',
      artifactName: 'parser_output_marked_confirmed.json',
    ),
    _MutationPlanScenario(
      id: 'subtotal_line_becomes_inventory',
      mutationType: 'receipt_noise_not_filtered',
      ownerSuite: 'inventory.noise_lines',
      artifactName: 'subtotal_line_becomes_inventory.json',
    ),
    _MutationPlanScenario(
      id: 'home_depot_alias_not_normalized',
      mutationType: 'merchant_normalization_disabled',
      ownerSuite: 'inventory.merchant_rules',
      artifactName: 'home_depot_alias_not_normalized.json',
    ),
    _MutationPlanScenario(
      id: 'plumbing_context_hides_electrical_pvc',
      mutationType: 'trade_context_overpowered',
      ownerSuite: 'inventory.trade_context',
      artifactName: 'plumbing_context_hides_electrical_pvc.json',
    ),
    _MutationPlanScenario(
      id: 'pvc_elbow_conflict_rule_removed',
      mutationType: 'negative_match_removed',
      ownerSuite: 'inventory.separation_safety',
      artifactName: 'pvc_elbow_conflict_rule_removed.json',
    ),
  ];

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final byId = {for (final scenario in _scenarios) scenario.id: scenario};
    final requestedIds = _requestedScenarioIds();
    final selected = requestedIds.isEmpty
        ? const <_MutationPlanScenario>[]
        : [
            for (final id in requestedIds)
              if (byId[id] != null) byId[id]!,
          ];

    for (final id in requestedIds) {
      if (byId.containsKey(id)) continue;
      failures.add(
        QaFailure(
          suite: name,
          id: 'unknown_mutation_scenario:$id',
          message: 'Mutation dry-run requested an unknown scenario.',
          expected: byId.keys.join(', '),
          actual: id,
          suggestedFix:
              'Use a scenario id from the mutation scenario matrix before running mutation QA.',
          metadata: const {'triageCategory': QaFailureTriage.governance},
        ),
      );
    }

    if (_mutationMode.isNotEmpty && !_mutationDryRun && requestedIds.isEmpty) {
      failures.add(
        QaFailure(
          suite: name,
          id: 'mutation_requires_explicit_scenario_selection',
          message:
              'Non-dry-run mutation mode must require explicit scenario selection.',
          severity: QaSeverity.critical,
          expected: 'PARSER_QA_MUTATION_SCENARIOS is non-empty',
          actual: 'empty',
          suggestedFix:
              'Keep mutation sweeps scenario-filtered unless a separate approved release runner is added.',
          metadata: const {'triageCategory': QaFailureTriage.security},
        ),
      );
    }

    final artifactPaths = <String>[];
    for (final scenario in selected) {
      final path = scenario.artifactPath;
      artifactPaths.add(path);
      if (!path.startsWith('$_artifactRoot/')) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'mutation_artifact_not_local:${scenario.id}',
            message: 'Mutation artifact path is outside the local build area.',
            expected: '$_artifactRoot/<scenario>.json',
            actual: path,
            suggestedFix:
                'Write mutation artifacts only under ignored local build paths.',
            metadata: const {'triageCategory': QaFailureTriage.security},
          ),
        );
      }
      if (path.contains('..') || path.contains('\\')) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'mutation_artifact_path_unsafe:${scenario.id}',
            message: 'Mutation artifact path contains unsafe traversal syntax.',
            expected: 'normalized relative build path',
            actual: path,
            suggestedFix:
                'Use stable normalized artifact names generated from scenario ids.',
            metadata: const {'triageCategory': QaFailureTriage.security},
          ),
        );
      }
    }

    return timer.finish(
      suite: name,
      checked: _scenarios.length + requestedIds.length + selected.length + 2,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'mutationMode': _mutationMode,
        'mutationDryRun': _mutationDryRun,
        'requestedScenarioIds': requestedIds,
        'selectedScenarioIds': [for (final scenario in selected) scenario.id],
        'scenarioCount': _scenarios.length,
        'selectedScenarioCount': selected.length,
        'artifactRoot': _artifactRoot,
        'artifactPaths': artifactPaths,
        'localOnlyMutationArtifacts': true,
        'firebaseWritesAllowed': false,
        'networkAllowed': false,
        'catalogMutationAllowed': false,
        'parserCalls': 0,
      },
    );
  }

  List<String> _requestedScenarioIds() {
    return _mutationScenarios
        .split(',')
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
  }
}

class _MutationPlanScenario {
  const _MutationPlanScenario({
    required this.id,
    required this.mutationType,
    required this.ownerSuite,
    required this.artifactName,
  });

  final String id;
  final String mutationType;
  final String ownerSuite;
  final String artifactName;

  String get artifactPath =>
      'build/parser_qa_reports/mutations/$mutationType/$artifactName';
}
