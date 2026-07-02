import 'package:flutter_test/flutter_test.dart';

import 'helpers/receipt_native_android_bridge_source_readers.dart';

void main() {
  test(
    'Android native capture diagnostics payload has no duplicate keys',
    () async {
      final sources = await readAndroidReceiptCameraBridgeSources();
      final diagnosticsBody = _nativeCaptureDiagnosticsBody(
        sources.cameraActivity,
      );
      final keys = _kotlinMapKeys(diagnosticsBody);
      final duplicateKeys = _duplicates(keys);

      expect(keys, isNotEmpty);
      expect(
        duplicateKeys,
        isEmpty,
        reason:
            'Duplicate diagnostics keys hide overwritten values and make admin reports unreliable.',
      );
    },
  );
}

String _nativeCaptureDiagnosticsBody(String source) {
  const functionName = 'nativeCaptureDiagnostics(';
  final start = source.indexOf(functionName);
  expect(start, isNonNegative, reason: 'nativeCaptureDiagnostics must exist.');

  const endMarker = '\n}\n';
  final end = source.indexOf(endMarker, start + functionName.length);
  if (end == -1) {
    return source.substring(start);
  }
  return source.substring(start, end);
}

List<String> _kotlinMapKeys(String source) {
  final keyPattern = RegExp(r'^\s+"([^"]+)" to ', multiLine: true);
  return [for (final match in keyPattern.allMatches(source)) match.group(1)!];
}

Set<String> _duplicates(List<String> values) {
  final seen = <String>{};
  final duplicates = <String>{};
  for (final value in values) {
    if (!seen.add(value)) {
      duplicates.add(value);
    }
  }
  return duplicates;
}
