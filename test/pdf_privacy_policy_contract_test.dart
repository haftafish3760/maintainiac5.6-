import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/pdf/app_generated_pdf_models.dart';
import 'package:maintaniac/shared/pdf/app_generated_pdf_service.dart';
import 'package:maintaniac/shared/pdf/app_pdf_privacy_policy.dart';

void main() {
  test('PDF privacy policy blocks private generated document content', () {
    final privateBytes = Uint8List.fromList(
      '%PDF-1.7\n'
              '1 0 obj << /Type /Page >> stream\n'
              'VIN 1HGCM82633A004352\n'
              'Patient MRN 445566\n'
              'Card ending 4242\n'
              'Unconfirmed OCR suggestion subtotal 12.00\n'
              '/Users/somebody/Documents/private/receipt.pdf\n'
              'endstream endobj\n%%EOF'
          .codeUnits,
    );

    final issues = AppPdfPrivacyPolicy.issueCodesForExport(bytes: privateBytes);

    expect(issues, contains(AppPdfPrivacyPolicy.vin));
    expect(issues, contains(AppPdfPrivacyPolicy.patientData));
    expect(issues, contains(AppPdfPrivacyPolicy.paymentFragment));
    expect(issues, contains(AppPdfPrivacyPolicy.unconfirmedOcrSuggestion));
    expect(issues, contains(AppPdfPrivacyPolicy.privateSourcePath));
  });

  test('PDF privacy policy blocks passenger and patient labels', () {
    final issues = AppPdfPrivacyPolicy.issueCodesForExport(
      bytes: Uint8List.fromList(
        '%PDF-1.7\n'
                'Passenger: Jane Customer\n'
                'Rider phone: 555-1212\n'
                'Patient: Sam Example\n'
                'Diagnosis: private condition\n'
                '%%EOF'
            .codeUnits,
      ),
    );

    expect(issues, contains(AppPdfPrivacyPolicy.passengerData));
    expect(issues, contains(AppPdfPrivacyPolicy.patientData));
  });

  test('PDF privacy policy blocks unlabeled VINs and short plate labels', () {
    final issues = AppPdfPrivacyPolicy.issueCodesForExport(
      bytes: Uint8List.fromList(
        '%PDF-1.7\n'
                '1FTFW1E50MFA12345\n'
                'Plate: ABC 1234\n'
                '%%EOF'
            .codeUnits,
      ),
    );

    expect(issues, contains(AppPdfPrivacyPolicy.vin));
    expect(issues, contains(AppPdfPrivacyPolicy.licensePlate));
  });

  test('generated PDF validation checks exported titles and share text', () {
    final document = AppGeneratedPdfDocument(
      kind: AppGeneratedPdfKind.invoice,
      title: 'Invoice for license plate ABC 123',
      fileName: 'invoice.pdf',
      bytes: Uint8List.fromList('%PDF-1.7\n%%EOF'.codeUnits),
      createdAt: DateTime(2026, 7, 4),
      shareSubject: 'Customer invoice',
      shareText: 'Internal ID firebase_record_123456 should not export',
    );

    expect(document.validation.isValid, isFalse);
    expect(
      document.validation.issues,
      contains(AppPdfPrivacyPolicy.licensePlate),
    );
    expect(
      document.validation.issues,
      contains(AppPdfPrivacyPolicy.internalId),
    );
    expect(document.validation.userMessage, contains('private information'));
  });

  test('generated PDF service refuses private PDFs before writing', () async {
    final document = AppGeneratedPdfDocument(
      kind: AppGeneratedPdfKind.expenseExport,
      title: 'Expense export',
      fileName: 'expense_export.pdf',
      bytes: Uint8List.fromList(
        '%PDF-1.7\nPassenger name Jane Customer\n%%EOF'.codeUnits,
      ),
      createdAt: DateTime(2026, 7, 4),
    );

    await expectLater(
      const AppGeneratedPdfService().writeTemporary(document),
      throwsA(
        isA<AppGeneratedPdfException>().having(
          (error) => error.message,
          'message',
          contains('private information'),
        ),
      ),
    );
  });

  test('ordinary generated business PDF metadata remains sendable', () {
    final document = AppGeneratedPdfDocument(
      kind: AppGeneratedPdfKind.invoice,
      title: 'Invoice INV-1001',
      fileName: 'invoice_INV-1001.pdf',
      bytes: Uint8List.fromList(
        '%PDF-1.7\nSubtotal 100.00\nTax 7.50\nTotal 107.50\n%%EOF'.codeUnits,
      ),
      createdAt: DateTime(2026, 7, 4),
      shareSubject: 'Maintainiac invoice',
      shareText: 'Invoice attached for confirmed work.',
    );

    expect(document.validation.isValid, isTrue);
    expect(document.isSendablePdf, isTrue);
  });
}
