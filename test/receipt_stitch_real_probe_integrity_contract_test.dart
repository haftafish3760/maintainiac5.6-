import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('real receipt stitch probes verify source integrity', () {
    final scripts = <File>[
      File('tool/receipt_stitch_real_probe.sh'),
      File('tool/receipt_stitch_real_window_probe.sh'),
      File('tool/receipt_stitch_real_window_matrix.sh'),
    ];

    for (final script in scripts) {
      expect(script.existsSync(), isTrue, reason: script.path);
      final source = script.readAsStringSync();
      expect(source, contains('shasum -a 256'));
      expect(source, contains('Receipt stitch altered source image:'));
      expect(source, contains('Receipt stitch source integrity: PASS'));
    }
  });

  test('receipt stitch health gate retains real-probe contracts', () {
    final source = File('tool/receipt_stitch_contract_health.sh')
        .readAsStringSync();

    expect(source, contains('run_flutter_test real-probe-contracts'));
    expect(source, contains('run_real_probe_contracts'));
  });
}
