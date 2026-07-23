import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/maintenance/data/maintenance_receipt_parser.dart';

void main() {
  test('dirty character substitutions remain conservative and reviewable', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        sourceText: '''
AUT0Z0NE
07/23/2026
FULL SYNTHETLC 0IL 5W—3O 34.99
0IL FI1TER PH8A 12.99
AMOUNT PAID 47.98
''',
      ),
    );

    expect(result.merchantName, 'AutoZone');
    final oil = result.candidates.singleWhere(
      (candidate) => candidate.itemName == 'Engine Oil',
    );
    final filter = result.candidates.singleWhere(
      (candidate) => candidate.itemName == 'Oil Filter',
    );
    expect(oil.action, MaintenanceReceiptAction.reviewTrackingSetup);
    expect(oil.detailA, 'Full Synthetic');
    expect(oil.detailB, '5W-30');
    expect(filter.action, MaintenanceReceiptAction.reviewTrackingSetup);
    expect(filter.detailB, 'PH8A');
    expect(
      oil.evidence.map((item) => item.safeSnippet).join(' '),
      contains('SYNTHETLC'),
    );
    expect(
      filter.evidence.map((item) => item.safeSnippet).join(' '),
      contains('FI1TER'),
    );
  });

  test('crumpled line fragments can form one purchase candidate', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        sourceText: '''
ADVANCE AUTO PARTS
07/23/2026
FULL SYNTHETIC MOTOR
OIL 5W-30 34.99
OIL
FILTER PH8A 12.99
AMOUNT PAID 47.98
''',
      ),
    );

    expect(
      result.candidates.map((candidate) => candidate.itemName),
      containsAll(['Engine Oil', 'Oil Filter']),
    );
    expect(
      result.candidates,
      everyElement(
        isA<MaintenanceReceiptCandidate>()
            .having(
              (candidate) => candidate.action,
              'action',
              MaintenanceReceiptAction.reviewTrackingSetup,
            )
            .having(
              (candidate) => candidate.completedServiceIndicated,
              'completed',
              isFalse,
            ),
      ),
    );
  });

  test('dirty split service text still requires review before history', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        currentOdometer: 101000,
        sourceText: '''
MAIN STREET AUTO
07/23/2026
REPAIR ORDER 600
0D0METER 100000
SERVICE PERFORMED
0IL
CHANGE 5W—3O 69.99
PAID IN FULL 69.99
''',
      ),
    );

    final oil = result.candidates.single;
    expect(oil.itemName, 'Engine Oil');
    expect(oil.action, MaintenanceReceiptAction.reviewCompletedService);
    expect(oil.serviceOdometer, 100000);
    expect(oil.detailB, '5W-30');
    expect(oil.requiresUserConfirmation, isTrue);
  });

  test('unrecognized severe damage never invents maintenance', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        sourceText: '''
UNKNOWN STORE
07/23/2026
0!L F!LT3R ?? 12.99
TOTAL 12.99
''',
      ),
    );

    expect(result.candidates, isEmpty);
    expect(
      result.reviewStatus,
      MaintenanceReceiptReviewStatus.noMaintenanceEvidence,
    );
  });
}
