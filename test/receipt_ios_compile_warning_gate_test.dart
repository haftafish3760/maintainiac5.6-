import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('iOS compile gate rejects first-party receipt camera warnings', () async {
    final gate = await File(
      'tool/ios_receipt_camera_compile_gate.sh',
    ).readAsString();

    expect(gate, contains('set -euo pipefail'));
    expect(gate, contains('mktemp'));
    expect(gate, contains(r'''2>&1 | tee "$BUILD_LOG"'''));
    expect(
      gate,
      contains("grep -Eq '/ios/Runner/[^:]+:[0-9]+:[0-9]+: warning:'"),
    );
    expect(
      gate,
      contains('First-party iOS receipt-camera warnings are not allowed:'),
    );
    expect(
      gate,
      contains(
        'iOS receipt camera compile gate passed with no first-party Swift warnings.',
      ),
    );
  });
}
