import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/maintenance/maintenance_screen.dart';
import 'package:maintaniac/shared/state/app_state.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';

Future<void> pumpMaintenanceTestScreen(
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

void expectMaintenanceFieldsOnSameRow(
  WidgetTester tester,
  String leftText,
  String rightText, {
  double tolerance = 3,
}) {
  final left = tester.getTopLeft(find.text(leftText).first).dy;
  final right = tester.getTopLeft(find.text(rightText).first).dy;
  expect((left - right).abs(), lessThan(tolerance));
}
