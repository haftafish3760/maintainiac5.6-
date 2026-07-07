import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'ledger archive tool preserves newest rows and archives older history',
    () async {
      final root = Directory.systemTemp.createTempSync(
        'receipt_ledger_archive_',
      );
      addTearDown(() {
        if (root.existsSync()) root.deleteSync(recursive: true);
      });

      final ledger = File('${root.path}/ledger.md')
        ..writeAsStringSync(_sampleLedger(5));
      final archive = File('${root.path}/archive.md');

      final result = await Process.run('dart', [
        'run',
        'tool/receipt_bug_regression_ledger_archive.dart',
        '--ledger=${ledger.path}',
        '--archive=${archive.path}',
        '--keep=2',
      ]);

      expect(result.exitCode, 0, reason: result.stderr.toString());
      final activeText = ledger.readAsStringSync();
      final archiveText = archive.readAsStringSync();
      expect(activeText, contains('BUG-RECEIPT-0005'));
      expect(activeText, contains('BUG-RECEIPT-0004'));
      expect(activeText, isNot(contains('BUG-RECEIPT-0003')));
      expect(archiveText, contains('BUG-RECEIPT-0003'));
      expect(archiveText, contains('BUG-RECEIPT-0001'));
    },
  );
}

String _sampleLedger(int count) {
  final rows = <String>[];
  for (var id = count; id >= 1; id--) {
    final padded = id.toString().padLeft(4, '0');
    rows.add(
      '| `BUG-RECEIPT-$padded` | `qa_harness` | Symptom $id | Cause $id | Fix $id | Test $id | `closed` |',
    );
  }
  return [
    '# Receipt Bug Regression Ledger',
    '',
    'Allowed categories:',
    '- `qa_harness`',
    '| Bug ID | Category | Symptom | Root cause | Fix | Regression coverage | Status |',
    '| --- | --- | --- | --- | --- | --- | --- |',
    ...rows,
    '',
  ].join('\n');
}
