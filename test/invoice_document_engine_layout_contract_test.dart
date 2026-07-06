import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/invoices/data/invoice_ledger_models.dart';
import 'package:maintaniac/screens/invoices/data/invoice_pdf_export_verifier.dart';
import 'package:maintaniac/screens/invoices/data/invoice_pdf_privacy_guard.dart';
import 'package:maintaniac/screens/invoices/data/invoice_pdf_template_renderer.dart';
import 'package:maintaniac/screens/invoices/data/invoice_record.dart';
import 'package:maintaniac/screens/invoices/data/invoice_template_catalog.dart';
import 'package:maintaniac/shared/pdf/app_generated_pdf_models.dart';
import 'package:maintaniac/shared/pdf/app_pdf_page_spec.dart';
import 'package:maintaniac/shared/pdf/app_pdf_privacy_policy.dart';
import 'package:maintaniac/shared/pdf/app_pdf_text_decoder.dart';

import 'helpers/invoice_document_engine_fixture_factory.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('invoice Document Engine keeps pagination isolated from rendering', () {
    final rendererSource = File(
      'lib/screens/invoices/data/invoice_pdf_template_renderer.dart',
    ).readAsStringSync();
    final paginationSource = File(
      'lib/screens/invoices/data/invoice_pdf_pagination.dart',
    ).readAsStringSync();

    expect(rendererSource, contains("part 'invoice_pdf_pagination.dart';"));
    expect(
      paginationSource,
      contains("part of 'invoice_pdf_template_renderer.dart';"),
    );
    expect(paginationSource, contains('class _InvoicePaginator'));
    expect(paginationSource, contains('_minimumContinuationLines'));
    expect(rendererSource, isNot(contains('class _InvoicePaginator')));
  });

  test(
    'invoice Document Engine keeps content rules isolated from rendering',
    () {
      final rendererSource = File(
        'lib/screens/invoices/data/invoice_pdf_template_renderer.dart',
      ).readAsStringSync();
      final contentRulesSource = File(
        'lib/screens/invoices/data/invoice_pdf_content_rules.dart',
      ).readAsStringSync();

      expect(
        rendererSource,
        contains("part 'invoice_pdf_content_rules.dart';"),
      );
      expect(
        contentRulesSource,
        contains("part of 'invoice_pdf_template_renderer.dart';"),
      );
      expect(contentRulesSource, contains('class InvoicePdfContentRules'));
      expect(contentRulesSource, contains('issueCodesForRecord'));
      expect(contentRulesSource, contains('messageFor'));
      expect(rendererSource, isNot(contains('lineSubtotalsAreFinite')));
    },
  );

  test('invoice Document Engine layout text never uses hard clipping', () {
    final rendererSource = File(
      'lib/screens/invoices/data/invoice_pdf_template_renderer.dart',
    ).readAsStringSync();

    expect(rendererSource, isNot(contains('pw.TextOverflow.clip')));
    expect(rendererSource, contains('pw.TextOverflow.span'));
  });

  test('invoice Document Engine fixture factory keeps arithmetic stable', () {
    final standard = InvoiceDocumentEngineFixtureFactory.standardInvoice(
      lineCount: 14,
    );
    final estimate = InvoiceDocumentEngineFixtureFactory.estimate(lineCount: 9);
    final decimal =
        InvoiceDocumentEngineFixtureFactory.decimalsRefundsAndOverpayment();
    final huge = InvoiceDocumentEngineFixtureFactory.hugeInvoice(lineCount: 96);

    expect(standard.subtotalCents, greaterThan(0));
    expect(standard.taxTotalCents, greaterThan(0));
    expect(
      standard.totalCents,
      standard.taxableSubtotalCents + standard.taxTotalCents,
    );
    expect(
      standard.balanceDueCents,
      standard.totalCents - standard.paidTotalCents,
    );
    expect(estimate.isEstimate, isTrue);
    expect(estimate.paidTotalCents, 0);
    expect(decimal.subtotalCents, 18615);
    expect(decimal.discountAmountCents, 101);
    expect(decimal.taxTotalCents, -70);
    expect(decimal.balanceDueCents, -81557);
    expect(huge.lines.length, 96);
    expect(invoicePdfPageCountForRecord(huge), greaterThan(5));
  });

  test('invoice Document Engine renders core fixtures as valid PDFs', () async {
    final renderer = const InvoicePdfTemplateRenderer();
    final fixtures = <_InvoiceRenderFixture>[
      _InvoiceRenderFixture(
        name: 'standard invoice',
        record: InvoiceDocumentEngineFixtureFactory.standardInvoice(
          lineCount: 16,
        ),
        templateId: 'structured-logo',
        minimumPages: 2,
      ),
      _InvoiceRenderFixture(
        name: 'estimate',
        record: InvoiceDocumentEngineFixtureFactory.estimate(lineCount: 13),
        templateId: 'printer-friendly',
        minimumPages: 2,
      ),
      _InvoiceRenderFixture(
        name: 'missing optional fields',
        record: InvoiceDocumentEngineFixtureFactory.missingOptionalFields(),
        templateId: 'plumbing-watermark',
        minimumPages: 1,
      ),
      _InvoiceRenderFixture(
        name: 'decimal refunds and overpayment',
        record:
            InvoiceDocumentEngineFixtureFactory.decimalsRefundsAndOverpayment(),
        templateId: 'structured-logo',
        minimumPages: 1,
      ),
      _InvoiceRenderFixture(
        name: 'long text',
        record: InvoiceDocumentEngineFixtureFactory.longTextStress(
          lineCount: 34,
        ),
        templateId: 'structured-logo',
        minimumPages: 3,
      ),
    ];

    for (final fixture in fixtures) {
      final bytes = await renderer.buildRecordDocumentBytes(
        record: fixture.record,
        template: InvoiceTemplateCatalog.byId(fixture.templateId),
      );
      final report = AppGeneratedPdfValidationReport.inspect(
        Uint8List.fromList(bytes),
      );

      expect(bytes.length, greaterThan(1000), reason: fixture.name);
      expect(
        latin1.decode(bytes.take(5).toList()),
        '%PDF-',
        reason: fixture.name,
      );
      expect(report.isValid, isTrue, reason: fixture.name);
      expect(
        invoicePdfPageCountForRecord(fixture.record),
        greaterThanOrEqualTo(fixture.minimumPages),
        reason: fixture.name,
      );
      expect(
        sha256.convert(bytes).toString(),
        matches(RegExp(r'^[a-f0-9]{64}$')),
        reason: fixture.name,
      );
    }
  });

  test('invoice Document Engine output is deterministic by template', () async {
    final renderer = const InvoicePdfTemplateRenderer();
    final record = InvoiceDocumentEngineFixtureFactory.standardInvoice(
      lineCount: 22,
    );

    for (final template in InvoiceTemplateCatalog.templates) {
      final first = await renderer.buildRecordDocumentBytes(
        record: record.copyWith(templateId: template.id),
        template: template,
      );
      final second = await renderer.buildRecordDocumentBytes(
        record: record.copyWith(templateId: template.id),
        template: template,
      );

      expect(first, second, reason: template.id);
      expect(
        sha256.convert(first).toString(),
        sha256.convert(second).toString(),
        reason: template.id,
      );
    }
  });

  test(
    'invoice Document Engine supports portrait and landscape page formats',
    () async {
      expect(
        AppPdfPageSpec.letterPortrait.width,
        lessThan(AppPdfPageSpec.letterPortrait.height),
      );
      expect(
        AppPdfPageSpec.letterLandscape.width,
        greaterThan(AppPdfPageSpec.letterLandscape.height),
      );
      expect(
        AppPdfPageSpec.letterLandscape.rotated().key,
        AppPdfPageSpec.letterPortrait.key,
      );
      expect(AppPdfPageSpec.all.map((spec) => spec.key).toSet(), {
        'letter_portrait',
        'letter_landscape',
        'legal_portrait',
        'legal_landscape',
        'a4_portrait',
        'a4_landscape',
      });
      expect(AppPdfPageSpec.fromKey(' A4_LANDSCAPE ').key, 'a4_landscape');
      expect(AppPdfPageSpec.fromKey('unsupported').key, 'letter_portrait');

      final renderer = const InvoicePdfTemplateRenderer();
      final record =
          InvoiceDocumentEngineFixtureFactory.missingOptionalFields();
      final portraitBytes = await renderer.buildRecordDocumentBytes(
        record: record.copyWith(templateId: 'structured-logo'),
        template: InvoiceTemplateCatalog.byId('structured-logo'),
      );
      final landscapeBytes = await renderer.buildRecordDocumentBytes(
        record: record.copyWith(templateId: 'landscaping-garden-artwork-v1'),
        template: InvoiceTemplateCatalog.byId('landscaping-garden-artwork-v1'),
      );
      final legalBytes = await renderer.buildRecordDocumentBytes(
        record: record.copyWith(templateId: 'structured-logo'),
        template: InvoiceTemplateCatalog.byId('structured-logo'),
        pageSpecOverride: AppPdfPageSpec.legalPortrait,
      );
      final a4LandscapeBytes = await renderer.buildRecordDocumentBytes(
        record: record.copyWith(templateId: 'structured-logo'),
        template: InvoiceTemplateCatalog.byId('structured-logo'),
        pageSpecOverride: AppPdfPageSpec.a4Landscape,
      );

      final portraitBoxes = _mediaBoxes(portraitBytes);
      final landscapeBoxes = _mediaBoxes(landscapeBytes);
      final legalBoxes = _mediaBoxes(legalBytes);
      final a4LandscapeBoxes = _mediaBoxes(a4LandscapeBytes);

      expect(portraitBoxes, isNotEmpty);
      expect(landscapeBoxes, isNotEmpty);
      expect(legalBoxes, isNotEmpty);
      expect(a4LandscapeBoxes, isNotEmpty);
      expect(
        portraitBoxes.every((box) => box.isPortrait),
        isTrue,
        reason: 'structured-logo must stay vertical for normal invoices',
      );
      expect(
        landscapeBoxes.every((box) => box.isLandscape),
        isTrue,
        reason: 'landscaping artwork must generate horizontal PDF pages',
      );
      expect(legalBoxes.every((box) => box.isPortrait), isTrue);
      expect(a4LandscapeBoxes.every((box) => box.isLandscape), isTrue);
      expect(
        AppGeneratedPdfValidationReport.inspect(
          Uint8List.fromList(landscapeBytes),
        ).isValid,
        isTrue,
      );
    },
  );

  test(
    'invoice Document Engine landscape templates do not drop line items',
    () async {
      final renderer = const InvoicePdfTemplateRenderer();
      final template = InvoiceTemplateCatalog.byId(
        'landscaping-garden-artwork-v1',
      );
      final record =
          InvoiceDocumentEngineFixtureFactory.standardInvoice(
            lineCount: 17,
          ).copyWith(
            templateId: template.id,
            lines: [
              for (var index = 1; index <= 17; index++)
                InvoiceLineItemRecord(
                  id: 'landscape-retained-$index',
                  name: 'Landscape retained item $index',
                  details: 'Confirmed landscape page item $index',
                  quantity: 1,
                  unit: 'ea',
                  unitPrice: 10.0 + index,
                  taxRate: 0,
                  taxable: false,
                ),
            ],
          );

      final pageCount = invoicePdfPageCountForRecord(
        record,
        template: template,
      );
      final bytes = await renderer.buildRecordDocumentBytes(
        record: record,
        template: template,
      );
      final decoded = AppPdfTextDecoder.textWithDecodedPdfStreams(bytes);

      expect(pageCount, 3);
      expect(_mediaBoxes(bytes).every((box) => box.isLandscape), isTrue);
      expect(decoded, contains(r'$11.00'));
      expect(decoded, contains(r'$18.00'));
      expect(decoded, contains(r'$25.00'));
      expect(decoded, contains(r'$27.00'));
      expect(
        AppGeneratedPdfValidationReport.inspect(
          Uint8List.fromList(bytes),
        ).isValid,
        isTrue,
      );
    },
  );

  test(
    'invoice Document Engine never exports private vehicle or passenger data',
    () async {
      final privateRecord =
          InvoiceDocumentEngineFixtureFactory.standardInvoice(
            id: 'invoice-private-block',
            invoiceNumber: 'INV-PRIVATE-001',
            lineCount: 1,
          ).copyWith(
            title: 'Invoice for plate ABC 1234',
            lines: const [
              InvoiceLineItemRecord(
                id: 'private-line',
                name: 'Passenger: Jane Customer',
                details: 'VIN 1HGCM82633A004352',
                quantity: 1,
                unit: 'ea',
                unitPrice: 100,
                taxable: false,
              ),
            ],
          );

      final issues = InvoicePdfPrivacyGuard.issueCodesForRecord(privateRecord);

      expect(issues, contains(AppPdfPrivacyPolicy.licensePlate));
      expect(issues, contains(AppPdfPrivacyPolicy.vin));
      expect(issues, contains(AppPdfPrivacyPolicy.passengerData));
      await expectLater(
        const InvoicePdfTemplateRenderer().buildRecordDocumentBytes(
          record: privateRecord,
          template: InvoiceTemplateCatalog.byId('structured-logo'),
        ),
        throwsA(
          isA<InvoicePdfPrivacyException>().having(
            (error) => error.issues,
            'issues',
            containsAll([
              AppPdfPrivacyPolicy.licensePlate,
              AppPdfPrivacyPolicy.vin,
              AppPdfPrivacyPolicy.passengerData,
            ]),
          ),
        ),
      );
    },
  );

  test('invoice Document Engine refuses missing line items', () async {
    final record = InvoiceDocumentEngineFixtureFactory.standardInvoice(
      lineCount: 1,
    ).copyWith(lines: const []);

    expect(
      InvoicePdfTemplateRenderer.contentIssueCodesForRecord(record),
      contains(InvoicePdfTemplateRenderer.missingLineItems),
    );
    await expectLater(
      const InvoicePdfTemplateRenderer().buildRecordDocumentBytes(
        record: record,
        template: InvoiceTemplateCatalog.byId('structured-logo'),
      ),
      throwsA(
        isA<InvoicePdfContentException>().having(
          (error) => error.issues,
          'issues',
          contains(InvoicePdfTemplateRenderer.missingLineItems),
        ),
      ),
    );
  });

  test(
    'invoice Document Engine refuses missing business document identity',
    () async {
      final record =
          InvoiceDocumentEngineFixtureFactory.standardInvoice(
            lineCount: 1,
          ).copyWith(
            invoiceNumber: '   ',
            company: const InvoicePartySnapshot(),
            client: const InvoicePartySnapshot(),
          );

      expect(
        InvoicePdfTemplateRenderer.contentIssueCodesForRecord(record),
        containsAll([
          InvoicePdfTemplateRenderer.missingInvoiceNumber,
          InvoicePdfTemplateRenderer.missingCompanyName,
          InvoicePdfTemplateRenderer.missingClientName,
        ]),
      );
      await expectLater(
        const InvoicePdfTemplateRenderer().buildRecordDocumentBytes(
          record: record,
          template: InvoiceTemplateCatalog.byId('structured-logo'),
        ),
        throwsA(
          isA<InvoicePdfContentException>().having(
            (error) => error.issues,
            'issues',
            containsAll([
              InvoicePdfTemplateRenderer.missingInvoiceNumber,
              InvoicePdfTemplateRenderer.missingCompanyName,
              InvoicePdfTemplateRenderer.missingClientName,
            ]),
          ),
        ),
      );
    },
  );

  test('invoice Document Engine refuses impossible invoice dates', () async {
    final record =
        InvoiceDocumentEngineFixtureFactory.standardInvoice(
          lineCount: 1,
        ).copyWith(
          issueDate: InvoiceDocumentEngineFixtureFactory.fixedNow,
          dueDate: InvoiceDocumentEngineFixtureFactory.fixedNow.subtract(
            const Duration(days: 1),
          ),
        );

    expect(
      InvoicePdfTemplateRenderer.contentIssueCodesForRecord(record),
      contains(InvoicePdfTemplateRenderer.dueDateBeforeIssueDate),
    );
    await expectLater(
      const InvoicePdfTemplateRenderer().buildRecordDocumentBytes(
        record: record,
        template: InvoiceTemplateCatalog.byId('structured-logo'),
      ),
      throwsA(
        isA<InvoicePdfContentException>().having(
          (error) => error.message,
          'message',
          'Check the invoice dates before preparing the PDF.',
        ),
      ),
    );
  });

  test('invoice Document Engine refuses blank line items', () async {
    final record =
        InvoiceDocumentEngineFixtureFactory.standardInvoice(
          lineCount: 1,
        ).copyWith(
          lines: const [
            InvoiceLineItemRecord(
              id: 'blank-line',
              name: '   ',
              details: '   ',
              quantity: 1,
              unit: 'ea',
              unitPrice: 10,
              taxable: false,
            ),
          ],
        );

    expect(
      InvoicePdfTemplateRenderer.contentIssueCodesForRecord(record),
      contains(InvoicePdfTemplateRenderer.blankLineItem),
    );
    await expectLater(
      const InvoicePdfTemplateRenderer().buildRecordDocumentBytes(
        record: record,
        template: InvoiceTemplateCatalog.byId('structured-logo'),
      ),
      throwsA(
        isA<InvoicePdfContentException>().having(
          (error) => error.issues,
          'issues',
          contains(InvoicePdfTemplateRenderer.blankLineItem),
        ),
      ),
    );
  });

  test('invoice Document Engine refuses unsafe line-item numbers', () async {
    final record =
        InvoiceDocumentEngineFixtureFactory.standardInvoice(
          lineCount: 1,
        ).copyWith(
          lines: const [
            InvoiceLineItemRecord(
              id: 'bad-quantity',
              name: 'Bad quantity',
              quantity: double.nan,
              unitPrice: 10,
              taxRate: 0,
            ),
            InvoiceLineItemRecord(
              id: 'bad-price',
              name: 'Bad price',
              quantity: 1,
              unitPrice: double.infinity,
              taxRate: 0,
            ),
            InvoiceLineItemRecord(
              id: 'bad-tax',
              name: 'Bad tax',
              quantity: 1,
              unitPrice: 10,
              taxRate: -5,
            ),
          ],
        );

    expect(
      InvoicePdfTemplateRenderer.contentIssueCodesForRecord(record),
      containsAll([
        InvoicePdfTemplateRenderer.nonFiniteLineQuantity,
        InvoicePdfTemplateRenderer.nonFiniteLineUnitPrice,
        InvoicePdfTemplateRenderer.negativeLineTaxRate,
      ]),
    );
    await expectLater(
      const InvoicePdfTemplateRenderer().buildRecordDocumentBytes(
        record: record,
        template: InvoiceTemplateCatalog.byId('structured-logo'),
      ),
      throwsA(isA<InvoicePdfContentException>()),
    );
  });

  test(
    'invoice Document Engine refuses unsafe discounts and payments',
    () async {
      final badDiscount =
          InvoiceDocumentEngineFixtureFactory.standardInvoice(
            lineCount: 1,
          ).copyWith(
            discount: const InvoiceDiscountRecord(
              type: InvoiceDiscountType.percent,
              value: 150,
            ),
          );
      final badPayment =
          InvoiceDocumentEngineFixtureFactory.standardInvoice(
            lineCount: 1,
          ).copyWith(
            payments: [
              InvoicePaymentRecord(
                id: 'bad-payment',
                amount: double.infinity,
                paidAt: InvoiceDocumentEngineFixtureFactory.fixedNow,
                method: 'Card',
              ),
            ],
          );

      expect(
        InvoicePdfTemplateRenderer.contentIssueCodesForRecord(badDiscount),
        contains(InvoicePdfTemplateRenderer.excessiveDiscountPercent),
      );
      expect(
        InvoicePdfTemplateRenderer.contentIssueCodesForRecord(badPayment),
        contains(InvoicePdfTemplateRenderer.nonFinitePaymentAmount),
      );
      await expectLater(
        const InvoicePdfTemplateRenderer().buildRecordDocumentBytes(
          record: badDiscount,
          template: InvoiceTemplateCatalog.byId('structured-logo'),
        ),
        throwsA(isA<InvoicePdfContentException>()),
      );
      await expectLater(
        const InvoicePdfTemplateRenderer().buildRecordDocumentBytes(
          record: badPayment,
          template: InvoiceTemplateCatalog.byId('structured-logo'),
        ),
        throwsA(isA<InvoicePdfContentException>()),
      );
    },
  );

  test(
    'invoice Document Engine validates huge invoice pagination boundaries',
    () async {
      final renderer = const InvoicePdfTemplateRenderer();
      final record = InvoiceDocumentEngineFixtureFactory.hugeInvoice(
        lineCount: 120,
      );
      final bytes = await renderer.buildRecordDocumentBytes(
        record: record,
        template: InvoiceTemplateCatalog.byId('printer-friendly'),
      );
      final pages = invoicePdfPageCountForRecord(record);

      expect(pages, greaterThanOrEqualTo(10));
      expect(pages, lessThan(20));
      expect(bytes.length, greaterThan(1000));
      expect(
        AppGeneratedPdfValidationReport.inspect(
          Uint8List.fromList(bytes),
        ).isValid,
        isTrue,
      );
    },
  );

  test(
    'invoice Document Engine exercises every template with missing logos',
    () async {
      final renderer = const InvoicePdfTemplateRenderer();
      final record =
          InvoiceDocumentEngineFixtureFactory.missingOptionalFields();

      for (final template in InvoiceTemplateCatalog.templates) {
        final bytes = await renderer.buildRecordDocumentBytes(
          record: record.copyWith(templateId: template.id),
          template: template,
        );

        expect(bytes.length, greaterThan(1000), reason: template.id);
        expect(
          latin1.decode(bytes.take(5).toList()),
          '%PDF-',
          reason: template.id,
        );
        expect(
          AppGeneratedPdfValidationReport.inspect(
            Uint8List.fromList(bytes),
          ).isValid,
          isTrue,
          reason: template.id,
        );
      }
    },
  );

  test(
    'invoice Document Engine preserves decimal-safe totals in generated bytes',
    () async {
      final record =
          InvoiceDocumentEngineFixtureFactory.decimalsRefundsAndOverpayment();
      final bytes = await const InvoicePdfTemplateRenderer()
          .buildRecordDocumentBytes(
            record: record,
            template: InvoiceTemplateCatalog.byId('structured-logo'),
          );
      final decoded = AppPdfTextDecoder.textWithDecodedPdfStreams(bytes);

      expect(record.subtotalCents, 18615);
      expect(record.discountAmountCents, 101);
      expect(record.taxTotalCents, -70);
      expect(record.balanceDueCents, -81557);
      expect(decoded, contains(r'$186.15'));
      expect(decoded, contains(r'$1.01'));
      expect(decoded, contains(r'-$815.57'));
    },
  );

  test(
    'invoice Document Engine verifier proves rendered export essentials',
    () async {
      final renderer = const InvoicePdfTemplateRenderer();
      final records = <InvoiceRecord>[
        InvoiceDocumentEngineFixtureFactory.standardInvoice(lineCount: 16),
        InvoiceDocumentEngineFixtureFactory.estimate(lineCount: 13),
        InvoiceDocumentEngineFixtureFactory.decimalsRefundsAndOverpayment(),
      ];

      for (final record in records) {
        final template = InvoiceTemplateCatalog.byId(record.templateId);
        final bytes = await renderer.buildRecordDocumentBytes(
          record: record,
          template: template,
        );
        final issues = InvoicePdfExportVerifier.issueCodesForExport(
          record: record,
          template: template,
          bytes: bytes,
        );

        expect(issues, isEmpty, reason: record.invoiceNumber);
        expect(
          AppPdfTextDecoder.textWithDecodedPdfStreams(bytes),
          isNot(contains(record.id)),
          reason: record.invoiceNumber,
        );
      }
    },
  );

  test(
    'invoice Document Engine verifier rejects missing text and internal ids',
    () {
      final record = InvoiceDocumentEngineFixtureFactory.standardInvoice(
        id: 'internal-record-777',
        lineCount: 2,
      );
      final template = InvoiceTemplateCatalog.byId(record.templateId);
      final noTextIssues = InvoicePdfExportVerifier.issueCodesForExport(
        record: record,
        template: template,
        bytes: latin1.encode('%PDF-1.7\n1 0 obj<<>>endobj\n%%EOF'),
      );
      final internalIdIssues = InvoicePdfExportVerifier.issueCodesForExport(
        record: record,
        template: template,
        bytes: latin1.encode(
          '%PDF-1.7\n'
          'Invoice ${record.invoiceNumber}\n'
          '${record.company.bestName}\n'
          '${record.client.bestName}\n'
          '${record.balanceDue}\n'
          'Subtotal Total Balance internal-record-777\n'
          '%%EOF',
        ),
      );

      expect(
        noTextIssues,
        contains(InvoicePdfExportVerifier.missingPdfTextLayer),
      );
      expect(
        internalIdIssues,
        contains(InvoicePdfExportVerifier.internalRecordIdExported),
      );
    },
  );

  test(
    'invoice Document Engine page counts stay stable near known boundaries',
    () {
      final expectations = <int, int>{
        0: 1,
        1: 1,
        7: 1,
        8: 2,
        17: 2,
        18: 3,
        29: 3,
        30: 4,
        42: 5,
        54: 6,
        96: 9,
      };

      for (final entry in expectations.entries) {
        final record = InvoiceDocumentEngineFixtureFactory.standardInvoice(
          lineCount: entry.key,
        );

        expect(
          invoicePdfPageCountForRecord(record),
          entry.value,
          reason: 'line count ${entry.key}',
        );
      }
    },
  );
}

class _InvoiceRenderFixture {
  const _InvoiceRenderFixture({
    required this.name,
    required this.record,
    required this.templateId,
    required this.minimumPages,
  });

  final String name;
  final InvoiceRecord record;
  final String templateId;
  final int minimumPages;
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

  bool get isPortrait => height > width;

  bool get isLandscape => width > height;
}
