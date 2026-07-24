import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/dashboard/trip_tracking_setup_sheet.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';

void main() {
  testWidgets('first setup asks work type before location assistance', (
    tester,
  ) async {
    await _pumpLauncher(tester, const TripTrackingSettings());

    await tester.tap(find.text('Open setup'));
    await tester.pumpAndSettle();

    expect(find.text('Step 1 of 3'), findsOneWidget);
    expect(find.text('What Type of Work Do You Do?'), findsOneWidget);
    expect(find.text('Contractor and service work'), findsOneWidget);
    expect(find.text('Would You Like Location Assistance?'), findsNothing);
  });

  testWidgets('manual contractor setup completes without enabling GPS', (
    tester,
  ) async {
    TripTrackingSetupResult? result;
    await _pumpLauncher(
      tester,
      const TripTrackingSettings(),
      onResult: (value) => result = value,
    );

    await tester.tap(find.text('Open setup'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Contractor and service work'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enter mileage myself'));
    await tester.pump();
    await tester.tap(find.text('Use Manual Mileage'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.action, TripTrackingSetupAction.skip);
    expect(result!.settings.tripTrackingSetupCompleted, isTrue);
    expect(result!.settings.gpsAssistedTrackingEnabled, isFalse);
    expect(
      result!.settings.defaultProfile,
      TripTrackingProfile.contractorVehicle,
    );
    expect(result!.settings.backgroundTrackingEnabled, isFalse);
    expect(result!.settings.activityRecognitionEnabled, isFalse);
  });

  testWidgets('completed manual setup does not ask work type again', (
    tester,
  ) async {
    await _pumpLauncher(
      tester,
      const TripTrackingSettings(
        tripTrackingSetupCompleted: true,
        defaultProfile: TripTrackingProfile.contractorVehicle,
      ),
    );

    await tester.tap(find.text('Open setup'));
    await tester.pumpAndSettle();

    expect(find.text('Step 1 of 2'), findsOneWidget);
    expect(find.text('Would You Like Location Assistance?'), findsOneWidget);
    expect(find.text('What Type of Work Do You Do?'), findsNothing);
  });

  testWidgets('GPS setup saves work profile and highest accuracy defaults', (
    tester,
  ) async {
    TripTrackingSetupResult? result;
    await _pumpLauncher(
      tester,
      const TripTrackingSettings(),
      onResult: (value) => result = value,
    );

    await tester.tap(find.text('Open setup'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delivery and gig work'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use GPS assistance'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Step 3 of 3'), findsOneWidget);
    expect(find.text('Choose How Tracking Works'), findsOneWidget);
    expect(find.text('Highest accuracy'), findsOneWidget);
    expect(find.text('Track with the screen locked'), findsOneWidget);
    expect(find.text('Suggest stops when I get out'), findsOneWidget);

    await tester.tap(find.text('Turn On Location'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.action, TripTrackingSetupAction.start);
    expect(result!.settings.tripTrackingSetupCompleted, isTrue);
    expect(result!.settings.gpsAssistedTrackingEnabled, isTrue);
    expect(
      result!.settings.defaultProfile,
      TripTrackingProfile.deliveryVehicle,
    );
    expect(
      result!.settings.samplingPreset,
      TripTrackingSamplingPreset.highAccuracy,
    );
  });

  testWidgets('iPhone setup explains Apple location and motion choices', (
    tester,
  ) async {
    await _pumpLauncher(
      tester,
      const TripTrackingSettings(),
      platform: TargetPlatform.iOS,
    );

    await tester.tap(find.text('Open setup'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Contractor and service work'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use GPS assistance'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.textContaining('iPhone will ask for location'), findsOneWidget);
    expect(find.textContaining('Always Allow'), findsOneWidget);
    expect(find.textContaining('Motion & Fitness'), findsOneWidget);
    expect(find.textContaining('Android will ask'), findsNothing);
  });
}

Future<void> _pumpLauncher(
  WidgetTester tester,
  TripTrackingSettings settings, {
  ValueChanged<TripTrackingSetupResult?>? onResult,
  TargetPlatform platform = TargetPlatform.android,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(900, 2400);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(platform: platform),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () async {
                final result = await openTripTrackingSetupSheet(
                  context,
                  currentSettings: settings,
                );
                onResult?.call(result);
              },
              child: const Text('Open setup'),
            ),
          ),
        ),
      ),
    ),
  );
}
