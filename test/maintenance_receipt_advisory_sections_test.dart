import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/maintenance/data/maintenance_receipt_parser.dart';

void main() {
  test('advisory headings scope findings without claiming service', () {
    final scenarios =
        <
          ({
            String id,
            String sourceText,
            String completedItem,
            String advisoryItem,
          })
        >[
          (
            id: 'technician notes after completed oil service',
            sourceText: '''
MAIN STREET AUTO
07/23/2026
REPAIR ORDER 233
WORK COMPLETED
ENGINE OIL CHANGE 59.99
TECHNICIAN NOTES
FRONT BRAKE PADS WORN
PAID IN FULL 59.99
''',
            completedItem: 'Engine Oil',
            advisoryItem: 'Brake Pads',
          ),
          (
            id: 'advisories after completed tire rotation',
            sourceText: '''
MAIN STREET AUTO
07/23/2026
REPAIR ORDER 234
SERVICE PERFORMED
TIRE ROTATION 29.99
ADVISORIES
AUTOMOTIVE BATTERY WEAK
PAID IN FULL 29.99
''',
            completedItem: 'Tire Rotation',
            advisoryItem: 'Battery',
          ),
          (
            id: 'completed heading resets observations',
            sourceText: '''
MAIN STREET AUTO
07/23/2026
REPAIR ORDER 235
OBSERVATIONS
CABIN AIR FILTER DIRTY
WORK COMPLETED
TIRE ROTATION 29.99
PAID IN FULL 29.99
''',
            completedItem: 'Tire Rotation',
            advisoryItem: 'Cabin Air Filter',
          ),
        ];

    for (final scenario in scenarios) {
      final result = parseMaintenanceReceipt(
        MaintenanceReceiptParserInput(
          activeVehicleId: 'vehicle_1',
          sourceText: scenario.sourceText,
        ),
      );
      final candidates = {
        for (final candidate in result.candidates)
          candidate.itemName: candidate,
      };

      expect(
        candidates[scenario.completedItem]!.action,
        MaintenanceReceiptAction.reviewCompletedService,
        reason: scenario.id,
      );
      expect(
        candidates[scenario.completedItem]!.notCompletedIndicated,
        isFalse,
        reason: scenario.id,
      );
      expect(
        candidates[scenario.advisoryItem]!.action,
        MaintenanceReceiptAction.manualReview,
        reason: scenario.id,
      );
      expect(
        candidates[scenario.advisoryItem]!.notCompletedIndicated,
        isTrue,
        reason: scenario.id,
      );
    }
  });
}
