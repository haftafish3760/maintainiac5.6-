/// Widget regression coverage for the App Assistant possible-drive review sheet.
///
/// Verifies visible review and explicit decisions only. It does not create a
/// workday, trip, mileage record, vehicle assignment, or classification.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/dashboard/trip_automatic_evidence_review_sheet.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_automatic_evidence_candidate_store.dart';
import 'package:maintaniac/shared/trip_tracking/trip_automatic_start_detector.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';

void main() {
  testWidgets('possible drive remains unconfirmed after Keep for Review', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final at = DateTime.utc(2026, 8, 4, 12);
    final odometer = GlobalOdometerController(
      vehicleId: 'vehicle_1',
      initialReading: 1000,
    );
    final controller = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      automaticEvidenceCandidateStore:
          TripAutomaticEvidenceCandidateStore.memory(),
      clockNow: () => at.add(const Duration(minutes: 1)),
      odometer: odometer,
    );
    addTearDown(controller.dispose);
    addTearDown(odometer.dispose);
    await controller.captureAutomaticStartAssistance(
      settings: const TripTrackingSettings(
        gpsAssistedTrackingEnabled: true,
        automaticStartAssistanceEnabled: true,
      ),
      accessLevel: TripAutomaticStartAccessLevel.paid,
      observations: List.generate(
        3,
        (index) => TripAutomaticStartObservation(
          recordedAt: at.add(Duration(seconds: index * 15)),
          speedMetersPerSecond: 8,
          displacementMeters: 30,
          horizontalAccuracyMeters: 8,
          activity: TripActivity.automotive,
          activityConfidence: 90,
          bluetoothVehicleId: 'vehicle_1',
        ),
      ),
    );

    await tester.pumpWidget(
      TripTrackingScope(
        controller: controller,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showTripAutomaticEvidenceReviewSheet(context),
                child: const Text('Open review'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open review'));
    await tester.pumpAndSettle();
    expect(find.text('POSSIBLE DRIVE — REVIEW NEEDED'), findsOneWidget);
    expect(find.text('KEEP FOR LATER REVIEW'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('KEEP FOR LATER REVIEW'),
      160,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('KEEP FOR LATER REVIEW'));
    await tester.pumpAndSettle();
    expect(find.text('Kept for later review'), findsOneWidget);
    expect(controller.pendingAutomaticEvidenceCandidates, isEmpty);
    expect(controller.isTracking, isFalse);
    expect(odometer.confirmedReading, 1000);
  });
}
