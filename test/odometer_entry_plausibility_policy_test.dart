// Regression tests for explainable manual odometer plausibility decisions.
//
// Owns manual-only, elapsed-time, dwell, units, and safe-summary coverage. It
// does not test GPS accuracy, persistence, Dashboard layout, or confirmation.

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/odometer/odometer_distance_value.dart';
import 'package:maintaniac/shared/odometer/odometer_entry_plausibility_policy.dart';
import 'package:maintaniac/shared/odometer/odometer_mileage_review.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';

void main() {
  const policy = OdometerEntryPlausibilityPolicy();
  final enteredAt = DateTime.utc(2026, 8, 1, 12);

  OdometerDistanceValue miles(int tenths) => OdometerDistanceValue.fromTenths(
    tenths: tenths,
    unit: OdometerDistanceUnit.miles,
  )!;

  test('manual-only normal mileage proceeds without GPS or averages', () {
    final decision = policy.evaluate(
      current: miles(10000),
      candidate: miles(10100),
      enteredAt: enteredAt,
    );

    expect(decision.requiresReview, isFalse);
    expect(decision.evidenceSources, ['manual_odometer']);
  });

  test(
    'manual-only large jump requests review without blocking correction',
    () {
      final decision = policy.evaluate(
        current: miles(10000),
        candidate: miles(16000),
        enteredAt: enteredAt,
      );

      expect(decision.requiresReview, isTrue);
      expect(decision.reasonCode, 'manual_only_large_odometer_jump');
      expect(decision.toSafeMap()['canWriteOdometer'], isFalse);
    },
  );

  test('300 miles in three hours requests speed plausibility review', () {
    final decision = policy.evaluate(
      current: miles(10000),
      candidate: miles(13000),
      enteredAt: enteredAt,
      context: OdometerEntryPlausibilityContext(
        workdayStartedAt: enteredAt.subtract(const Duration(hours: 3)),
      ),
    );

    expect(decision.requiresReview, isTrue);
    expect(decision.reasonCode, 'odometer_speed_plausibility_review');
    expect(decision.minimumAverageSpeed, 100);
  });

  test('confirmed dwell tightens only evidence-backed driving time', () {
    final decision = policy.evaluate(
      current: miles(10000),
      candidate: miles(11500),
      enteredAt: enteredAt,
      context: OdometerEntryPlausibilityContext(
        workdayStartedAt: enteredAt.subtract(const Duration(hours: 3)),
        confirmedDwellDuration: const Duration(hours: 2),
        confirmedStopCount: 2,
      ),
    );

    expect(decision.requiresReview, isTrue);
    expect(decision.minimumAverageSpeed, 150);
    expect(decision.evidenceSources, contains('confirmed_stop_dwell'));
    expect(decision.evidenceSources, contains('confirmed_stop_count'));
  });

  test('lower reading explains resolution choices without rewriting truth', () {
    final decision = policy.evaluate(
      current: miles(10000),
      candidate: miles(9990),
      enteredAt: enteredAt,
    );

    expect(decision.requiresReview, isTrue);
    expect(decision.reasonCode, 'odometer_lower_than_confirmed');
    expect(decision.explanation, contains('mistyped'));
    expect(decision.explanation, contains('another vehicle'));
    expect(decision.explanation, contains('backdated'));
  });

  test('unit mismatch cannot be silently converted into vehicle truth', () {
    final kilometers = OdometerDistanceValue.fromTenths(
      tenths: 10000,
      unit: OdometerDistanceUnit.kilometers,
    )!;
    final decision = policy.evaluate(
      current: miles(10000),
      candidate: kilometers,
      enteredAt: enteredAt,
    );

    expect(decision.requiresReview, isTrue);
    expect(decision.reasonCode, 'odometer_unit_mismatch');
  });

  test('safe review output exposes explanations but no confidence score', () {
    final summary = policy
        .evaluate(
          current: miles(10000),
          candidate: miles(16000),
          enteredAt: enteredAt,
        )
        .toSafeMap();

    expect(summary['requiresUserReview'], isTrue);
    expect(summary['explanation'], isNotEmpty);
    expect(summary['expectedResultIfAccepted'], isNotEmpty);
    expect(summary['confidenceScoreShown'], isFalse);
    expect(summary, isNot(contains('confidence')));
  });

  test('kilometer thresholds are equivalent to the mile policy', () {
    final current = OdometerDistanceValue.fromTenths(
      tenths: 10000,
      unit: OdometerDistanceUnit.kilometers,
    )!;
    final candidate = OdometerDistanceValue.fromTenths(
      tenths: 12400,
      unit: OdometerDistanceUnit.kilometers,
    )!;
    final decision = policy.evaluate(
      current: current,
      candidate: candidate,
      enteredAt: enteredAt,
      context: OdometerEntryPlausibilityContext(
        workdayStartedAt: enteredAt.subtract(const Duration(hours: 1)),
      ),
    );

    expect(decision.requiresReview, isTrue);
    expect(decision.reasonCode, 'odometer_speed_plausibility_review');
  });

  test(
    'global odometer requires review before accepting implausible speed',
    () {
      final controller = GlobalOdometerController(initialReading: 1000);
      addTearDown(controller.dispose);
      final context = OdometerEntryPlausibilityContext(
        workdayStartedAt: enteredAt.subtract(const Duration(hours: 3)),
      );

      final review = controller.updateFromText(
        '1300',
        enteredAt: enteredAt,
        mileageReview: const OdometerMileageReview(
          use: OdometerMileageUse.business,
        ),
        plausibilityContext: context,
      );

      expect(review.ok, isFalse);
      expect(review.requiresConfirmation, isTrue);
      expect(review.message, contains('100.0 mph'));
      expect(controller.reading, 1000);

      final confirmed = controller.updateFromText(
        '1300',
        enteredAt: enteredAt,
        confirmSuspicious: true,
        mileageReview: const OdometerMileageReview(
          use: OdometerMileageUse.business,
        ),
        plausibilityContext: context,
      );

      expect(confirmed.ok, isTrue);
      expect(controller.reading, 1300);
    },
  );
}
