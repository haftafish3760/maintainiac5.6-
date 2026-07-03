import 'package:flutter_test/flutter_test.dart';
import 'dart:io';

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

  test(
    'source audit debt ledger tracks current oversized production files',
    () {
      final oversizedPaths = <String>{};
      for (final file in Directory('lib').listSync(recursive: true)) {
        if (file is! File || !file.path.endsWith('.dart')) continue;
        final relative = file.path
            .replaceFirst(
              '${Directory.current.path}${Platform.pathSeparator}',
              '',
            )
            .replaceAll('\\', '/');
        final rule = maintainiacSourceAuditPolicy.ruleFor(relative);
        if (rule == null) continue;
        final lineCount = file.readAsLinesSync().length;
        if (lineCount > rule.hardMaxLines) {
          oversizedPaths.add(relative);
        }
      }

      expect(
        maintainiacSourceAuditDebtLedger.validate(
          actualOversizedPaths: oversizedPaths,
        ),
        isEmpty,
      );
      expect(
        maintainiacSourceAuditDebtLedger.toJson().toString(),
        contains('work_supply_receipt_parser.dart'),
      );
    },
  );

  test('source audit debt ledger rejects non-production debt entries', () {
    const ledger = MaintainiacSourceAuditDebtLedger([
      MaintainiacSourceAuditDebt(
        path: 'test/support/qa_harness/oversized_helper.dart',
        owner: 'qa_backbone',
        reason: 'QA helper should not be production debt.',
        splitPlan:
            'Split the helper if needed, but do not hide it as app debt.',
        targetMaxLines: 1000,
      ),
      MaintainiacSourceAuditDebt(
        path: 'tool/generated_helper.dart',
        owner: 'qa_backbone',
        reason: 'Uncovered tool file should not be production debt.',
        splitPlan: 'Add a tool audit rule or keep it out of the debt ledger.',
        targetMaxLines: 1000,
      ),
    ]);

    final failures = ledger
        .validateAgainstPolicy(maintainiacSourceAuditPolicy)
        .join('\n');

    expect(
      failures,
      contains(
        'test/support/qa_harness/oversized_helper.dart debt must be production scoped',
      ),
    );
    expect(
      failures,
      contains(
        'test/support/qa_harness/oversized_helper.dart debt must target a production lib file',
      ),
    );
    expect(
      failures,
      contains('tool/generated_helper.dart has no source audit rule'),
    );
  });
}
