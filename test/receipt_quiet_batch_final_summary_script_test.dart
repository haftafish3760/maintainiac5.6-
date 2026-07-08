import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'quiet batch status stays metadata-only and final summary is separate',
    () {
      final statusScript = File('tool/receipt_quiet_batch_status.sh');
      final summaryScript = File('tool/receipt_quiet_batch_final_summary.sh');
      expect(statusScript.existsSync(), isTrue);
      expect(summaryScript.existsSync(), isTrue);

      final statusSource = statusScript.readAsStringSync();
      expect(statusSource, contains('Prints quiet-batch status metadata only'));
      expect(statusSource, contains('runner_started='));
      expect(statusSource, contains('runner_finished='));
      expect(statusSource, isNot(contains('tail -80')));
      expect(statusSource, isNot(contains('grep -E')));

      final summarySource = summaryScript.readAsStringSync();
      expect(summarySource, contains(r'batch=$name status=$status'));
      expect(
        summarySource,
        contains("grep -E '^(START|END|EXIT_CODE|.*: PASS\$|PASS )'"),
      );
      expect(summarySource, contains(r'tail -80 "$log_file"'));
      expect(summarySource, isNot(contains('tail -f')));
    },
  );
}
