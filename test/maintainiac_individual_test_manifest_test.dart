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
    expect(
      manifest.commandForId('qa_environment_local_truth'),
      equals(
        'flutter test test/maintainiac_qa_environment_test.dart '
        '--plain-name "QA environment fakes preserve local truth and mirror copies"',
      ),
    );
    expect(manifest.commandsForModule('inventory'), isNotEmpty);
    expect(manifest.toJson().toString(), contains('source-of-truth'));
  });

  test(
    'individual test manifest mirrors surgical selector commands exactly',
    () {
      final manifest = maintainiacIndividualTestManifest;
      const registry = maintainiacSurgicalTestSelectorRegistry;

      expect(manifest.entries, hasLength(registry.selectors.length));

      for (final selector in registry.selectors) {
        final entry = manifest.entryForId(selector.id);

        expect(entry.command, selector.command);
        expect(entry.whenToRun, selector.reason);
        expect(
          entry.command,
          equals(
            'flutter test ${selector.file} --plain-name "${selector.plainName}"',
          ),
        );
      }
    },
  );

  test('individual test manifest entries keep stable reporting metadata', () {
    final manifest = maintainiacIndividualTestManifest;
    final json = manifest.toJson();
    final modules = json['modules']! as List<String>;
    final riskFamilies = json['riskFamilies']! as List<String>;

    expect(json['entryCount'], manifest.entries.length);
    expect(modules, orderedEquals([...modules]..sort()));
    expect(riskFamilies, orderedEquals([...riskFamilies]..sort()));

    for (final entry in manifest.entries) {
      expect(entry.owner, 'qa_backbone');
      expect(entry.module.trim(), isNotEmpty);
      expect(entry.riskFamily.trim(), isNotEmpty);
      expect(entry.whenToRun, startsWith('Run only '));
      expect(entry.command, startsWith('flutter test test/'));
      expect(entry.command, contains(' --plain-name '));
      expect(entry.toJson().keys, {
        'id',
        'module',
        'riskFamily',
        'command',
        'owner',
        'whenToRun',
      });
    }
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
