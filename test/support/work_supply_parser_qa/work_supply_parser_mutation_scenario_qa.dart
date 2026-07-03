import '../qa_harness/qa_harness.dart';

class WorkSupplyParserMutationScenarioSuite extends QaSuite {
  const WorkSupplyParserMutationScenarioSuite()
    : super('inventory.mutation_scenario_matrix');

  static const _requiredMutationTypes = {
    'alias_removed',
    'alias_too_generic',
    'size_extraction_shifted',
    'dangerous_word_overconfident',
    'confidence_threshold_loosened',
    'review_state_auto_confirmed',
    'receipt_noise_not_filtered',
    'merchant_normalization_disabled',
    'trade_context_overpowered',
    'negative_match_removed',
  };

  static const _scenarios = [
    _MutationScenario(
      id: 'alias_removed_known_receipt_phrase',
      mutationType: 'alias_removed',
      caughtBySuite: 'inventory.golden_fixtures',
      protectedFailure: 'known receipt phrase no longer matches item',
      severity: QaSeverity.error,
    ),
    _MutationScenario(
      id: 'alias_added_as_generic_pvc',
      mutationType: 'alias_too_generic',
      caughtBySuite: 'inventory.alias_conflicts',
      protectedFailure: 'generic alias creates broad false positives',
      severity: QaSeverity.error,
    ),
    _MutationScenario(
      id: 'half_inch_fraction_read_as_one_inch',
      mutationType: 'size_extraction_shifted',
      caughtBySuite: 'inventory.golden_fixtures',
      protectedFailure: 'size token maps to wrong canonical size',
      severity: QaSeverity.critical,
    ),
    _MutationScenario(
      id: 'pvc_single_word_confident_match',
      mutationType: 'dangerous_word_overconfident',
      caughtBySuite: 'inventory.dangerous_words',
      protectedFailure: 'dangerous word returns one confident item',
      severity: QaSeverity.critical,
    ),
    _MutationScenario(
      id: 'good_threshold_accepts_risky_lines',
      mutationType: 'confidence_threshold_loosened',
      caughtBySuite: 'inventory.confidence_calibration',
      protectedFailure: 'risky fixture crosses good threshold',
      severity: QaSeverity.error,
    ),
    _MutationScenario(
      id: 'parser_output_marked_confirmed',
      mutationType: 'review_state_auto_confirmed',
      caughtBySuite: 'inventory.review_safety_contract',
      protectedFailure: 'parser line bypasses human review',
      severity: QaSeverity.critical,
    ),
    _MutationScenario(
      id: 'subtotal_line_becomes_inventory',
      mutationType: 'receipt_noise_not_filtered',
      caughtBySuite: 'inventory.noise_lines',
      protectedFailure: 'receipt total/noise becomes an item candidate',
      severity: QaSeverity.error,
    ),
    _MutationScenario(
      id: 'home_depot_alias_not_normalized',
      mutationType: 'merchant_normalization_disabled',
      caughtBySuite: 'inventory.merchant_rules',
      protectedFailure: 'merchant rules lose store-specific context',
      severity: QaSeverity.warning,
    ),
    _MutationScenario(
      id: 'plumbing_context_hides_electrical_pvc',
      mutationType: 'trade_context_overpowered',
      caughtBySuite: 'inventory.trade_context',
      protectedFailure: 'context boost erases realistic ambiguity',
      severity: QaSeverity.critical,
    ),
    _MutationScenario(
      id: 'pvc_elbow_conflict_rule_removed',
      mutationType: 'negative_match_removed',
      caughtBySuite: 'inventory.separation_safety',
      protectedFailure: 'cross-trade PVC/conduit/fitting conflict collapses',
      severity: QaSeverity.critical,
    ),
  ];

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final scenarioIds = <String>{};
    final coveredTypes = <String>{};

    for (final scenario in _scenarios) {
      if (!scenarioIds.add(scenario.id)) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'duplicate_mutation_scenario:${scenario.id}',
            message: 'Mutation scenario IDs must be stable and unique.',
            expected: 'unique scenario ID',
            actual: scenario.id,
            suggestedFix:
                'Rename or merge duplicate mutation scenario definitions.',
            metadata: const {'triageCategory': QaFailureTriage.governance},
          ),
        );
      }
      coveredTypes.add(scenario.mutationType);
      if (!scenario.caughtBySuite.startsWith('inventory.')) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'invalid_mutation_owner:${scenario.id}',
            message: 'Mutation scenario must point to an inventory QA suite.',
            expected: 'inventory.* owner suite',
            actual: scenario.caughtBySuite,
            suggestedFix:
                'Route each mutation to the suite that should catch the injected fault.',
            metadata: const {'triageCategory': QaFailureTriage.governance},
          ),
        );
      }
      if (scenario.protectedFailure.trim().isEmpty) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'missing_protected_failure:${scenario.id}',
            message: 'Mutation scenario does not name the failure it protects.',
            expected: 'protected failure description',
            actual: 'empty',
            suggestedFix:
                'Name the bad parser behavior this mutation must prove catchable.',
            metadata: const {'triageCategory': QaFailureTriage.governance},
          ),
        );
      }
    }

    final missingTypes = _requiredMutationTypes.difference(coveredTypes);
    for (final type in missingTypes) {
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_mutation_type:$type',
          message:
              'Required mutation type is missing from the scenario matrix.',
          expected: type,
          actual: coveredTypes.join(', '),
          suggestedFix:
              'Add a named mutation scenario before claiming parser mutation coverage is complete.',
          metadata: const {'triageCategory': QaFailureTriage.governance},
        ),
      );
    }

    return timer.finish(
      suite: name,
      checked: _scenarios.length + _requiredMutationTypes.length,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'scenarioCount': _scenarios.length,
        'mutationTypes': coveredTypes.toList()..sort(),
        'parserCalls': 0,
      },
    );
  }
}

class _MutationScenario {
  const _MutationScenario({
    required this.id,
    required this.mutationType,
    required this.caughtBySuite,
    required this.protectedFailure,
    required this.severity,
  });

  final String id;
  final String mutationType;
  final String caughtBySuite;
  final String protectedFailure;
  final QaSeverity severity;
}
