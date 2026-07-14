import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_attachment_duplicate_detector.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_ocr_service.dart';

void main() {
  ReceiptAttachmentRecord photo(String id, String hash) {
    return ReceiptAttachmentRecord(
      id: id,
      path: '/missing/$id.jpg',
      kind: ReceiptAttachmentKind.photo,
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      createdAt: DateTime(2026, 7, 13),
      fileHash: hash,
    );
  }

  test('only exact-content receipt photos are marked duplicate', () async {
    final report = await detectDuplicateReceiptPhotos([
      photo('first', 'same-content'),
      photo('second', 'same-content'),
      photo('next-section', 'different-content'),
    ]);

    expect(report.duplicateAttachmentIndexes, {1});
  });

  test(
    'falls back to exact file content when a stored hash is unavailable',
    () async {
      final directory = await Directory.systemTemp.createTemp('receipt_ocr_');
      try {
        final photoFile = File('${directory.path}/receipt.jpg');
        await photoFile.writeAsBytes([1, 2, 3, 4]);

        final report = await detectDuplicateReceiptPhotos([
          ReceiptAttachmentRecord(
            id: 'first',
            path: photoFile.path,
            kind: ReceiptAttachmentKind.photo,
            dataSaverLevel: ReceiptDataSaverLevel.balanced,
            createdAt: DateTime(2026, 7, 13),
          ),
          ReceiptAttachmentRecord(
            id: 'second',
            path: photoFile.path,
            kind: ReceiptAttachmentKind.photo,
            dataSaverLevel: ReceiptDataSaverLevel.balanced,
            createdAt: DateTime(2026, 7, 13),
          ),
        ]);

        expect(report.duplicateAttachmentIndexes, {1});
      } finally {
        await directory.delete(recursive: true);
      }
    },
  );

  test('repeated attachment IDs retain every imported receipt text', () async {
    final result = await const ReceiptOcrService()
        .recognizeTextFromAttachments([
          ReceiptAttachmentRecord(
            id: 'reused-id',
            path: '',
            kind: ReceiptAttachmentKind.emailText,
            dataSaverLevel: ReceiptDataSaverLevel.balanced,
            createdAt: DateTime(2026, 7, 13),
            importedText: 'FIRST RECEIPT',
          ),
          ReceiptAttachmentRecord(
            id: 'reused-id',
            path: '',
            kind: ReceiptAttachmentKind.emailText,
            dataSaverLevel: ReceiptDataSaverLevel.balanced,
            createdAt: DateTime(2026, 7, 13),
            importedText: 'SECOND RECEIPT',
          ),
        ]);

    expect(
      result.textByAttachmentId['reused-id'],
      'FIRST RECEIPT\nSECOND RECEIPT',
    );
    expect(result.stats.importedTextRead, 2);
    expect(result.warnings.join(' '), contains('same identifier'));
  });

  test(
    'OCR reads the first exact duplicate once and warns for review',
    () async {
      final result = await const ReceiptOcrService(maxPhotoOcrAttachments: 8)
          .recognizeTextFromAttachments([
            photo('first', 'same-content'),
            photo('second', 'same-content'),
            ReceiptAttachmentRecord(
              id: 'text',
              path: '',
              kind: ReceiptAttachmentKind.emailText,
              dataSaverLevel: ReceiptDataSaverLevel.balanced,
              createdAt: DateTime(2026, 7, 13),
              importedText: 'STORE\nTOTAL 12.99',
            ),
          ]);

      expect(result.stats.duplicatePhotosSkipped, 1);
      expect(result.stats.photosSkipped, 1);
      expect(
        result.warnings.join(' '),
        contains('selected photo appears identical'),
      );
      expect(
        result.structuredWarnings
            .firstWhere(
              (warning) => warning.message.contains(
                'identical to an earlier receipt photo',
              ),
            )
            .kind,
        ReceiptOcrWarningKind.sourceSkipped,
      );
      expect(result.hasText, isTrue);
    },
  );
}
