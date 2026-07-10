enum MaintainiacFailureCategory {
  schema,
  privacy,
  security,
  sync,
  money,
  permissions,
  sourceMutation,
  parser,
  performance,
  fixture,
  unknown,
}

class MaintainiacFailureTaxonomyProbe {
  const MaintainiacFailureTaxonomyProbe();

  MaintainiacFailureCategory classify(String text) {
    final normalized = text.toLowerCase();
    if (_containsAny(normalized, ['schema', 'missing id', 'duplicate id'])) {
      return MaintainiacFailureCategory.schema;
    }
    if (_containsAny(normalized, [
      'vin',
      'plate',
      'patient',
      'passenger',
      'card',
    ])) {
      return MaintainiacFailureCategory.privacy;
    }
    if (_containsAny(normalized, [
      'cross-account',
      'ownership',
      'export scope',
    ])) {
      return MaintainiacFailureCategory.security;
    }
    if (_containsAny(normalized, ['sync', 'dirty', 'mirror', 'retry'])) {
      return MaintainiacFailureCategory.sync;
    }
    if (_containsAny(normalized, [
      'money',
      'cents',
      'tax',
      'rounding',
      'total',
    ])) {
      return MaintainiacFailureCategory.money;
    }
    if (_containsAny(normalized, [
      'permission',
      'employee',
      'vehicle_not_assigned',
    ])) {
      return MaintainiacFailureCategory.permissions;
    }
    if (_containsAny(normalized, ['mutated source', 'source collection'])) {
      return MaintainiacFailureCategory.sourceMutation;
    }
    if (_containsAny(normalized, [
      'parser',
      'alias',
      'confidence',
      'candidate',
    ])) {
      return MaintainiacFailureCategory.parser;
    }
    if (_containsAny(normalized, [
      'slow',
      'timeout',
      'memory',
      'catalog100k',
    ])) {
      return MaintainiacFailureCategory.performance;
    }
    if (_containsAny(normalized, ['fixture', 'golden', 'holdout'])) {
      return MaintainiacFailureCategory.fixture;
    }
    return MaintainiacFailureCategory.unknown;
  }

  Map<String, int> summarize(Iterable<String> failures) {
    final counts = <String, int>{
      for (final category in MaintainiacFailureCategory.values)
        category.name: 0,
    };
    for (final failure in failures) {
      final category = classify(failure).name;
      counts.update(category, (value) => value + 1);
    }
    return counts;
  }

  bool _containsAny(String text, Iterable<String> needles) {
    return needles.any(text.contains);
  }
}
