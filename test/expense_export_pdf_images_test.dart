import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_export_handoff.dart';
import 'package:maintaniac/screens/expenses/data/expense_export_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/shared/pdf/app_generated_pdf_export_estimator.dart';
import 'package:maintaniac/shared/pdf/app_generated_pdf_service.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('thumbnail PDF export loads images only during generation', () async {
    final snapshot = buildExpenseExportSnapshot(
      receipts: [
        ExpenseReceiptRecord(
          id: 'receipt-1',
          receiptDate: DateTime(2026, 7, 9),
          merchantName: 'Parts Store',
          enteredTotal: 12,
          hasReceiptProof: true,
          attachments: [
            ReceiptAttachmentRecord(
              id: 'photo-1',
              path: '/cloud-only/photo-1.jpg',
              kind: ReceiptAttachmentKind.photo,
              dataSaverLevel: ReceiptDataSaverLevel.balanced,
              createdAt: DateTime(2026, 7, 9),
              byteSize: 900000,
            ),
          ],
          lines: const [
            ExpenseReceiptLineRecord(
              id: 'line-1',
              description: 'Materials',
              category: 'Materials',
              use: ExpenseLineUse.business,
              quantity: 1,
              unitsPerPackage: 1,
              unit: 'each',
              subtotal: 12,
            ),
          ],
        ),
      ],
      range: ExpenseDateRange(
        start: DateTime(2026, 7, 1),
        end: DateTime(2026, 7, 9),
      ),
      categoryFilter: ExpenseExportCategoryFilter.all,
    );
    var calls = 0;
    final png = Uint8List.fromList(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      ),
    );
    Future<Uint8List?> loader({
      required String attachmentId,
      required AppGeneratedPdfExportMode mode,
    }) async {
      calls += 1;
      expect(attachmentId, 'photo-1');
      expect(mode, AppGeneratedPdfExportMode.thumbnails);
      return png;
    }

    final document = await buildExpenseExportSummaryPdf(
      snapshot,
      mode: AppGeneratedPdfExportMode.thumbnails,
      imageLoader: loader,
    );

    expect(calls, 1);
    expect(document.validation.isValid, isTrue);
    expect(document.bytes, isNotEmpty);
  });

  test('image modes fail clearly when no image source is supplied', () async {
    final snapshot = buildExpenseExportSnapshot(
      receipts: const [],
      range: ExpenseDateRange(
        start: DateTime(2026, 7, 1),
        end: DateTime(2026, 7, 9),
      ),
      categoryFilter: ExpenseExportCategoryFilter.all,
    );

    await expectLater(
      buildExpenseExportSummaryPdf(
        snapshot,
        mode: AppGeneratedPdfExportMode.fullImages,
      ),
      throwsA(isA<AppGeneratedPdfException>()),
    );
  });

  test(
    'local export loader reuses proof paths without thumbnail fallback',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'pdf-image-loader-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final fullPath = '${directory.path}/full.jpg';
      final thumbnailPath = '${directory.path}/thumbnail.jpg';
      await File(fullPath).writeAsBytes([1, 2, 3]);
      await File(thumbnailPath).writeAsBytes([4, 5]);
      final snapshot = buildExpenseExportSnapshot(
        receipts: [
          ExpenseReceiptRecord(
            id: 'receipt-loader',
            receiptDate: DateTime(2026, 7, 9),
            merchantName: 'Parts Store',
            enteredTotal: 12,
            attachments: [
              ReceiptAttachmentRecord(
                id: 'photo-loader',
                path: fullPath,
                kind: ReceiptAttachmentKind.photo,
                dataSaverLevel: ReceiptDataSaverLevel.balanced,
                createdAt: DateTime(2026, 7, 9),
              ),
            ],
            lines: const [
              ExpenseReceiptLineRecord(
                id: 'line-loader',
                description: 'Materials',
                category: 'Materials',
                use: ExpenseLineUse.business,
                quantity: 1,
                unitsPerPackage: 1,
                unit: 'each',
                subtotal: 12,
              ),
            ],
          ),
        ],
        range: ExpenseDateRange(
          start: DateTime(2026, 7, 1),
          end: DateTime(2026, 7, 9),
        ),
        categoryFilter: ExpenseExportCategoryFilter.all,
      );
      final loader = expenseReceiptImageLoaderForExport(
        snapshot: snapshot,
        thumbnailPathsByAttachmentId: {'photo-loader': thumbnailPath},
      );

      expect(
        await loader(
          attachmentId: 'photo-loader',
          mode: AppGeneratedPdfExportMode.thumbnails,
        ),
        [4, 5],
      );
      expect(
        await loader(
          attachmentId: 'photo-loader',
          mode: AppGeneratedPdfExportMode.fullImages,
        ),
        [1, 2, 3],
      );
      expect(
        await loader(
          attachmentId: 'missing-thumbnail',
          mode: AppGeneratedPdfExportMode.thumbnails,
        ),
        isNull,
      );
    },
  );
}
