import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/pdf/app_pdf_typography.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'PDF typography uses embedded app fonts for generated documents',
    () async {
      final pubspec = File('pubspec.yaml').readAsStringSync();

      expect(pubspec, contains(AppPdfTypography.regularFontAsset));
      expect(pubspec, contains(AppPdfTypography.boldFontAsset));
      expect(
        File(AppPdfTypography.regularFontAsset).lengthSync(),
        greaterThan(0),
      );
      expect(File(AppPdfTypography.boldFontAsset).lengthSync(), greaterThan(0));

      final theme = await AppPdfTypography.loadTheme();
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          theme: theme,
          build: (_) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Maintainiac PDF typography'),
              pw.Text('Customer: Rene Services'),
              pw.Text('Receipt note: cafe, facade, resume'),
              pw.Text('Total: 123.45'),
            ],
          ),
        ),
      );

      final bytes = await pdf.save();
      expect(bytes.length, greaterThan(1000));
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    },
  );

  test('PDF storage test fixtures avoid default Helvetica pages', () {
    for (final testPath in const [
      'test/app_document_store_test.dart',
      'test/expense_draft_storage_lifecycle_test.dart',
      'test/receipt_proof_storage_lifecycle_test.dart',
    ]) {
      final source = File(testPath).readAsStringSync();

      expect(source, contains('PdfTestTypography.loadTheme()'));
      expect(source, isNot(contains('pw.Page(build:')));
    }
  });
}
