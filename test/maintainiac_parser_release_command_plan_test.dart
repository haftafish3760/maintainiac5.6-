import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('parser release command plan covers every parser consumer family', () {
    const plan = maintainiacParserReleaseCommandPlan;

    expect(plan.validate(), isEmpty);
    expect(
      plan.commandsFor(MaintainiacParserCommandTier.surgical),
      hasLength(greaterThanOrEqualTo(15)),
    );
    expect(plan.commandsFor(MaintainiacParserCommandTier.smoke), isNotEmpty);
    expect(
      plan.commandsFor(MaintainiacParserCommandTier.focused),
      hasLength(2),
    );
    expect(plan.commandsFor(MaintainiacParserCommandTier.release), isNotEmpty);
    expect(
      plan.commands.every((entry) => entry.command.contains(' --plain-name ')),
      isTrue,
    );
    expect(
      plan.toJson().toString(),
      contains('maintainiac_parser_consumer_gate_test.dart'),
    );
    expect(
      plan.commandsFor(MaintainiacParserCommandTier.surgical).first,
      contains('--plain-name'),
    );
    expect(plan.toJson().toString(), contains('locale_spanish_release_one'));
    expect(plan.toJson().toString(), contains('privacy_redaction'));
  });

  test(
    'parser release command plan rejects unsafe commands and missing tiers',
    () {
      const badPlan = MaintainiacParserReleaseCommandPlan([
        MaintainiacParserReleaseCommand(
          id: 'bad',
          tier: MaintainiacParserCommandTier.smoke,
          command: 'flutter test test/camera_mlkit_test.dart',
          reason: '',
          coveredFamilies: {},
        ),
      ]);

      final failures = badPlan.validate().join('\n');

      expect(failures, contains('bad missing reason'));
      expect(failures, contains('bad missing covered families'));
      expect(failures, contains('bad must use individual plain-name command'));
      expect(failures, contains('outside OCR/camera'));
      expect(failures, contains('missing focused tier'));
      expect(failures, contains('missing release tier'));
      expect(failures, contains('misses family catalog_schema_metadata'));
    },
  );
}
