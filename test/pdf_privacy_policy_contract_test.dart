import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/pdf/app_generated_pdf_models.dart';
import 'package:maintaniac/shared/pdf/app_generated_pdf_service.dart';
import 'package:maintaniac/shared/pdf/app_pdf_privacy_policy.dart';

import 'helpers/pdf_security_fixture_factory.dart';

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

  test('PDF privacy policy blocks mobile and Android source paths', () {
    final issues = AppPdfPrivacyPolicy.issueCodesForExport(
      bytes: Uint8List.fromList(
        '%PDF-1.7\n'
                '/storage/emulated/0/Download/private-receipt.pdf\n'
                '/data/user/0/com.maintainiac/cache/shared.pdf\n'
                '/private/var/mobile/Containers/Data/Application/app/tmp/file.pdf\n'
                '%%EOF'
            .codeUnits,
      ),
    );

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

  test('PDF privacy policy blocks hex encoded private text', () {
    final issues = AppPdfPrivacyPolicy.issueCodesForExport(
      bytes: Uint8List.fromList(
        '%PDF-1.7\n'
                '1 0 obj << /Type /Page >> stream\n'
                'BT <56494E20314847434D383236333341303034333532> Tj ET\n'
                'BT <FEFF00500061007300730065006E006700650072003A0020004A0061006E006500200043007500730074006F006D00650072> Tj ET\n'
                '%%EOF'
            .codeUnits,
      ),
    );

    expect(issues, contains(AppPdfPrivacyPolicy.vin));
    expect(issues, contains(AppPdfPrivacyPolicy.passengerData));
  });

  test('PDF privacy policy blocks compressed private text streams', () {
    final issues = AppPdfPrivacyPolicy.issueCodesForExport(
      bytes: PdfSecurityFixtureFactory.flateStreamPdf(
        PdfSecurityFixtureFactory.privateExportText(),
      ),
    );

    expect(issues, contains(AppPdfPrivacyPolicy.passengerData));
    expect(issues, contains(AppPdfPrivacyPolicy.vin));
    expect(issues, contains(AppPdfPrivacyPolicy.privateSourcePath));
  });

  test(
    'PDF privacy policy maps private fixture table across generated surfaces',
    () {
      final cases = <_PrivacyFixtureCase>[
        _PrivacyFixtureCase(
          name: 'raw exported body',
          bytes: Uint8List.fromList(
            '%PDF-1.7\n'
                    'VIN 1HGCM82633A004352\n'
                    'Passenger: Jane Customer\n'
                    'Patient MRN 445566\n'
                    'Card ending 4242\n'
                    '/Users/owner/Documents/private-receipt.pdf\n'
                    '%%EOF'
                .codeUnits,
          ),
          expectedIssues: const [
            AppPdfPrivacyPolicy.vin,
            AppPdfPrivacyPolicy.passengerData,
            AppPdfPrivacyPolicy.patientData,
            AppPdfPrivacyPolicy.paymentFragment,
            AppPdfPrivacyPolicy.privateSourcePath,
          ],
        ),
        _PrivacyFixtureCase(
          name: 'hex encoded text layer',
          bytes: Uint8List.fromList(
            '%PDF-1.7\n'
                    'BT <56494E20314847434D383236333341303034333532> Tj ET\n'
                    'BT <50617373656E6765723A204A616E6520437573746F6D6572> Tj ET\n'
                    '%%EOF'
                .codeUnits,
          ),
          expectedIssues: const [
            AppPdfPrivacyPolicy.vin,
            AppPdfPrivacyPolicy.passengerData,
          ],
        ),
        _PrivacyFixtureCase(
          name: 'compressed text stream',
          bytes: PdfSecurityFixtureFactory.flateStreamPdf(
            PdfSecurityFixtureFactory.privateExportText(),
          ),
          expectedIssues: const [
            AppPdfPrivacyPolicy.vin,
            AppPdfPrivacyPolicy.passengerData,
            AppPdfPrivacyPolicy.privateSourcePath,
          ],
        ),
        _PrivacyFixtureCase(
          name: 'metadata only leak',
          bytes: Uint8List.fromList('%PDF-1.7\n%%EOF'.codeUnits),
          metadata: const [
            'Invoice for license plate ABC 123',
            'Internal ID firebase_record_123456 should not export',
          ],
          expectedIssues: const [
            AppPdfPrivacyPolicy.licensePlate,
            AppPdfPrivacyPolicy.internalId,
          ],
        ),
      ];

      for (final fixture in cases) {
        final issues = AppPdfPrivacyPolicy.issueCodesForExport(
          bytes: fixture.bytes,
          metadata: fixture.metadata,
        );
        final document = AppGeneratedPdfDocument(
          kind: AppGeneratedPdfKind.invoice,
          title: 'Privacy fixture ${fixture.name}',
          fileName: 'privacy_fixture.pdf',
          bytes: fixture.bytes,
          createdAt: DateTime(2026, 7, 4),
          shareText: fixture.metadata.join('\n'),
        );

        expect(
          issues,
          containsAll(fixture.expectedIssues),
          reason: fixture.name,
        );
        expect(
          document.validation.issues,
          containsAll(fixture.expectedIssues),
          reason: fixture.name,
        );
        expect(document.validation.isValid, isFalse, reason: fixture.name);
      }
    },
  );

  test('PDF privacy policy ignores non-text hex payloads', () {
    final issues = AppPdfPrivacyPolicy.issueCodesForExport(
      bytes: Uint8List.fromList(
        '%PDF-1.7\n'
                '1 0 obj << /Type /Page >> stream\n'
                'BT <FEFF000100020003> Tj ET\n'
                '%%EOF'
            .codeUnits,
      ),
    );

    expect(issues, isEmpty);
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

class _PrivacyFixtureCase {
  const _PrivacyFixtureCase({
    required this.name,
    required this.bytes,
    required this.expectedIssues,
    this.metadata = const [],
  });

  final String name;
  final Uint8List bytes;
  final List<String> expectedIssues;
  final List<String> metadata;
}
