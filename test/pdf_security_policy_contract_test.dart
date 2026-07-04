import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/pdf/app_generated_pdf_models.dart';
import 'package:maintaniac/shared/pdf/app_pdf_security_policy.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_pdf_inspector.dart';

import 'helpers/pdf_security_fixture_factory.dart';

void main() {
  test('shared PDF policy catches active content for every PDF surface', () {
    final bytes = PdfSecurityFixtureFactory.rawPdf(
      PdfSecurityFixtureFactory.activeActionBody(),
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
    final bytes = PdfSecurityFixtureFactory.rawPdf(
      PdfSecurityFixtureFactory.escapedActiveNameBody(),
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

  test('shared PDF policy catches hex URI and remote navigation actions', () {
    final bytes = PdfSecurityFixtureFactory.rawPdf(
      PdfSecurityFixtureFactory.remoteNavigationActionBody(),
    );

    final policyIssues = AppPdfSecurityPolicy.activeContentIssueCodesForBytes(
      bytes,
    );

    expect(policyIssues, contains(AppPdfSecurityPolicy.externalLinks));
    expect(
      AppGeneratedPdfValidationReport.inspect(Uint8List.fromList(bytes)).issues,
      contains(AppPdfSecurityPolicy.externalLinks),
    );
    expect(
      ReceiptPdfInspector.detectRiskFlags(bytes),
      contains('external links'),
    );
  });

  test('shared PDF policy catches form reset and import actions', () {
    final bytes = PdfSecurityFixtureFactory.rawPdf(
      PdfSecurityFixtureFactory.formDataActionBody(),
    );

    final policyIssues = AppPdfSecurityPolicy.activeContentIssueCodesForBytes(
      bytes,
    );

    expect(policyIssues, contains(AppPdfSecurityPolicy.formSubmissionAction));
    expect(
      AppGeneratedPdfValidationReport.inspect(Uint8List.fromList(bytes)).issues,
      contains(AppPdfSecurityPolicy.formSubmissionAction),
    );
    expect(
      ReceiptPdfInspector.detectRiskFlags(bytes),
      contains('form submission actions'),
    );
  });

  test('shared PDF policy catches named actions and media actions', () {
    final bytes = PdfSecurityFixtureFactory.rawPdf(
      PdfSecurityFixtureFactory.namedMediaActionBody(),
    );

    final policyIssues = AppPdfSecurityPolicy.activeContentIssueCodesForBytes(
      bytes,
    );

    expect(policyIssues, contains(AppPdfSecurityPolicy.externalLinks));
    expect(policyIssues, contains(AppPdfSecurityPolicy.embeddedMedia));
    expect(
      AppGeneratedPdfValidationReport.inspect(Uint8List.fromList(bytes)).issues,
      containsAll([
        AppPdfSecurityPolicy.externalLinks,
        AppPdfSecurityPolicy.embeddedMedia,
      ]),
    );
    expect(
      ReceiptPdfInspector.detectRiskFlags(bytes),
      containsAll(['external links', 'embedded media']),
    );
  });

  test('shared PDF policy catches compressed active content streams', () {
    final bytes = PdfSecurityFixtureFactory.flateStreamPdf(
      PdfSecurityFixtureFactory.compressedActiveActionBody(),
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
        AppPdfSecurityPolicy.externalLinks,
        AppPdfSecurityPolicy.formSubmissionAction,
      ]),
    );
    expect(
      AppGeneratedPdfValidationReport.inspect(Uint8List.fromList(bytes)).issues,
      containsAll(policyIssues),
    );
    expect(
      ReceiptPdfInspector.detectRiskFlags(bytes),
      containsAll([
        'embedded JavaScript',
        'auto-open actions',
        'launch actions',
        'automatic actions',
        'external links',
        'form submission actions',
      ]),
    );
  });

  test(
    'shared PDF policy maps a fixture table across generated and receipt PDF surfaces',
    () {
      final cases = <_SecurityFixtureCase>[
        _SecurityFixtureCase(
          name: 'raw active actions',
          bytes: PdfSecurityFixtureFactory.rawPdf(
            PdfSecurityFixtureFactory.activeActionBody(),
          ),
          issues: const [
            AppPdfSecurityPolicy.activeJavaScript,
            AppPdfSecurityPolicy.activeLaunchAction,
            AppPdfSecurityPolicy.automaticAction,
            AppPdfSecurityPolicy.autoOpenAction,
            AppPdfSecurityPolicy.dynamicFormContent,
            AppPdfSecurityPolicy.embeddedFile,
            AppPdfSecurityPolicy.embeddedMedia,
            AppPdfSecurityPolicy.externalLinks,
            AppPdfSecurityPolicy.formSubmissionAction,
          ],
          flags: const [
            'embedded JavaScript',
            'launch actions',
            'automatic actions',
            'auto-open actions',
            'form fields',
            'embedded files',
            'embedded media',
            'external links',
            'form submission actions',
          ],
        ),
        _SecurityFixtureCase(
          name: 'escaped names',
          bytes: PdfSecurityFixtureFactory.rawPdf(
            PdfSecurityFixtureFactory.escapedActiveNameBody(),
          ),
          issues: const [
            AppPdfSecurityPolicy.activeJavaScript,
            AppPdfSecurityPolicy.activeLaunchAction,
            AppPdfSecurityPolicy.automaticAction,
            AppPdfSecurityPolicy.autoOpenAction,
            AppPdfSecurityPolicy.dynamicFormContent,
            AppPdfSecurityPolicy.embeddedFile,
            AppPdfSecurityPolicy.embeddedMedia,
            AppPdfSecurityPolicy.externalLinks,
            AppPdfSecurityPolicy.formSubmissionAction,
          ],
          flags: const [
            'embedded JavaScript',
            'launch actions',
            'automatic actions',
            'auto-open actions',
            'form fields',
            'embedded files',
            'embedded media',
            'external links',
            'form submission actions',
          ],
        ),
        _SecurityFixtureCase(
          name: 'compressed active stream',
          bytes: PdfSecurityFixtureFactory.flateStreamPdf(
            PdfSecurityFixtureFactory.compressedActiveActionBody(),
          ),
          issues: const [
            AppPdfSecurityPolicy.activeJavaScript,
            AppPdfSecurityPolicy.activeLaunchAction,
            AppPdfSecurityPolicy.automaticAction,
            AppPdfSecurityPolicy.autoOpenAction,
            AppPdfSecurityPolicy.externalLinks,
            AppPdfSecurityPolicy.formSubmissionAction,
          ],
          flags: const [
            'embedded JavaScript',
            'launch actions',
            'automatic actions',
            'auto-open actions',
            'external links',
            'form submission actions',
          ],
        ),
        _SecurityFixtureCase(
          name: 'named media actions',
          bytes: PdfSecurityFixtureFactory.rawPdf(
            PdfSecurityFixtureFactory.namedMediaActionBody(),
          ),
          issues: const [
            AppPdfSecurityPolicy.embeddedMedia,
            AppPdfSecurityPolicy.externalLinks,
          ],
          flags: const ['embedded media', 'external links'],
        ),
        _SecurityFixtureCase(
          name: 'form data actions',
          bytes: PdfSecurityFixtureFactory.rawPdf(
            PdfSecurityFixtureFactory.formDataActionBody(),
          ),
          issues: const [
            AppPdfSecurityPolicy.automaticAction,
            AppPdfSecurityPolicy.formSubmissionAction,
          ],
          flags: const ['automatic actions', 'form submission actions'],
        ),
      ];

      for (final fixture in cases) {
        final policyIssues =
            AppPdfSecurityPolicy.activeContentIssueCodesForBytes(fixture.bytes);
        final generatedIssues = AppGeneratedPdfValidationReport.inspect(
          Uint8List.fromList(fixture.bytes),
        ).issues;
        final receiptFlags = ReceiptPdfInspector.detectRiskFlags(fixture.bytes);

        expect(policyIssues, containsAll(fixture.issues), reason: fixture.name);
        expect(
          generatedIssues,
          containsAll(fixture.issues),
          reason: fixture.name,
        );
        expect(receiptFlags, containsAll(fixture.flags), reason: fixture.name);
      }
    },
  );
}

class _SecurityFixtureCase {
  const _SecurityFixtureCase({
    required this.name,
    required this.bytes,
    required this.issues,
    required this.flags,
  });

  final String name;
  final List<int> bytes;
  final List<String> issues;
  final List<String> flags;
}
