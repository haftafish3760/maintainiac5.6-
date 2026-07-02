import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shared flow exposes native UI and reader handoff health evidence', () async {
    final flow =
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_flow.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_flow_recovery.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_flow_recovery_results.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_flow_handoff_signals.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_flow_handoff_risks.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_flow_native_signals.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_flow_capture_and_review.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_flow_review_result.dart',
        ).readAsString();
    final models =
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_models.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_review_result_helper_health_codes.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_review_result_helper_control_health_codes.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_review_result_helper_counts.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_review_result_native_signals.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_review_result_settings_health.dart',
        ).readAsString();

    expect(flow, contains('native_camera_ui_health_available'));
    expect(flow, contains('native_camera_ui_'));
    expect(flow, contains('_nativeCameraUiDocumentSignalsFor'));
    expect(flow, contains('_nativeCameraUiRiskFlagsFor'));
    expect(flow, contains('_nativeCloseCapturedPhotoDocumentSignalsFor'));
    expect(flow, contains('_nativeCloseCapturedPhotoRiskFlagsFor'));
    expect(flow, contains('_receiptReaderHandoffDiagnosticsFor'));
    expect(flow, contains('receiptReaderHandoffOutcome'));
    expect(flow, contains('receiptReaderHandoffActionLabel'));
    expect(flow, contains('receiptReaderHandoffRoute'));
    expect(flow, contains('receiptReaderHandoffNextScreen'));
    expect(flow, contains('receiptReaderHandoffNextStepLabel'));
    expect(flow, contains('receiptReaderHandoffMustOpenReceiptDetails'));
    expect(flow, contains('receiptReaderHandoffMustOpenFilledReview'));
    expect(flow, contains('receiptReaderHandoffUserAction'));
    expect(flow, contains('receiptReaderHandoffEvidence'));
    expect(flow, contains('result.acceptedPhotoHandoffOutcome'));
    expect(flow, contains('result.acceptedPhotoHandoffActionLabel'));
    expect(flow, contains('result.acceptedPhotoWarningProfile'));
    expect(flow, contains('result.acceptedPhotoHandoffRoute'));
    expect(flow, contains('result.acceptedPhotoHandoffNextScreen'));
    expect(flow, contains('result.acceptedPhotoHandoffNextStepLabel'));
    expect(flow, contains('result.acceptedPhotoHandoffMustOpenReceiptDetails'));
    expect(flow, contains('result.acceptedPhotoHandoffMustOpenFilledReview'));
    expect(flow, contains('result.acceptedPhotoHandoffUserAction'));
    expect(flow, contains('result.acceptedPhotoHandoffEvidenceLabel'));
    expect(flow, contains('nativeCameraUiHealthOutcome'));
    expect(flow, contains('nativeCameraUiHealthCounts'));
    expect(flow, contains('nativeCloseCapturedPhotoHealthOutcome'));
    expect(flow, contains('nativeCloseCapturedPhotoActionLabel'));
    expect(flow, contains('nativeCloseCapturedPhotoOutcomeCounts'));
    expect(models, contains('_nativeSettingsControlHealthCodes'));
    expect(models, contains('nativeCloseCapturedPhotoHealthOutcome'));
    expect(models, contains('nativeCloseCapturedPhotoActionLabel'));
    expect(models, contains('nativeCloseCapturedPhotoOutcomeCounts'));
    expect(models, contains('closeCapturedPhotoOutcome'));
    expect(models, contains('settings_control_visible'));
    expect(models, contains('settings_contract_v1'));
    expect(models, contains('settings_button_top_bar_right'));
    expect(models, contains('settings_contract_missing'));
    expect(models, contains('settings_control_missing'));
  });
}
