import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/maintenance/data/maintenance_receipt_application_service.dart';
import 'package:maintaniac/screens/maintenance/data/maintenance_receipt_parser.dart';
import 'package:maintaniac/screens/maintenance/data/maintenance_receipt_review.dart';
import 'package:maintaniac/shared/state/app_state.dart';
import 'package:maintaniac/shared/storage/app_storage_guard.dart';

void main() {
  test(
    'confirmed setup and service apply atomically and retry idempotently',
    () async {
      final state = AppStateController();
      addTearDown(state.dispose);
      final outcome = _confirmedServiceOutcome(
        state.activeVehicle!,
        includeOdometer: true,
      );

      final first = await applyMaintenanceReceiptOutcome(
        state: state,
        outcome: outcome,
      );

      expect(first.isApplied, isTrue);
      expect(first.recordsAdded, 1);
      expect(first.eventsAdded, 1);
      expect(state.maintenance, hasLength(1));
      expect(state.maintenanceEvents, hasLength(1));
      expect(state.maintenance.single.itemName, 'Engine Oil');
      expect(state.maintenance.single.lastServiceOdometer, 100000);
      expect(
        state.maintenance.single.sourceReceiptFingerprint,
        outcome.commands.single.sourceFingerprintSha256,
      );
      expect(
        state.maintenance.single.sourceParserSchemaVersion,
        MaintenanceReceiptParserResult.schemaVersion,
      );
      expect(
        state.maintenanceEvents.single.eventId,
        outcome.commands.single.commandId,
      );
      expect(
        state.maintenanceEvents.single.sourceCommandId,
        outcome.commands.single.commandId,
      );

      final retry = await applyMaintenanceReceiptOutcome(
        state: state,
        outcome: outcome,
      );

      expect(retry.isApplied, isTrue);
      expect(retry.recordsAdded, 0);
      expect(retry.eventsAdded, 0);
      expect(state.maintenance, hasLength(1));
      expect(state.maintenanceEvents, hasLength(1));
    },
  );

  test(
    'active vehicle change rejects the whole receipt without mutation',
    () async {
      final state = AppStateController();
      addTearDown(state.dispose);
      final outcome = _confirmedServiceOutcome(
        state.activeVehicle!,
        includeOdometer: true,
      );
      await state.selectVehicle(state.vehicles.last);

      final result = await applyMaintenanceReceiptOutcome(
        state: state,
        outcome: outcome,
      );

      expect(result.isApplied, isFalse);
      expect(
        result.issues.map((issue) => issue.code),
        contains('active_vehicle_changed'),
      );
      expect(state.maintenance, isEmpty);
      expect(state.maintenanceEvents, isEmpty);
    },
  );

  test(
    'basic purchase setup saves intervals without product details',
    () async {
      final state = AppStateController();
      addTearDown(state.dispose);
      final vehicle = state.activeVehicle!;
      final parsed = parseMaintenanceReceipt(
        MaintenanceReceiptParserInput(
          activeVehicleId: vehicle.id,
          activeVehicleName: vehicle.nickname,
          currentOdometer: 101250,
          sourceText: '''
ADVANCE AUTO PARTS
07/23/2026
FULL SYNTHETIC MOTOR OIL 5W-30 34.99
TOTAL 34.99
''',
        ),
      );
      final review = createMaintenanceReceiptReview(
        parserResult: parsed,
        currentOdometer: 101250,
      );
      final outcome = buildMaintenanceReceiptCommands(
        review.copyWith(
          items: [
            review.items.single.copyWith(
              decision: MaintenanceReceiptReviewDecision.setupOnly,
              intervalMiles: 7500,
              intervalMonths: 6,
            ),
          ],
        ),
      );

      final result = await applyMaintenanceReceiptOutcome(
        state: state,
        outcome: outcome,
      );

      expect(result.isApplied, isTrue);
      expect(state.maintenanceEvents, isEmpty);
      final record = state.maintenance.single;
      expect(record.setupComplete, isFalse);
      expect(record.intervalMiles, 7500);
      expect(record.intervalMonths, 6);
      expect(record.detailA, isEmpty);
      expect(record.detailB, isEmpty);
      expect(record.sourceCommandId, outcome.commands.single.commandId);

      final renewal = parseMaintenanceReceipt(
        MaintenanceReceiptParserInput(
          activeVehicleId: vehicle.id,
          activeVehicleName: vehicle.nickname,
          sourceText: 'DMV\n08/05/2026\nVEHICLE REGISTRATION RENEWED 79.00',
        ),
      );
      final renewalReview = createMaintenanceReceiptReview(
        parserResult: renewal,
        currentOdometer: 101250,
      );
      final renewalOutcome = buildMaintenanceReceiptCommands(
        renewalReview.copyWith(
          items: [
            renewalReview.items.single.copyWith(
              decision: MaintenanceReceiptReviewDecision.setupAndService,
            ),
          ],
        ),
      );
      expect(renewalOutcome.commands.single.intervalMiles, isNull);
      expect(renewalOutcome.commands.single.intervalMonths, 12);
      final renewalResult = await applyMaintenanceReceiptOutcome(
        state: state,
        outcome: renewalOutcome,
      );
      expect(renewalResult.isApplied, isTrue);
      final registration = state.maintenance.singleWhere(
        (saved) => saved.itemName == 'Registration',
      );
      expect(registration.intervalMiles, 0);
      expect(registration.intervalMonths, 12);
      expect(registration.importance, 98);
      expect(registration.timeOnly, isTrue);
      expect(registration.setupComplete, isTrue);
      expect(state.maintenanceEvents.single.odometer, 0);
    },
  );

  test('advanced setup explicitly saves reviewed product details', () async {
    final state = AppStateController();
    addTearDown(state.dispose);
    final vehicle = state.activeVehicle!;
    final parsed = parseMaintenanceReceipt(
      MaintenanceReceiptParserInput(
        activeVehicleId: vehicle.id,
        activeVehicleName: vehicle.nickname,
        sourceText: 'ADVANCE AUTO PARTS\nFULL SYNTHETIC MOTOR OIL 5W-30 34.99',
      ),
    );
    final review = createMaintenanceReceiptReview(
      parserResult: parsed,
      currentOdometer: 101250,
    );
    final outcome = buildMaintenanceReceiptCommands(
      review.copyWith(
        items: [
          review.items.single.copyWith(
            decision: MaintenanceReceiptReviewDecision.setupOnly,
            setupMode: MaintenanceReceiptSetupMode.advanced,
            intervalMiles: 7500,
            intervalMonths: 6,
          ),
        ],
      ),
    );

    final result = await applyMaintenanceReceiptOutcome(
      state: state,
      outcome: outcome,
    );

    expect(result.isApplied, isTrue);
    expect(state.maintenance.single.detailA, 'Full Synthetic');
    expect(state.maintenance.single.detailB, '5W-30');
  });

  test('basic setup rejects a forged advanced-detail payload', () async {
    final state = AppStateController();
    addTearDown(state.dispose);
    final outcome = _confirmedServiceOutcome(
      state.activeVehicle!,
      includeOdometer: true,
    );
    final source = outcome.commands.single;
    const forgedDetail = 'Full Synthetic';
    final forged = MaintenanceReceiptConfirmedCommand(
      vehicleId: source.vehicleId,
      vehicleName: source.vehicleName,
      commandId: maintenanceReceiptCommandId(
        sourceFingerprint: source.sourceFingerprintSha256,
        parserSchemaVersion: source.parserSchemaVersion,
        vehicleId: source.vehicleId,
        candidateIndex: source.candidateIndex,
        itemName: source.itemName,
        decision: source.decision,
        setupMode: source.setupMode,
        merchantName: source.merchantName,
        detailA: forgedDetail,
        detailB: source.detailB,
        serviceDate: source.serviceDate,
        serviceOdometer: source.serviceOdometer,
        intervalMiles: source.intervalMiles,
        intervalMonths: source.intervalMonths,
      ),
      sourceFingerprintSha256: source.sourceFingerprintSha256,
      parserSchemaVersion: source.parserSchemaVersion,
      candidateIndex: source.candidateIndex,
      decision: source.decision,
      setupMode: source.setupMode,
      itemName: source.itemName,
      setupTracking: source.setupTracking,
      logCompletedService: source.logCompletedService,
      merchantName: source.merchantName,
      evidenceLineNumbers: source.evidenceLineNumbers,
      detailA: forgedDetail,
      detailB: source.detailB,
      serviceDate: source.serviceDate,
      serviceOdometer: source.serviceOdometer,
      intervalMiles: source.intervalMiles,
      intervalMonths: source.intervalMonths,
    );

    final result = await applyMaintenanceReceiptOutcome(
      state: state,
      outcome: MaintenanceReceiptReviewOutcome(
        issues: const [],
        commands: [forged],
        vehicleId: outcome.vehicleId,
        sourceFingerprintSha256: outcome.sourceFingerprintSha256,
      ),
    );

    expect(result.isApplied, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('basic_setup_contains_advanced_details'),
    );
    expect(state.maintenance, isEmpty);
  });

  test(
    'missing service odometer rejects every command without partial setup',
    () async {
      final state = AppStateController();
      addTearDown(state.dispose);
      final outcome = _confirmedServiceOutcome(
        state.activeVehicle!,
        includeOdometer: false,
      );
      expect(outcome.isValid, isTrue);

      final result = await applyMaintenanceReceiptOutcome(
        state: state,
        outcome: outcome,
      );

      expect(result.isApplied, isFalse);
      expect(
        result.issues.map((issue) => issue.code),
        contains('service_evidence_required'),
      );
      expect(state.maintenance, isEmpty);
      expect(state.maintenanceEvents, isEmpty);
    },
  );

  test('edited command payload is rejected before durable mutation', () async {
    final state = AppStateController();
    addTearDown(state.dispose);
    final outcome = _confirmedServiceOutcome(
      state.activeVehicle!,
      includeOdometer: true,
    );
    final original = outcome.commands.single;
    final tampered = MaintenanceReceiptConfirmedCommand(
      vehicleId: original.vehicleId,
      vehicleName: original.vehicleName,
      commandId: original.commandId,
      sourceFingerprintSha256: original.sourceFingerprintSha256,
      parserSchemaVersion: original.parserSchemaVersion,
      candidateIndex: original.candidateIndex,
      decision: original.decision,
      setupMode: original.setupMode,
      itemName: original.itemName,
      setupTracking: original.setupTracking,
      logCompletedService: original.logCompletedService,
      merchantName: original.merchantName,
      evidenceLineNumbers: original.evidenceLineNumbers,
      detailA: original.detailA,
      detailB: original.detailB,
      serviceDate: original.serviceDate,
      serviceOdometer: original.serviceOdometer,
      intervalMiles: (original.intervalMiles ?? 5000) + 1,
      intervalMonths: original.intervalMonths,
    );
    final tamperedOutcome = MaintenanceReceiptReviewOutcome(
      issues: const [],
      commands: [tampered],
      vehicleId: outcome.vehicleId,
      sourceFingerprintSha256: outcome.sourceFingerprintSha256,
    );

    final result = await applyMaintenanceReceiptOutcome(
      state: state,
      outcome: tamperedOutcome,
    );

    expect(result.isApplied, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('command_integrity_failed'),
    );
    expect(state.maintenance, isEmpty);
    expect(state.maintenanceEvents, isEmpty);
  });

  test(
    'failed durable transaction leaves records and events unchanged',
    () async {
      final hiveDirectory = await Directory.systemTemp.createTemp(
        'maintenance_receipt_application_service_test_',
      );
      Hive.init(hiveDirectory.path);
      final state = await AppStateController.create(
        maintenanceStorageCheck: _blockedStorage,
      );
      try {
        final outcome = _confirmedServiceOutcome(
          state.activeVehicle!,
          includeOdometer: true,
        );

        await expectLater(
          applyMaintenanceReceiptOutcome(state: state, outcome: outcome),
          throwsA(isA<StateError>()),
        );

        expect(state.maintenance, isEmpty);
        expect(state.maintenanceEvents, isEmpty);
      } finally {
        state.dispose();
        await Hive.close();
        await hiveDirectory.delete(recursive: true);
      }
    },
  );

  test('receipt provenance survives local restart without raw text', () async {
    final hiveDirectory = await Directory.systemTemp.createTemp(
      'maintenance_receipt_provenance_test_',
    );
    Hive.init(hiveDirectory.path);
    final first = await AppStateController.create(
      maintenanceStorageCheck: _enoughStorage,
    );
    final outcome = _confirmedServiceOutcome(
      first.activeVehicle!,
      includeOdometer: true,
    );
    try {
      await applyMaintenanceReceiptOutcome(state: first, outcome: outcome);
      first.dispose();
      await Hive.close();
      Hive.init(hiveDirectory.path);

      final restored = await AppStateController.create(
        maintenanceStorageCheck: _enoughStorage,
      );
      try {
        expect(
          restored.maintenance.single.sourceReceiptFingerprint,
          outcome.commands.single.sourceFingerprintSha256,
        );
        expect(
          restored.maintenanceEvents.single.sourceCommandId,
          outcome.commands.single.commandId,
        );
        final serialized = {
          'record': restored.maintenance.single.toMap(),
          'event': restored.maintenanceEvents.single.toMap(),
        }.toString();
        expect(serialized, isNot(contains('TAKE 5 OIL CHANGE')));
        expect(serialized, isNot(contains('REPAIR ORDER 100')));
      } finally {
        restored.dispose();
      }
    } finally {
      await Hive.close();
      await hiveDirectory.delete(recursive: true);
    }
  });
}

MaintenanceReceiptReviewOutcome _confirmedServiceOutcome(
  VehicleProfile vehicle, {
  required bool includeOdometer,
}) {
  final parsed = parseMaintenanceReceipt(
    MaintenanceReceiptParserInput(
      activeVehicleId: vehicle.id,
      activeVehicleName: vehicle.nickname,
      currentOdometer: 101250,
      sourceText:
          '''
TAKE 5 OIL CHANGE
07/23/2026
REPAIR ORDER 100
${includeOdometer ? 'ODOMETER 100000' : ''}
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
        for (final item in review.items)
          item.copyWith(
            decision: MaintenanceReceiptReviewDecision.setupAndService,
          ),
      ],
    ),
  );
}

Future<AppStorageCheck> _blockedStorage() async => const AppStorageCheck(
  availableBytes: 0,
  operationBytes: 1024 * 1024,
  requiredBytes: 25 * 1024 * 1024,
  purpose: AppStoragePurpose.smallRecordWrite,
);

Future<AppStorageCheck> _enoughStorage() async => const AppStorageCheck(
  availableBytes: 1024 * 1024 * 1024,
  operationBytes: 1024 * 1024,
  requiredBytes: 26 * 1024 * 1024,
  purpose: AppStoragePurpose.smallRecordWrite,
);
