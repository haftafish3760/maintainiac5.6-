import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('derived output contract keeps reports and invoices read-only', () {
    const contract = maintainiacDerivedOutputContract;

    expect(contract.validate(), isEmpty);
    expect(contract.rulesForModule('recap'), hasLength(1));
    expect(
      contract.rulesForModule('invoices').single.forbidsSourceWrite('jobs'),
      isTrue,
    );
    expect(
      contract.toJson().toString(),
      contains('notifications_read_sources_schedule_events'),
    );
    expect(
      contract.toJson().toString(),
      contains('exports_read_sources_write_artifacts'),
    );
  });

  test('derived output contract rejects source mutation ambiguity', () {
    const contract = MaintainiacDerivedOutputContract([
      MaintainiacDerivedOutputRule(
        id: 'bad',
        module: '',
        outputFamily: '',
        readSourceFamilies: {},
        allowedOutputWrites: {'expenses'},
        forbiddenSourceWrites: {'expenses'},
        reason: '',
      ),
    ]);

    final failures = contract.validate().join('\n');

    expect(failures, contains('bad missing module'));
    expect(failures, contains('bad missing output family'));
    expect(failures, contains('bad must declare source reads'));
    expect(failures, contains('bad missing reason'));
    expect(failures, contains('bad allows and forbids expenses'));
    expect(failures, contains('derived output contract missing module recap'));
  });
}
