import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/maintenance/data/maintenance_receipt_application_service.dart';
import 'package:maintaniac/screens/maintenance/data/maintenance_receipt_parser.dart';
import 'package:maintaniac/screens/maintenance/data/maintenance_receipt_review.dart';
import 'package:maintaniac/screens/maintenance/maintenance_draft_store.dart';
import 'package:maintaniac/screens/maintenance/maintenance_receipt_apply_dialog.dart';
import 'package:maintaniac/shared/state/app_state.dart';
import 'package:maintaniac/shared/storage/app_storage_guard.dart';

void main() {
  late AppStateController state;

  setUp(() async {
    await Hive.openBox<dynamic>(
      MaintenanceDraftStore.boxName,
      bytes: Uint8List(0),
    );
    MaintenanceDraftStore.setStorageCheckForTesting(_enoughStorage);
    state = AppStateController();
  });

  tearDown(() async {
    state.dispose();
    await Hive.close();
    MaintenanceDraftStore.setStorageCheckForTesting(null);
  });

  testWidgets(
    'final confirmation cancels safely then applies and clears exact draft',
    (tester) async {
      final outcome = _confirmedOutcome(state.activeVehicle!);
      final parsed = _parsed(state.activeVehicle!);
      final review = createMaintenanceReceiptReview(
        parserResult: parsed,
        currentOdometer: 101250,
      );
      await MaintenanceDraftStore.saveReceiptReviewDraft(
        vehicleId: outcome.vehicleId,
        vehicleName: state.activeVehicle!.nickname,
        sourceFingerprintSha256: outcome.sourceFingerprintSha256,
        review: review.toDraftJson(),
      );
      MaintenanceReceiptApplicationResult? result;

      await tester.pumpWidget(
        AppStateScope(
          controller: state,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    result = await confirmAndApplyMaintenanceReceiptOutcome(
                      context,
                      outcome: outcome,
                    );
                  },
                  child: const Text('Apply receipt'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Apply receipt'));
      await tester.pumpAndSettle();
      expect(find.text('Save reviewed maintenance?'), findsOneWidget);
      expect(
        find.textContaining('odometer will not be changed'),
        findsOneWidget,
      );
      expect(state.maintenance, isEmpty);

      await tester.tap(find.text('Keep Reviewing'));
      await tester.pumpAndSettle();
      expect(result, isNull);
      expect(
        await MaintenanceDraftStore.loadReceiptReviewDraft(
          vehicleId: outcome.vehicleId,
          sourceFingerprintSha256: outcome.sourceFingerprintSha256,
        ),
        isNotNull,
      );

      await tester.tap(find.text('Apply receipt'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Maintenance'));
      await tester.pumpAndSettle();

      expect(result?.isApplied, isTrue);
      expect(state.maintenance, hasLength(1));
      expect(state.maintenanceEvents, hasLength(1));
      expect(
        await MaintenanceDraftStore.loadReceiptReviewDraft(
          vehicleId: outcome.vehicleId,
          sourceFingerprintSha256: outcome.sourceFingerprintSha256,
        ),
        isNull,
      );
    },
  );
}

MaintenanceReceiptParserResult _parsed(VehicleProfile vehicle) {
  return parseMaintenanceReceipt(
    MaintenanceReceiptParserInput(
      activeVehicleId: vehicle.id,
      activeVehicleName: vehicle.nickname,
      currentOdometer: 101250,
      sourceText: '''
TAKE 5 OIL CHANGE
07/23/2026
ODOMETER 100000
FULL SYNTHETIC OIL CHANGE 5W-30 79.99
NEXT DUE 105000
''',
    ),
  );
}

MaintenanceReceiptReviewOutcome _confirmedOutcome(VehicleProfile vehicle) {
  final review = createMaintenanceReceiptReview(
    parserResult: _parsed(vehicle),
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

Future<AppStorageCheck> _enoughStorage() async => const AppStorageCheck(
  availableBytes: 1024 * 1024 * 1024,
  operationBytes: 1024 * 1024,
  requiredBytes: 26 * 1024 * 1024,
  purpose: AppStoragePurpose.smallRecordWrite,
);
