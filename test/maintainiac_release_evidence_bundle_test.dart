import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('release evidence bundle records required milestone proof', () {
    const bundle = maintainiacReleaseEvidenceBundle;

    expect(bundle.validate(), isEmpty);
    expect(bundle.toJson()['evidenceCount'], greaterThanOrEqualTo(6));
    expect(bundle.requiredCommands(), contains('git push'));
    expect(
      bundle.requiredCommands().where(
        (command) => command.contains('--plain-name'),
      ),
      hasLength(greaterThanOrEqualTo(4)),
    );
    expect(bundle.toJson().toString(), contains('main_backbone_visibility'));
  });

  test('release evidence bundle rejects broad or missing proof', () {
    const bundle = MaintainiacReleaseEvidenceBundle([
      MaintainiacReleaseEvidence(
        id: 'bad_individual',
        kind: MaintainiacEvidenceKind.individualTest,
        commandOrArtifact: 'flutter test test/broad_test.dart',
        proves: '',
        requiredForRelease: true,
      ),
      MaintainiacReleaseEvidence(
        id: 'bad_push',
        kind: MaintainiacEvidenceKind.gitPush,
        commandOrArtifact: 'git status',
        proves: 'bad push',
        requiredForRelease: true,
      ),
    ]);

    final failures = bundle.validate().join('\n');

    expect(failures, contains('bad_individual missing proof statement'));
    expect(
      failures,
      contains('bad_individual individual test evidence must use --plain-name'),
    );
    expect(failures, contains('bad_push git push evidence must use git push'));
    expect(
      failures,
      contains('release evidence missing required kind analyzer'),
    );
  });
}
