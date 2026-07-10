import '../qa_harness/qa_harness.dart';

class WorkSupplyParserMutationFaultProbeSuite extends QaSuite {
  const WorkSupplyParserMutationFaultProbeSuite()
    : super('inventory.mutation_fault_probe');

  static const _probes = [
    _FaultProbe(
      id: 'alias_removed_probe',
      mutationType: 'alias_removed',
      ownerSuite: 'inventory.golden_fixtures',
      expectedFailureId: 'fixture expected parser candidate but got no match',
      severity: QaSeverity.error,
    ),
    _FaultProbe(
      id: 'alias_generic_probe',
      mutationType: 'alias_too_generic',
      ownerSuite: 'inventory.alias_conflicts',
      expectedFailureId: 'cross_item_alias',
      severity: QaSeverity.error,
    ),
    _FaultProbe(
      id: 'size_shift_probe',
      mutationType: 'size_extraction_shifted',
      ownerSuite: 'inventory.golden_fixtures',
      expectedFailureId: 'variant_wrong_item',
      severity: QaSeverity.critical,
    ),
    _FaultProbe(
      id: 'dangerous_word_confident_probe',
      mutationType: 'dangerous_word_overconfident',
      ownerSuite: 'inventory.dangerous_words',
      expectedFailureId: 'forced_confident_generic',
      severity: QaSeverity.critical,
    ),
    _FaultProbe(
      id: 'confidence_loosened_probe',
      mutationType: 'confidence_threshold_loosened',
      ownerSuite: 'inventory.confidence_calibration',
      expectedFailureId: 'risky_fixture_confidence_too_high',
      severity: QaSeverity.error,
    ),
    _FaultProbe(
      id: 'review_auto_confirmed_probe',
      mutationType: 'review_state_auto_confirmed',
      ownerSuite: 'inventory.review_safety_contract',
      expectedFailureId: 'review_status_allows_confirmed',
      severity: QaSeverity.critical,
    ),
    _FaultProbe(
      id: 'receipt_noise_probe',
      mutationType: 'receipt_noise_not_filtered',
      ownerSuite: 'inventory.noise_lines',
      expectedFailureId: 'noise_item_match',
      severity: QaSeverity.error,
    ),
    _FaultProbe(
      id: 'merchant_disabled_probe',
      mutationType: 'merchant_normalization_disabled',
      ownerSuite: 'inventory.merchant_rules',
      expectedFailureId: 'merchant_noise_item_match',
      severity: QaSeverity.warning,
    ),
    _FaultProbe(
      id: 'trade_context_overpowered_probe',
      mutationType: 'trade_context_overpowered',
      ownerSuite: 'inventory.trade_context',
      expectedFailureId: 'context_erased_ambiguity',
      severity: QaSeverity.critical,
    ),
    _FaultProbe(
      id: 'negative_match_removed_probe',
      mutationType: 'negative_match_removed',
      ownerSuite: 'inventory.conflict_graph',
      expectedFailureId: 'missing_conflict_warning',
      severity: QaSeverity.critical,
    ),
    _FaultProbe(
      id: 'copper_conflict_removed_probe',
      mutationType: 'negative_match_removed',
      ownerSuite: 'inventory.conflict_graph',
      expectedFailureId: 'conflict_missing_ranked_trade',
      severity: QaSeverity.critical,
    ),
    _FaultProbe(
      id: 'pvc_coupling_context_overpowered_probe',
      mutationType: 'trade_context_overpowered',
      ownerSuite: 'inventory.ranked_candidate_accuracy',
      expectedFailureId: 'ranked_context_erased_alternatives',
      severity: QaSeverity.critical,
    ),
  ];

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final probeIds = <String>{};
    final mutationTypes = <String>{};
    var blockingProbeCount = 0;

    for (final probe in _probes) {
      mutationTypes.add(probe.mutationType);
      if (!probeIds.add(probe.id)) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'duplicate_fault_probe:${probe.id}',
            message: 'Mutation fault probe id must be unique.',
            expected: 'unique fault probe id',
            actual: probe.id,
            metadata: const {'triageCategory': QaFailureTriage.governance},
          ),
        );
      }
      if (!probe.ownerSuite.startsWith('inventory.')) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'fault_probe_owner_not_inventory:${probe.id}',
            message: 'Mutation fault probe must target an inventory suite.',
            expected: 'inventory.* owner suite',
            actual: probe.ownerSuite,
            metadata: const {'triageCategory': QaFailureTriage.governance},
          ),
        );
      }
      final injected = probe.toInjectedFailure();
      if (injected.severity == QaSeverity.error ||
          injected.severity == QaSeverity.critical) {
        blockingProbeCount++;
      }
      if (injected.suite != probe.ownerSuite ||
          !injected.id.contains(probe.expectedFailureId)) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'fault_probe_not_catchable:${probe.id}',
            message:
                'Injected mutation fault does not map back to its expected owner-suite failure signature.',
            expected: '${probe.ownerSuite}:${probe.expectedFailureId}',
            actual: '${injected.suite}:${injected.id}',
            suggestedFix:
                'Keep every mutation probe tied to the suite/failure that must catch that bad parser behavior.',
            metadata: const {'triageCategory': QaFailureTriage.governance},
          ),
        );
      }
    }

    if (blockingProbeCount < 8) {
      failures.add(
        QaFailure(
          suite: name,
          id: 'insufficient_blocking_mutation_probes',
          message:
              'Mutation fault probes do not include enough blocking failure examples.',
          expected: 'at least 8 blocking probes',
          actual: '$blockingProbeCount',
          suggestedFix:
              'Most mutation families should map to error/critical failures so release gates catch them.',
          metadata: const {'triageCategory': QaFailureTriage.governance},
        ),
      );
    }

    return timer.finish(
      suite: name,
      checked: _probes.length + mutationTypes.length + 1,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'faultProbeCount': _probes.length,
        'blockingProbeCount': blockingProbeCount,
        'mutationTypes': mutationTypes.toList()..sort(),
        'injectedFailureOwners': [
          for (final probe in _probes) probe.ownerSuite,
        ],
        'catalogMutationAllowed': false,
        'firebaseWritesAllowed': false,
        'parserCalls': 0,
      },
    );
  }
}

class _FaultProbe {
  const _FaultProbe({
    required this.id,
    required this.mutationType,
    required this.ownerSuite,
    required this.expectedFailureId,
    required this.severity,
  });

  final String id;
  final String mutationType;
  final String ownerSuite;
  final String expectedFailureId;
  final QaSeverity severity;

  QaFailure toInjectedFailure() {
    return QaFailure(
      suite: ownerSuite,
      id: 'injected_mutation:$expectedFailureId:$id',
      message: 'Synthetic mutation probe for $mutationType.',
      severity: severity,
      expected: 'owner suite catches injected mutation',
      actual: mutationType,
      suggestedFix:
          'If this were a live mutation run, inspect the owner suite before accepting parser changes.',
      metadata: const {'triageCategory': QaFailureTriage.governance},
    );
  }
}
