import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/pdf/app_generated_pdf_models.dart';
import 'package:maintaniac/shared/pdf/app_pdf_page_spec.dart';
import 'package:maintaniac/shared/pdf/app_pdf_text_decoder.dart';
import 'package:maintaniac/shared/pdf/app_pdf_typography.dart';
import 'package:maintaniac/shared/pdf/app_receipt_pdf_document.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'receipt PDF renderer creates deterministic confirmed receipt PDFs',
    () async {
      const renderer = AppReceiptPdfRenderer();
      final data = _receiptData(lineCount: 18);

      final first = await renderer.buildReceiptDocument(
        data: data,
        createdAt: DateTime.utc(2026, 7, 5, 12),
        theme: await AppPdfTypography.loadTheme(),
      );
      final second = await renderer.buildReceiptDocument(
        data: data,
        createdAt: DateTime.utc(2026, 7, 5, 12),
        theme: await AppPdfTypography.loadTheme(),
      );

      expect(first.kind, AppGeneratedPdfKind.receipt);
      expect(
        first.safeFileName,
        'maintainiac_receipt_2026-07-05_supply-house.pdf',
      );
      expect(first.sourceModule, 'receipts');
      expect(first.sourceRecordId, 'receipt_42');
      expect(first.validation.isValid, isTrue);
      expect(first.bytes, second.bytes);
      expect(latin1.decode(first.bytes.take(5).toList()), '%PDF-');

      final decoded = AppPdfTextDecoder.textWithDecodedPdfStreams(first.bytes);
      expect(decoded, contains('Maintainiac'));
      expect(decoded, contains('Receipt'));
      expect(decoded, contains('Supply'));
      expect(decoded, contains('House'));
      expect(decoded, contains('Materials'));
      expect(decoded, contains(r'$456.78'));
    },
  );

  test('receipt PDF renderer refuses unconfirmed receipt data', () async {
    final data = _receiptData(lineCount: 1, confirmedByUser: false);

    await expectLater(
      const AppReceiptPdfRenderer().buildReceiptDocument(
        data: data,
        theme: await AppPdfTypography.loadTheme(),
      ),
      throwsA(
        isA<AppReceiptPdfException>().having(
          (error) => error.message,
          'message',
          contains('confirms the receipt data'),
        ),
      ),
    );
  });

  test('receipt PDF renderer refuses empty confirmed receipt lines', () async {
    final data = _receiptData(lineCount: 0);

    await expectLater(
      const AppReceiptPdfRenderer().buildReceiptDocument(
        data: data,
        theme: await AppPdfTypography.loadTheme(),
      ),
      throwsA(
        isA<AppReceiptPdfException>().having(
          (error) => error.message,
          'message',
          contains('at least one confirmed receipt line'),
        ),
      ),
    );
  });

  test('receipt PDF renderer refuses mismatched confirmed totals', () async {
    final data = _receiptData(lineCount: 2, totalCents: 999999);

    await expectLater(
      const AppReceiptPdfRenderer().buildReceiptDocument(
        data: data,
        theme: await AppPdfTypography.loadTheme(),
      ),
      throwsA(
        isA<AppReceiptPdfException>().having(
          (error) => error.message,
          'message',
          contains('confirmed line totals do not match'),
        ),
      ),
    );
  });

  test('receipt PDF renderer blocks private receipt metadata', () async {
    final data = _receiptData(
      lineCount: 1,
      merchantName: 'Supply House VIN 1HGCM82633A004352',
    );

    await expectLater(
      const AppReceiptPdfRenderer().buildReceiptDocument(
        data: data,
        theme: await AppPdfTypography.loadTheme(),
      ),
      throwsA(
        isA<AppReceiptPdfException>().having(
          (error) => error.message,
          'message',
          contains('private information'),
        ),
      ),
    );
  });

  test('receipt PDF renderer supports landscape receipt output', () async {
    final document = await const AppReceiptPdfRenderer().buildReceiptDocument(
      data: _receiptData(lineCount: 6),
      pageSpec: AppPdfPageSpec.letterLandscape,
      createdAt: DateTime.utc(2026, 7, 5, 12),
      theme: await AppPdfTypography.loadTheme(),
    );
    final boxes = _mediaBoxes(document.bytes);

    expect(document.validation.isValid, isTrue);
    expect(boxes, isNotEmpty);
    expect(boxes.every((box) => box.isLandscape), isTrue);
  });
}

AppReceiptPdfData _receiptData({
  required int lineCount,
  bool confirmedByUser = true,
  String merchantName = 'Supply House',
  int totalCents = 45678,
}) {
  return AppReceiptPdfData(
    merchantName: merchantName,
    receiptDate: DateTime(2026, 7, 5),
    confirmedByUser: confirmedByUser,
    receiptNumber: 'R-2042',
    businessUseLabel: 'Business',
    sourceRecordId: 'receipt_42',
    subtotalCents: 42108,
    taxCents: 3570,
    totalCents: totalCents,
    notes: 'Confirmed by user before export.',
    lines: [
      for (var index = 1; index <= lineCount; index++)
        AppReceiptPdfLine(
          description: 'Confirmed material line $index',
          category: 'Materials',
          quantity: index.isEven ? 2 : 1,
          unit: index.isEven ? 'ea' : 'box',
          totalCents: index.isEven ? 2450 : 1899,
        ),
    ],
  );
}

List<_MediaBox> _mediaBoxes(List<int> bytes) {
  final raw = latin1.decode(bytes, allowInvalid: true);
  final pattern = RegExp(
    r'/MediaBox\s*\[\s*0\s+0\s+([0-9.]+)\s+([0-9.]+)\s*\]',
  );
  return pattern
      .allMatches(raw)
      .map(
        (match) => _MediaBox(
          width: double.parse(match.group(1)!),
          height: double.parse(match.group(2)!),
        ),
      )
      .toList(growable: false);
}

class _MediaBox {
  const _MediaBox({required this.width, required this.height});

  final double width;
  final double height;

  bool get isLandscape => width > height;
}
