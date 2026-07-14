import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/maintenance/maintenance_draft_store.dart';
import 'package:maintaniac/screens/maintenance/maintenance_screen.dart';
import 'package:maintaniac/screens/maintenance/maintenance_models.dart';
import 'package:maintaniac/shared/calendar/calendar_day_flow.dart';
import 'package:maintaniac/shared/calendar/calendar_flow_models.dart';
import 'package:maintaniac/shared/state/app_state.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';

void main() {
  late AppStateController appState;
  late GlobalOdometerController odometer;
  late Directory hiveDirectory;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'maintenance_tracking_test_',
    );
    Hive.init(hiveDirectory.path);
    await Hive.openBox<dynamic>(MaintenanceDraftStore.boxName);
  });

  setUp(() async {
    if (Hive.isBoxOpen(MaintenanceDraftStore.boxName)) {
      await Hive.box<dynamic>(MaintenanceDraftStore.boxName).clear();
    }
    appState = AppStateController();
    odometer = GlobalOdometerController();
  });

  tearDown(() async {
    appState.dispose();
    odometer.dispose();
  });

  tearDownAll(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  testWidgets(
    'maintenance first-time selection lands on the maintenance home',
    (tester) async {
      await _pumpMaintenance(tester, appState, odometer);

      expect(find.text('Maintenance Setup'), findsOneWidget);
      expect(find.text('Manual Maintenance Setup'), findsNothing);

      await tester.tap(find.text('Engine Oil'));
      await tester.pump();
      await tester.ensureVisible(find.text('Continue'));
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Manual Maintenance Setup'), findsNothing);
      expect(find.text('Tracked Maintenance'), findsOneWidget);
      expect(find.text('Engine Oil'), findsOneWidget);
      expect(appState.maintenance.length, 1);
      expect(appState.maintenance.single.vehicleName, 'Work Truck 1');
    },
  );

  testWidgets('maintenance log service saves a service event', (tester) async {
    appState.addMaintenanceRecords([
      MaintenanceRecord(
        itemName: 'Engine Oil',
        vehicleName: 'Work Truck 1',
        intervalMiles: 5000,
        milesSinceService: 4100,
        intervalMonths: 6,
        monthsSinceService: 4,
        importance: 100,
      ),
    ]);

    await _pumpMaintenance(tester, appState, odometer);

    await tester.tap(find.text('Log Service'));
    await tester.pumpAndSettle();

    expect(find.text('Log Maintenance'), findsOneWidget);
    expect(find.text('Manual Service Visit'), findsOneWidget);
    expect(find.text('Engine Oil'), findsWidgets);
    expect(find.text('Item 1 of 1'), findsOneWidget);
    expect(find.text('Open Setup'), findsOneWidget);
    expect(find.text('Date of Service'), findsOneWidget);
    expect(find.text('Service Odometer'), findsOneWidget);
    expect(find.text('Who Did The Work?'), findsOneWidget);

    await tester.ensureVisible(find.text('Review').last);
    await tester.pump();
    await tester.tap(find.text('Review').last);
    await tester.pumpAndSettle();

    expect(find.text('Review Maintenance Visit'), findsOneWidget);
    expect(find.text('Expense'), findsOneWidget);
    expect(find.text('Not linked'), findsOneWidget);
    await tester.tap(find.text('Save Visit'));
    await tester.pumpAndSettle();

    expect(appState.maintenanceEvents.length, 1);
    expect(appState.maintenanceEvents.single.itemName, 'Engine Oil');
    expect(
      appState.maintenanceEvents.single.odometer,
      odometer.reading,
      reason:
          'Maintenance must use the shared vehicle odometer, not AppState\'s retired shadow value.',
    );
    expect(appState.maintenance.single.milesSinceService, 0);
    expect(find.text('Tracked Maintenance'), findsOneWidget);
  });

  testWidgets('manual maintenance visit handles multiple selected items', (
    tester,
  ) async {
    appState.addMaintenanceRecords([
      MaintenanceRecord(
        itemName: 'Engine Oil',
        vehicleName: 'Work Truck 1',
        intervalMiles: 5000,
        milesSinceService: 4100,
        intervalMonths: 6,
        monthsSinceService: 4,
        importance: 100,
      ),
      MaintenanceRecord(
        itemName: 'Oil Filter',
        vehicleName: 'Work Truck 1',
        intervalMiles: 5000,
        milesSinceService: 4100,
        intervalMonths: 6,
        monthsSinceService: 4,
        importance: 92,
      ),
      MaintenanceRecord(
        itemName: 'Tire Rotation',
        vehicleName: 'Work Truck 1',
        intervalMiles: 6000,
        milesSinceService: 5400,
        intervalMonths: 6,
        monthsSinceService: 5,
        importance: 90,
      ),
    ]);

    await _pumpMaintenance(tester, appState, odometer);

    await tester.tap(find.text('Log Service'));
    await tester.pumpAndSettle();

    expect(find.text('What Was Serviced?'), findsOneWidget);
    await tester.tap(find.text('Engine Oil').last);
    await tester.tap(find.text('Oil Filter').last);
    await tester.tap(find.text('Tire Rotation').last);
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Manual Service Visit'), findsOneWidget);
    expect(find.text('Item 1 of 3'), findsOneWidget);
    expect(find.text('Next Item'), findsOneWidget);

    await tester.tap(find.text('Next Item'));
    await tester.pumpAndSettle();

    expect(find.text('Item 2 of 3'), findsOneWidget);
    await tester.ensureVisible(find.text('Review'));
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();

    expect(find.text('Review Maintenance Visit'), findsOneWidget);
    expect(appState.maintenanceEvents, isEmpty);

    await tester.tap(find.text('Save Visit'));
    await tester.pumpAndSettle();

    expect(appState.maintenanceEvents.length, 3);
    expect(
      appState.maintenanceEvents.map((event) => event.itemName),
      containsAll(['Engine Oil', 'Oil Filter', 'Tire Rotation']),
    );
  });

  testWidgets('tracked maintenance row opens item setup', (tester) async {
    appState.addMaintenanceRecords([
      MaintenanceRecord(
        itemName: 'Engine Oil',
        vehicleName: 'Work Truck 1',
        intervalMiles: 5000,
        milesSinceService: 4100,
        intervalMonths: 6,
        monthsSinceService: 4,
        importance: 100,
      ),
    ]);

    await _pumpMaintenance(tester, appState, odometer);

    await tester.tap(find.text('Engine Oil').first);
    await tester.pumpAndSettle();

    expect(find.text('Engine Oil'), findsWidgets);
    expect(find.text('Last Service Information'), findsOneWidget);
    expect(find.text('Date of last service'), findsOneWidget);
    expect(find.text('How long has it been?'), findsOneWidget);
    expect(find.text('Odometer reading'), findsOneWidget);
    expect(find.text('Estimated miles since'), findsOneWidget);
    expect(find.text('Service Mode'), findsOneWidget);
    expect(find.text('Mileage Interval'), findsOneWidget);
    expect(find.text('Thresholds'), findsOneWidget);
  });

  testWidgets(
    'maintenance setup keeps paired fields side by side at S9 width',
    (tester) async {
      appState.addMaintenanceRecords([
        MaintenanceRecord(
          itemName: 'Engine Oil',
          vehicleName: 'Work Truck 1',
          intervalMiles: 5000,
          milesSinceService: 4100,
          intervalMonths: 6,
          monthsSinceService: 4,
          importance: 100,
        ),
      ]);

      await _pumpMaintenance(
        tester,
        appState,
        odometer,
        physicalSize: const Size(360, 900),
      );

      await tester.scrollUntilVisible(
        find.text('Engine Oil').first,
        180,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pump();
      await tester.tap(find.text('Engine Oil').first);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Mileage Interval'));
      await tester.pump();
      _expectSameRow(tester, 'Mileage Interval', 'Time Interval');

      await tester.ensureVisible(find.text('Show Advanced Details'));
      await tester.pump();
      await tester.tap(find.text('Show Advanced Details'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Oil type'));
      await tester.pump();
      _expectSameRow(tester, 'Oil type', 'Oil weight');

      await tester.scrollUntilVisible(
        find.text('900+ miles'),
        220,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pump();
      _expectSameRow(tester, '900+ miles', '31+ days', tolerance: 14);
    },
  );

  test('maintenance mileage threshold colors match product rules', () {
    expect(thresholdColor(901), const Color(0xFF20B24A));
    expect(thresholdColor(900), const Color(0xFFFFC928));
    expect(thresholdColor(601), const Color(0xFFFFC928));
    expect(thresholdColor(600), const Color(0xFFFF7A00));
    expect(thresholdColor(301), const Color(0xFFFF7A00));
    expect(thresholdColor(300), const Color(0xFFE3342F));
    expect(thresholdColor(0), const Color(0xFFE3342F));
    expect(thresholdColor(-1), const Color(0xFFE3342F));
  });

  testWidgets('maintenance calendar day view shows saved service entries', (
    tester,
  ) async {
    final serviceDate = DateTime.now();
    appState.logMaintenanceService(
      MaintenanceServiceEvent(
        itemName: 'Engine Oil',
        vehicleName: 'Work Truck 1',
        serviceDate: serviceDate,
        odometer: 128415,
        provider: 'Test Shop',
        totalCost: 74.25,
        receiptProofCount: 1,
        notes: 'Full synthetic service',
      ),
    );

    await tester.pumpWidget(
      AppStateScope(
        controller: appState,
        child: MaterialApp(
          home: CalendarDayFlowScreen(
            day: serviceDate,
            source: CalendarFlowSource.maintenance,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Maintenance Calendar'), findsOneWidget);
    expect(find.text('Services'), findsOneWidget);
    expect(find.text('1'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Engine Oil'),
      220,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('Engine Oil'), findsOneWidget);
    expect(find.text('Work Truck 1 - 128415 miles'), findsOneWidget);
    expect(find.text(r'$74.25'), findsOneWidget);
  });

  testWidgets('maintenance home summarizes saved service history', (
    tester,
  ) async {
    appState.addMaintenanceRecords([
      MaintenanceRecord(
        itemName: 'Engine Oil',
        vehicleName: 'Work Truck 1',
        intervalMiles: 5000,
        milesSinceService: 4100,
        intervalMonths: 6,
        monthsSinceService: 4,
        importance: 100,
      ),
    ]);
    appState.logMaintenanceService(
      MaintenanceServiceEvent(
        itemName: 'Engine Oil',
        vehicleName: 'Work Truck 1',
        serviceDate: DateTime.now(),
        odometer: 128415,
        provider: 'Test Shop',
        totalCost: 74.25,
        receiptProofCount: 1,
      ),
    );

    await _pumpMaintenance(tester, appState, odometer);
    await tester.pump();

    expect(find.text('Service History'), findsOneWidget);
    expect(find.text('Spent'), findsOneWidget);
    expect(find.text(r'$74.25'), findsOneWidget);
    expect(find.text('Proof'), findsOneWidget);
    expect(find.text(r'128,415 miles • $74.25 • 1 proof'), findsOneWidget);

    await tester.tap(find.text(r'128,415 miles • $74.25 • 1 proof'));
    await tester.pumpAndSettle();

    expect(find.text('Service Record'), findsOneWidget);
    expect(find.text('Provider'), findsOneWidget);
    expect(find.text('Test Shop'), findsOneWidget);
    expect(find.text('Open Item'), findsOneWidget);
    expect(find.text('Log Again'), findsOneWidget);
  });

  testWidgets('maintenance home shows setup draft and resumes it', (
    tester,
  ) async {
    appState.addMaintenanceRecords([
      MaintenanceRecord(
        itemName: 'Engine Oil',
        vehicleName: 'Work Truck 1',
        intervalMiles: 5000,
        milesSinceService: 4100,
        intervalMonths: 6,
        monthsSinceService: 4,
        importance: 100,
      ),
    ]);
    await tester.runAsync(
      () => MaintenanceDraftStore.saveSetupDraft(
        vehicleName: 'Work Truck 1',
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

    await _pumpMaintenance(tester, appState, odometer);
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
}

Future<void> _pumpMaintenance(
  WidgetTester tester,
  AppStateController appState,
  GlobalOdometerController odometer, {
  Size physicalSize = const Size(900, 1500),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = physicalSize;
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
}

void _expectSameRow(
  WidgetTester tester,
  String leftText,
  String rightText, {
  double tolerance = 3,
}) {
  final left = tester.getTopLeft(find.text(leftText).first).dy;
  final right = tester.getTopLeft(find.text(rightText).first).dy;
  expect((left - right).abs(), lessThan(tolerance));
}

Finder _editableTextWithValue(String value) {
  return find.byWidgetPredicate(
    (widget) => widget is EditableText && widget.controller.text == value,
    description: 'EditableText with value $value',
  );
}
