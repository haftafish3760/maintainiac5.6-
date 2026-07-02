import 'package:flutter_test/flutter_test.dart';

import 'helpers/receipt_native_ios_bridge_source_readers.dart';

void main() {
  test('iOS native capture diagnostics payload has no duplicate keys', () async {
    final sources = await readIosReceiptCameraBridgeSources();
    final diagnosticsBody = _nativeCaptureDiagnosticsBody(
      sources.cameraController,
    );
    final keys = _swiftDictionaryKeys(diagnosticsBody);
    final duplicateKeys = _duplicates(keys);

    expect(keys, isNotEmpty);
    expect(
      duplicateKeys,
      isEmpty,
      reason:
          'Duplicate diagnostics keys hide overwritten values and Swift compile warnings.',
    );
  });
}

String _nativeCaptureDiagnosticsBody(String source) {
  const functionName = 'func nativeCaptureDiagnostics(';
  final start = source.indexOf(functionName);
  expect(start, isNonNegative, reason: 'nativeCaptureDiagnostics must exist.');

  const endMarker = '\n  func ';
  final nextFunction = source.indexOf(endMarker, start + functionName.length);
  if (nextFunction == -1) {
    return source.substring(start);
  }
  return source.substring(start, nextFunction);
}

List<String> _swiftDictionaryKeys(String source) {
  final keyPattern = RegExp(r'^\s+"([^"]+)":', multiLine: true);
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
