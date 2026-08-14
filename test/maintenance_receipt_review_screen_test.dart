import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/maintenance/data/maintenance_receipt_application_service.dart';
import 'package:maintaniac/screens/maintenance/data/maintenance_receipt_review.dart';
import 'package:maintaniac/screens/maintenance/maintenance_draft_store.dart';
import 'package:maintaniac/screens/maintenance/maintenance_receipt_review_flow.dart';
import 'package:maintaniac/shared/state/app_state.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';

import 'support/maintenance_receipt_review_widget_test_support.dart';

final _openReview = openMaintenanceReceiptReview;
final _tapVisible = tapVisibleMaintenanceReceiptControl;
final _partsResult = maintenancePartsReceiptResult;
final _serviceResult = maintenanceServiceReceiptResult;
final _enoughStorage = enoughMaintenanceTestStorage;

void main() {
  late AppStateController state;
  late GlobalOdometerController odometer;
  late GlobalKey<NavigatorState> navigatorKey;

  setUp(() async {
    await Hive.openBox<dynamic>(
      MaintenanceDraftStore.boxName,
      bytes: Uint8List(0),
    );
    MaintenanceDraftStore.setStorageCheckForTesting(_enoughStorage);
    state = AppStateController();
    odometer = GlobalOdometerController(initialReading: 101250);
    navigatorKey = GlobalKey<NavigatorState>();
  });

  tearDown(() async {
    state.dispose();
    odometer.dispose();
    await Hive.close();
    MaintenanceDraftStore.setStorageCheckForTesting(null);
  });

  testWidgets(
    'purchase review requires decisions and returns setup commands without mutation',
    (tester) async {
      final result = _partsResult(state.activeVehicle!);
      final handle = await _openReview(
        tester,
        result,
        state,
        odometer,
        navigatorKey,
      );
      await _tapVisible(tester, find.text('Continue with Reviewed Items'));
      expect(find.textContaining('Choose what to do with'), findsWidgets);
      expect(state.maintenance, isEmpty);
      expect(odometer.reading, 101250);

      while (find.textContaining('Use recommendation:').evaluate().isNotEmpty) {
        await _tapVisible(
          tester,
          find.textContaining('Use recommendation:').first,
        );
      }
      expect(find.textContaining('editable app suggestion'), findsWidgets);
      await _tapVisible(tester, find.text('Continue with Reviewed Items'));
      await tester.pumpAndSettle();

      final outcome = await handle.future;
      expect(outcome, isNotNull);
      expect(outcome!.isValid, isTrue);
      expect(outcome.commands, isNotEmpty);
      expect(
        outcome.commands,
        everyElement(
          isA<MaintenanceReceiptConfirmedCommand>()
              .having((command) => command.setupTracking, 'setup', isTrue)
              .having(
                (command) => command.logCompletedService,
                'service',
                isFalse,
              ),
        ),
      );
      expect(state.maintenance, isEmpty);
      expect(state.maintenanceEvents, isEmpty);
      expect(odometer.reading, 101250);
      expect(
        await MaintenanceDraftStore.loadReceiptReviewDraft(
          vehicleId: result.activeVehicleId,
          sourceFingerprintSha256: result.sourceFingerprintSha256,
        ),
        isNotNull,
      );
    },
  );

  testWidgets(
    'service odometer conflict needs confirmation and never changes global truth',
    (tester) async {
      odometer.dispose();
      odometer = GlobalOdometerController(initialReading: 90000);
      final result = _serviceResult(
        state.activeVehicle!,
        currentOdometer: 90000,
      );
      final handle = await _openReview(
        tester,
        result,
        state,
        odometer,
        navigatorKey,
      );
      await _tapVisible(
        tester,
        find.textContaining('Use recommendation:').first,
      );
      expect(find.textContaining('receipt evidence'), findsWidgets);
      expect(
        find.textContaining('receipt reading of 100000 miles'),
        findsOneWidget,
      );
      await _tapVisible(tester, find.text('Continue with Reviewed Items'));
      expect(
        find.textContaining('Confirm the receipt odometer'),
        findsOneWidget,
      );

      await _tapVisible(
        tester,
        find.textContaining('receipt reading of 100000 miles'),
      );
      await _tapVisible(tester, find.text('Continue with Reviewed Items'));
      await tester.pumpAndSettle();

      final outcome = await handle.future;
      expect(outcome, isNotNull);
      expect(outcome!.commands.single.logCompletedService, isTrue);
      expect(outcome.commands.single.serviceOdometer, 100000);
      expect(state.maintenance, isEmpty);
      expect(state.maintenanceEvents, isEmpty);
      expect(odometer.reading, 90000);
    },
  );

  testWidgets('discarding an edited review returns no command or mutation', (
    tester,
  ) async {
    final result = _serviceResult(state.activeVehicle!);
    final handle = await _openReview(
      tester,
      result,
      state,
      odometer,
      navigatorKey,
    );
    await _tapVisible(tester, find.textContaining('Use recommendation:').first);
    await _tapVisible(tester, find.text('Cancel'));

    expect(find.text('Discard receipt review?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Discard Review'));
    await tester.pumpAndSettle();

    expect(await handle.future, isNull);
    expect(state.maintenance, isEmpty);
    expect(state.maintenanceEvents, isEmpty);
    expect(odometer.reading, 101250);
  });

  testWidgets('active vehicle change blocks stale receipt review', (
    tester,
  ) async {
    final otherVehicle = state.vehicles.last;
    final result = _partsResult(otherVehicle);
    final handle = await _openReview(
      tester,
      result,
      state,
      odometer,
      navigatorKey,
    );

    expect(
      find.textContaining('active vehicle changed after this receipt'),
      findsOneWidget,
    );
    final continueButton = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Continue with Reviewed Items'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(continueButton.onPressed, isNull);

    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
    expect(await handle.future, isNull);
    expect(state.maintenance, isEmpty);
  });

  testWidgets(
    'text handoff binds live vehicle and odometer without OCR access',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      MaintenanceReceiptReviewOutcome? outcome;
      await tester.pumpWidget(
        AppStateScope(
          controller: state,
          child: GlobalOdometerScope(
            controller: odometer,
            child: MaterialApp(
              home: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () async {
                      outcome = await openMaintenanceReceiptTextReview(
                        context,
                        sourceText: '''
NAPA AUTO PARTS
07/23/2026
AUTOMOTIVE BATTERY GROUP 65 189.99
TOTAL 189.99
''',
                      );
                    },
                    child: const Text('Review text'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Review text'));
      await tester.pumpAndSettle();
      expect(find.text('Review Maintenance Receipt'), findsOneWidget);
      expect(find.text('NAPA Auto Parts'), findsOneWidget);
      expect(find.text(state.activeVehicle!.nickname), findsWidgets);
      expect(find.textContaining('101250 miles current'), findsOneWidget);

      await _tapVisible(
        tester,
        find.textContaining('Use recommendation:').first,
      );
      await _tapVisible(tester, find.text('Continue with Reviewed Items'));
      await tester.pumpAndSettle();
      expect(outcome, isNotNull);
      expect(outcome!.commands.single.vehicleId, state.activeVehicle!.id);
      expect(state.maintenance, isEmpty);
      expect(odometer.reading, 101250);
    },
  );

  testWidgets('text handoff restores the matching local review draft', (
    tester,
  ) async {
    final result = _partsResult(state.activeVehicle!);
    final restored = MaintenanceReceiptReview(
      parserResult: result,
      currentOdometer: odometer.reading,
      items: [
        for (final candidate in result.candidates)
          MaintenanceReceiptReviewItem(
            source: candidate,
            decision: MaintenanceReceiptReviewDecision.setupOnly,
          ),
      ],
    );
    await MaintenanceDraftStore.saveReceiptReviewDraft(
      vehicleId: result.activeVehicleId,
      vehicleName: result.activeVehicleName,
      sourceFingerprintSha256: result.sourceFingerprintSha256,
      review: restored.toDraftJson(),
    );

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
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => openMaintenanceReceiptTextReview(
                    context,
                    sourceText: '''
ADVANCE AUTO PARTS
07/23/2026
FULL SYNTHETIC MOTOR OIL 5W-30 34.99
OIL FILTER 12.99
TOTAL 47.98
''',
                  ),
                  child: const Text('Review text'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Review text'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('restored from local maintenance drafts'),
      findsOneWidget,
    );
    expect(find.textContaining('Use recommendation:'), findsNothing);

    await _tapVisible(tester, find.text('Cancel'));
    await tester.tap(find.widgetWithText(FilledButton, 'Discard Review'));
    await tester.pumpAndSettle();
    expect(
      await MaintenanceDraftStore.loadReceiptReviewDraft(
        vehicleId: result.activeVehicleId,
        sourceFingerprintSha256: result.sourceFingerprintSha256,
      ),
      isNull,
    );
  });

  testWidgets(
    'full text flow requires final consent then saves without odometer mutation',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      MaintenanceReceiptApplicationResult? result;
      await tester.pumpWidget(
        AppStateScope(
          controller: state,
          child: GlobalOdometerScope(
            controller: odometer,
            child: MaterialApp(
              home: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () async {
                      result = await openMaintenanceReceiptTextReviewAndConfirm(
                        context,
                        sourceText: '''
TAKE 5 OIL CHANGE
07/23/2026
ODOMETER 100000
FULL SYNTHETIC OIL CHANGE 5W-30 79.99
NEXT DUE 105000
''',
                      );
                    },
                    child: const Text('Review and save'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Review and save'));
      await tester.pumpAndSettle();
      await _tapVisible(
        tester,
        find.textContaining('Use recommendation:').first,
      );
      await _tapVisible(tester, find.text('Continue with Reviewed Items'));
      await tester.pumpAndSettle();

      expect(find.text('Save reviewed maintenance?'), findsOneWidget);
      expect(state.maintenance, isEmpty);
      expect(state.maintenanceEvents, isEmpty);
      expect(odometer.reading, 101250);

      await tester.tap(find.text('Save Maintenance'));
      await tester.pumpAndSettle();

      expect(result?.isApplied, isTrue);
      expect(state.maintenance, hasLength(1));
      expect(state.maintenanceEvents, hasLength(1));
      expect(odometer.reading, 101250);
    },
  );
}
