import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_diagnostics_policy.dart';

void main() {
  test(
    'blocks receipt camera diagnostics until improvement opt-in is enabled',
    () {
      const policy = ReceiptCaptureDiagnosticPublishPolicy();
      const diagnostic = {
        'captureFlow': 'maintainiac_native_receipt_camera',
        'nativeCaptureFailureReason': 'native_camera_plugin_missing',
      };

      expect(
        policy.shouldPublish(improvementOptIn: false, diagnostic: diagnostic),
        isFalse,
      );
      expect(
        policy.envelope(improvementOptIn: false, diagnostic: diagnostic),
        isEmpty,
      );
    },
  );

  test('published camera diagnostics carry machine-only privacy flags', () {
    const policy = ReceiptCaptureDiagnosticPublishPolicy();
    const diagnostic = {
      'captureFlow': 'maintainiac_native_receipt_camera',
      'nativeCaptureFailureReason': 'native_camera_plugin_missing',
    };

    final envelope = policy.envelope(
      improvementOptIn: true,
      diagnostic: diagnostic,
    );

    expect(envelope['cameraDiagnosticsImprovementOptIn'], isTrue);
    expect(envelope['adminDiagnosticOwnerImagePreviewAllowed'], isFalse);
    expect(envelope['captureFlow'], 'maintainiac_native_receipt_camera');
    expect(envelope.toString().toLowerCase(), isNot(contains('receipt text')));
    expect(envelope.toString().toLowerCase(), isNot(contains('/tmp/')));
  });
}
