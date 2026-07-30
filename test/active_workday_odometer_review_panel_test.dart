/// Active Day lower-odometer review visibility regression tests.
///
/// Owns the visible pending-review contract. Does not test correction storage
/// or TripLog behavior. Consumed by dashboard UI regression QA.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/dashboard/active_workday_odometer_review_panel.dart';
import 'package:maintaniac/screens/dashboard/data/active_workday_odometer_review.dart';
import 'package:maintaniac/shared/odometer/odometer_correction_review.dart';

void main() {
  final review = ActiveWorkdayOdometerReview(
    id: 'odometer-review-1',
    createdAt: DateTime(2026, 7, 30, 9),
    startingOdometer: 12000,
    enteredOdometer: 11900,
    reason: OdometerCorrectionReason.backdatedEntry,
  );

  testWidgets('pending review is visible and explains no automatic change', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActiveWorkdayOdometerReviewNotice(
            reviews: [review],
            onPressed: () => showActiveWorkdayOdometerReviews(
              tester.element(find.byType(ActiveWorkdayOdometerReviewNotice)),
              reviews: [review],
            ),
          ),
        ),
      ),
    );

    expect(find.text('ODOMETER REVIEW PENDING'), findsOneWidget);
    await tester.tap(find.text('ODOMETER REVIEW PENDING'));
    await tester.pumpAndSettle();

    expect(find.text('Odometer reviews'), findsOneWidget);
    expect(find.text('This is a backdated receipt or trip'), findsOneWidget);
    expect(
      find.textContaining('did not change the vehicle odometer'),
      findsOneWidget,
    );
    expect(find.textContaining('Entered 11900 mi'), findsOneWidget);
  });
}
