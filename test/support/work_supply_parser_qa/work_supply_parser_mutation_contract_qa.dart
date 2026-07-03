import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserMutationContractSuite extends QaSuite {
  const WorkSupplyParserMutationContractSuite()
    : super('inventory.mutation_contract');

  static const _contracts = [
    _MutationContract(
      name: 'mutation_strategy_docs',
      path: 'docs/inventory_parser_qa_harness_plan.md',
      tokens: [
        'Mutation/fault-injection tests',
        'intentionally break aliases',
        'size extraction',
        'dangerous-word handling',
        'confidence thresholds',
        'review-state logic',
        'receipt-noise handling',
        'merchant context',
        'trade context',
      ],
    ),
    _MutationContract(
      name: 'alias_fault_target',
      path: 'test/support/work_supply_parser_qa/work_supply_parser_qa.dart',
      tokens: [
        'inventory.alias_conflicts',
        '_tooGenericAliases',
        'cross_item_alias',
        'negative-match/conflict metadata',
      ],
    ),
    _MutationContract(
      name: 'dangerous_word_fault_target',
      path: 'test/support/work_supply_parser_qa/work_supply_parser_qa.dart',
      tokens: [
        'inventory.dangerous_words',
        'forced_confident_generic',
        'Dangerous generic word',
        'unknown, ambiguous, or needs review',
      ],
    ),
    _MutationContract(
      name: 'confidence_threshold_fault_target',
      path:
          'test/support/work_supply_parser_qa/work_supply_parser_confidence_qa.dart',
      tokens: [
        'Good/Review/Poor confidence bands',
        'goodThreshold',
        'reviewThreshold',
        'risky or ambiguous lines must not cross the Good threshold',
      ],
    ),
    _MutationContract(
      name: 'review_state_fault_target',
      path:
          'test/support/work_supply_parser_qa/work_supply_parser_review_safety_qa.dart',
      tokens: [
        'inventory.review_safety_contract',
        '_requiredReviewStatuses',
        'review_status_allows_confirmed',
        'good_confidence_not_review_required',
      ],
    ),
    _MutationContract(
      name: 'receipt_noise_fault_target',
      path:
          'test/support/work_supply_parser_qa/work_supply_parser_noise_qa.dart',
      tokens: [
        'inventory.noise_lines',
        'noise_item_match',
        'Receipt noise produced an inventory item candidate.',
        'Filter receipt totals, payment, loyalty, auth, return, discount',
      ],
    ),
    _MutationContract(
      name: 'merchant_context_fault_target',
      path:
          'test/support/work_supply_parser_qa/work_supply_parser_merchant_qa.dart',
      tokens: [
        'inventory.merchant_rules',
        'merchant',
        'THE HOME DEPOT',
        'FERGUSON',
      ],
    ),
    _MutationContract(
      name: 'trade_context_fault_target',
      path:
          'test/support/work_supply_parser_qa/work_supply_parser_context_qa.dart',
      tokens: [
        'inventory.trade_context',
        'PVC EL 3/4',
        'Plumbing',
        'Electrical',
        'HVAC',
      ],
    ),
    _MutationContract(
      name: 'fault_probe_suite',
      path:
          'test/support/work_supply_parser_qa/work_supply_parser_mutation_fault_probe_qa.dart',
      tokens: [
        'inventory.mutation_fault_probe',
        'injected_mutation',
        'blockingProbeCount',
        'catalogMutationAllowed',
        'firebaseWritesAllowed',
      ],
    ),
  ];

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final present = <String>[];
    var checked = 0;

    for (final contract in _contracts) {
      checked += contract.tokens.length;
      final source = _read(contract.path, failures);
      final missing = [
        for (final token in contract.tokens)
          if (!source.contains(token)) token,
      ];
      if (missing.isEmpty) {
        present.add(contract.name);
        continue;
      }
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_mutation_contract:${contract.name}',
          message: 'Parser mutation/fault-injection contract is incomplete.',
          expected: '${contract.path}: ${contract.tokens.join(' + ')}',
          actual: 'missing ${missing.join(' + ')}',
          suggestedFix:
              'Keep mutation targets for aliases, dangerous words, confidence, review states, noise, merchant context, and trade context wired before bulk catalog expansion.',
          metadata: const {'triageCategory': QaFailureTriage.governance},
        ),
      );
    }

    return timer.finish(
      suite: name,
      checked: checked + _contracts.length,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'mutationTargetCount': _contracts.length,
        'presentMutationTargets': present,
        'parserCalls': 0,
      },
    );
  }

  String _read(String path, List<QaFailure> failures) {
    final file = File(path);
    if (file.existsSync()) return file.readAsStringSync();
    failures.add(
      QaFailure(
        suite: name,
        id: 'missing_mutation_contract_file:$path',
        message: 'Mutation contract scan file is missing.',
        expected: path,
        actual: 'not found',
        suggestedFix: 'Update this suite if mutation-target files move.',
        metadata: const {'triageCategory': QaFailureTriage.schema},
      ),
    );
    return '';
  }
}

class _MutationContract {
  const _MutationContract({
    required this.name,
    required this.path,
    required this.tokens,
  });

  final String name;
  final String path;
  final List<String> tokens;
}
