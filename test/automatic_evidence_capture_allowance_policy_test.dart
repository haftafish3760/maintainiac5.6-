// Regression tests for monthly automatic-evidence-capture allowance rules.
//
// Owns deterministic entitlement, boundary, and consumption timing checks.
// It does not test persistence, billing, GPS detection, or UI presentation.

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/automatic_evidence_capture_allowance_policy.dart';

void main() {
  const policy = AutomaticEvidenceCaptureAllowancePolicy();
  final august = DateTime.utc(2026, 8, 15, 12);

  test('free users receive four accepted recoveries per month', () {
    for (var used = 0; used < 4; used++) {
      final decision = policy.evaluate(
        access: AutomaticEvidenceCaptureAccess.free,
        occurredAt: august,
        acceptedFreeUsesInPeriod: used,
      );
      expect(decision.allowed, isTrue);
      expect(decision.freeUsesRemaining, 4 - used);
      expect(decision.consumesFreeUseIfAccepted, isTrue);
      expect(decision.consumesOnDetection, isFalse);
      expect(decision.consumesOnRejection, isFalse);
    }
  });

  test('fifth accepted free recovery requires paid access', () {
    final decision = policy.evaluate(
      access: AutomaticEvidenceCaptureAccess.free,
      occurredAt: august,
      acceptedFreeUsesInPeriod: 4,
    );

    expect(decision.allowed, isFalse);
    expect(decision.freeUsesRemaining, 0);
    expect(decision.reasonCode, 'free_recovery_allowance_used');
  });

  test('paid access is not consumed as a free recovery', () {
    final decision = policy.evaluate(
      access: AutomaticEvidenceCaptureAccess.paid,
      occurredAt: august,
      acceptedFreeUsesInPeriod: 900,
    );

    expect(decision.allowed, isTrue);
    expect(decision.consumesFreeUseIfAccepted, isFalse);
    expect(decision.requiresUserApproval, isTrue);
    expect(decision.canStartTrip, isFalse);
  });

  test('period key is stable at local and UTC month boundaries', () {
    expect(
      automaticEvidenceCapturePeriodKey(
        DateTime.parse('2026-08-31T23:59:59-04:00'),
      ),
      '2026-09',
    );
    expect(
      automaticEvidenceCapturePeriodKey(DateTime.utc(2027, 1, 1)),
      '2027-01',
    );
  });

  test('negative counters fail safely without creating extra allowance', () {
    final decision = policy.evaluate(
      access: AutomaticEvidenceCaptureAccess.free,
      occurredAt: august,
      acceptedFreeUsesInPeriod: -5,
    );

    expect(decision.acceptedFreeUses, 0);
    expect(decision.freeUsesRemaining, 4);
  });

  test('safe map states proposal-only and approval contracts', () {
    final map = policy
        .evaluate(
          access: AutomaticEvidenceCaptureAccess.free,
          occurredAt: august,
          acceptedFreeUsesInPeriod: 2,
        )
        .toSafeMap();

    expect(map['canStartTrip'], isFalse);
    expect(map['requiresUserApproval'], isTrue);
    expect(map['consumesOnDetection'], isFalse);
    expect(map['consumesOnRejection'], isFalse);
  });
}
