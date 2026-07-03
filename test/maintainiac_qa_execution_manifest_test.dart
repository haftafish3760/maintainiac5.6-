import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('QA execution manifest labels every runnable release-one check', () {
    final manifest = MaintainiacQaExecutionManifest.releaseOneCore();

    expect(manifest.validate(), isEmpty);
    expect(manifest.executions, hasLength(greaterThanOrEqualTo(10)));
    for (final execution in manifest.executions) {
      expect(execution.label, isNotEmpty, reason: execution.id);
      expect(execution.proves, isNotEmpty, reason: execution.id);
      expect(execution.failureAction, contains('Stop feature work'));
      expect(execution.liveServicesAllowed, isFalse);
      expect(execution.firebaseWritesAllowed, isFalse);
    }
  });

  test('QA execution manifest separates focused checks from release gates', () {
    final manifest = MaintainiacQaExecutionManifest.releaseOneCore();

    final focused = manifest.byCadence(MaintainiacQaCadence.focused);
    final release = manifest.byCadence(MaintainiacQaCadence.release);

    expect(focused, isNotEmpty);
    expect(release, isNotEmpty);
    expect(
      release.map((execution) => execution.id),
      containsAll(['QA-BACKBONE-001', 'QA-SYNC-001', 'QA-SEC-001']),
    );
    expect(
      focused.map((execution) => execution.id),
      containsAll(['QA-BOUNDARY-001', 'QA-DEVICE-001']),
    );
  });

  test('QA execution manifest provides deduped surgical command plans', () {
    final manifest = MaintainiacQaExecutionManifest.releaseOneCore();

    final focusedCommands = manifest.commandPlanFor(
      MaintainiacQaCadence.focused,
    );
    final releaseCommands = manifest.commandPlanFor(
      MaintainiacQaCadence.release,
    );

    expect(focusedCommands.toSet(), hasLength(focusedCommands.length));
    expect(releaseCommands.toSet(), hasLength(releaseCommands.length));
    expect(
      focusedCommands.every((command) => command.contains(' --plain-name ')),
      isTrue,
    );
    expect(focusedCommands.join('\n'), contains('maintainiac_source_boundary'));
    expect(releaseCommands.join('\n'), contains('maintainiac_qa_backbone'));
  });

  test('QA execution manifest rejects unlabeled or live-service checks', () {
    const manifest = MaintainiacQaExecutionManifest([
      MaintainiacQaExecution(
        id: 'QA-BAD-001',
        label: '',
        module: MaintainiacQaModule.inventory,
        command: 'flutter test test/bad_test.dart',
        cadence: MaintainiacQaCadence.focused,
        owner: 'qa',
        proves: 'bad check is rejected',
        failureAction: 'Stop feature work.',
        tags: {'bad'},
        liveServicesAllowed: true,
      ),
    ]);

    expect(manifest.validate().join('\n'), contains('missing label'));
    expect(
      manifest.validate().join('\n'),
      contains('must not allow live services'),
    );
    expect(
      manifest.validate().join('\n'),
      contains('focused Flutter command must use --plain-name'),
    );
  });
}
