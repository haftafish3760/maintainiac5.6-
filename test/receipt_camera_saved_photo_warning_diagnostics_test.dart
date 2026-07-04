import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  test('native saved-photo diagnostics explain preview capture mismatch', () {
    final darkerThanPreview =
        ReceiptNativeSavedPhotoReviewWarning.fromDiagnostics(const {
          'latestCapturedExposureMismatch': 'live_ok_capture_too_dark',
          'latestCapturedBrightnessBucket': 'captured_too_dark',
        });
    final dimmerThanPreview =
        ReceiptNativeSavedPhotoReviewWarning.fromDiagnostics(const {
          'latestCapturedExposureMismatch': 'live_ok_capture_dim',
          'latestCapturedBrightnessBucket': 'captured_dim',
        });
    final brightnessAssistFailed =
        ReceiptNativeSavedPhotoReviewWarning.fromDiagnostics(const {
          'latestCapturedExposureMismatch':
              'pre_capture_brightened_still_too_dark',
          'latestCapturedBrightnessBucket': 'captured_too_dark',
        });
    final brightnessAssistStillDim =
        ReceiptNativeSavedPhotoReviewWarning.fromDiagnostics(const {
          'latestCapturedExposureMismatch': 'pre_capture_brightened_still_dim',
          'latestCapturedBrightnessBucket': 'captured_dim',
          'latestCapturedAverageLuma': 91.2,
          'latestCapturedEdgeScore': 8.4,
        });
    final soft = ReceiptNativeSavedPhotoReviewWarning.fromDiagnostics(const {
      'latestCapturedSharpnessBucket': 'captured_soft_blur_risk',
    });
    final glare = ReceiptNativeSavedPhotoReviewWarning.fromDiagnostics(const {
      'latestCapturedBrightnessBucket': 'captured_glare_risk',
    });
    final shadow = ReceiptNativeSavedPhotoReviewWarning.fromDiagnostics(const {
      'latestReadabilitySignal': 'shadow_risk',
      'latestCapturedAverageLuma': 82.0,
      'latestCapturedEdgeScore': 6.0,
    });
    final checkSharpness = ReceiptNativeSavedPhotoReviewWarning.fromDiagnostics(
      const {'latestCapturedSharpnessBucket': 'captured_soft'},
    );
    final bottomDark = ReceiptNativeSavedPhotoReviewWarning.fromDiagnostics(
      const {'latestCapturedVerticalQualitySignal': 'bottom_darker_than_upper'},
    );
    final bottomDarkerThanTop =
        ReceiptNativeSavedPhotoReviewWarning.fromDiagnostics(const {
          'latestCapturedBottomTopLumaDelta': -31.4,
          'latestCapturedBottomTopLumaDeltaBucket': 'bottom_darker_than_top',
        });
    final bottomMuchDarkerThanTop =
        ReceiptNativeSavedPhotoReviewWarning.fromDiagnostics(const {
          'latestCapturedBottomTopLumaDelta': -48.0,
          'latestCapturedBottomTopLumaDeltaBucket':
              'bottom_much_darker_than_top',
        });
    final bottomDarkerButReadable =
        ReceiptNativeSavedPhotoReviewWarning.maybeFromDiagnostics(const {
          'latestCapturedBottomTopLumaDelta': -31.4,
          'latestCapturedBottomTopLumaDeltaBucket': 'bottom_darker_than_top',
          'latestCapturedBottomLuma': 112.0,
          'latestCapturedEdgeScore': 16.0,
        });
    final bottomBogusNativeNumber =
        ReceiptNativeSavedPhotoReviewWarning.fromDiagnostics(const {
          'latestCapturedBottomTopLumaDeltaBucket': 'bottom_darker_than_top',
          'latestCapturedBottomLuma': double.infinity,
          'latestCapturedEdgeScore': 16.0,
        });
    final bottomSoft = ReceiptNativeSavedPhotoReviewWarning.fromDiagnostics(
      const {'latestCapturedVerticalQualitySignal': 'bottom_soft_blur_risk'},
    );
    final borderlineDimButReadable =
        ReceiptNativeSavedPhotoReviewWarning.maybeFromDiagnostics(const {
          'latestCapturedExposureMismatch': 'live_ok_capture_dim',
          'latestCapturedBrightnessBucket': 'captured_dim',
          'latestCapturedAverageLuma': 102.4,
          'latestCapturedEdgeScore': 18.6,
        });
    final brightReadablePaper =
        ReceiptNativeSavedPhotoReviewWarning.maybeFromDiagnostics(const {
          'latestCapturedBrightnessBucket': 'captured_glare_risk',
          'latestCapturedAverageLuma': 246.8,
          'latestCapturedEdgeScore': 19.1,
        });
    final ok = ReceiptNativeSavedPhotoReviewWarning.fromDiagnostics(const {});

    expect(darkerThanPreview.code, 'saved_photo_darker_than_preview');
    expect(darkerThanPreview.isCritical, isTrue);
    expect(darkerThanPreview.message, contains('Retake with more light'));
    expect(darkerThanPreview.primaryActionLabel, 'Retake with more light');
    expect(dimmerThanPreview.code, 'saved_photo_dimmer_than_preview');
    expect(dimmerThanPreview.isCritical, isFalse);
    expect(dimmerThanPreview.message, contains('bottom looks dim'));
    expect(
      dimmerThanPreview.primaryActionLabel,
      'Check readability, then add light if needed',
    );
    expect(
      brightnessAssistFailed.code,
      'saved_photo_brightness_assist_failed_dark',
    );
    expect(brightnessAssistFailed.isCritical, isTrue);
    expect(brightnessAssistFailed.actionCode, 'turn_on_light_or_retake');
    expect(
      brightnessAssistFailed.primaryActionLabel,
      'Turn on receipt light or retake',
    );
    expect(
      brightnessAssistStillDim.code,
      'saved_photo_brightness_assist_still_dim',
    );
    expect(brightnessAssistStillDim.isCritical, isFalse);
    expect(brightnessAssistStillDim.message, contains('Add light or retake'));
    expect(soft.code, 'saved_photo_soft_blur_risk');
    expect(soft.isCritical, isTrue);
    expect(soft.message, contains('holding steady'));
    expect(glare.code, 'saved_photo_glare_risk');
    expect(glare.message, contains('totals are washed out'));
    expect(shadow.code, 'saved_photo_shadow_risk');
    expect(shadow.actionCode, 'move_to_even_light_or_retake');
    expect(shadow.parserRiskCode, 'ocr_shadowed_text_may_fail');
    expect(shadow.message, contains('even light'));
    expect(checkSharpness.code, 'saved_photo_ok');
    expect(bottomDark.code, 'saved_photo_bottom_too_dark');
    expect(bottomDark.message, contains('bottom receipt lines'));
    expect(bottomDark.prefersAddSection, isTrue);
    expect(
      bottomDark.primaryActionLabel,
      'Add Another Photo or raise Brightness for the bottom lines',
    );
    expect(bottomDarkerThanTop.code, 'saved_photo_bottom_too_dark');
    expect(bottomDarkerThanTop.parserRiskCode, 'ocr_bottom_total_may_fail');
    expect(bottomDarkerThanTop.prefersAddSection, isTrue);
    expect(bottomMuchDarkerThanTop.code, 'saved_photo_bottom_too_dark');
    expect(
      bottomMuchDarkerThanTop.message,
      contains('Add Another Photo for a clearer bottom section'),
    );
    expect(bottomDarkerButReadable, isNull);
    expect(bottomBogusNativeNumber.code, 'saved_photo_bottom_too_dark');
    expect(bottomBogusNativeNumber.parserRiskCode, 'ocr_bottom_total_may_fail');
    expect(bottomSoft.code, 'saved_photo_bottom_soft');
    expect(bottomSoft.prefersAddSection, isTrue);
    expect(bottomSoft.actionCode, 'check_bottom_or_retake');
    expect(soft.prefersAddSection, isFalse);
    expect(borderlineDimButReadable, isNull);
    expect(brightReadablePaper, isNull);
    expect(ok.code, 'saved_photo_ok');
    expect(ok.shouldSurface, isFalse);
  });
}
