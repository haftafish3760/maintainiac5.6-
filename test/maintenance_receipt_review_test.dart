import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/maintenance/data/maintenance_receipt_parser.dart';
import 'package:maintaniac/screens/maintenance/data/maintenance_receipt_review.dart';

void main() {
  test('review starts undecided and cannot mutate maintenance', () {
    final review = createMaintenanceReceiptReview(
      parserResult: _partsReceipt(),
      currentOdometer: 101250,
    );

    expect(review.items, isNotEmpty);
    expect(
      review.items.first.decision,
      MaintenanceReceiptReviewDecision.undecided,
    );
    expect(
      review.items.first.recommendedDecision,
      MaintenanceReceiptReviewDecision.setupOnly,
    );
    expect(review.mayMutateMaintenance, isFalse);
    final outcome = buildMaintenanceReceiptCommands(review);
    expect(outcome.isValid, isFalse);
    expect(outcome.issues.first.code, 'decision_required');
    expect(outcome.commands, isEmpty);
    expect(outcome.mayMutateMaintenance, isFalse);
  });

  test('parts purchase can prepare setup without claiming installation', () {
    final source = createMaintenanceReceiptReview(
      parserResult: _partsReceipt(),
      currentOdometer: 101250,
    );
    final items = [
      for (final item in source.items)
        item.copyWith(decision: MaintenanceReceiptReviewDecision.setupOnly),
    ];
    final outcome = buildMaintenanceReceiptCommands(
      source.copyWith(items: items),
    );

    expect(outcome.isValid, isTrue);
    expect(outcome.commands, isNotEmpty);
    expect(
      outcome.commands,
      everyElement(isA<MaintenanceReceiptConfirmedCommand>()),
    );
    expect(outcome.commands.first.setupTracking, isTrue);
    expect(outcome.commands.first.logCompletedService, isFalse);
    expect(outcome.commands.first.setupMode, MaintenanceReceiptSetupMode.basic);
    expect(outcome.commands.first.detailA, isNull);
    expect(outcome.commands.first.detailB, isNull);
  });

  test(
    'parts purchase needs explicit installation confirmation for history',
    () {
      final source = createMaintenanceReceiptReview(
        parserResult: _partsReceipt(),
        currentOdometer: 101250,
      );
      final reviewed = source.copyWith(
        items: [
          source.items.first.copyWith(
            decision: MaintenanceReceiptReviewDecision.setupAndService,
            serviceDate: DateTime(2026, 7, 23),
            serviceOdometer: 101000,
          ),
          for (final item in source.items.skip(1))
            item.copyWith(decision: MaintenanceReceiptReviewDecision.ignore),
        ],
      );

      final blocked = buildMaintenanceReceiptCommands(reviewed);
      expect(blocked.issues.single.code, 'installation_confirmation_required');
      expect(blocked.commands, isEmpty);

      final confirmed = buildMaintenanceReceiptCommands(
        reviewed.copyWith(
          items: [
            reviewed.items.first.copyWith(
              confirmedPurchasedItemWasInstalled: true,
            ),
            ...reviewed.items.skip(1),
          ],
        ),
      );
      expect(confirmed.isValid, isTrue);
      expect(confirmed.commands.single.logCompletedService, isTrue);
    },
  );

  test('odometer conflict blocks command until separately acknowledged', () {
    final source = createMaintenanceReceiptReview(
      parserResult: _serviceReceipt(currentOdometer: 90000),
      currentOdometer: 90000,
    );
    final reviewed = source.copyWith(
      items: [
        for (final item in source.items)
          item.copyWith(
            decision: MaintenanceReceiptReviewDecision.setupAndService,
          ),
      ],
    );

    final blocked = buildMaintenanceReceiptCommands(reviewed);
    expect(
      blocked.issues.first.code,
      'odometer_conflict_confirmation_required',
    );
    expect(blocked.commands, isEmpty);

    final confirmed = buildMaintenanceReceiptCommands(
      reviewed.copyWith(
        items: [
          for (final item in reviewed.items)
            item.copyWith(confirmedOdometerConflict: true),
        ],
      ),
    );
    expect(confirmed.isValid, isTrue);
    expect(
      confirmed.commands.every((command) => command.serviceOdometer == 100000),
      isTrue,
    );
  });

  test('missing vehicle blocks maintenance commands but not ignore', () {
    final parserResult = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        sourceText: 'NAPA AUTO PARTS\nBATTERY GROUP 65 189.99',
      ),
    );
    final source = createMaintenanceReceiptReview(
      parserResult: parserResult,
      currentOdometer: 1000,
    );
    final apply = buildMaintenanceReceiptCommands(
      source.copyWith(
        items: [
          source.items.single.copyWith(
            decision: MaintenanceReceiptReviewDecision.setupOnly,
          ),
        ],
      ),
    );
    expect(apply.issues.single.code, 'vehicle_required');

    final ignore = buildMaintenanceReceiptCommands(
      source.copyWith(
        items: [
          source.items.single.copyWith(
            decision: MaintenanceReceiptReviewDecision.ignore,
          ),
        ],
      ),
    );
    expect(ignore.isValid, isTrue);
    expect(ignore.commands, isEmpty);
  });

  test('reviewed edits are carried without raw receipt text', () {
    final source = createMaintenanceReceiptReview(
      parserResult: _serviceReceipt(currentOdometer: 101250),
      currentOdometer: 101250,
    );
    final first = source.items.first;
    final reviewed = source.copyWith(
      items: [
        first.copyWith(
          decision: MaintenanceReceiptReviewDecision.setupAndService,
          setupMode: MaintenanceReceiptSetupMode.advanced,
          detailA: 'Synthetic Blend',
          detailB: '0W-20',
          intervalMiles: 6000,
        ),
        for (final item in source.items.skip(1))
          item.copyWith(decision: MaintenanceReceiptReviewDecision.ignore),
      ],
    );

    final outcome = buildMaintenanceReceiptCommands(reviewed);
    expect(outcome.isValid, isTrue);
    final command = outcome.commands.single;
    expect(command.detailA, 'Synthetic Blend');
    expect(command.detailB, '0W-20');
    expect(command.intervalMiles, 6000);
    expect(command.evidenceLineNumbers, isNotEmpty);
    expect(command.mayMutateMaintenance, isFalse);
  });

  test('return and declined-work contradictions need explicit resolution', () {
    final returnedResult = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_work_truck_1',
        sourceText: 'AUTOZONE\nRETURN BATTERY GROUP 65 -189.99',
      ),
    );
    final returned = createMaintenanceReceiptReview(
      parserResult: returnedResult,
      currentOdometer: 101250,
    );
    final blockedReturn = buildMaintenanceReceiptCommands(
      returned.copyWith(
        items: [
          returned.items.single.copyWith(
            decision: MaintenanceReceiptReviewDecision.setupOnly,
          ),
        ],
      ),
    );
    expect(blockedReturn.issues.single.code, 'return_resolution_required');

    final declinedResult = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_work_truck_1',
        sourceText:
            'REPAIR ORDER\n07/23/2026\nOIL CHANGE RECOMMENDED - DECLINED',
      ),
    );
    final declined = createMaintenanceReceiptReview(
      parserResult: declinedResult,
      currentOdometer: 101250,
    );
    final blockedDeclined = buildMaintenanceReceiptCommands(
      declined.copyWith(
        items: [
          declined.items.single.copyWith(
            decision: MaintenanceReceiptReviewDecision.serviceOnly,
            serviceDate: DateTime(2026, 7, 23),
          ),
        ],
      ),
    );
    expect(
      blockedDeclined.issues.single.code,
      'completed_work_confirmation_required',
    );
  });

  test('confirmed command identity is stable and vehicle-specific', () {
    MaintenanceReceiptReview reviewed(String vehicleId) {
      final parsed = parseMaintenanceReceipt(
        MaintenanceReceiptParserInput(
          activeVehicleId: vehicleId,
          activeVehicleName: 'Selected Vehicle',
          sourceText: 'AUTOZONE\n07/23/2026\nOIL FILTER 12.99',
        ),
      );
      final review = createMaintenanceReceiptReview(
        parserResult: parsed,
        currentOdometer: 101250,
      );
      return review.copyWith(
        items: [
          review.items.single.copyWith(
            decision: MaintenanceReceiptReviewDecision.setupOnly,
          ),
        ],
      );
    }

    final first = buildMaintenanceReceiptCommands(reviewed('vehicle_1'));
    final retry = buildMaintenanceReceiptCommands(reviewed('vehicle_1'));
    final otherVehicle = buildMaintenanceReceiptCommands(reviewed('vehicle_2'));

    expect(first.commands.single.commandId, retry.commands.single.commandId);
    expect(
      otherVehicle.commands.single.commandId,
      isNot(first.commands.single.commandId),
    );
    expect(first.commands.single.sourceFingerprintSha256, hasLength(64));
    expect(first.commands.single.parserSchemaVersion, 1);
    expect(first.commands.single.candidateIndex, 0);
    expect(
      first.commands.single.decision,
      MaintenanceReceiptReviewDecision.setupOnly,
    );
  });

  test('confirmed command identity binds every durable reviewed value', () {
    String identity({
      int parserSchemaVersion = 1,
      MaintenanceReceiptSetupMode setupMode =
          MaintenanceReceiptSetupMode.advanced,
      String merchantName = 'AUTOZONE',
      String? detailA = 'Full Synthetic',
      String? detailB = '5W-30',
      DateTime? serviceDate,
      int? serviceOdometer = 100000,
      int? intervalMiles = 5000,
      int? intervalMonths = 6,
    }) {
      return maintenanceReceiptCommandId(
        sourceFingerprint: 'a' * 64,
        parserSchemaVersion: parserSchemaVersion,
        vehicleId: 'vehicle_1',
        candidateIndex: 0,
        itemName: 'Engine Oil',
        decision: MaintenanceReceiptReviewDecision.setupAndService,
        setupMode: setupMode,
        merchantName: merchantName,
        detailA: detailA,
        detailB: detailB,
        serviceDate: serviceDate ?? DateTime.utc(2026, 7, 23),
        serviceOdometer: serviceOdometer,
        intervalMiles: intervalMiles,
        intervalMonths: intervalMonths,
      );
    }

    final baseline = identity();
    expect(identity(), baseline);
    expect(identity(parserSchemaVersion: 2), isNot(baseline));
    expect(
      identity(setupMode: MaintenanceReceiptSetupMode.basic),
      isNot(baseline),
    );
    expect(identity(merchantName: 'NAPA'), isNot(baseline));
    expect(identity(detailA: 'Synthetic Blend'), isNot(baseline));
    expect(identity(detailB: '0W-20'), isNot(baseline));
    expect(identity(serviceDate: DateTime.utc(2026, 7, 24)), isNot(baseline));
    expect(identity(serviceOdometer: 100001), isNot(baseline));
    expect(identity(intervalMiles: 7500), isNot(baseline));
    expect(identity(intervalMonths: 12), isNot(baseline));
  });

  test('review can explicitly clear parser-prefilled nullable fields', () {
    final source = createMaintenanceReceiptReview(
      parserResult: _serviceReceipt(currentOdometer: 101250),
      currentOdometer: 101250,
    );
    final cleared = source.items.first.copyWith(
      decision: MaintenanceReceiptReviewDecision.serviceOnly,
      clearServiceDate: true,
      clearServiceOdometer: true,
      clearIntervalMiles: true,
      clearIntervalMonths: true,
    );

    expect(cleared.effectiveServiceDate, isNull);
    expect(cleared.effectiveServiceOdometer, isNull);
    expect(cleared.effectiveIntervalMiles, isNull);
    expect(cleared.effectiveIntervalMonths, isNull);
    final outcome = buildMaintenanceReceiptCommands(
      source.copyWith(
        items: [
          cleared,
          for (final item in source.items.skip(1))
            item.copyWith(decision: MaintenanceReceiptReviewDecision.ignore),
        ],
      ),
    );
    expect(outcome.issues.single.code, 'service_date_required');
    expect(outcome.commands, isEmpty);
  });

  test('versioned review draft round-trips without raw receipt text', () {
    final parsed = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_work_truck_1',
        activeVehicleName: 'Work Truck 1',
        currentOdometer: 101250,
        sourceText: '''
TAKE 5 OIL CHANGE
VIN 1HGCM82633A004352
EMAIL owner@example.com
07/23/2026
REPAIR ORDER 100
ODOMETER 100000
FULL SYNTHETIC OIL CHANGE 5W-30 79.99
''',
      ),
    );
    final source = createMaintenanceReceiptReview(
      parserResult: parsed,
      currentOdometer: 101250,
    );
    final review = source.copyWith(
      items: [
        source.items.single.copyWith(
          decision: MaintenanceReceiptReviewDecision.setupAndService,
          setupMode: MaintenanceReceiptSetupMode.advanced,
          detailA: 'Synthetic Blend',
          intervalMiles: 6000,
        ),
      ],
    );

    final payload = review.toDraftJson();
    final encoded = jsonEncode(payload);
    expect(encoded, isNot(contains('1HGCM82633A004352')));
    expect(encoded, isNot(contains('owner@example.com')));
    expect(encoded, isNot(contains('"sourceText"')));
    final restored = MaintenanceReceiptReview.fromDraftJson(payload);
    expect(
      restored.parserResult.sourceFingerprintSha256,
      parsed.sourceFingerprintSha256,
    );
    expect(
      restored.items.single.decision,
      MaintenanceReceiptReviewDecision.setupAndService,
    );
    expect(
      restored.items.single.setupMode,
      MaintenanceReceiptSetupMode.advanced,
    );
    expect(restored.items.single.effectiveDetailA, 'Synthetic Blend');
    expect(restored.items.single.effectiveIntervalMiles, 6000);
    expect(restored.mayMutateMaintenance, isFalse);
  });

  test('review draft rejects unsupported or mismatched schemas', () {
    final source = createMaintenanceReceiptReview(
      parserResult: _partsReceipt(),
      currentOdometer: 101250,
    );
    final legacy = Map<String, Object?>.from(source.toDraftJson());
    final legacyItems = (legacy['items']! as List<Object?>)
        .map(
          (item) =>
              Map<String, Object?>.from(item! as Map)..remove('setupMode'),
        )
        .toList();
    legacy['items'] = legacyItems;
    expect(
      MaintenanceReceiptReview.fromDraftJson(
        legacy,
      ).items.map((item) => item.setupMode),
      everyElement(MaintenanceReceiptSetupMode.basic),
    );

    final unsupported = Map<String, Object?>.from(source.toDraftJson())
      ..['draftSchemaVersion'] = 999;
    expect(
      () => MaintenanceReceiptReview.fromDraftJson(unsupported),
      throwsFormatException,
    );

    final mismatched = Map<String, Object?>.from(source.toDraftJson())
      ..['items'] = const <Object?>[];
    expect(
      () => MaintenanceReceiptReview.fromDraftJson(mismatched),
      throwsFormatException,
    );
  });
}

MaintenanceReceiptParserResult _partsReceipt() {
  return parseMaintenanceReceipt(
    const MaintenanceReceiptParserInput(
      activeVehicleId: 'vehicle_work_truck_1',
      activeVehicleName: 'Work Truck 1',
      currentOdometer: 101250,
      sourceText: '''
ADVANCE AUTO PARTS
07/23/2026
FULL SYNTHETIC MOTOR OIL 5W-30 34.99
OIL FILTER 12.99
TOTAL 47.98
''',
    ),
  );
}

MaintenanceReceiptParserResult _serviceReceipt({required int currentOdometer}) {
  return parseMaintenanceReceipt(
    MaintenanceReceiptParserInput(
      activeVehicleId: 'vehicle_work_truck_1',
      activeVehicleName: 'Work Truck 1',
      currentOdometer: currentOdometer,
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
