import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/maintenance/data/maintenance_receipt_parser.dart';
import 'package:maintaniac/screens/maintenance/data/maintenance_receipt_review.dart';
import 'package:maintaniac/screens/maintenance/maintenance_receipt_review_screen.dart';
import 'package:maintaniac/shared/state/app_state.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/storage/app_storage_guard.dart';

class MaintenanceReceiptReviewHandle {
  const MaintenanceReceiptReviewHandle(this.future);

  final Future<MaintenanceReceiptReviewOutcome?> future;
}

Future<MaintenanceReceiptReviewHandle> openMaintenanceReceiptReview(
  WidgetTester tester,
  MaintenanceReceiptParserResult result,
  AppStateController state,
  GlobalOdometerController odometer,
  GlobalKey<NavigatorState> navigatorKey,
) async {
  tester.view.physicalSize = const Size(900, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

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
  final future = navigatorKey.currentState!
      .push<MaintenanceReceiptReviewOutcome>(
        MaterialPageRoute(
          builder: (_) => MaintenanceReceiptReviewScreen(parserResult: result),
        ),
      );
  await tester.pumpAndSettle();
  return MaintenanceReceiptReviewHandle(future);
}

Future<void> tapVisibleMaintenanceReceiptControl(
  WidgetTester tester,
  Finder finder,
) async {
  final target = finder.first;
  await tester.scrollUntilVisible(
    target,
    300,
    scrollable: find
        .descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.tap(target);
  await tester.pumpAndSettle();
}

MaintenanceReceiptParserResult maintenancePartsReceiptResult(
  VehicleProfile vehicle,
) {
  return parseMaintenanceReceipt(
    MaintenanceReceiptParserInput(
      activeVehicleId: vehicle.id,
      activeVehicleName: vehicle.nickname,
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

MaintenanceReceiptParserResult maintenanceServiceReceiptResult(
  VehicleProfile vehicle, {
  int currentOdometer = 101250,
}) {
  return parseMaintenanceReceipt(
    MaintenanceReceiptParserInput(
      activeVehicleId: vehicle.id,
      activeVehicleName: vehicle.nickname,
      currentOdometer: currentOdometer,
      sourceText: '''
TAKE 5 OIL CHANGE
07/23/2026
REPAIR ORDER 100
ODOMETER 100000
FULL SYNTHETIC OIL CHANGE 5W-30 79.99
NEXT DUE 105000
''',
    ),
  );
}

Future<AppStorageCheck> enoughMaintenanceTestStorage() async =>
    const AppStorageCheck(
      availableBytes: 1024 * 1024 * 1024,
      operationBytes: 1024 * 1024,
      requiredBytes: 26 * 1024 * 1024,
      purpose: AppStoragePurpose.smallRecordWrite,
    );
