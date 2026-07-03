class MaintainiacMutationGuardProbe {
  const MaintainiacMutationGuardProbe();

  static const sourceCollections = {
    'expenses',
    'trips',
    'inventory',
    'odometer',
    'receipts',
  };

  static const derivedCollections = {
    'recaps',
    'exports',
    'notifications',
    'estimates',
    'invoices',
    'reports',
  };

  List<String> validateDerivedOutputWrites({
    required String operation,
    required Iterable<String> writeTargets,
  }) {
    final failures = <String>[];
    for (final target in writeTargets) {
      final collection = _collectionFor(target);
      if (sourceCollections.contains(collection)) {
        failures.add('$operation mutated source collection $collection');
      }
    }
    return failures;
  }

  List<String> validateSourceOperationWrites({
    required String operation,
    required Iterable<String> writeTargets,
    required Set<String> allowedSourceCollections,
  }) {
    final failures = <String>[];
    for (final target in writeTargets) {
      final collection = _collectionFor(target);
      if (sourceCollections.contains(collection) &&
          !allowedSourceCollections.contains(collection)) {
        failures.add(
          '$operation wrote disallowed source collection $collection',
        );
      }
    }
    return failures;
  }

  bool isDerivedCollection(String target) {
    return derivedCollections.contains(_collectionFor(target));
  }

  String _collectionFor(String target) {
    final normalized = target.replaceAll('\\', '/');
    final parts = normalized
        .split('/')
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.single;
    return parts.length.isEven ? parts[parts.length - 2] : parts.last;
  }
}

class MaintainiacMutationGuardCase {
  const MaintainiacMutationGuardCase({
    required this.id,
    required this.operation,
    required this.writeTargets,
    required this.allowedSourceCollections,
    required this.derivedOnly,
    required this.expectedFailures,
    required this.reason,
  });

  final String id;
  final String operation;
  final Set<String> writeTargets;
  final Set<String> allowedSourceCollections;
  final bool derivedOnly;
  final Set<String> expectedFailures;
  final String reason;

  List<String> validate() {
    final failures = <String>[];
    if (id.trim().isEmpty) {
      failures.add('mutation guard case missing id');
    }
    if (operation.trim().isEmpty) {
      failures.add('$id missing operation');
    }
    if (writeTargets.isEmpty) {
      failures.add('$id missing write targets');
    }
    if (reason.trim().isEmpty) {
      failures.add('$id missing reason');
    }
    final probe = const MaintainiacMutationGuardProbe();
    final actual = derivedOnly
        ? probe.validateDerivedOutputWrites(
            operation: operation,
            writeTargets: writeTargets,
          )
        : probe.validateSourceOperationWrites(
            operation: operation,
            writeTargets: writeTargets,
            allowedSourceCollections: allowedSourceCollections,
          );
    if (actual.toSet().toString() != expectedFailures.toString()) {
      failures.add('$id expected failures do not match actual failures');
    }
    if (derivedOnly && allowedSourceCollections.isNotEmpty) {
      failures.add('$id derived-only case must not allow source collections');
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'operation': operation,
      'writeTargets': writeTargets.toList()..sort(),
      'allowedSourceCollections': allowedSourceCollections.toList()..sort(),
      'derivedOnly': derivedOnly,
      'expectedFailures': expectedFailures.toList()..sort(),
      'reason': reason,
    };
  }
}

class MaintainiacMutationGuardMatrix {
  const MaintainiacMutationGuardMatrix(this.cases);

  final List<MaintainiacMutationGuardCase> cases;

  List<String> validate() {
    final failures = <String>[];
    final ids = <String>{};
    var cleanCaseCount = 0;
    var failingCaseCount = 0;
    for (final entry in cases) {
      if (!ids.add(entry.id)) {
        failures.add('duplicate mutation guard case ${entry.id}');
      }
      if (entry.expectedFailures.isEmpty) {
        cleanCaseCount += 1;
      } else {
        failingCaseCount += 1;
      }
      failures.addAll(entry.validate());
    }
    if (cleanCaseCount == 0) {
      failures.add('mutation guard matrix missing clean case');
    }
    if (failingCaseCount == 0) {
      failures.add('mutation guard matrix missing failing case');
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'caseCount': cases.length,
      'cases': [for (final entry in cases) entry.toJson()],
    };
  }
}

const maintainiacMutationGuardMatrix = MaintainiacMutationGuardMatrix([
  MaintainiacMutationGuardCase(
    id: 'recap_writes_only_derived_outputs',
    operation: 'daily_recap',
    writeTargets: {
      'accounts/acct_1/recaps/day_2026_07_03',
      'accounts/acct_1/reports/report_1',
    },
    allowedSourceCollections: {},
    derivedOnly: true,
    expectedFailures: {},
    reason: 'Recap/report outputs must not mutate source records.',
  ),
  MaintainiacMutationGuardCase(
    id: 'export_mutating_expenses_blocked',
    operation: 'monthly_export',
    writeTargets: {
      'accounts/acct_1/exports/export_1',
      'accounts/acct_1/expenses/expense_1',
    },
    allowedSourceCollections: {},
    derivedOnly: true,
    expectedFailures: {'monthly_export mutated source collection expenses'},
    reason: 'Exports may write export artifacts only.',
  ),
  MaintainiacMutationGuardCase(
    id: 'confirm_expense_only_writes_expenses',
    operation: 'confirm_expense',
    writeTargets: {
      'accounts/acct_1/expenses/expense_1',
      'accounts/acct_1/inventory/item_1',
    },
    allowedSourceCollections: {'expenses'},
    derivedOnly: false,
    expectedFailures: {
      'confirm_expense wrote disallowed source collection inventory',
    },
    reason: 'Expense confirmation cannot mutate inventory as a side effect.',
  ),
]);
