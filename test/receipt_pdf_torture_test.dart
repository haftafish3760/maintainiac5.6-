import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_pdf_inspector.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_pdf_limits.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_pdf_viewer_screen.dart';

import 'helpers/pdf_torture_fixtures.dart';
import 'helpers/receipt_pdf_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PDF torture fixtures', () {
    late PdfTortureFixtures fixtures;

    setUp(() async {
      fixtures = await PdfTortureFixtures.create();
    });

    tearDown(() async {
      await fixtures.dispose();
    });

    test('creates every requested torture file in a temp sandbox', () {
      expect(
        fixtures.files.keys,
        containsAll([
          'valid_1_page',
          'valid_3_page',
          'valid_10_page',
          'valid_20_page',
          'document_50_page',
          'blank_pages',
          'rotated_pages',
          'landscape_pages',
          'image_layer_pdf',
          'cropped_pages',
          'long_filename',
          'special_filename',
          'zero_byte',
          'txt_renamed_pdf',
          'image_renamed_pdf',
          'corrupted_pdf',
          'truncated_pdf',
          'invalid_header',
          'no_pages',
          'password_marker',
          'duplicate_original',
          'duplicate_different_filename',
          'duplicate_different_path',
          'active_actions',
          'manual_document',
        ]),
      );
      for (final file in fixtures.files.values) {
        expect(file.path, startsWith(fixtures.root.path));
        expect(file.existsSync(), isTrue);
      }
    });

    test(
      'valid PDFs import while long and unusual documents warn safely',
      () async {
        final simple = await ReceiptPdfInspector.inspect(
          fixtures['valid_1_page'].path,
        );
        final three = await ReceiptPdfInspector.inspect(
          fixtures['valid_3_page'].path,
        );
        final ten = await ReceiptPdfInspector.inspect(
          fixtures['valid_10_page'].path,
        );
        final twenty = await ReceiptPdfInspector.inspect(
          fixtures['valid_20_page'].path,
        );
        final fifty = await ReceiptPdfInspector.inspect(
          fixtures['document_50_page'].path,
        );
        final blank = await ReceiptPdfInspector.inspect(
          fixtures['blank_pages'].path,
        );
        final rotated = await ReceiptPdfInspector.inspect(
          fixtures['rotated_pages'].path,
        );
        final landscape = await ReceiptPdfInspector.inspect(
          fixtures['landscape_pages'].path,
        );
        final imageLayer = await ReceiptPdfInspector.inspect(
          fixtures['image_layer_pdf'].path,
        );
        final cropped = await ReceiptPdfInspector.inspect(
          fixtures['cropped_pages'].path,
        );
        final longName = await ReceiptPdfInspector.inspect(
          fixtures['long_filename'].path,
        );
        final specialName = await ReceiptPdfInspector.inspect(
          fixtures['special_filename'].path,
        );

        for (final inspection in [
          simple,
          three,
          ten,
          twenty,
          fifty,
          blank,
          rotated,
          landscape,
          imageLayer,
          cropped,
          longName,
          specialName,
        ]) {
          expect(inspection.importBlocker, isNull);
          expect(inspection.validationStatus, ReceiptPdfValidationStatus.valid);
          expect(
            inspection.pageCountStatus,
            ReceiptPdfPageCountStatus.estimated,
          );
        }

        expect(simple.pageCount, 1);
        expect(three.pageCount, 3);
        expect(ten.pageCount, 10);
        expect(twenty.userWarning, contains('longer than most'));
        expect(fifty.exceedsAssistedReadPageLimit, isFalse);
        expect(fifty.longReceiptWarning, contains('unusually long'));
        expect(
          simple.documentSignals,
          contains(ReceiptPdfInspector.portraitPageSignal),
        );
        expect(
          landscape.documentSignals,
          contains(ReceiptPdfInspector.landscapePageSignal),
        );
        expect(imageLayer.appearsImageOnly, isTrue);
        expect(imageLayer.documentFitWarning, contains('image-based pages'));
        expect(cropped.hasRotatedOrCroppedPages, isTrue);
        expect(cropped.documentFitWarning, contains('rotated or cropped'));
      },
    );

    test(
      'bad and fake PDFs are blocked or proof-only without crashing',
      () async {
        final zero = await ReceiptPdfInspector.inspect(
          fixtures['zero_byte'].path,
        );
        final txt = await ReceiptPdfInspector.inspect(
          fixtures['txt_renamed_pdf'].path,
        );
        final image = await ReceiptPdfInspector.inspect(
          fixtures['image_renamed_pdf'].path,
        );
        final corrupted = await ReceiptPdfInspector.inspect(
          fixtures['corrupted_pdf'].path,
        );
        final truncated = await ReceiptPdfInspector.inspect(
          fixtures['truncated_pdf'].path,
        );
        final invalid = await ReceiptPdfInspector.inspect(
          fixtures['invalid_header'].path,
        );
        final noPages = await ReceiptPdfInspector.inspect(
          fixtures['no_pages'].path,
        );
        final password = await ReceiptPdfInspector.inspect(
          fixtures['password_marker'].path,
        );

        expect(zero.importBlocker, contains('empty'));
        expect(txt.importBlocker, contains('valid PDF'));
        expect(image.importBlocker, contains('valid PDF'));
        expect(invalid.importBlocker, contains('valid PDF'));
        expect(corrupted.importBlocker, isNull);
        expect(corrupted.riskFlags, contains('missing EOF marker'));
        expect(truncated.riskFlags, contains('missing EOF marker'));
        expect(noPages.pageCountStatus, ReceiptPdfPageCountStatus.estimated);
        expect(noPages.importBlocker, contains('does not appear to contain'));
        expect(password.importBlocker, isNull);
        expect(password.assistedReadBlocker, contains('encrypted'));
        expect(
          password.handlingDisposition,
          ReceiptPdfHandlingDisposition.proofOnly,
        );
      },
    );

    test(
      'hard limits and page limits are enforced without auto-processing',
      () async {
        final exactLimit = File('${fixtures.root.path}/exact_hard_limit.pdf');
        final overLimit = File('${fixtures.root.path}/over_hard_limit.pdf');
        final overHardPages = File('${fixtures.root.path}/over_hard_pages.pdf');
        await writeSparsePdfHeader(exactLimit, ReceiptPdfLimits.maxPdfBytes);
        await writeSparsePdfHeader(overLimit, ReceiptPdfLimits.maxPdfBytes + 1);
        await writeFakePdfWithPages(
          overHardPages,
          ReceiptPdfLimits.hardPdfPageLimit + 1,
        );

        final exact = await ReceiptPdfInspector.inspect(exactLimit.path);
        final over = await ReceiptPdfInspector.inspect(overLimit.path);
        final pages = await ReceiptPdfInspector.inspect(overHardPages.path);

        expect(exact.importBlocker, isNull);
        expect(exact.exceedsImportSizeLimit, isFalse);
        expect(over.importBlocker, contains('too large'));
        expect(over.validationStatus, ReceiptPdfValidationStatus.tooLarge);
        expect(pages.importBlocker, isNull);
        expect(pages.exceedsHardReceiptPageLimit, isTrue);
        expect(pages.assistedReadBlocker, contains('too long'));
        expect(pages.longReceiptWarning, contains('read-only proof'));
        expect(
          pages.handlingDisposition,
          ReceiptPdfHandlingDisposition.proofOnly,
        );
      },
    );

    test('preview summary is safe for missing, risky, and long PDFs', () async {
      final missing = await ReceiptPdfInspector.inspect(
        '${fixtures.root.path}/missing.pdf',
      );
      final active = await ReceiptPdfInspector.inspect(
        fixtures['active_actions'].path,
      );
      final manual = await ReceiptPdfInspector.inspect(
        fixtures['manual_document'].path,
      );
      final long = await ReceiptPdfInspector.inspect(
        fixtures['document_50_page'].path,
      );

      final missingSummary = ReceiptPdfViewerSummary.fromInspection(missing);
      final activeSummary = ReceiptPdfViewerSummary.fromInspection(active);
      final manualSummary = ReceiptPdfViewerSummary.fromInspection(manual);
      final longSummary = ReceiptPdfViewerSummary.fromInspection(long);

      expect(missingSummary.detailLabels, contains('Cannot attach'));
      expect(missingSummary.warning, isNull);
      expect(active.importBlocker, isNull);
      expect(active.riskFlags, contains('auto-open actions'));
      expect(activeSummary.warning, contains('will not run scripts'));
      expect(manual.importBlocker, isNull);
      expect(manualSummary.warning, contains('more like'));
      expect(longSummary.detailLabels, contains('50 pages'));
      expect(longSummary.detailLabels.join(' '), contains('read-only proof'));
    });
  });
}
