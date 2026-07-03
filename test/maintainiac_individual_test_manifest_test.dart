import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('individual test manifest exposes surgical command metadata', () {
    final manifest = maintainiacIndividualTestManifest;

    expect(manifest.validate(), isEmpty);
    expect(manifest.entries.length, greaterThanOrEqualTo(18));
    expect(
      manifest.entries.every((entry) => entry.command.contains('--plain-name')),
      isTrue,
    );
    expect(manifest.commandsForRiskFamily('security'), isNotEmpty);
    expect(manifest.commandsForRiskFamily('financial'), isNotEmpty);
    expect(manifest.commandsForRiskFamily('performance'), isNotEmpty);
    expect(manifest.commandsForRiskFamily('fixtures'), isNotEmpty);
    expect(
      manifest.toJson().toString(),
      contains('qa_environment_local_truth'),
    );
    expect(manifest.toJson().toString(), contains('source-of-truth'));
  });

  test('individual test manifest rejects unsafe or non-surgical commands', () {
    const manifest = MaintainiacIndividualTestManifest([
      MaintainiacIndividualTestEntry(
        id: 'bad',
        module: '',
        riskFamily: '',
        command:
            'flutter test test/receipt_camera_test.dart && flutter test test/other.dart',
        owner: '',
        whenToRun: '',
      ),
    ]);

    final failures = manifest.validate().join('\n');

    expect(failures, contains('bad missing module'));
    expect(failures, contains('bad missing risk family'));
    expect(failures, contains('bad missing owner'));
    expect(failures, contains('bad missing run guidance'));
    expect(failures, contains('bad must use --plain-name'));
    expect(failures, contains('bad must not chain commands'));
    expect(
      failures,
      contains('bad must not touch OCR/camera/live cloud providers'),
    );
    expect(failures, contains('individual test manifest missing inventory'));
  });
}
