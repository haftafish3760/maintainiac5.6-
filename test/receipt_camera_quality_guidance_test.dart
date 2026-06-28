import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  test(
    'receipt quality scoring gives real receipts a bounded review score',
    () {
      const unreadable = ReceiptPhotoQualityCheck(
        width: 0,
        height: 0,
        focusScore: 0,
        isLikelyReadable: false,
      );
      const blurry = ReceiptPhotoQualityCheck(
        width: 900,
        height: 1100,
        focusScore: 5,
        isLikelyReadable: false,
      );
      const readable = ReceiptPhotoQualityCheck(
        width: 1600,
        height: 2200,
        focusScore: 14,
        isLikelyReadable: true,
      );

      expect(unreadable.reviewScore, 0);
      expect(blurry.reviewScore, inInclusiveRange(1, 60));
      expect(readable.reviewScore, greaterThan(blurry.reviewScore));
      expect(readable.reviewScore, inInclusiveRange(80, 100));
      expect(blurry.focusLabel, 'may be blurry');
      expect(blurry.reviewTitle, 'Retake Recommended');
      expect(blurry.reviewGuidance, contains('Tap the receipt text'));
      expect(readable.focusLabel, 'sharp');
    },
  );

  test('review guidance separates soft warnings from critical retakes', () {
    const soft = ReceiptPhotoQualityCheck(
      width: 1600,
      height: 2200,
      focusScore: 7,
      brightness: 130,
      contrast: 30,
      cropScore: .7,
      textBandScore: 10,
      isLikelyReadable: false,
    );
    const glare = ReceiptPhotoQualityCheck(
      width: 1600,
      height: 2200,
      focusScore: 14,
      brightness: 240,
      contrast: 30,
      cropScore: .7,
      textBandScore: 10,
      isLikelyReadable: false,
    );

    expect(soft.needsReview, isTrue);
    expect(soft.hasCriticalIssue, isFalse);
    expect(soft.canContinueWithReview, isTrue);
    expect(soft.reviewTitle, 'Check Before Continuing');
    expect(soft.reviewGuidance, contains('Zoom in and check'));
    expect(glare.hasCriticalIssue, isTrue);
    expect(glare.canContinueWithReview, isFalse);
    expect(glare.reviewTitle, 'Retake Recommended');
    expect(glare.reviewGuidance, contains('Reduce glare'));
  });

  test('receipt framing warnings do not fight readable dark borders', () {
    const readableWithDarkBorder = ReceiptPhotoQualityCheck(
      width: 1600,
      height: 2200,
      focusScore: 14,
      brightness: 135,
      contrast: 34,
      cropScore: .32,
      textBandScore: 12,
      isLikelyReadable: true,
    );
    const possiblyCutOff = ReceiptPhotoQualityCheck(
      width: 1600,
      height: 2200,
      focusScore: 14,
      brightness: 135,
      contrast: 34,
      cropScore: .22,
      textBandScore: 12,
      isLikelyReadable: false,
    );

    expect(readableWithDarkBorder.isPoorlyFramed, isFalse);
    expect(readableWithDarkBorder.needsReview, isFalse);
    expect(possiblyCutOff.isPoorlyFramed, isTrue);
    expect(possiblyCutOff.hasCriticalIssue, isFalse);
    expect(possiblyCutOff.reviewGuidance, contains('If every line'));
  });

  test(
    'native camera contract carries user control and OCR-first rules',
    () async {
      final contract = await File(
        'lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart',
      ).readAsString();
      final androidActivity = await File(
        'android/app/src/main/kotlin/com/maintainiac/ReceiptCameraActivity.kt',
      ).readAsString();
      final iosController = await File(
        'ios/Runner/ReceiptCameraViewController.swift',
      ).readAsString();

      expect(contract, contains('manualShutterAlwaysAvailable = true'));
      expect(contract, contains('autoCaptureEnabled = false'));
      expect(contract, contains('tapFocusEnabled = true'));
      expect(contract, contains('pinchZoomEnabled = true'));
      expect(contract, contains('exposureSliderEnabled = true'));
      expect(contract, contains('edgeDetectionEnabled = true'));
      expect(contract, contains('previousSectionGhostGuideEnabled = true'));
      expect(contract, contains('ocrUsesOriginalFirst = true'));
      expect(contract, contains('queueAcceptedCaptureLocally = true'));
      expect(androidActivity, contains('Take receipt photo'));
      expect(androidActivity, contains('Receipt camera settings'));
      expect(androidActivity, contains('manualShutterAlwaysAvailable'));
      expect(androidActivity, contains('ocrUsesOriginalFirst'));
      expect(iosController, contains('Take receipt photo'));
      expect(iosController, contains('Receipt camera settings'));
      expect(iosController, contains('manualShutterAlwaysAvailable'));
      expect(iosController, contains('ocrUsesOriginalFirst'));
    },
  );
}
