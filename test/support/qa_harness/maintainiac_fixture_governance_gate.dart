enum MaintainiacFixturePrivacyLevel {
  publicSynthetic,
  redactedReal,
  privateBlocked,
}

enum MaintainiacFixtureReviewCadence { perChange, weekly, monthly, perRelease }

class MaintainiacFixtureGovernanceRule {
  const MaintainiacFixtureGovernanceRule({
    required this.id,
    required this.fixtureFamily,
    required this.pathRoot,
    required this.owner,
    required this.privacyLevel,
    required this.reviewCadence,
    required this.allowedInRepo,
    required this.requiredMetadata,
  });

  final String id;
  final String fixtureFamily;
  final String pathRoot;
  final String owner;
  final MaintainiacFixturePrivacyLevel privacyLevel;
  final MaintainiacFixtureReviewCadence reviewCadence;
  final bool allowedInRepo;
  final Set<String> requiredMetadata;

  List<String> validate() {
    final failures = <String>[];
    if (id.trim().isEmpty) {
      failures.add('fixture governance rule missing id');
    }
    if (fixtureFamily.trim().isEmpty) {
      failures.add('$id missing fixture family');
    }
    if (!pathRoot.startsWith('test/fixtures/') &&
        !pathRoot.startsWith('test/support/')) {
      failures.add('$id fixture path must stay under test fixtures/support');
    }
    if (owner.trim().isEmpty) {
      failures.add('$id missing owner');
    }
    if (requiredMetadata.length < 5) {
      failures.add('$id needs rich fixture metadata requirements');
    }
    if (privacyLevel == MaintainiacFixturePrivacyLevel.privateBlocked &&
        allowedInRepo) {
      failures.add('$id private fixtures must not be allowed in repo');
    }
    if (privacyLevel == MaintainiacFixturePrivacyLevel.redactedReal &&
        !requiredMetadata.contains('redactionProof')) {
      failures.add('$id redacted real fixtures need redaction proof');
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'fixtureFamily': fixtureFamily,
      'pathRoot': pathRoot,
      'owner': owner,
      'privacyLevel': privacyLevel.name,
      'reviewCadence': reviewCadence.name,
      'allowedInRepo': allowedInRepo,
      'requiredMetadata': requiredMetadata.toList()..sort(),
    };
  }
}

class MaintainiacFixtureGovernanceGate {
  const MaintainiacFixtureGovernanceGate(this.rules);

  final List<MaintainiacFixtureGovernanceRule> rules;

  List<String> validate() {
    final failures = <String>[];
    final ids = <String>{};
    final families = <String>{};
    for (final rule in rules) {
      if (!ids.add(rule.id)) {
        failures.add('duplicate fixture governance rule ${rule.id}');
      }
      families.add(rule.fixtureFamily);
      failures.addAll(rule.validate());
    }
    for (final required in {
      'parser',
      'expense',
      'sync_conflict',
      'malformed',
      'generated_dataset',
      'bug_regression',
    }) {
      if (!families.contains(required)) {
        failures.add('fixture governance missing family $required');
      }
    }
    return failures;
  }

  List<MaintainiacFixtureGovernanceRule> repoBlockedRules() {
    return [
      for (final rule in rules)
        if (!rule.allowedInRepo) rule,
    ];
  }

  Map<String, Object?> toJson() {
    return {
      'ruleCount': rules.length,
      'repoBlockedCount': repoBlockedRules().length,
      'rules': [for (final rule in rules) rule.toJson()],
    };
  }
}

const _baseMetadata = {
  'id',
  'owner',
  'module',
  'reviewedAt',
  'expectedBehavior',
};

const maintainiacFixtureGovernanceGate = MaintainiacFixtureGovernanceGate([
  MaintainiacFixtureGovernanceRule(
    id: 'parser_fixture_governance',
    fixtureFamily: 'parser',
    pathRoot: 'test/fixtures/work_supply_parser',
    owner: 'maintainiac-qa',
    privacyLevel: MaintainiacFixturePrivacyLevel.publicSynthetic,
    reviewCadence: MaintainiacFixtureReviewCadence.perRelease,
    allowedInRepo: true,
    requiredMetadata: {
      ..._baseMetadata,
      'locale',
      'merchant',
      'trade',
      'synthetic',
    },
  ),
  MaintainiacFixtureGovernanceRule(
    id: 'expense_fixture_governance',
    fixtureFamily: 'expense',
    pathRoot: 'test/fixtures/expense_receipts',
    owner: 'maintainiac-qa',
    privacyLevel: MaintainiacFixturePrivacyLevel.publicSynthetic,
    reviewCadence: MaintainiacFixtureReviewCadence.perRelease,
    allowedInRepo: true,
    requiredMetadata: {
      ..._baseMetadata,
      'category',
      'totalCents',
      'currency',
      'synthetic',
    },
  ),
  MaintainiacFixtureGovernanceRule(
    id: 'sync_conflict_fixture_governance',
    fixtureFamily: 'sync_conflict',
    pathRoot: 'test/fixtures/sync_conflicts',
    owner: 'maintainiac-qa',
    privacyLevel: MaintainiacFixturePrivacyLevel.publicSynthetic,
    reviewCadence: MaintainiacFixtureReviewCadence.perChange,
    allowedInRepo: true,
    requiredMetadata: {
      ..._baseMetadata,
      'localVersion',
      'mirrorVersion',
      'conflictPolicy',
    },
  ),
  MaintainiacFixtureGovernanceRule(
    id: 'malformed_fixture_governance',
    fixtureFamily: 'malformed',
    pathRoot: 'test/fixtures/malformed',
    owner: 'maintainiac-qa',
    privacyLevel: MaintainiacFixturePrivacyLevel.publicSynthetic,
    reviewCadence: MaintainiacFixtureReviewCadence.monthly,
    allowedInRepo: true,
    requiredMetadata: {
      ..._baseMetadata,
      'malformationType',
      'safeFailure',
      'reportExpectation',
    },
  ),
  MaintainiacFixtureGovernanceRule(
    id: 'generated_dataset_governance',
    fixtureFamily: 'generated_dataset',
    pathRoot: 'test/support/generated_datasets',
    owner: 'maintainiac-qa',
    privacyLevel: MaintainiacFixturePrivacyLevel.publicSynthetic,
    reviewCadence: MaintainiacFixtureReviewCadence.weekly,
    allowedInRepo: true,
    requiredMetadata: {
      ..._baseMetadata,
      'generatorVersion',
      'seed',
      'caseCount',
      'schemaVersion',
    },
  ),
  MaintainiacFixtureGovernanceRule(
    id: 'bug_regression_fixture_governance',
    fixtureFamily: 'bug_regression',
    pathRoot: 'test/fixtures/regressions',
    owner: 'maintainiac-qa',
    privacyLevel: MaintainiacFixturePrivacyLevel.redactedReal,
    reviewCadence: MaintainiacFixtureReviewCadence.perChange,
    allowedInRepo: true,
    requiredMetadata: {
      ..._baseMetadata,
      'bugId',
      'rootCause',
      'redactionProof',
      'fixedVersion',
    },
  ),
  MaintainiacFixtureGovernanceRule(
    id: 'private_fixture_block',
    fixtureFamily: 'private_blocked',
    pathRoot: 'test/fixtures/private',
    owner: 'maintainiac-qa',
    privacyLevel: MaintainiacFixturePrivacyLevel.privateBlocked,
    reviewCadence: MaintainiacFixtureReviewCadence.perChange,
    allowedInRepo: false,
    requiredMetadata: {..._baseMetadata, 'deleteReason', 'replacementFixture'},
  ),
]);
