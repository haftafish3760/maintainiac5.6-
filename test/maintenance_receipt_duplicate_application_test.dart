import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/maintenance/data/maintenance_receipt_application_service.dart';
import 'package:maintaniac/screens/maintenance/data/maintenance_receipt_parser.dart';
import 'package:maintaniac/screens/maintenance/data/maintenance_receipt_review.dart';
import 'package:maintaniac/shared/state/app_state.dart';

void main() {
  test(
    'different scan identity cannot duplicate the same service event',
    () async {
      final state = AppStateController();
      addTearDown(state.dispose);
      final first = _serviceOutcome(
        state.activeVehicle!,
        merchantLine: 'TAKE 5 OIL CHANGE',
        orderLine: 'REPAIR ORDER 100',
      );
      final rescanned = _serviceOutcome(
        state.activeVehicle!,
        merchantLine: 'TAKE 5 OIL CHANGE STORE 22',
        orderLine: 'REPAIR ORDER 100 RESCAN',
      );
      expect(
        rescanned.commands.single.commandId,
        isNot(first.commands.single.commandId),
      );

      expect(
        (await applyMaintenanceReceiptOutcome(
          state: state,
          outcome: first,
        )).isApplied,
        isTrue,
      );
      final duplicate = await applyMaintenanceReceiptOutcome(
        state: state,
        outcome: rescanned,
      );

      expect(duplicate.isApplied, isFalse);
      expect(
        duplicate.issues.map((issue) => issue.code),
        contains('possible_duplicate_service_event'),
      );
      expect(state.maintenanceEvents, hasLength(1));

      final firstRenewal = _timeOnlyOutcome(
        state.activeVehicle!,
        receiptLine: 'COUNTY RECEIPT 200',
      );
      final rescannedRenewal = _timeOnlyOutcome(
        state.activeVehicle!,
        receiptLine: 'COUNTY RECEIPT 200 RESCAN',
      );
      expect(
        (await applyMaintenanceReceiptOutcome(
          state: state,
          outcome: firstRenewal,
        )).isApplied,
        isTrue,
      );
      final duplicateRenewal = await applyMaintenanceReceiptOutcome(
        state: state,
        outcome: rescannedRenewal,
      );
      expect(duplicateRenewal.isApplied, isFalse);
      expect(
        duplicateRenewal.issues.map((issue) => issue.code),
        contains('possible_duplicate_service_event'),
      );
      expect(state.maintenanceEvents, hasLength(2));
    },
  );
}

MaintenanceReceiptReviewOutcome _timeOnlyOutcome(
  VehicleProfile vehicle, {
  required String receiptLine,
}) {
  final parsed = parseMaintenanceReceipt(
    MaintenanceReceiptParserInput(
      activeVehicleId: vehicle.id,
      activeVehicleName: vehicle.nickname,
      sourceText:
          '''
COUNTY SERVICE CENTER
08/05/2026
$receiptLine
VEHICLE REGISTRATION RENEWED 79.00
''',
    ),
  );
  final review = createMaintenanceReceiptReview(
    parserResult: parsed,
    currentOdometer: 101250,
  );
  return buildMaintenanceReceiptCommands(
    review.copyWith(
      items: [
        review.items.single.copyWith(
          decision: MaintenanceReceiptReviewDecision.setupAndService,
        ),
      ],
    ),
  );
}

MaintenanceReceiptReviewOutcome _serviceOutcome(
  VehicleProfile vehicle, {
  required String merchantLine,
  required String orderLine,
}) {
  final parsed = parseMaintenanceReceipt(
    MaintenanceReceiptParserInput(
      activeVehicleId: vehicle.id,
      activeVehicleName: vehicle.nickname,
      currentOdometer: 101250,
      sourceText:
          '''
$merchantLine
07/23/2026
$orderLine
ODOMETER 100000
FULL SYNTHETIC OIL CHANGE 5W-30 79.99
NEXT DUE 105000
''',
    ),
  );
  final review = createMaintenanceReceiptReview(
    parserResult: parsed,
    currentOdometer: 101250,
  );
  return buildMaintenanceReceiptCommands(
    review.copyWith(
      items: [
        review.items.single.copyWith(
          decision: MaintenanceReceiptReviewDecision.setupAndService,
        ),
      ],
    ),
  );
}
