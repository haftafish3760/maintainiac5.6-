import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_export_handoff.dart';
import 'package:maintaniac/screens/expenses/data/expense_export_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/shared/pdf/app_generated_pdf_export_estimator.dart';
import 'package:maintaniac/shared/pdf/app_generated_pdf_image_loader.dart';
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
      imageResolver: AppGeneratedPdfImageResolver(fetch: loader),
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

  test(
    'resolver is cache-first and requires consent for full downloads',
    () async {
      var fetchCalls = 0;
      final cache = <String, Uint8List>{
        'cached:thumbnails': Uint8List.fromList([7, 8]),
      };
      final resolver = AppGeneratedPdfImageResolver(
        fetch: ({required attachmentId, required mode}) async {
          fetchCalls += 1;
          return Uint8List.fromList([1, 2, 3]);
        },
        cacheRead: (key) async => cache[key],
        cacheWrite: (key, bytes) async => cache[key] = bytes,
      );

      expect(
        await resolver.resolve(
          attachmentId: 'cached',
          mode: AppGeneratedPdfExportMode.thumbnails,
        ),
        [7, 8],
      );
      expect(fetchCalls, 0);
      await expectLater(
        resolver.resolve(
          attachmentId: 'new',
          mode: AppGeneratedPdfExportMode.fullImages,
        ),
        throwsA(
          isA<AppGeneratedPdfImageResolutionException>().having(
            (error) => error.reasonCode,
            'reasonCode',
            'full_image_download_requires_explicit_selection',
          ),
        ),
      );
      final fetched = await resolver.resolve(
        attachmentId: 'new',
        mode: AppGeneratedPdfExportMode.fullImages,
        allowFullImageDownload: true,
      );
      expect(fetched, [1, 2, 3]);
      expect(fetchCalls, 1);
      expect(cache['new:fullImages'], [1, 2, 3]);
    },
  );

  test('resolver deduplicates repeated and concurrent image fetches', () async {
    var fetchCalls = 0;
    final resolver = AppGeneratedPdfImageResolver(
      fetch: ({required attachmentId, required mode}) async {
        fetchCalls += 1;
        await Future<void>.delayed(const Duration(milliseconds: 1));
        return Uint8List.fromList([attachmentId.length, mode.index]);
      },
    );

    final results = await Future.wait([
      resolver.resolve(
        attachmentId: 'same-photo',
        mode: AppGeneratedPdfExportMode.thumbnails,
      ),
      resolver.resolve(
        attachmentId: 'same-photo',
        mode: AppGeneratedPdfExportMode.thumbnails,
      ),
    ]);

    expect(fetchCalls, 1);
    expect(results[0], [10, 1]);
    expect(results[1], [10, 1]);
    expect(
      await resolver.resolve(
        attachmentId: 'same-photo',
        mode: AppGeneratedPdfExportMode.thumbnails,
      ),
      [10, 1],
    );
    expect(fetchCalls, 1);
  });
}
