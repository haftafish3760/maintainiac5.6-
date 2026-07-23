import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/maintenance/data/maintenance_receipt_parser.dart';
import 'package:maintaniac/screens/maintenance/data/maintenance_receipt_review.dart';
import 'package:maintaniac/screens/maintenance/maintenance_draft_store.dart';
import 'package:maintaniac/screens/maintenance/maintenance_screen.dart';
import 'package:maintaniac/shared/state/app_state.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';

void main() {
  late Directory hiveDirectory;
  late AppStateController appState;
  late GlobalOdometerController odometer;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'maintenance_draft_resume_test_',
    );
    Hive.init(hiveDirectory.path);
    await Hive.openBox<dynamic>(MaintenanceDraftStore.boxName);
    appState = AppStateController();
    odometer = GlobalOdometerController();
  });

  tearDown(() async {
    appState.dispose();
    odometer.dispose();
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  testWidgets('maintenance home shows setup draft and resumes it', (
    tester,
  ) async {
    final vehicle = appState.activeVehicle!;
    await appState.addMaintenanceRecords([
      MaintenanceRecord(
        itemName: 'Engine Oil',
        vehicleId: vehicle.id,
        vehicleName: vehicle.nickname,
        intervalMiles: 5000,
        milesSinceService: 4100,
        intervalMonths: 6,
        monthsSinceService: 4,
        importance: 100,
      ),
    ]);
    await tester.runAsync(
      () => MaintenanceDraftStore.saveSetupDraft(
        vehicleName: vehicle.nickname,
        itemName: 'Engine Oil',
        values: {
          'dateEntryMode': 'elapsed',
          'odometerEntryMode': 'distance',
          'monthsSinceService': '2',
          'milesSinceService': '1200',
          'mileInterval': 7500,
          'monthInterval': 6,
        },
      ),
    );

    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 1500);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      AppStateScope(
        controller: appState,
        child: GlobalOdometerScope(
          controller: odometer,
          child: const MaterialApp(home: MaintenanceScreen()),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Unfinished Maintenance'), findsOneWidget);
    expect(find.text('Setup draft'), findsOneWidget);

    await tester.tap(find.text('Setup draft'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('How long has it been?'), findsOneWidget);
    expect(find.text('Estimated miles since'), findsOneWidget);
    expect(_editableTextWithValue('2'), findsOneWidget);
    expect(_editableTextWithValue('1200'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets(
    'maintenance home resumes a receipt review by stable vehicle id',
    (tester) async {
      final vehicle = appState.activeVehicle!;
      await appState.addMaintenanceRecords([
        MaintenanceRecord(
          itemName: 'Engine Oil',
          vehicleId: vehicle.id,
          vehicleName: vehicle.nickname,
          intervalMiles: 5000,
          milesSinceService: 1000,
          intervalMonths: 6,
          monthsSinceService: 1,
          importance: 100,
        ),
      ]);
      final parsed = parseMaintenanceReceipt(
        MaintenanceReceiptParserInput(
          activeVehicleId: vehicle.id,
          activeVehicleName: vehicle.nickname,
          currentOdometer: odometer.reading,
          sourceText: '''
NAPA AUTO PARTS
07/23/2026
AUTOMOTIVE BATTERY GROUP 65 189.99
TOTAL 189.99
''',
        ),
      );
      final review = MaintenanceReceiptReview(
        parserResult: parsed,
        currentOdometer: odometer.reading,
        items: [
          for (final candidate in parsed.candidates)
            MaintenanceReceiptReviewItem(
              source: candidate,
              decision: MaintenanceReceiptReviewDecision.setupOnly,
            ),
        ],
      );
      await tester.runAsync(
        () => MaintenanceDraftStore.saveReceiptReviewDraft(
          vehicleId: vehicle.id,
          vehicleName: vehicle.nickname,
          sourceFingerprintSha256: parsed.sourceFingerprintSha256,
          review: review.toDraftJson(),
        ),
      );

      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1500);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        AppStateScope(
          controller: appState,
          child: GlobalOdometerScope(
            controller: odometer,
            child: const MaterialApp(home: MaintenanceScreen()),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Unfinished Maintenance'), findsOneWidget);
      expect(find.text('Receipt review'), findsOneWidget);
      expect(find.text('NAPA Auto Parts'), findsOneWidget);

      await tester.tap(find.text('Receipt review'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Review Maintenance Receipt'), findsOneWidget);
      expect(
        find.textContaining('restored from local maintenance drafts'),
        findsOneWidget,
      );
      expect(find.text(vehicle.nickname), findsWidgets);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}

Finder _editableTextWithValue(String value) {
  return find.byWidgetPredicate(
    (widget) => widget is EditableText && widget.controller.text == value,
    description: 'EditableText with value $value',
  );
}
