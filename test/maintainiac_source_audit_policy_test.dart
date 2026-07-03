import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('source audit policy separates production and QA line caps', () {
    const policy = maintainiacSourceAuditPolicy;

    expect(policy.validate(), isEmpty);
    expect(
      policy.ruleFor('lib/screens/expenses/expense_screen.dart')!.hardMaxLines,
      1000,
    );
    expect(
      policy.ruleFor('test/support/qa_harness/qa_harness.dart')!.hardMaxLines,
      1500,
    );
    expect(
      policy.violationFor(
        path: 'lib/screens/expenses/monolith.dart',
        lineCount: 1200,
      ),
      contains('exceeds hard line limit 1000'),
    );
    expect(
      policy.violationFor(
        path: 'test/support/qa_harness/qa_harness.dart',
        lineCount: 1200,
      ),
      isNull,
    );
  });

  test('source audit policy rejects unsafe or incomplete limits', () {
    const policy = MaintainiacSourceAuditPolicy([
      MaintainiacSourceAuditRule(
        id: 'bad',
        scope: MaintainiacSourceAuditScope.production,
        pathPrefix: '',
        preferredMaxLines: 500,
        hardMaxLines: 5000,
        reason: '',
      ),
    ]);

    final failures = policy.validate().join('\n');

    expect(failures, contains('bad missing path prefix'));
    expect(
      failures,
      contains('bad production hard limit must not exceed 1000'),
    );
    expect(failures, contains('bad missing reason'));
    expect(failures, contains('source audit policy missing scope qaHarness'));
  });
}
