import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('module boundary gate labels safe QA lanes', () {
    const gate = maintainiacModuleBoundaryGate;

    expect(gate.validate(), isEmpty);
    expect(gate.toJson()['ruleCount'], greaterThanOrEqualTo(6));
    expect(
      gate.violationsFor('inventory_parser_lane', [
        'test/support/qa_harness/maintainiac_parser_consumer_gate.dart',
        'test/camera/receipt_camera_flow_test.dart',
      ]),
      ['test/camera/receipt_camera_flow_test.dart'],
    );
    expect(gate.toJson().toString(), contains('security_privacy_lane'));
  });

  test('module boundary gate rejects weak or missing lanes', () {
    const gate = MaintainiacModuleBoundaryGate([
      MaintainiacModuleBoundaryRule(
        id: 'bad',
        owner: '',
        module: 'inventory',
        allowedPathPrefixes: {},
        forbiddenPathTokens: {},
        violationAction: '',
      ),
    ]);

    final failures = gate.validate().join('\n');

    expect(failures, contains('bad missing owner'));
    expect(failures, contains('bad missing allowed path prefixes'));
    expect(failures, contains('bad missing forbidden path tokens'));
    expect(failures, contains('bad missing violation action'));
    expect(failures, contains('module boundary gate missing module expenses'));
  });
}
