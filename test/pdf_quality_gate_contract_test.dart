import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'PDF quality gate stays behavior, storage, security, and receipt focused',
    () {
      final script = File('tool/pdf_quality_gate.sh').readAsStringSync();

      expect(script, contains('set -euo pipefail'));
      expect(script, contains('bash -n tool/pdf_quality_gate.sh'));
      expect(script, contains('bash -n tool/pdf_render_smoke_gate.sh'));
      expect(script, contains('bash tool/pdf_render_smoke_gate.sh'));
      expect(script, contains('dart analyze'));
      expect(script, contains('flutter test'));
      expect(script, contains('git diff --check'));
      expect(script, contains('lib/shared/pdf'));
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
      expect(script, contains('test/pdf_security_policy_contract_test.dart'));
      expect(script, contains('test/pdf_privacy_policy_contract_test.dart'));
      expect(script, contains('test/pdf_typography_contract_test.dart'));
      expect(script, contains('test/app_generated_pdf_service_test.dart'));
      expect(script, contains('test/invoice_template_pdf_factory_test.dart'));
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
    },
  );
}
