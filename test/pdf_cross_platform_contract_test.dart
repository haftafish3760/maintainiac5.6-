import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/pdf/app_generated_pdf_models.dart';
import 'package:maintaniac/shared/pdf/app_generated_pdf_service.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_proof_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temporaryDirectory;
  late Directory documentsDirectory;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'pdf_cross_platform_temp_',
    );
    documentsDirectory = await Directory.systemTemp.createTemp(
      'pdf_cross_platform_docs_',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => switch (call.method) {
            'getTemporaryDirectory' => temporaryDirectory.path,
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
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
    if (await documentsDirectory.exists()) {
      await documentsDirectory.delete(recursive: true);
    }
  });

  test('generated PDF names are safe across Android iOS macOS and Windows', () {
    final unsafeNames = [
      r'C:\Users\Owner\Downloads\Invoice:ACME*June?.pdf',
      '../Customer/../../statement<>|.pdf',
      '  iCloud Drive:Estimate "Job #42".PDF  ',
      'android/content/export/customer:invoice.pdf',
      'CON.pdf',
      'LPT1',
      'aux.',
      'invoice\u0000with\u001Fcontrols.pdf',
      '.hidden-receipt.pdf',
    ];

    for (final name in unsafeNames) {
      final safe = AppGeneratedPdfFileName.clean(name);
      final baseName = safe.substring(0, safe.length - 4).toLowerCase();

      expect(safe, endsWith('.pdf'));
      expect(safe.length, lessThanOrEqualTo(120));
      expect(safe, isNot(contains(RegExp(r'[\\/:*?"<>|]'))));
      expect(safe, isNot(contains(RegExp(r'[\x00-\x1F\x7F]'))));
      expect(safe, isNot(contains('..')));
      expect(safe.trim(), safe);
      expect(
        baseName,
        isNot(
          isIn([
            'con',
            'prn',
            'aux',
            'nul',
            'com1',
            'com2',
            'com3',
            'com4',
            'com5',
            'com6',
            'com7',
            'com8',
            'com9',
            'lpt1',
            'lpt2',
            'lpt3',
            'lpt4',
            'lpt5',
            'lpt6',
            'lpt7',
            'lpt8',
            'lpt9',
          ]),
        ),
      );
    }
  });

  test(
    'generated PDF write uses platform temp directory and safe basename',
    () async {
      final document = AppGeneratedPdfDocument(
        kind: AppGeneratedPdfKind.invoice,
        title: 'Invoice',
        fileName: r'C:\Users\Owner\Downloads\INV:42?.pdf',
        bytes: Uint8List.fromList('%PDF-1.7\n%%EOF'.codeUnits),
        createdAt: DateTime(2026, 7, 4),
      );

      final generated = await const AppGeneratedPdfService().writeTemporary(
        document,
      );

      expect(generated.path, startsWith(temporaryDirectory.path));
      expect(generated.path, contains('maintaniac_generated_pdfs'));
      expect(generated.path, endsWith('.pdf'));
      expect(File(generated.path).uri.pathSegments.last, document.safeFileName);
      expect(File(generated.path).uri.pathSegments.last, isNot(contains('\\')));
    },
  );

  test('receipt PDF proof storage sanitizes hostile original names', () async {
    final source = File('${temporaryDirectory.path}/source.pdf');
    await source.writeAsString(
      '%PDF-1.7\n1 0 obj << /Type /Page >> endobj\n%%EOF',
      flush: true,
    );

    final staged = await ReceiptProofStorage.instance.stageAttachment(
      ReceiptAttachmentRecord(
        id: r'id:..\bad\proof?',
        path: source.path,
        kind: ReceiptAttachmentKind.pdf,
        dataSaverLevel: ReceiptDataSaverLevel.original,
        createdAt: DateTime(2026, 7, 4),
        displayName: r'..\Downloads\Fuel:Receipt?.pdf',
        originalFileName: 'CON.pdf',
        mimeType: 'application/pdf',
      ),
    );

    final basename = File(staged.path).uri.pathSegments.last;
    expect(staged.path, startsWith(documentsDirectory.path));
    expect(staged.path, contains('receipt_proofs_staging'));
    expect(basename, endsWith('.pdf'));
    expect(basename, isNot(contains(RegExp(r'[\\/:*?"<>|]'))));
    expect(basename, isNot(contains('..')));
    expect(staged.originalFileName, endsWith('.pdf'));
    expect(staged.originalFileName, isNot(contains(RegExp(r'[\\/:*?"<>|]'))));
    expect(staged.originalFileName, isNot(contains('..')));
    expect(staged.originalFileName.toLowerCase(), isNot('con.pdf'));
    expect(await source.exists(), isTrue);
    expect(await File(staged.path).exists(), isTrue);
  });
}
