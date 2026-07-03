enum MaintainiacParserFixtureSource { synthetic, anonymizedReal, manualReview }

enum MaintainiacParserFixtureRole { golden, holdout, regression, malformed }

class MaintainiacParserFixtureSet {
  const MaintainiacParserFixtureSet({
    required this.id,
    required this.domain,
    required this.path,
    required this.locale,
    required this.country,
    required this.owner,
    required this.source,
    required this.role,
    required this.expectedBehavior,
    required this.reviewedAt,
    this.merchant = 'unknown',
    this.trade = 'unknown',
    this.requiresReview = true,
    this.tags = const {},
  });

  final String id;
  final String domain;
  final String path;
  final String locale;
  final String country;
  final String owner;
  final MaintainiacParserFixtureSource source;
  final MaintainiacParserFixtureRole role;
  final String merchant;
  final String trade;
  final String expectedBehavior;
  final DateTime reviewedAt;
  final bool requiresReview;
  final Set<String> tags;

  List<String> validate() {
    final failures = <String>[];
    if (id.trim().isEmpty) failures.add('fixture set missing id');
    if (domain.trim().isEmpty) failures.add('$id missing parser domain');
    if (!path.startsWith('test/fixtures/')) {
      failures.add('$id fixture path must live under test/fixtures');
    }
    if (!RegExp(r'^[a-z]{2}(-[A-Z]{2})?$').hasMatch(locale)) {
      failures.add('$id locale must look like en-US or es-US');
    }
    if (country.trim().length != 2) {
      failures.add('$id country must be two-letter ISO code');
    }
    if (owner.trim().isEmpty) failures.add('$id missing owner');
    if (expectedBehavior.trim().isEmpty) {
      failures.add('$id missing expected behavior');
    }
    if (tags.isEmpty) failures.add('$id needs searchable tags');
    if (!tags.contains(role.name)) {
      failures.add('$id tags must include fixture role ${role.name}');
    }
    if (source == MaintainiacParserFixtureSource.anonymizedReal &&
        !tags.contains('privacy-reviewed')) {
      failures.add('$id anonymized real fixture needs privacy-reviewed tag');
    }
    if (source == MaintainiacParserFixtureSource.anonymizedReal &&
        !tags.contains('redaction-proof')) {
      failures.add('$id anonymized real fixture needs redaction-proof tag');
    }
    if (role == MaintainiacParserFixtureRole.holdout &&
        tags.contains('training')) {
      failures.add('$id holdout fixtures must not be training fixtures');
    }
    if (role == MaintainiacParserFixtureRole.regression &&
        !tags.any((tag) => RegExp(r'^[A-Z]+-\d{4,}$').hasMatch(tag))) {
      failures.add('$id regression fixtures need bug id tag');
    }
    if (!requiresReview && tags.contains('dangerous-word')) {
      failures.add('$id dangerous-word fixtures must require review');
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'domain': domain,
      'path': path,
      'locale': locale,
      'country': country,
      'owner': owner,
      'source': source.name,
      'role': role.name,
      'merchant': merchant,
      'trade': trade,
      'expectedBehavior': expectedBehavior,
      'reviewedAt': reviewedAt.toIso8601String(),
      'requiresReview': requiresReview,
      'tags': tags.toList()..sort(),
    };
  }
}

class MaintainiacParserFixtureManifest {
  const MaintainiacParserFixtureManifest(this.fixtureSets);

  final List<MaintainiacParserFixtureSet> fixtureSets;

  List<String> validate() {
    final failures = <String>[];
    final ids = <String>{};
    if (fixtureSets.isEmpty) failures.add('parser fixture manifest is empty');
    for (final fixtureSet in fixtureSets) {
      if (!ids.add(fixtureSet.id)) {
        failures.add('duplicate parser fixture set id ${fixtureSet.id}');
      }
      failures.addAll(fixtureSet.validate());
    }
    final domains = fixtureSets.map((set) => set.domain).toSet();
    final roles = fixtureSets.map((set) => set.role).toSet();
    if (!domains.contains('inventory_parser')) {
      failures.add('fixture manifest missing inventory parser fixtures');
    }
    if (!domains.contains('expense_receipt_parser')) {
      failures.add('fixture manifest missing expense receipt parser fixtures');
    }
    for (final required in MaintainiacParserFixtureRole.values) {
      if (!roles.contains(required)) {
        failures.add('fixture manifest missing role ${required.name}');
      }
    }
    return failures;
  }

  List<MaintainiacParserFixtureSet> byDomain(String domain) {
    return [
      for (final fixtureSet in fixtureSets)
        if (fixtureSet.domain == domain) fixtureSet,
    ];
  }

  Map<String, Object?> toJson() {
    return {
      'fixtureSetCount': fixtureSets.length,
      'fixtureSets': [
        for (final fixtureSet in fixtureSets) fixtureSet.toJson(),
      ],
    };
  }
}

final maintainiacParserFixtureManifest = MaintainiacParserFixtureManifest([
  MaintainiacParserFixtureSet(
    id: 'inventory_en_us_core_ambiguous',
    domain: 'inventory_parser',
    path: 'test/fixtures/work_supply_parser/golden_fixtures.json',
    locale: 'en-US',
    country: 'US',
    owner: 'maintainiac-qa',
    source: MaintainiacParserFixtureSource.synthetic,
    role: MaintainiacParserFixtureRole.golden,
    expectedBehavior: 'generic PVC lines require review',
    reviewedAt: DateTime.utc(2026, 7, 3),
    merchant: 'mixed',
    trade: 'plumbing',
    tags: {'golden', 'dangerous-word', 'inventory'},
  ),
  MaintainiacParserFixtureSet(
    id: 'expense_en_us_fuel_core',
    domain: 'expense_receipt_parser',
    path: 'test/fixtures/expense_receipts/fuel_core.json',
    locale: 'en-US',
    country: 'US',
    owner: 'maintainiac-qa',
    source: MaintainiacParserFixtureSource.synthetic,
    role: MaintainiacParserFixtureRole.golden,
    expectedBehavior: 'fuel totals remain review-only until confirmed',
    reviewedAt: DateTime.utc(2026, 7, 3),
    merchant: 'gas_station',
    trade: 'expense',
    tags: {'golden', 'expense', 'financial'},
  ),
  MaintainiacParserFixtureSet(
    id: 'inventory_es_us_holdout_core',
    domain: 'inventory_parser',
    path: 'test/fixtures/work_supply_parser/holdout_es_us.json',
    locale: 'es-US',
    country: 'US',
    owner: 'maintainiac-qa',
    source: MaintainiacParserFixtureSource.manualReview,
    role: MaintainiacParserFixtureRole.holdout,
    expectedBehavior: 'Spanish US pack validation stays independent',
    reviewedAt: DateTime.utc(2026, 7, 3),
    merchant: 'mixed',
    trade: 'plumbing',
    tags: {'holdout', 'spanish', 'inventory'},
  ),
  MaintainiacParserFixtureSet(
    id: 'expense_private_text_regression',
    domain: 'expense_receipt_parser',
    path: 'test/fixtures/regressions/expense_private_text.json',
    locale: 'en-US',
    country: 'US',
    owner: 'maintainiac-qa',
    source: MaintainiacParserFixtureSource.anonymizedReal,
    role: MaintainiacParserFixtureRole.regression,
    expectedBehavior: 'diagnostics stay redacted and review-only',
    reviewedAt: DateTime.utc(2026, 7, 3),
    merchant: 'mixed',
    trade: 'expense',
    tags: {'regression', 'EXP-0001', 'privacy-reviewed', 'redaction-proof'},
  ),
  MaintainiacParserFixtureSet(
    id: 'parser_malformed_noise_lines',
    domain: 'inventory_parser',
    path: 'test/fixtures/malformed/parser_noise_lines.json',
    locale: 'en-US',
    country: 'US',
    owner: 'maintainiac-qa',
    source: MaintainiacParserFixtureSource.synthetic,
    role: MaintainiacParserFixtureRole.malformed,
    expectedBehavior: 'noise lines remain unknown or review-only',
    reviewedAt: DateTime.utc(2026, 7, 3),
    merchant: 'unknown',
    trade: 'mixed',
    tags: {'malformed', 'noise', 'parser'},
  ),
]);
