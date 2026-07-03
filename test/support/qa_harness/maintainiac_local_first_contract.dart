enum MaintainiacWriteTarget { localHive, firestoreMirror, derivedOutput }

class MaintainiacWriteStep {
  const MaintainiacWriteStep({
    required this.order,
    required this.target,
    required this.collection,
    required this.recordId,
    required this.sourceOperation,
    this.mirrorOnly = false,
    this.mutatesSource = false,
  });

  final int order;
  final MaintainiacWriteTarget target;
  final String collection;
  final String recordId;
  final String sourceOperation;
  final bool mirrorOnly;
  final bool mutatesSource;

  List<String> validate() {
    final failures = <String>[];
    if (order < 0) failures.add('write step order must be non-negative');
    if (collection.trim().isEmpty) {
      failures.add('write step missing collection');
    }
    if (recordId.trim().isEmpty) failures.add('write step missing record id');
    if (sourceOperation.trim().isEmpty) {
      failures.add('write step missing source operation');
    }
    if (target == MaintainiacWriteTarget.firestoreMirror && !mirrorOnly) {
      failures.add('$collection/$recordId Firestore write must be mirror-only');
    }
    if (target == MaintainiacWriteTarget.derivedOutput && mutatesSource) {
      failures.add(
        '$collection/$recordId derived output must not mutate source',
      );
    }
    if (target == MaintainiacWriteTarget.localHive && mirrorOnly) {
      failures.add(
        '$collection/$recordId local Hive write cannot be mirror-only',
      );
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'order': order,
      'target': target.name,
      'collection': collection,
      'recordId': recordId,
      'sourceOperation': sourceOperation,
      'mirrorOnly': mirrorOnly,
      'mutatesSource': mutatesSource,
    };
  }
}

class MaintainiacLocalFirstContract {
  const MaintainiacLocalFirstContract(this.steps);

  final List<MaintainiacWriteStep> steps;

  List<String> validate() {
    final failures = <String>[];
    if (steps.isEmpty) failures.add('local-first contract has no write steps');
    final sorted = [...steps]..sort((a, b) => a.order.compareTo(b.order));
    for (final step in sorted) {
      failures.addAll(step.validate());
    }
    final sourceKeys = <String>{};
    for (final step in sorted) {
      final key = '${step.sourceOperation}:${step.collection}:${step.recordId}';
      if (step.target == MaintainiacWriteTarget.localHive) {
        sourceKeys.add(key);
      }
      if (step.target == MaintainiacWriteTarget.firestoreMirror &&
          !sourceKeys.contains(key)) {
        failures.add('$key mirrored before local Hive source write');
      }
      if (step.target == MaintainiacWriteTarget.derivedOutput &&
          step.collection.startsWith('source/')) {
        failures.add('$key derived output points at source collection');
      }
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'stepCount': steps.length,
      'steps': [for (final step in steps) step.toJson()],
    };
  }
}
