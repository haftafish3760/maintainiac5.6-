import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('surgical selector registry exposes individual plain-name commands', () {
    const registry = maintainiacSurgicalTestSelectorRegistry;

    expect(registry.validate(), isEmpty);
    expect(registry.toJson()['singleBehaviorCount'], greaterThanOrEqualTo(15));
    expect(registry.commandsForTag('inventory'), isNotEmpty);
    expect(registry.commandsForTag('expenses'), isNotEmpty);
    expect(
      registry.commandsForTag('privacy').single,
      contains(
        '--plain-name "expense parser consumer rejects unsafe fake readiness"',
      ),
    );
    expect(
      registry.toJson().toString(),
      contains('main_backbone_parser_visibility'),
    );
  });

  test('surgical selector registry rejects broad or unsafe selectors', () {
    const badRegistry = MaintainiacSurgicalTestSelectorRegistry([
      MaintainiacSurgicalTestSelector(
        id: 'bad',
        scope: MaintainiacSurgicalTestScope.singleBehavior,
        file: 'test/camera_ocr_test.dart',
        plainName: '',
        reason: '',
        tags: {'inventory'},
      ),
      MaintainiacSurgicalTestSelector(
        id: 'bad',
        scope: MaintainiacSurgicalTestScope.releaseGate,
        file: 'lib/not_a_test.dart',
        plainName: 'duplicate',
        reason: 'duplicate selector',
        tags: {'expenses'},
      ),
    ]);

    final failures = badRegistry.validate().join('\n');

    expect(failures, contains('duplicate surgical selector bad'));
    expect(failures, contains('bad missing plain-name selector'));
    expect(failures, contains('bad missing reason'));
    expect(failures, contains('outside OCR/camera/live Firebase'));
    expect(failures, contains('bad must target one Dart test file'));
    expect(failures, contains('surgical registry missing tag parser-consumer'));
    expect(failures, contains('surgical registry missing tag privacy'));
  });
}
