import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/pdf/app_generated_pdf_models.dart';
import 'package:maintaniac/shared/pdf/app_pdf_security_policy.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_pdf_inspector.dart';

void main() {
  test('shared PDF policy catches active content for every PDF lane', () {
    final bytes = latin1.encode(
      '%PDF-1.7\n'
      '1 0 obj << /Type /Page /OpenAction 2 0 R /AA 3 0 R >> endobj\n'
      '2 0 obj << /JavaScript 4 0 R /Launch 5 0 R /EmbeddedFile 6 0 R /RichMedia 7 0 R /SubmitForm 8 0 R /URI (https://example.com) >> endobj\n'
      '3 0 obj << /AcroForm 9 0 R /XFA 10 0 R >> endobj\n'
      'xref\ntrailer << /Root 1 0 R >>\nstartxref\n0\n%%EOF',
    );

    final policyIssues = AppPdfSecurityPolicy.activeContentIssueCodesForBytes(
      bytes,
    );
    expect(
      policyIssues,
      containsAll([
        AppPdfSecurityPolicy.activeJavaScript,
        AppPdfSecurityPolicy.activeLaunchAction,
        AppPdfSecurityPolicy.automaticAction,
        AppPdfSecurityPolicy.autoOpenAction,
        AppPdfSecurityPolicy.dynamicFormContent,
        AppPdfSecurityPolicy.embeddedFile,
        AppPdfSecurityPolicy.embeddedMedia,
        AppPdfSecurityPolicy.externalLinks,
        AppPdfSecurityPolicy.formSubmissionAction,
      ]),
    );

    final generatedReport = AppGeneratedPdfValidationReport.inspect(
      Uint8List.fromList(bytes),
    );
    expect(generatedReport.issues, containsAll(policyIssues));

    final receiptFlags = ReceiptPdfInspector.detectRiskFlags(bytes);
    expect(receiptFlags, contains('embedded JavaScript'));
    expect(receiptFlags, contains('auto-open actions'));
    expect(receiptFlags, contains('launch actions'));
    expect(receiptFlags, contains('automatic actions'));
    expect(receiptFlags, contains('embedded files'));
    expect(receiptFlags, contains('embedded media'));
    expect(receiptFlags, contains('form submission actions'));
    expect(receiptFlags, contains('external links'));
  });

  test('shared PDF policy avoids name-substring false positives', () {
    final bytes = latin1.encode(
      '%PDF-1.7\n'
      '1 0 obj << /Type /Page /JsonThing true /Aardvark true /OpenActionsButNotAName true >> endobj\n'
      'xref\ntrailer << /Root 1 0 R >>\nstartxref\n0\n%%EOF',
    );

    expect(
      AppPdfSecurityPolicy.activeContentIssueCodesForBytes(bytes),
      isEmpty,
    );
    expect(
      ReceiptPdfInspector.detectRiskFlags(bytes),
      isNot(contains('embedded JavaScript')),
    );
    expect(
      ReceiptPdfInspector.detectRiskFlags(bytes),
      isNot(contains('auto-open actions')),
    );
  });

  test('shared PDF policy decodes escaped PDF name tokens', () {
    final bytes = latin1.encode(
      '%PDF-1.7\n'
      '1 0 obj << /Type /Page /Open#41ction 2 0 R /A#41 3 0 R >> endobj\n'
      '2 0 obj << /Java#53cript 4 0 R /Launch 5 0 R /Embedded#46ile 6 0 R /Rich#4Dedia 7 0 R /Submit#46orm 8 0 R /U#52I (https://example.com) >> endobj\n'
      '3 0 obj << /Acro#46orm 9 0 R /X#46A 10 0 R >> endobj\n'
      'xref\ntrailer << /Root 1 0 R >>\nstartxref\n0\n%%EOF',
    );

    expect(
      AppPdfSecurityPolicy.activeContentIssueCodesForBytes(bytes),
      containsAll([
        AppPdfSecurityPolicy.activeJavaScript,
        AppPdfSecurityPolicy.activeLaunchAction,
        AppPdfSecurityPolicy.automaticAction,
        AppPdfSecurityPolicy.autoOpenAction,
        AppPdfSecurityPolicy.dynamicFormContent,
        AppPdfSecurityPolicy.embeddedFile,
        AppPdfSecurityPolicy.embeddedMedia,
        AppPdfSecurityPolicy.externalLinks,
        AppPdfSecurityPolicy.formSubmissionAction,
      ]),
    );
  });
}
