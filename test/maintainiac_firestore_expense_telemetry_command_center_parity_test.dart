import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_screen_telemetry.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_documents.dart';

import 'helpers/expense_telemetry_command_center_parity_fixture.dart';
import 'helpers/expense_telemetry_schema_expectations.dart';

void main() {
  test('keeps every Command Center telemetry field in Firestore summary', () {
    final snapshot = buildExpenseTelemetryCommandCenterParitySnapshot();
    final commandCenterMap = snapshot.toCommandCenterMap();
    final doc =
        MaintainiacFirestoreDocumentBuilder.expenseTelemetrySummaryDocument(
          orgId: 'ORG-1',
          summaryId: 'latest',
          snapshot: snapshot,
        );
    final missingKeys = [
      for (final key in commandCenterMap.keys)
        if (!doc.data.containsKey(key)) key,
    ];
    const criticalConditionalKeys = {
      'topExpenseSummaryOcrContractSource',
      'topExpenseSummaryOcrContractSkippedReason',
      'topOcrFailureCause',
      'topOcrFailureSource',
      'topOcrFailureSourceAction',
      'topOcrFailureStage',
      'topOcrFailureStageLabel',
    };

    expect(
      missingKeys,
      isEmpty,
      reason:
          'Firestore summary sanitizer must keep every top-level Command Center telemetry key.',
    );
    expect(
      commandCenterMap.keys.toSet(),
      expectedExpenseTelemetryCommandCenterKeys,
      reason:
          'Command Center expense telemetry schema changed. Update the Firestore sanitizer, docs, and Command 1 contract together.',
    );
    for (final key in criticalConditionalKeys) {
      expect(
        commandCenterMap,
        contains(key),
        reason: 'The rich parity fixture must exercise conditional key $key.',
      );
      expect(
        doc.data,
        contains(key),
        reason: 'Firestore summary must keep conditional telemetry key $key.',
      );
    }
    expect(doc.data['topExpenseSummaryOcrContractSource'], 'none');
    expect(
      doc.data['topExpenseSummaryOcrContractSkippedReason'],
      'ledger_ocr_contract_disabled',
    );
    expect(doc.data['topOcrFailureCause'], 'no_readable_text');
    expect(doc.data['topOcrFailureSource'], 'photo');
    expect(
      doc.data['topOcrFailureSourceAction'],
      'investigate_receipt_camera_focus_exposure_crop_coverage_long_rec',
    );
    expect(
      doc.data['topOcrFailureStage'],
      'after_attachment_read_before_parser',
    );
    expect(
      doc.data['topOcrFailureStageLabel'],
      'After attachment read before parser',
    );
    expect(doc.data['nativeRecoveryFreshnessCounts'], {'stale': 1});
    expect(doc.data['nativeRecoveryStorageStatusCounts'], {
      'partial_photos_available': 1,
    });
    expect(doc.data['topNativeRecoveryFreshness'], 'stale');
    expect(
      doc.data['topNativeRecoveryStorageStatus'],
      'partial_photos_available',
    );
    expect(
      doc.data['topNativeRecoveryAction'],
      contains('missing receipt photos'),
    );
    expect(doc.data['schema'], 'expense_telemetry_summary_v1');
    expect(doc.data['rawEventUploadCount'], 0);
    expect(doc.data.toString().toLowerCase(), isNot(contains('receipt text')));
    expect(doc.data.toString(), isNot(contains('ORG-1')));
  });
}
