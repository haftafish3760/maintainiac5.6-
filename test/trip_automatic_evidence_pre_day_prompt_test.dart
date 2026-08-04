// Widget regression coverage for pre-workday App Assistant review access.
//
// Owns visibility and review navigation checks. Does not test native capture,
// workday creation, trip confirmation, or odometer confirmation.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/dashboard/trip_automatic_evidence_pre_day_prompt.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_automatic_evidence_candidate_store.dart';
import 'package:maintaniac/shared/trip_tracking/trip_automatic_start_detector.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';

void main() {
  testWidgets('pre-workday prompt opens review without starting a trip', (
    tester,
  ) async {
    final at = DateTime.utc(2026, 8, 4, 12);
    final store = TripAutomaticEvidenceCandidateStore.memory();
    final odometer = GlobalOdometerController(initialReading: 1000);
    final controller = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: odometer,
      automaticEvidenceCandidateStore: store,
      clockNow: () => at.add(const Duration(seconds: 30)),
    );
    addTearDown(odometer.dispose);
    addTearDown(controller.dispose);
    await controller.captureAutomaticStartAssistance(
      settings: const TripTrackingSettings(
        gpsAssistedTrackingEnabled: true,
        automaticStartAssistanceEnabled: true,
      ),
      accessLevel: TripAutomaticStartAccessLevel.paid,
      observations: [
        TripAutomaticStartObservation(
          recordedAt: at,
          speedMetersPerSecond: 8,
          displacementMeters: 30,
          horizontalAccuracyMeters: 12,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TripTrackingScope(
          controller: controller,
          child: const Scaffold(body: TripAutomaticEvidencePreDayPrompt()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('App Assistant found 1 possible drive'),
      findsOneWidget,
    );
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    expect(find.text('App Assistant Review'), findsOneWidget);
    expect(controller.isTracking, isFalse);
    expect(odometer.confirmedReading, 1000);
  });
}
