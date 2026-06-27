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

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'maintenance_tracking_test_',
    );
    Hive.init(hiveDirectory.path);
    appState = AppStateController();
    odometer = GlobalOdometerController();
  });

  tearDown(() async {
    appState.dispose();
    odometer.dispose();
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
    expect(find.text('Items'), findsOneWidget);
    expect(find.text('Service Details'), findsOneWidget);
    expect(find.text('Engine Oil'), findsOneWidget);
    _expectSameRow(tester, 'Service Date', 'Service Odometer');

    await tester.ensureVisible(find.text('Review').last);
    await tester.pump();
    await tester.tap(find.text('Review').last);
    await tester.pumpAndSettle();

    expect(find.text('Review Service'), findsOneWidget);
    await tester.tap(find.text('Save Service'));
    await tester.pumpAndSettle();

    expect(appState.maintenanceEvents.length, 1);
    expect(appState.maintenanceEvents.single.itemName, 'Engine Oil');
    expect(appState.maintenance.single.milesSinceService, 0);
    expect(find.text('Tracked Maintenance'), findsOneWidget);
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
    await MaintenanceDraftStore.saveSetupDraft(
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
