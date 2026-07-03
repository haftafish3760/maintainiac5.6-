enum MaintainiacParserFixtureSource { synthetic, anonymizedReal, manualReview }

class MaintainiacParserFixtureSet {
  const MaintainiacParserFixtureSet({
    required this.id,
    required this.domain,
    required this.path,
    required this.locale,
    required this.country,
    required this.owner,
    required this.source,
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
    if (source == MaintainiacParserFixtureSource.anonymizedReal &&
        !tags.contains('privacy-reviewed')) {
      failures.add('$id anonymized real fixture needs privacy-reviewed tag');
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
    if (!domains.contains('inventory_parser')) {
      failures.add('fixture manifest missing inventory parser fixtures');
    }
    if (!domains.contains('expense_receipt_parser')) {
      failures.add('fixture manifest missing expense receipt parser fixtures');
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
