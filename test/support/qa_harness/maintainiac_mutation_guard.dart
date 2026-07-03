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
