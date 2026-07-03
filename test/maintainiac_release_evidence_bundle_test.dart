import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('release evidence bundle records required milestone proof', () {
    const bundle = maintainiacReleaseEvidenceBundle;

    expect(bundle.validate(), isEmpty);
    expect(bundle.toJson()['evidenceCount'], greaterThanOrEqualTo(6));
    expect(bundle.requiredCommands(), contains('git push'));
    expect(
      bundle.requiredCommands(),
      contains(
        'dart run tool/maintainiac_individual_qa_command.dart --id qa_environment_local_truth',
      ),
    );
    expect(
      bundle.requiredCommands(),
      contains('dart run tool/maintainiac_release_gate.dart --json'),
    );
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
        id: 'bad_analyzer',
        kind: MaintainiacEvidenceKind.analyzer,
        commandOrArtifact: 'dart analyze .',
        proves: 'too broad',
        requiredForRelease: true,
      ),
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
      MaintainiacReleaseEvidence(
        id: 'bad_resolver',
        kind: MaintainiacEvidenceKind.individualCommandResolver,
        commandOrArtifact: 'flutter test test/all.dart',
        proves: 'bad resolver',
        requiredForRelease: true,
      ),
      MaintainiacReleaseEvidence(
        id: 'bad_release_gate',
        kind: MaintainiacEvidenceKind.releaseGateTool,
        commandOrArtifact: 'flutter test test/release_gate_test.dart',
        proves: 'bad release gate',
        requiredForRelease: true,
      ),
    ]);

    final failures = bundle.validate().join('\n');

    expect(
      failures,
      contains('bad_analyzer analyzer evidence must stay targeted'),
    );
    expect(
      failures,
      contains(
        'bad_analyzer analyzer evidence must include QA harness sources',
      ),
    );
    expect(failures, contains('bad_individual missing proof statement'));
    expect(
      failures,
      contains('bad_individual individual test evidence must use --plain-name'),
    );
    expect(failures, contains('bad_push git push evidence must use git push'));
    expect(
      failures,
      contains('bad_resolver must prove exact individual command lookup by id'),
    );
    expect(
      failures,
      contains(
        'bad_release_gate must prove the release gate tool output directly',
      ),
    );
    expect(
      failures,
      contains('release evidence missing required kind backboneVisibility'),
    );
  });

  test('release evidence bundle requires targeted analyzer proof', () {
    const targeted = MaintainiacReleaseEvidence(
      id: 'targeted_analyzer',
      kind: MaintainiacEvidenceKind.analyzer,
      commandOrArtifact:
          'dart analyze test/support/qa_harness test/maintainiac_qa_backbone_test.dart',
      proves: 'QA harness sources are analyzer clean.',
      requiredForRelease: true,
    );
    const broad = MaintainiacReleaseEvidence(
      id: 'broad_analyzer',
      kind: MaintainiacEvidenceKind.analyzer,
      commandOrArtifact: 'dart analyze',
      proves: 'too broad and not attributable',
      requiredForRelease: true,
    );

    expect(targeted.validate(), isEmpty);
    expect(
      broad.validate(),
      contains('broad_analyzer analyzer evidence must stay targeted'),
    );
  });
}
