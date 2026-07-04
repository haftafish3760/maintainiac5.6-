import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_ocr_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory documentsDirectory;

  setUp(() async {
    documentsDirectory = await Directory.systemTemp.createTemp(
      'receipt_proof_storage_test_',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => switch (call.method) {
            'getApplicationDocumentsDirectory' => documentsDirectory.path,
            _ => null,
          },
        );
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
    if (await documentsDirectory.exists()) {
      await documentsDirectory.delete(recursive: true);
    }
  });

  test('ocr service warns when saved proof copy is small', () async {
    final result = await const ReceiptOcrService(maxPhotoOcrAttachments: 0)
        .recognizeTextFromAttachments([
          ReceiptAttachmentRecord(
            id: 'tiny-proof',
            path: '/tmp/tiny-proof.jpg',
            kind: ReceiptAttachmentKind.photo,
            dataSaverLevel: ReceiptDataSaverLevel.maximum,
            createdAt: DateTime(2026, 6, 29),
            riskFlags: const [
              'ocr_source_small_proof_copy_review_required',
              'ocr_source_proof_data_saver_maximum',
            ],
          ),
        ]);

    expect(result.hasText, isFalse);
    expect(result.stats.photosSkipped, 1);
    expect(result.warnings.join(' '), contains('proof copy is small'));
    expect(result.warnings.join(' '), contains('review the saved proof image'));
    expect(
      result.structuredWarnings.map((warning) => warning.kind),
      contains(ReceiptOcrWarningKind.photoQuality),
    );
    expect(
      result.sourceHandoffSummary.photoQualityRiskCounts,
      containsPair('ocr_source_small_proof_copy_review_required', 1),
    );
  });

  test('ocr service warns when scanner prep used a quality guard', () async {
    final result = await const ReceiptOcrService(maxPhotoOcrAttachments: 0)
        .recognizeTextFromAttachments([
          ReceiptAttachmentRecord(
            id: 'quality-guard',
            path: '/tmp/quality-guard.jpg',
            kind: ReceiptAttachmentKind.photo,
            dataSaverLevel: ReceiptDataSaverLevel.balanced,
            createdAt: DateTime(2026, 6, 29),
            riskFlags: const [
              'ocr_source_cleanup_skipped_quality_guard',
              'ocr_source_ocr_source_full_quality_selected_quality_guard',
            ],
          ),
        ]);

    expect(result.hasText, isFalse);
    expect(result.stats.photosSkipped, 1);
    expect(result.warnings.join(' '), contains('image cleanup needs review'));
    expect(result.warnings.join(' '), contains('safest available source'));
    expect(
      result.structuredWarnings.map((warning) => warning.kind),
      contains(ReceiptOcrWarningKind.photoQuality),
    );
    expect(
      result.sourceHandoffSummary.photoQualityRiskCounts,
      containsPair('ocr_source_cleanup_skipped_quality_guard', 1),
    );
    expect(result.sourceHandoffSummary.status, 'scanner_prep_review_needed');
    expect(
      result.diagnostics.ocrSourceHandoffStatus,
      'scanner_prep_review_needed',
    );
    expect(
      result.diagnostics.ocrSourceHandoffContract['status'],
      'scanner_prep_review_needed',
    );
  });

  test(
    'ocr service warns when scanner prep failed or skipped cleanup',
    () async {
      final result = await const ReceiptOcrService(maxPhotoOcrAttachments: 0)
          .recognizeTextFromAttachments([
            ReceiptAttachmentRecord(
              id: 'decode-failed',
              path: '/tmp/decode-failed.jpg',
              kind: ReceiptAttachmentKind.photo,
              dataSaverLevel: ReceiptDataSaverLevel.balanced,
              createdAt: DateTime(2026, 6, 29),
              riskFlags: const ['ocr_source_decode_failed_native_processor'],
            ),
            ReceiptAttachmentRecord(
              id: 'cleanup-skipped',
              path: '/tmp/cleanup-skipped.jpg',
              kind: ReceiptAttachmentKind.photo,
              dataSaverLevel: ReceiptDataSaverLevel.balanced,
              createdAt: DateTime(2026, 6, 29),
              riskFlags: const ['ocr_source_cleanup_skipped_no_edges'],
            ),
          ]);

      expect(result.hasText, isFalse);
      expect(result.stats.photosSkipped, 2);
      expect(
        result.warnings.where(
          (warning) => warning.contains('image cleanup needs review'),
        ),
        hasLength(2),
      );
      expect(
        result.structuredWarnings.where(
          (warning) => warning.kind == ReceiptOcrWarningKind.photoQuality,
        ),
        hasLength(2),
      );
      expect(
        result.sourceHandoffSummary.photoQualityRiskCounts,
        containsPair('ocr_source_decode_failed_native_processor', 1),
      );
      expect(
        result.sourceHandoffSummary.photoQualityRiskCounts,
        containsPair('ocr_source_cleanup_skipped_no_edges', 1),
      );
    },
  );
}
