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

  test(
    'published camera diagnostics drop receipt content paths and devices',
    () {
      const policy = ReceiptCaptureDiagnosticPublishPolicy();
      const diagnostic = {
        'captureFlow': 'maintainiac_native_receipt_camera',
        'nativeCaptureFailureReason': 'native_camera_plugin_missing',
        'sourcePath': '/tmp/private-receipt.jpg',
        'receiptText': 'PRIVATE STORE TOTAL 51.68',
        'rawOcrText': 'PRIVATE STORE TOTAL 51.68',
        'deviceId': 'abc-private-device',
        'deviceModel': 'Galaxy_S25_Ultra',
        'deviceName': 'Robbies_Phone',
        'nested': {
          'safeCount': 1,
          'receiptText': 'PRIVATE STORE',
          'sourcePath': '/tmp/private.jpg',
        },
      };

      final envelope = policy.envelope(
        improvementOptIn: true,
        diagnostic: diagnostic,
      );
      final encoded = envelope.toString().toLowerCase();

      expect(envelope['captureFlow'], 'maintainiac_native_receipt_camera');
      expect(envelope.containsKey('sourcePath'), isFalse);
      expect(envelope.containsKey('receiptText'), isFalse);
      expect(envelope.containsKey('rawOcrText'), isFalse);
      expect(envelope.containsKey('deviceId'), isFalse);
      expect(envelope.containsKey('deviceModel'), isFalse);
      expect(envelope.containsKey('deviceName'), isFalse);
      expect(envelope['nested'], {'safeCount': 1});
      expect(encoded, isNot(contains('/tmp/')));
      expect(encoded, isNot(contains('private store')));
      expect(encoded, isNot(contains('galaxy')));
    },
  );

  test(
    'published camera diagnostics drop human-facing text and merchant-like tokens',
    () {
      const policy = ReceiptCaptureDiagnosticPublishPolicy();
      const diagnostic = {
        'captureFlow': 'maintainiac_native_receipt_camera',
        'safeReasonCode': 'ocr_source_ready',
        'operatorNote': 'LOWES_AUSTIN_TX_78745',
        'failureLabel': 'LOWES',
        'guidanceMessage': 'move_closer',
        'lineItemName': 'plumbers_putty',
        'receiptCategory': 'fuel',
        'nested': {
          'safeCode': 'stitch_ready',
          'userMessage': 'LOWES',
          'storeNameToken': 'lowes',
          'receiptLineLabel': 'sale_total_3_24',
        },
      };

      final envelope = policy.envelope(
        improvementOptIn: true,
        diagnostic: diagnostic,
      );
      final encoded = envelope.toString().toLowerCase();

      expect(envelope['captureFlow'], 'maintainiac_native_receipt_camera');
      expect(envelope['safeReasonCode'], 'ocr_source_ready');
      expect(envelope.containsKey('operatorNote'), isFalse);
      expect(envelope.containsKey('failureLabel'), isFalse);
      expect(envelope.containsKey('guidanceMessage'), isFalse);
      expect(envelope.containsKey('lineItemName'), isFalse);
      expect(envelope['receiptCategory'], 'fuel');
      expect(envelope['nested'], {'safeCode': 'stitch_ready'});
      expect(encoded, isNot(contains('lowes')));
      expect(encoded, isNot(contains('plumbers')));
      expect(encoded, isNot(contains('sale_total')));
    },
  );

  test('published camera diagnostics keep finite scores only', () {
    const policy = ReceiptCaptureDiagnosticPublishPolicy();
    const diagnostic = {
      'latestEdgeCoverage': 0.82,
      'latestMotionScore': 3.5,
      'latestShadowScore': double.nan,
      'latestFrameBrightness': double.infinity,
      'nested': {
        'latestCapturedAverageLuma': 188.25,
        'latestCapturedSharpness': double.negativeInfinity,
      },
    };

    final envelope = policy.envelope(
      improvementOptIn: true,
      diagnostic: diagnostic,
    );

    expect(envelope['latestEdgeCoverage'], 0.82);
    expect(envelope['latestMotionScore'], 3.5);
    expect(envelope.containsKey('latestShadowScore'), isFalse);
    expect(envelope.containsKey('latestFrameBrightness'), isFalse);
    expect(envelope['nested'], {'latestCapturedAverageLuma': 188.25});
  });
}
