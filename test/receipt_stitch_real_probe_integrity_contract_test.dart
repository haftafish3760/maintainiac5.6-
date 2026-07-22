import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('real receipt stitch probes verify source integrity', () {
    for (final path in const [
      'tool/receipt_stitch_real_probe.sh',
      'tool/receipt_stitch_real_window_probe.sh',
      'tool/receipt_stitch_real_window_matrix.sh',
    ]) {
      final source = File(path).readAsStringSync();
      expect(source, contains('shasum -a 256'), reason: path);
      expect(
        source,
        contains('Receipt stitch altered source image:'),
        reason: path,
      );
      expect(
        source,
        contains('Receipt stitch source integrity: PASS'),
        reason: path,
      );
      expect(source, contains(r'${FLUTTER_BIN:-flutter}'), reason: path);
    }
  });

  test('real receipt stitch probes execute without altering sources', () async {
    final temp = await Directory.systemTemp.createTemp(
      'receipt-probe-integrity-',
    );
    addTearDown(() => temp.delete(recursive: true));
    final first = File('${temp.path}/first.jpg')..writeAsStringSync('first');
    final second = File('${temp.path}/second.jpg')..writeAsStringSync('second');
    final environment = <String, String>{
      ...Platform.environment,
      'FLUTTER_BIN': '/usr/bin/true',
    };

    final invocations = <(String, List<String>)>[
      ('tool/receipt_stitch_real_probe.sh', [first.path, second.path]),
      ('tool/receipt_stitch_real_window_probe.sh', [first.path, '900', '620']),
      ('tool/receipt_stitch_real_window_matrix.sh', [first.path, '900:620']),
    ];
    for (final invocation in invocations) {
      final result = await Process.run(
        invocation.$1,
        invocation.$2,
        environment: environment,
      );
      expect(result.exitCode, 0, reason: '${invocation.$1}: ${result.stderr}');
      expect(
        result.stdout,
        contains('Receipt stitch source integrity: PASS'),
        reason: invocation.$1,
      );
    }

    expect(first.readAsStringSync(), 'first');
    expect(second.readAsStringSync(), 'second');
  });
}
