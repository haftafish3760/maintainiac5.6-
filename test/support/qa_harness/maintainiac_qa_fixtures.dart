enum MaintainiacFixtureKind {
  json,
  receiptImage,
  ocrText,
  parser,
  inventoryCatalog,
  estimateInvoice,
  syncConflict,
  malformed,
  corrupted,
  generatedDataset,
  bugRegression,
}

class MaintainiacFixtureDescriptor {
  const MaintainiacFixtureDescriptor({
    required this.id,
    required this.kind,
    required this.module,
    required this.path,
    required this.owner,
    required this.synthetic,
    required this.reviewed,
    this.locale = 'en-US',
    this.merchant = '',
    this.expectedBehavior = '',
  });

  final String id;
  final MaintainiacFixtureKind kind;
  final String module;
  final String path;
  final String owner;
  final bool synthetic;
  final bool reviewed;
  final String locale;
  final String merchant;
  final String expectedBehavior;

  List<String> validate() {
    final failures = <String>[];
    if (id.trim().isEmpty) {
      failures.add('missing id');
    }
    if (module.trim().isEmpty) {
      failures.add('missing module');
    }
    if (path.trim().isEmpty) {
      failures.add('missing path');
    }
    if (owner.trim().isEmpty) {
      failures.add('missing owner');
    }
    if (expectedBehavior.trim().isEmpty) {
      failures.add('missing expected behavior');
    }
    if (!reviewed && kind == MaintainiacFixtureKind.bugRegression) {
      failures.add('bug regression fixtures must be reviewed');
    }
    return failures;
  }
}

class MaintainiacFixtureCatalog {
  const MaintainiacFixtureCatalog(this.fixtures);

  final List<MaintainiacFixtureDescriptor> fixtures;

  List<String> validate() {
    final failures = <String>[];
    final ids = <String>{};
    for (final fixture in fixtures) {
      if (!ids.add(fixture.id)) {
        failures.add('duplicate fixture ${fixture.id}');
      }
      for (final issue in fixture.validate()) {
        failures.add('${fixture.id}: $issue');
      }
    }
    return failures;
  }
}
