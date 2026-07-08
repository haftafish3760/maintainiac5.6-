import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'receipt stitch contract health script runs stitch and handoff tests',
    () {
      final script = File('tool/receipt_stitch_contract_health.sh');
      expect(script.existsSync(), isTrue);

      final source = script.readAsStringSync();
      expect(
        source,
        contains('receipt_native_camera_session_limits_test.dart'),
      );
      expect(source, contains('receipt_capture_flow_shareability_test.dart'));
      expect(
        source,
        contains('receipt_camera_phase5_long_receipt_contract_test.dart'),
      );
      expect(source, contains('receipt_stitching_test.dart'));
      expect(source, contains('receipt_stitching_variants_test.dart'));
      expect(
        source,
        contains('receipt_camera_result_stitch_scanner_test.dart'),
      );
      expect(
        source,
        contains('receipt_camera_phase6_stitching_handoff_contract_test.dart'),
      );
      expect(
        source,
        contains(
          'receipt_camera_result_stitch_handoff_followthrough_test.dart',
        ),
      );
      expect(source, contains('Receipt stitch contract health: PASS'));
      expect(source, isNot(contains('receipt_camera_qa_gate.sh full')));
    },
  );
}
