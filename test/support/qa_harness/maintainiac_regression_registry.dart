class MaintainiacRegressionCase {
  const MaintainiacRegressionCase({
    required this.bugId,
    required this.description,
    required this.rootCause,
    required this.inputFixture,
    required this.expectedBehavior,
    required this.fixedVersion,
    required this.area,
    required this.moduleTags,
    required this.permanentTest,
  });

  final String bugId;
  final String description;
  final String rootCause;
  final String inputFixture;
  final String expectedBehavior;
  final String fixedVersion;
  final String area;
  final Set<String> moduleTags;
  final String permanentTest;

  List<String> validate() {
    final failures = <String>[];
    if (!RegExp(r'^[A-Z]+-\d{4,}$').hasMatch(bugId)) {
      failures.add('bug id must look like AREA-0001');
    }
    if (description.trim().isEmpty) {
      failures.add('missing description');
    }
    if (rootCause.trim().isEmpty) {
      failures.add('missing root cause');
    }
    if (inputFixture.trim().isEmpty) {
      failures.add('missing input fixture');
    }
    if (expectedBehavior.trim().isEmpty) {
      failures.add('missing expected behavior');
    }
    if (fixedVersion.trim().isEmpty) {
      failures.add('missing fixed version');
    }
    if (area.trim().isEmpty) {
      failures.add('missing area');
    }
    if (moduleTags.isEmpty) {
      failures.add('missing module tags');
    }
    if (permanentTest.trim().isEmpty) {
      failures.add('missing permanent test');
    }
    return failures;
  }
}

class MaintainiacRegressionRegistry {
  const MaintainiacRegressionRegistry(this.cases);

  final List<MaintainiacRegressionCase> cases;

  List<String> validate() {
    final failures = <String>[];
    final ids = <String>{};
    for (final entry in cases) {
      if (!ids.add(entry.bugId)) {
        failures.add('duplicate bug id ${entry.bugId}');
      }
      for (final issue in entry.validate()) {
        failures.add('${entry.bugId}: $issue');
      }
    }
    return failures;
  }
}
