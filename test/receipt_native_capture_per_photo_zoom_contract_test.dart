import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('native capture preserves shutter zoom per staged photo', () async {
    final android = await File(
      'android/app/src/main/kotlin/com/maintainiac/ReceiptCameraDiagnosticsPayload.kt',
    ).readAsString();
    final staging = await File(
      'lib/shared/widgets/receipt_capture/receipt_native_capture_staging_stage_helpers.dart',
    ).readAsString();
    final diagnostics = await File(
      'lib/shared/widgets/receipt_capture/receipt_native_capture_staging_diagnostics.dart',
    ).readAsString();

    expect(android, contains('captureShutterZoomByPath'));
    expect(staging, contains('_stagedShutterZoom'));
    expect(diagnostics, contains("'captureShutterZoomScope': 'per_photo'"));
    expect(diagnostics, contains('shutterZoomRatio'));
  });
}
