import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
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

  test(
    'receipt PDF renderer refuses invalid confirmed line quantities',
    () async {
      final data = AppReceiptPdfData(
        merchantName: 'Supply House',
        receiptDate: DateTime(2026, 7, 5),
        confirmedByUser: true,
        subtotalCents: 1899,
        totalCents: 1899,
        lines: const [
          AppReceiptPdfLine(
            description: 'Confirmed material line',
            category: 'Materials',
            quantity: double.infinity,
            totalCents: 1899,
          ),
        ],
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
            contains('invalid quantity'),
          ),
        ),
      );
    },
  );

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

  test('receipt PDF renderer blocks private line item text', () async {
    final data = AppReceiptPdfData(
      merchantName: 'Supply House',
      receiptDate: DateTime(2026, 7, 5),
      confirmedByUser: true,
      subtotalCents: 1899,
      totalCents: 1899,
      lines: const [
        AppReceiptPdfLine(
          description: 'VIN 1HGCM82633A004352 oil filter',
          category: 'Vehicle Supplies',
          totalCents: 1899,
        ),
      ],
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

  test('receipt PDF renderer blocks private proof image labels', () async {
    final data = _receiptData(
      lineCount: 1,
      proofImages: [
        AppReceiptPdfImage(
          bytes: _receiptPng(),
          label: 'License plate ABC 123 proof image',
        ),
      ],
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
    for (final pageSpec in const [
      AppPdfPageSpec.letterLandscape,
      AppPdfPageSpec.legalLandscape,
      AppPdfPageSpec.a4Landscape,
    ]) {
      final document = await const AppReceiptPdfRenderer().buildReceiptDocument(
        data: _receiptData(lineCount: 6),
        pageSpec: pageSpec,
        createdAt: DateTime.utc(2026, 7, 5, 12),
        theme: await AppPdfTypography.loadTheme(),
      );
      final boxes = _mediaBoxes(document.bytes);

      expect(document.validation.isValid, isTrue, reason: pageSpec.key);
      expect(boxes, isNotEmpty, reason: pageSpec.key);
      expect(
        boxes.every((box) => box.isLandscape),
        isTrue,
        reason: pageSpec.key,
      );
    }
  });

  test('receipt PDF renderer supports shared receipt source modules', () async {
    final cases = <({String module, String recordId, String normalized})>[
      (
        module: 'Inventory Receipts',
        recordId: 'inventory_receipt_42',
        normalized: 'inventory_receipts',
      ),
      (
        module: 'Vendor Invoice Receipts',
        recordId: 'vendor_invoice_receipt_7',
        normalized: 'vendor_invoice_receipts',
      ),
    ];

    for (final receiptCase in cases) {
      final document = await const AppReceiptPdfRenderer().buildReceiptDocument(
        data: _receiptData(
          lineCount: 3,
          sourceModule: receiptCase.module,
          sourceRecordId: receiptCase.recordId,
        ),
        createdAt: DateTime.utc(2026, 7, 5, 12),
        theme: await AppPdfTypography.loadTheme(),
      );

      expect(document.validation.isValid, isTrue);
      expect(document.sourceModule, receiptCase.normalized);
      expect(document.sourceRecordId, receiptCase.recordId);
      expect(document.kind, AppGeneratedPdfKind.receipt);
    }
  });

  test(
    'receipt PDF renderer paginates long receipts with repeated context',
    () async {
      const renderer = AppReceiptPdfRenderer();
      final data = _receiptData(lineCount: 160);
      final sections = renderer.planLineSections(data);
      final document = await const AppReceiptPdfRenderer().buildReceiptDocument(
        data: data,
        createdAt: DateTime.utc(2026, 7, 5, 12),
        theme: await AppPdfTypography.loadTheme(),
      );
      final boxes = _mediaBoxes(document.bytes);
      final decoded = AppPdfTextDecoder.textWithDecodedPdfStreams(
        document.bytes,
      );

      expect(document.validation.isValid, isTrue);
      expect(boxes.length, greaterThan(1));
      expect(decoded, contains('Confirmed'));
      expect(decoded, contains('material'));
      expect(decoded, contains('line'));
      expect(decoded, contains('80'));
      expect(decoded, contains('160'));
      expect(sections, hasLength(5));
      expect(sections.first.label, 'Receipt line items section 1 of 5');
      expect(sections.last.label, 'Receipt line items section 5 of 5');
      expect(sections.every((section) => section.lines.length <= 32), isTrue);
      expect(decoded, contains('Item'));
      expect(decoded, contains('Category'));
      expect(
        _textOccurrences(decoded, 'Page'),
        greaterThanOrEqualTo(boxes.length),
      );
      expect(decoded, contains('Total'));
      expect(decoded, contains(r'$456.78'));
    },
  );

  test(
    'receipt PDF renderer embeds portrait and landscape proof images',
    () async {
      const renderer = AppReceiptPdfRenderer();
      final portrait = AppReceiptPdfImage(
        bytes: _receiptPng(width: 240, height: 520),
        label: 'Portrait receipt proof',
        sourcePageNumber: 1,
      );
      final landscape = AppReceiptPdfImage(
        bytes: _receiptPng(width: 520, height: 240),
        label: 'Landscape receipt proof',
        sourcePageNumber: 2,
      );

      final first = await renderer.buildReceiptDocument(
        data: _receiptData(lineCount: 4, proofImages: [portrait, landscape]),
        createdAt: DateTime.utc(2026, 7, 5, 12),
        theme: await AppPdfTypography.loadTheme(),
      );
      final second = await renderer.buildReceiptDocument(
        data: _receiptData(lineCount: 4, proofImages: [portrait, landscape]),
        createdAt: DateTime.utc(2026, 7, 5, 12),
        theme: await AppPdfTypography.loadTheme(),
      );
      final decoded = AppPdfTextDecoder.textWithDecodedPdfStreams(first.bytes);
      final raw = latin1.decode(first.bytes, allowInvalid: true);

      expect(first.validation.isValid, isTrue);
      expect(first.bytes, second.bytes);
      expect(decoded, contains('Receipt'));
      expect(decoded, contains('Proof'));
      expect(decoded, contains('Images'));
      expect(decoded, contains('Portrait'));
      expect(decoded, contains('Landscape'));
      expect(decoded, contains('receipt'));
      expect(decoded, contains('proof'));
      expect(decoded, contains(portrait.sha256Hex));
      expect(decoded, contains(landscape.sha256Hex));
      expect(
        RegExp(r'/Subtype\s*/Image').allMatches(raw).length,
        greaterThanOrEqualTo(2),
      );
    },
  );

  test('receipt PDF renderer refuses empty proof image bytes', () async {
    final data = _receiptData(
      lineCount: 1,
      proofImages: [AppReceiptPdfImage(bytes: Uint8List(0), label: 'empty')],
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
          contains('receipt proof image was empty'),
        ),
      ),
    );
  });

  test('receipt PDF renderer refuses unsupported proof image bytes', () async {
    final data = _receiptData(
      lineCount: 1,
      proofImages: [
        AppReceiptPdfImage(
          bytes: Uint8List.fromList([1, 2, 3, 4]),
          label: 'not an image',
        ),
      ],
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
          contains('not a supported image file'),
        ),
      ),
    );
  });

  test('receipt PDF renderer refuses corrupt proof image payloads', () async {
    final data = _receiptData(
      lineCount: 1,
      proofImages: [
        AppReceiptPdfImage(
          bytes: _fakePngBytes(512),
          label: 'corrupt receipt image',
        ),
      ],
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
          contains('not a supported image file'),
        ),
      ),
    );
  });

  test('receipt PDF renderer refuses unsafe proof image dimensions', () async {
    final data = _receiptData(
      lineCount: 1,
      proofImages: [
        AppReceiptPdfImage(
          bytes: _receiptPng(
            width: appReceiptPdfMaxEmbeddedImageEdgePixels + 1,
            height: 12,
          ),
          label: 'wide receipt strip',
        ),
      ],
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
          contains('too large to render safely'),
        ),
      ),
    );
  });

  test('receipt PDF renderer refuses too many proof images', () async {
    final image = AppReceiptPdfImage(bytes: _receiptPng());
    final data = _receiptData(
      lineCount: 1,
      proofImages: [
        for (var index = 0; index < appReceiptPdfMaxEmbeddedImages + 1; index++)
          image,
      ],
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
          contains('too many receipt proof images'),
        ),
      ),
    );
  });

  test('receipt PDF renderer refuses oversized proof image bytes', () async {
    final data = _receiptData(
      lineCount: 1,
      proofImages: [
        AppReceiptPdfImage(
          bytes: _fakePngBytes(appReceiptPdfMaxEmbeddedImageBytes + 1),
          label: 'oversized',
        ),
      ],
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
          contains('receipt proof image was too large'),
        ),
      ),
    );
  });

  test('receipt PDF renderer refuses oversized proof image batch', () async {
    final data = _receiptData(
      lineCount: 1,
      proofImages: [
        for (var index = 0; index < 3; index++)
          AppReceiptPdfImage(
            bytes: _fakePngBytes(9 * 1024 * 1024),
            label: 'batch $index',
          ),
      ],
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
          contains('receipt proof images were too large together'),
        ),
      ),
    );
  });
}

int _textOccurrences(String text, String value) {
  return RegExp(RegExp.escape(value)).allMatches(text).length;
}

AppReceiptPdfData _receiptData({
  required int lineCount,
  bool confirmedByUser = true,
  String merchantName = 'Supply House',
  int totalCents = 45678,
  List<AppReceiptPdfImage> proofImages = const [],
  String sourceModule = 'receipts',
  String sourceRecordId = 'receipt_42',
}) {
  return AppReceiptPdfData(
    merchantName: merchantName,
    receiptDate: DateTime(2026, 7, 5),
    confirmedByUser: confirmedByUser,
    receiptNumber: 'R-2042',
    businessUseLabel: 'Business',
    sourceModule: sourceModule,
    sourceRecordId: sourceRecordId,
    subtotalCents: 42108,
    taxCents: 3570,
    totalCents: totalCents,
    notes: 'Confirmed by user before export.',
    proofImages: proofImages,
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

Uint8List _receiptPng({int width = 240, int height = 480}) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(250, 250, 250));
  for (var y = 20; y < height - 20; y += 34) {
    img.drawLine(
      image,
      x1: 18,
      y1: y,
      x2: width - 18,
      y2: y,
      color: img.ColorRgb8(40, 40, 40),
      thickness: 2,
    );
  }
  img.drawRect(
    image,
    x1: 4,
    y1: 4,
    x2: width - 5,
    y2: height - 5,
    color: img.ColorRgb8(70, 70, 70),
    thickness: 2,
  );
  return Uint8List.fromList(img.encodePng(image));
}

Uint8List _fakePngBytes(int length) {
  final bytes = Uint8List(length);
  const header = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
  bytes.setRange(0, header.length, header);
  return bytes;
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
