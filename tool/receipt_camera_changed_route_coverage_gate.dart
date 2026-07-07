import 'dart:io';

const milestoneRoutes = [
  'tool/receipt_camera_qa_gate.sh',
  'tool/receipt_camera_changed_gate.sh',
  'tool/receipt_camera_qa_summary.sh',
  'tool/receipt_camera_scope_gate.sh',
  'tool/receipt_camera_changed_route_coverage_gate.dart',
  'tool/receipt_fast_guard_gate.sh',
  'tool/receipt_external_dataset_local_audit.dart',
  'tool/receipt_external_dataset_gate.dart',
  'tool/receipt_external_fixture_schema_gate.dart',
  'tool/receipt_start_camera_qa_gate.sh',
  'tool/receipt_quiet_batch.sh',
  'tool/receipt_quiet_batch_status.sh',
  'test/receipt_camera_changed_gate_contract_test.dart',
  'test/receipt_camera_changed_route_coverage_gate_test.dart',
  'test/receipt_camera_dataset_qa_gate_contract_test.dart',
  'test/receipt_camera_qa_gate_contract_test.dart',
  'test/receipt_camera_qa_gate_execution_test.dart',
  'test/receipt_external_dataset_local_audit_test.dart',
  'test/receipt_external_dataset_gate_test.dart',
  'test/receipt_external_fixture_schema_gate_test.dart',
  'test/receipt_fast_guard_gate_contract_test.dart',
];

const fastGuardSmokeRoutes = [
  'tool/receipt_camera_changed_route_coverage_gate.dart',
  'tool/receipt_camera_scope_gate.sh',
  'tool/receipt_fast_guard_gate.sh',
  'tool/receipt_camera_qa_gate.sh',
  'tool/receipt_quiet_batch_status.sh',
  'tool/receipt_external_fixture_schema_gate.dart',
  'tool/receipt_external_dataset_local_audit.dart',
  'tool/receipt_external_dataset_gate.dart',
  'test/receipt_camera_changed_gate_contract_test.dart',
  'test/receipt_camera_changed_route_coverage_gate_test.dart',
  'test/receipt_camera_dataset_qa_gate_contract_test.dart',
  'test/receipt_external_fixture_schema_gate_test.dart',
  'test/receipt_fast_guard_gate_contract_test.dart',
];

void main(List<String> args) {
  if (args.length > 2) {
    stderr.writeln(
      'Usage: dart tool/receipt_camera_changed_route_coverage_gate.dart '
      '[changed_gate_path] [fast_guard_path]',
    );
    exit(64);
  }

  final changedGatePath = args.isEmpty
      ? 'tool/receipt_camera_changed_gate.sh'
      : args[0];
  final fastGuardPath = args.length < 2
      ? 'tool/receipt_fast_guard_gate.sh'
      : args[1];
  final changedGate = File(changedGatePath).readAsStringSync();
  final fastGuard = File(fastGuardPath).readAsStringSync();
  final failures = <String>[];

  for (final route in milestoneRoutes) {
    if (!changedGate.contains(route)) {
      failures.add('MISSING_CHANGED_GATE_ROUTE $route');
    }
  }

  for (final route in fastGuardSmokeRoutes) {
    final smoke =
        "RECEIPT_CAMERA_CHANGED_FILES_FOR_TEST='$route' \\\n"
        '  bash tool/receipt_camera_changed_gate.sh --print-mode >/dev/null';
    if (!fastGuard.contains(smoke)) {
      failures.add('MISSING_FAST_GUARD_ROUTE_SMOKE $route');
    }
  }

  if (failures.isNotEmpty) {
    stderr.writeln(failures.join('\n'));
    exit(1);
  }

  stdout.writeln(
    'Receipt camera changed-route coverage gate passed: '
    '${milestoneRoutes.length} milestone routes, '
    '${fastGuardSmokeRoutes.length} fast guard smokes.',
  );
}
