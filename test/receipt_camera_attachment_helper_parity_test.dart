import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'attachment-panel OCR helper files preserve late handoff parity with flow helpers',
    () async {
      final flowSignals = await File(
        'lib/shared/widgets/receipt_capture/receipt_capture_flow_handoff_signals.dart',
      ).readAsString();
      final panelSignals = await File(
        'lib/shared/widgets/receipt_capture/receipt_attachment_ocr_source_signals.dart',
      ).readAsString();
      final flowRisks = await File(
        'lib/shared/widgets/receipt_capture/receipt_capture_flow_handoff_risks.dart',
      ).readAsString();
      final panelRisks = await File(
        'lib/shared/widgets/receipt_capture/receipt_attachment_ocr_source_risk_flags.dart',
      ).readAsString();
      final storageHelpers = await File(
        'lib/shared/widgets/receipt_capture/receipt_capture_review_result_handoff_storage.dart',
      ).readAsString();

      expect(
        storageHelpers,
        contains('temporary_ocr_source_original_quality_proof'),
      );

      for (final token in const [
        'ocr_source_artifact_available',
        'receipt_proof_storage_',
        'stitch_failed_pair_',
        'stitch_review_focus_pair_',
        'native_recovery_freshness_',
        'native_recovery_storage_',
      ]) {
        expect(flowSignals, contains(token), reason: 'flow signals missing $token');
        expect(
          panelSignals,
          contains(token),
          reason: 'attachment-panel signals missing $token',
        );
      }

      for (final token in const [
        'ocr_source_stitch_failed_pair_',
        'ocr_source_stitch_review_focus_pair_',
        'ocr_source_saved_proof_fallback_review',
        'ocr_source_temporary_full_quality_guard_review',
      ]) {
        expect(flowRisks, contains(token), reason: 'flow risks missing $token');
        expect(
          panelRisks,
          contains(token),
          reason: 'attachment-panel risks missing $token',
        );
      }

      expect(
        panelSignals,
        contains(
          'attachmentSignalToken(result.receiptProofStoragePolicyOutcome)',
        ),
      );
      expect(
        panelSignals,
        contains(
          "attachmentSignalToken(entry.key)",
        ),
      );
      expect(
        flowSignals,
        contains(
          '_signalToken(result.receiptProofStoragePolicyOutcome)',
        ),
      );
      expect(
        flowSignals,
        contains(
          "_signalToken(entry.key)",
        ),
      );
    },
  );
}
