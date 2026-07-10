import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/pdf/app_generated_pdf_export_verifier.dart';

void main() {
  test('counts generated page objects and accepts expected count', () {
    final bytes = Uint8List.fromList(
      '%PDF-1.7\n'
              '1 0 obj << /Type /Page >> endobj\n'
              '2 0 obj << /Type /Page >> endobj\n'
              '%%EOF'
          .codeUnits,
    );

    final result = AppGeneratedPdfExportVerification.inspect(
      bytes,
      expectedPageCount: 2,
    );

    expect(result.pageCount, 2);
    expect(result.isValid, isTrue);
  });

  test('rejects a page-count mismatch before delivery', () {
    final bytes = Uint8List.fromList(
      '%PDF-1.7\n1 0 obj << /Type /Page >> endobj\n%%EOF'.codeUnits,
    );

    final result = AppGeneratedPdfExportVerification.inspect(
      bytes,
      expectedPageCount: 2,
    );

    expect(result.pageCount, 1);
    expect(result.issues, contains('page_count_mismatch'));
    expect(result.isValid, isFalse);
  });
}
