import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/maintenance/maintenance_item_detail_screen.dart';
import 'package:maintaniac/screens/maintenance/maintenance_settings_screen.dart';
import 'package:maintaniac/shared/state/app_state.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';

void main() {
  late AppStateController state;
  late GlobalOdometerController odometer;
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'maintenance_archive_ui_test_',
    );
    Hive.init(hiveDirectory.path);
    state = AppStateController();
    odometer = GlobalOdometerController(initialReading: 101250);
  });

  tearDown(() async {
    state.dispose();
    odometer.dispose();
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  testWidgets('stop tracking requires confirmation and preserves the record', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final vehicle = state.activeVehicle!;
    await state.addMaintenanceRecords([
      MaintenanceRecord(
        itemName: 'Engine Oil',
        vehicleId: vehicle.id,
        vehicleName: vehicle.nickname,
        intervalMiles: 5000,
        milesSinceService: 1000,
        intervalMonths: 6,
        monthsSinceService: 2,
        importance: 100,
        setupComplete: true,
      ),
    ]);
    final record = state.maintenance.single;
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      AppStateScope(
        controller: state,
        child: GlobalOdometerScope(
          controller: odometer,
          child: MaterialApp(
            navigatorKey: navigatorKey,
            home: const Scaffold(body: Text('Maintenance home')),
          ),
        ),
      ),
    );
    navigatorKey.currentState!.push<void>(
      MaterialPageRoute(
        builder: (_) => MaintenanceItemDetailScreen(record: record),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Stop Tracking'),
      250,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Stop Tracking'));
    await tester.pumpAndSettle();

    expect(find.text('Stop tracking this item?'), findsOneWidget);
    expect(state.maintenance, hasLength(1));
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Stop Tracking'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Maintenance home'), findsOneWidget);
    expect(state.maintenance, isEmpty);
    expect(state.allMaintenanceRecords.single.recordId, record.recordId);
    expect(state.allMaintenanceRecords.single.isArchived, isTrue);
  });

  testWidgets('maintenance settings restores only the active vehicle item', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final vehicle = state.activeVehicle!;
    await state.addMaintenanceRecords([
      MaintenanceRecord(
        itemName: 'Battery',
        vehicleId: vehicle.id,
        vehicleName: vehicle.nickname,
        intervalMiles: 0,
        milesSinceService: 0,
        intervalMonths: 48,
        monthsSinceService: 0,
        importance: 86,
        timeOnly: true,
      ),
    ]);
    final recordId = state.maintenance.single.recordId;
    await state.archiveMaintenanceRecord(recordId);

    await tester.pumpWidget(
      AppStateScope(
        controller: state,
        child: GlobalOdometerScope(
          controller: odometer,
          child: const MaterialApp(home: MaintenanceSettingsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Stopped Items'), findsOneWidget);
    expect(find.text('Battery'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Restore'));
    await tester.pump();

    expect(state.maintenance.single.recordId, recordId);
    expect(find.text('Battery'), findsNothing);
  });
}
