import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fast receipt guard keeps source and log audits wired in', () {
    final script = File('tool/receipt_fast_guard_gate.sh').readAsStringSync();

    expect(script, contains('bash tool/receipt_cleanup_log_gate.sh'));
    expect(script, contains('bash tool/receipt_doc_size_gate.sh'));
    expect(script, contains('tool/receipt_bug_regression_ledger_gate.dart'));
    expect(
      script,
      contains('dart tool/receipt_bug_regression_ledger_gate.dart'),
    );
    expect(script, contains('dart analyze'));
    expect(script, contains('lib/shared/widgets/receipt_capture'));
    expect(script, contains('lib/shared/receipts'));
    expect(
      script,
      contains('lib/screens/expenses/data/expense_export_handoff.dart'),
    );
    expect(
      script,
      contains('lib/screens/expenses/data/expense_screen_telemetry.dart'),
    );
    expect(
      script,
      contains('lib/shared/firebase/maintainiac_firestore_documents.dart'),
    );
    expect(
      script,
      contains('lib/shared/firebase/maintainiac_firestore_upload_queue.dart'),
    );
    expect(
      script,
      contains(
        'test/expense_telemetry_ocr_source_redaction_contract_test.dart',
      ),
    );
    expect(
      script,
      contains('test/expense_telemetry_redaction_contract_guard_test.dart'),
    );
    expect(
      script,
      contains('test/expense_receipt_parser_assisted_review_test.dart'),
    );
    expect(
      script,
      contains('test/expense_receipt_parser_ocr_diagnostics_test.dart'),
    );
    expect(script, contains('test/expense_release_one_blueprint_test.dart'));
    expect(script, contains('test/firestore_data_model_guard_test.dart'));
    expect(
      script,
      contains('test/maintainiac_production_operating_directive_test.dart'),
    );
    expect(
      script,
      contains('test/receipt_camera_release_one_blueprint_test.dart'),
    );
    expect(
      script,
      contains('test/maintainiac_source_audit_contract_test.dart'),
    );
    expect(script, contains('test/receipt_doc_size_gate_contract_test.dart'));
    expect(script, contains('dart tool/maintainiac_source_audit.dart'));
    expect(script, contains('--max-line-length=220'));
    expect(script, contains('--tests-only'));
    expect(script, contains('dart tool/receipt_camera_io_guard.dart'));
    expect(script, contains('dart tool/receipt_camera_footprint_audit.dart'));
    expect(script, contains('test/receipt_fast_guard_gate_contract_test.dart'));
    expect(script, contains('tool/receipt_camera_qa_gate.sh'));
    expect(script, contains('tool/receipt_camera_qa_summary.sh'));
    expect(script, contains('tool/receipt_camera_scope_gate.sh'));
    expect(script, contains('tool/receipt_camera_changed_gate.sh'));
    expect(script, contains('tool/receipt_camera_stitch_gate.sh'));
    expect(script, contains('tool/receipt_start_camera_qa_gate.sh'));
    expect(script, contains('test/receipt_camera_qa_gate_contract_test.dart'));
    expect(script, contains('test/receipt_camera_footprint_audit_test.dart'));
    expect(script, contains('test/receipt_camera_result_test.dart'));
    expect(
      script,
      contains('test/receipt_photo_review_retake_order_test.dart'),
    );
    expect(
      script,
      contains('test/receipt_quiet_batch_policy_gate_contract_test.dart'),
    );
    expect(script, contains('test/receipt_quality_gate_contract_test.dart'));
    expect(script, contains('git diff --check'));
  });
}
