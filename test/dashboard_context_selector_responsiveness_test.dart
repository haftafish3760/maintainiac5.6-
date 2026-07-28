// Dashboard context-selector responsive layout regression coverage.
// Owns narrow iPhone SE and Galaxy S24 viewport checks for selector labels.
// Does not own dashboard navigation, vehicle persistence, or trip tracking.
// Consumed by the dashboard UI regression suite; protects readable labels.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/dashboard/dashboard_panels.dart';
import 'package:maintaniac/screens/dashboard/vehicle_profile_widgets.dart';
import 'package:maintaniac/shared/state/app_state.dart';

void main() {
  testWidgets('context selectors remain readable on iPhone SE width', (
    tester,
  ) async {
    await _pumpSelectors(tester, const Size(375, 667));

    expect(find.text('WORK PROFILE'), findsOneWidget);
    expect(find.text('ACTIVE VEHICLE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('context selectors remain readable on Galaxy S24 width', (
    tester,
  ) async {
    await _pumpSelectors(tester, const Size(412, 915));

    expect(find.text('WORK PROFILE'), findsOneWidget);
    expect(find.text('ACTIVE VEHICLE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpSelectors(WidgetTester tester, Size logicalSize) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = logicalSize;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DashboardContextSelectors(
          activeVehicle: const VehicleProfilePreview(
            id: 'field-van',
            nickname: 'Field Service Van',
            year: '2024',
            make: 'Maintainiac',
            model: 'Service Vehicle',
            odometer: '1,000.0 mi',
            status: 'Ready',
            usage: VehicleUsage.businessPersonal,
          ),
          workProfile: 'Residential Service Operations',
          onVehicleChanged: (_) {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
