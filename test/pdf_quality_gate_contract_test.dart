import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PDF user-facing copy keeps Maintainiac brand spelling', () {
    final pdfCopyFiles = [
      File('lib/shared/pdf/app_generated_pdf_models.dart'),
      File('lib/shared/pdf/app_generated_pdf_preview_screen.dart'),
      File('lib/shared/pdf/app_generated_pdf_service.dart'),
      File('lib/shared/documents/app_generated_pdf_archive_service.dart'),
    ];

    for (final file in pdfCopyFiles) {
      final source = file.readAsStringSync();

      expect(
        source,
        isNot(contains('Maintaniac')),
        reason: '${file.path} has misspelled PDF-facing brand copy.',
      );
      expect(
        source,
        contains('Maintainiac'),
        reason: '${file.path} should keep PDF-facing copy app-branded.',
      );
    }
  });

  test(
    'PDF quality gate stays behavior, storage, security, and receipt focused',
    () {
      final script = File('tool/pdf_quality_gate.sh').readAsStringSync();

      expect(script, contains('set -euo pipefail'));
      expect(script, contains('bash -n tool/pdf_quality_gate.sh'));
      expect(script, contains('bash -n tool/pdf_render_smoke_gate.sh'));
      expect(
        script,
        contains('python3 -m py_compile tool/pdf_render_pixel_assertions.py'),
      );
      expect(script, contains('bash tool/pdf_render_smoke_gate.sh'));
      expect(script, contains('cmp -s /tmp/maintainiac_gate_invoice_a.pdf'));
      expect(script, contains('cmp -s /tmp/maintainiac_gate_receipt_a.pdf'));
      expect(script, contains('dart analyze'));
      expect(script, contains('flutter test'));
      expect(script, contains('git diff --check'));
      expect(script, contains('lib/shared/pdf'));
      expect(
        script,
        contains('lib/screens/invoices/data/invoice_pdf_export_verifier.dart'),
      );
      expect(
        script,
        contains('lib/screens/invoices/data/invoice_pdf_privacy_guard.dart'),
      );
      expect(
        script,
        contains(
          'lib/screens/invoices/data/invoice_pdf_template_renderer.dart',
        ),
      );
      expect(
        script,
        contains('lib/shared/documents/app_generated_pdf_archive_service.dart'),
      );
      expect(
        script,
        contains(
          'lib/shared/widgets/receipt_capture/receipt_pdf_inspector.dart',
        ),
      );
      expect(script, contains('test/pdf_qa_fixture_inventory_test.dart'));
      expect(
        script,
        contains('test/document_engine_operating_directive_test.dart'),
      );
      expect(script, contains('test/pdf_cross_platform_contract_test.dart'));
      expect(
        script,
        contains('test/pdf_render_gate_invoice_generator_test.dart'),
      );
      expect(script, contains('test/pdf_security_policy_contract_test.dart'));
      expect(script, contains('test/pdf_text_decoder_contract_test.dart'));
      expect(script, contains('test/pdf_privacy_policy_contract_test.dart'));
      expect(script, contains('test/pdf_typography_contract_test.dart'));
      expect(script, contains('test/app_generated_pdf_service_test.dart'));
      expect(
        script,
        contains('test/invoice_document_engine_layout_contract_test.dart'),
      );
      expect(
        script,
        contains('test/invoice_pdf_export_verifier_contract_test.dart'),
      );
      expect(script, contains('test/invoice_template_pdf_factory_test.dart'));
      expect(script, contains('test/invoice_pdf_money_precision_test.dart'));
      expect(script, contains('test/pdf_formatters_contract_test.dart'));
      expect(script, contains('test/receipt_pdf_torture_test.dart'));
      expect(script, contains('test/receipt_pdf_torture_storage_test.dart'));
      expect(script, isNot(contains('service_pdf_security_test.dart')));
      expect(
        script,
        isNot(contains('test/app_generated_pdf_preview_screen_test.dart')),
      );
      expect(
        script,
        isNot(contains('test/receipt_pdf_viewer_accessibility_test.dart')),
      );
      expect(
        script,
        isNot(contains('test/receipt_pdf_viewer_hardening_test.dart')),
      );

      final renderGate = File(
        'tool/pdf_render_smoke_gate.sh',
      ).readAsStringSync();
      final pixelAssertions = File(
        'tool/pdf_render_pixel_assertions.py',
      ).readAsStringSync();
      expect(renderGate, contains('tool/pdf_render_pixel_assertions.py'));
      expect(renderGate, contains('PDF_RENDER_GATE_INVOICE_OUTPUT'));
      expect(renderGate, contains('PDF_RENDER_GATE_LONG_TEXT_INVOICE_OUTPUT'));
      expect(renderGate, contains('page_count'));
      expect(renderGate, contains('rendered_count'));
      expect(renderGate, contains('Real invoice render fixture'));
      expect(renderGate, contains('Long-text invoice render fixture'));
      expect(
        renderGate,
        contains(r'for page_number in $(seq 1 "$page_count")'),
      );
      expect(
        renderGate,
        contains('test/pdf_render_gate_invoice_generator_test.dart'),
      );
      expect(renderGate, contains('pdftoppm'));
      expect(pixelAssertions, contains('--max-edge-ink-ratio'));
      expect(pixelAssertions, contains('_edge_ink_ratio'));
      expect(pixelAssertions, contains('too much ink at the page edge'));
    },
  );
}
