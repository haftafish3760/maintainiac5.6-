import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('camera QA gate owns external receipt dataset safeguards', () {
    final qaGate = File('tool/receipt_camera_qa_gate.sh').readAsStringSync();
    final scopeGate = File(
      'tool/receipt_camera_scope_gate.sh',
    ).readAsStringSync();
    final changedGate = File(
      'tool/receipt_camera_changed_gate.sh',
    ).readAsStringSync();
    final fastGuard = File(
      'tool/receipt_fast_guard_gate.sh',
    ).readAsStringSync();

    for (final path in const [
      'tool/receipt_external_dataset_local_audit.dart',
      'tool/receipt_external_dataset_gate.dart',
      'tool/receipt_external_fixture_schema_gate.dart',
      'test/receipt_external_dataset_local_audit_test.dart',
      'test/receipt_external_dataset_gate_test.dart',
      'test/receipt_external_fixture_schema_gate_test.dart',
    ]) {
      expect(qaGate, contains(path));
      expect(scopeGate, contains(path));
    }

    for (final command in const [
      'dart tool/receipt_external_dataset_local_audit.dart',
      'dart tool/receipt_external_dataset_gate.dart',
      'dart tool/receipt_external_fixture_schema_gate.dart',
    ]) {
      expect(qaGate, contains(command));
      expect(fastGuard, contains(command));
    }

    for (final route in const [
      'tool/receipt_external_dataset_local_audit.dart',
      'tool/receipt_external_dataset_gate.dart',
      'tool/receipt_external_fixture_schema_gate.dart',
      'test/receipt_external_dataset_local_audit_test.dart',
      'test/receipt_external_dataset_gate_test.dart',
    ]) {
      expect(changedGate, contains(route));
    }

    expect(
      fastGuard,
      contains(
        "RECEIPT_CAMERA_CHANGED_FILES_FOR_TEST='tool/receipt_external_dataset_local_audit.dart'",
      ),
    );
    expect(
      fastGuard,
      contains(
        "RECEIPT_CAMERA_CHANGED_FILES_FOR_TEST='tool/receipt_external_dataset_gate.dart'",
      ),
    );
    expect(
      fastGuard,
      contains(
        "RECEIPT_CAMERA_CHANGED_FILES_FOR_TEST='tool/receipt_external_fixture_schema_gate.dart'",
      ),
    );
  });
}
