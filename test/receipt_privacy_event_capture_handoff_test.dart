import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_assistance_policy.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_ocr_service.dart';

void main() {
  test(
    'camera capture privacy event reports buckets without image content',
    () {
      const quality = ReceiptPhotoQualityCheck(
        width: 1600,
        height: 2200,
        focusScore: 15,
        brightness: 142,
        contrast: 38,
        cropScore: .76,
        textBandScore: 12,
        isLikelyReadable: true,
      );

      final event = PrivacySafeReceiptEvent.fromCapture(
        type: PrivacySafeReceiptEventType.receiptCaptureCompleted,
        featureArea: 'expense receipts',
        capability: const ReceiptDeviceCapability.standard(),
        captureMode: 'assisted_auto',
        captureOutcome: 'completed',
        quality: quality,
        photoSectionCount: 2,
        retakeCount: 1,
        captureDurationMs: 3200,
      );
      final map = event.toMap();
      final encoded = map.toString().toLowerCase();

      expect(
        map['event'],
        PrivacySafeReceiptEventType.receiptCaptureCompleted.name,
      );
      expect(map['featureArea'], 'expense_receipts');
      expect(map['capabilityTier'], ReceiptCapabilityTier.medium.name);
      expect(map['captureMode'], 'assisted_auto');
      expect(map['captureOutcome'], 'completed');
      expect(map['focusBucket'], 'sharp');
      expect(map['readabilityBucket'], 'high');
      expect(map['photoSectionCount'], 2);
      expect(map['retakeCount'], 1);
      expect(map['captureDurationMs'], 3200);
      expect(encoded, isNot(contains('lowes')));
      expect(encoded, isNot(contains('/tmp')));
      expect(encoded, isNot(contains('.jpg')));
    },
  );

  test(
    'OCR privacy event carries source handoff buckets without receipt content',
    () async {
      final result = await const ReceiptOcrService()
          .recognizeTextFromAttachments([
            _textAttachment(
              id: 'handoff',
              text: 'LOWES\nTOTAL 3.24',
              documentSignals: const [
                'receipt_handoff_possible_partial_receipt',
                'receipt_handoff_stitch_fallback',
                'multiple_ocr_sources_fallback',
                'scanner_decision_ocr_source_original_selected_quality_guard',
                'native_capture_source_phone_camera_backup',
              ],
              riskFlags: const ['ocr_source_saved_photo_soft_blur_risk'],
            ),
          ]);

      final event = PrivacySafeReceiptEvent.fromOcrResult(result: result);
      final map = event.toMap();
      final encoded = map.toString().toLowerCase();

      expect(map['ocrSourceHandoffStatus'], 'possible_partial_receipt');
      expect(map['ocrSourceHandoffSignalCounts'], {
        'receipt_handoff_possible_partial_receipt': 1,
        'receipt_handoff_stitch_fallback': 1,
      });
      expect(map['ocrSourceStitchSignalCounts'], {
        'receipt_handoff_stitch_fallback': 1,
        'multiple_ocr_sources_fallback': 1,
      });
      expect(map['ocrSourceScannerDecisionCounts'], {
        'scanner_decision_ocr_source_original_selected_quality_guard': 1,
      });
      expect(map['ocrSourceCaptureSourceSignalCounts'], {
        'native_capture_source_phone_camera_backup': 1,
      });
      expect(map['ocrSourcePhotoQualityRiskCounts'], {
        'ocr_source_saved_photo_soft_blur_risk': 1,
      });
      expect(encoded, isNot(contains('lowes')));
      expect(encoded, isNot(contains('3.24')));
      expect(encoded, isNot(contains('/tmp')));
    },
  );
}

ReceiptAttachmentRecord _textAttachment({
  required String id,
  required String text,
  List<String> documentSignals = const [],
  List<String> riskFlags = const [],
}) {
  return ReceiptAttachmentRecord(
    id: id,
    path: '',
    kind: ReceiptAttachmentKind.emailText,
    dataSaverLevel: ReceiptDataSaverLevel.balanced,
    createdAt: DateTime(2026, 6, 23),
    importedText: text,
    documentSignals: documentSignals,
    riskFlags: riskFlags,
  );
}
